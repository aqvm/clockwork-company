extends RefCounted
class_name CombatSimulator

const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatTextFormatterScript := preload("res://scripts/combat/logging/combat_text_formatter.gd")
const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")
const TurnSchedulerScript := preload("res://scripts/combat/runtime/turn_scheduler.gd")
const TacticResolverScript := preload("res://scripts/combat/rules/tactic_resolver.gd")
const ForecastServiceScript := preload("res://scripts/combat/rules/forecast_service.gd")
const JobEffectResolverScript := preload("res://scripts/combat/rules/job_effect_resolver.gd")
const AncestryFeatureResolverScript := preload("res://scripts/combat/rules/ancestry_feature_resolver.gd")
const ItemEffectResolverScript := preload("res://scripts/combat/rules/item_effect_resolver.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")
const DemoBattleFactoryScript := preload("res://scripts/combat/scenarios/demo_battle_factory.gd")
const CombatContextScript := preload("res://scripts/combat/runtime/combat_context.gd")
const CombatHookResolverScript := preload("res://scripts/combat/rules/combat_hook_resolver.gd")
const LOG_VERSION := 1

func run_demo_battle(enabled_mod_pack_ids: Variant = null) -> Array[String]:
	var report := run_demo_battle_report(enabled_mod_pack_ids)
	return report["lines"]


func run_demo_battle_report(enabled_mod_pack_ids: Variant = null) -> Dictionary:
	var units: Array = DemoBattleFactoryScript.create_demo_units(enabled_mod_pack_ids)
	return run_battle_report_from_units(units, "Phase 6 demo battle")


func run_battle_report(definitions: Array[UnitDefinition], battle_title := "Run battle", scenario_rules: Array = []) -> Dictionary:
	var units: Array = DemoBattleFactoryScript.create_units_from_definitions(definitions)
	return run_battle_report_from_units(units, battle_title, scenario_rules)


func run_battle_report_from_units(units: Array, battle_title := "Run battle", scenario_rules: Array = []) -> Dictionary:
	var log = CombatLogScript.new()
	var actions_taken := 0
	var replay_snapshots: Array[Dictionary] = []
	var context = CombatContextScript.new(units, log, scenario_rules)
	context.add_responder(CombatHookResolverScript.respond)

	log.add(battle_title)
	log.add("Random seed: none yet. This fight is deterministic because there are no random rolls.")
	log.add("Tie-breaker: if two units are ready at the same time, earlier roster position acts first.")
	log.add("Unit definitions: loaded from Resource files in res://resources/units/.")
	log.add("Item definitions: loaded from Resource files in res://resources/items/.")
	log.add("Job definitions: loaded from Resource files in res://resources/jobs/.")
	log.add("Loadout definitions: loaded through each UnitDefinition.")
	log.add("Tactics: loaded from Resource files through each loadout.")
	log.add("")
	_append_jobs_summary(log, units)
	log.add("")
	_append_gear_summary(log, units)
	log.add("")
	_append_tactics_summary(log, units)
	log.add("")
	var battle_start_event := CombatEventsScript.battle_start()
	var battle_start_entry_id: int = log.add_event("Battle starts.", battle_start_event["event_type"], 0, CombatLogScript.NO_PARENT, battle_start_event["payload"], battle_start_event["tags"])
	context.publish("battle_started", null, null, {}, -1, battle_start_entry_id, ["battle"])
	replay_snapshots.append(_build_replay_snapshot(battle_start_entry_id, 0, units))
	log.add("")
	_append_roster(log, units)
	log.add("")
	log.add("Combat log:")

	while TargetingRulesScript.team_has_living_unit(units, CombatConstantsScript.TEAM_ALLY) and TargetingRulesScript.team_has_living_unit(units, CombatConstantsScript.TEAM_ENEMY):
		if actions_taken >= CombatConstantsScript.MAX_ACTIONS:
			log.add("Battle stopped after %d actions to avoid an infinite fight." % CombatConstantsScript.MAX_ACTIONS)
			break

		var actor = TurnSchedulerScript.find_next_actor(units)
		var current_time: int = actor.next_action_time
		var turn_event := CombatEventsScript.turn_start(actor, actor.next_action_time)
		var turn_entry_id: int = log.add_event("%s takes a turn." % actor.unit_name, turn_event["event_type"], current_time, CombatLogScript.NO_PARENT, turn_event["payload"], turn_event["tags"])

		actor.tick_ability_cooldowns()
		context.publish("turn_started", actor, actor, {"time": current_time}, -1, turn_entry_id, ["turn"])
		_clear_guard_if_needed(context, log, turn_entry_id, actor)
		var active_status_instance_ids: Array[int] = actor.status_instance_ids()
		StatusResolverScript.apply_turn_start_statuses(log, turn_entry_id, actor, context)
		_take_tactical_action(context, log, turn_entry_id, actor, units)
		StatusResolverScript.elapse_turn_statuses(log, turn_entry_id, actor, active_status_instance_ids, context)
		context.publish("turn_completed", actor, actor, {"time": current_time}, -1, turn_entry_id, ["turn"])
		actions_taken += 1
		if actor.is_alive():
			TurnSchedulerScript.schedule_next_turn(actor)
		replay_snapshots.append(_build_replay_snapshot(turn_entry_id, current_time, units))

	log.add("")
	var result_text := CombatTextFormatterScript.build_result_line(units, actions_taken)
	var result_event := CombatEventsScript.result(result_text)
	var result_entry_id: int = log.add_event(result_text, result_event["event_type"], CombatLogScript.NO_TIME, CombatLogScript.NO_PARENT, result_event["payload"], result_event["tags"])
	replay_snapshots.append(_build_replay_snapshot(result_entry_id, CombatLogScript.NO_TIME, units))
	return {
		"log_version": LOG_VERSION,
		"lines": log.to_lines(),
		"events": log.to_event_objects(),
		"combat_events": context.event_snapshots(),
		"roster_units": _build_roster_units(units),
		"replay_snapshots": replay_snapshots,
		"winner": _winner_for_units(units),
		"actions_taken": actions_taken,
	}


func _append_jobs_summary(log, units: Array) -> void:
	var jobs_entry_id: int = log.add("Jobs:")
	for unit in units:
		log.add_child(jobs_entry_id, "%s: %s ancestry (%s), %s loadout, %s job. Job skill: %s. Assigned skill: %s. Passive: %s. Reaction: %s. Final stats before battle-start effects: HP %d, physical %d, magic %d, armor %d, interval %d." % [unit.unit_name, unit.ancestry_name(), unit.ancestry_feature_name(), unit.loadout_name(), unit.current_job_name(), unit.skill_name(), unit.assigned_skill_name(), unit.job_effect(), unit.reaction_name(), unit.max_hp, unit.physical_damage, unit.magic_damage, unit.total_armor(), unit.action_interval])


func _append_gear_summary(log, units: Array) -> void:
	var gear_entry_id: int = log.add("Equipped gear:")
	for unit in units:
		if unit.equipped_items.is_empty() and unit.skipped_items.is_empty():
			log.add_child(gear_entry_id, "%s: none" % unit.unit_name)
			continue
		for item in unit.equipped_items:
			log.add_child(gear_entry_id, "%s: %s allowed by %s." % [unit.unit_name, CombatTextFormatterScript.describe_item(item), unit.current_job_name()])
		for item in unit.skipped_items:
			log.add_child(gear_entry_id, "%s: %s skipped. %s cannot equip %s." % [unit.unit_name, CombatTextFormatterScript.describe_item(item), unit.current_job_name(), item.slot.to_lower()])


func _append_tactics_summary(log, units: Array) -> void:
	var tactics_entry_id: int = log.add("Loadout tactics:")
	for unit in units:
		var tactic_texts: Array[String] = []
		for tactic: TacticDefinition in unit.tactics:
			tactic_texts.append(CombatTextFormatterScript.describe_tactic(tactic))
		if tactic_texts.is_empty():
			log.add_child(tactics_entry_id, "%s: none" % unit.unit_name)
		else:
			log.add_child(tactics_entry_id, "%s: %s" % [unit.unit_name, CombatTextFormatterScript.join_text_parts(tactic_texts, "; ")])


func _append_roster(log, units: Array) -> void:
	var roster_entry_id: int = log.add("Roster:")
	for team in [CombatConstantsScript.TEAM_ALLY, CombatConstantsScript.TEAM_ENEMY]:
		var team_entry_id: int = log.add_child(roster_entry_id, "%s" % team)
		for unit in units:
			if unit.team == team:
				log.add_child(team_entry_id, "%s | HP %d | physical %d | magic %d | armor %d | interval %d | item %s | tactics %d" % [unit.unit_name, unit.max_hp, unit.physical_damage, unit.magic_damage, unit.total_armor(), unit.action_interval, CombatTextFormatterScript.item_name_or_none(unit), unit.tactics.size()])


func _take_tactical_action(context, log, turn_entry_id: int, actor, units: Array) -> void:
	var decision: Dictionary = TacticResolverScript.choose_action(actor, units, func(tactic): return foretell_target_for_tactic(actor, units, tactic))
	_log_and_resolve_decision(context, log, turn_entry_id, actor, decision)


func foretell_target_for_tactic(actor, units: Array, tactic: TacticDefinition):
	return ForecastServiceScript.foretell_target(
		actor,
		units,
		tactic,
		_execute_speculative_current_action,
		_execute_speculative_future_turn,
		_evaluate_speculative_tactic_target
	)

func _evaluate_speculative_tactic_target(tactic: TacticDefinition, actor, units: Array):
	var target = TacticResolverScript.find_tactic_target(tactic.target, actor, units, tactic)
	if not TacticResolverScript.condition_matches(tactic.condition, actor, units, target, tactic):
		return {"matched": false}
	return {
		"matched": true,
		"target": target,
	}

func _log_and_resolve_decision(context, log, turn_entry_id: int, actor, decision: Dictionary) -> void:
	for skipped_reason: String in decision.get("skipped_reasons", []):
		var skipped_event := CombatEventsScript.tactic_skipped(actor, skipped_reason)
		log.add_event(skipped_reason, skipped_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, skipped_event["payload"], skipped_event["tags"])
	if String(decision.get("reason_type", "")) == "selected":
		var selected_event := CombatEventsScript.tactic_selected(actor, decision["action"], decision["target"], String(decision.get("reason_tactic", "")))
		log.add_event(decision["reason"], selected_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, selected_event["payload"], selected_event["tags"])
	else:
		var fallback_event := CombatEventsScript.tactic_fallback(actor, decision["target"])
		log.add_event(decision["reason"], fallback_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, fallback_event["payload"], fallback_event["tags"])
	var action_event_id: int = context.publish("action_selected", actor, decision["target"], {"action": decision["action"]}, -1, turn_entry_id, ["action"])
	_resolve_tactic_action(context, log, turn_entry_id, actor, decision["target"], decision["action"], action_event_id)
	context.publish("action_completed", actor, decision["target"], {"action": decision["action"]}, action_event_id, turn_entry_id, ["action"])


func _execute_speculative_current_action(actor, units: Array) -> void:
	var log = CombatLogScript.new()
	var context = CombatContextScript.new(units, log, [], true)
	context.add_responder(CombatHookResolverScript.respond)
	var turn_entry_id: int = log.add("Speculative current action")
	var active_status_instance_ids: Array[int] = actor.status_instance_ids()
	var decision: Dictionary = TacticResolverScript.choose_action(actor, units, Callable(), false)
	var action_event_id: int = context.publish("action_selected", actor, decision["target"], {"action": decision["action"]}, -1, turn_entry_id, ["action"])
	_resolve_tactic_action(context, log, turn_entry_id, actor, decision["target"], decision["action"], action_event_id)
	context.publish("action_completed", actor, decision["target"], {"action": decision["action"]}, action_event_id, turn_entry_id, ["action"])
	StatusResolverScript.elapse_turn_statuses(log, turn_entry_id, actor, active_status_instance_ids, context)


func _execute_speculative_future_turn(actor, units: Array) -> void:
	var log = CombatLogScript.new()
	var context = CombatContextScript.new(units, log, [], true)
	context.add_responder(CombatHookResolverScript.respond)
	var turn_entry_id: int = log.add("Speculative future turn")
	context.publish("turn_started", actor, actor, {"time": actor.next_action_time}, -1, turn_entry_id, ["turn"])
	actor.tick_ability_cooldowns()
	_clear_guard_if_needed(context, log, turn_entry_id, actor)
	var active_status_instance_ids: Array[int] = actor.status_instance_ids()
	StatusResolverScript.apply_turn_start_statuses(log, turn_entry_id, actor, context)
	var decision: Dictionary = TacticResolverScript.choose_action(actor, units, Callable(), false)
	var action_event_id: int = context.publish("action_selected", actor, decision["target"], {"action": decision["action"]}, -1, turn_entry_id, ["action"])
	_resolve_tactic_action(context, log, turn_entry_id, actor, decision["target"], decision["action"], action_event_id)
	context.publish("action_completed", actor, decision["target"], {"action": decision["action"]}, action_event_id, turn_entry_id, ["action"])
	StatusResolverScript.elapse_turn_statuses(log, turn_entry_id, actor, active_status_instance_ids, context)
	context.publish("turn_completed", actor, actor, {"time": actor.next_action_time}, -1, turn_entry_id, ["turn"])
	if actor.is_alive():
		TurnSchedulerScript.schedule_next_turn(actor)


func _resolve_tactic_action(context, log, turn_entry_id: int, actor, target, action: String, parent_event_id := -1) -> void:
	if action == CombatConstantsScript.ACTION_JOB_SKILL:
		_resolve_skill(context, log, turn_entry_id, actor, target, actor.current_skill, "job skill", parent_event_id)
		return
	if action == CombatConstantsScript.ACTION_ASSIGNED_SKILL:
		_resolve_skill(context, log, turn_entry_id, actor, target, actor.assigned_skill, "assigned skill", parent_event_id)
		return
	if action == CombatConstantsScript.ACTION_HEAL:
		_resolve_heal(context, log, turn_entry_id, actor, target, 0, parent_event_id)
		return
	if action == CombatConstantsScript.ACTION_GUARD:
		_resolve_guard(context, log, turn_entry_id, actor, 0, parent_event_id)
		return
	_resolve_attack(context, log, turn_entry_id, actor, target, 0, [], parent_event_id, "Physical")


func _resolve_skill(context, log, turn_entry_id: int, actor, target, skill: SkillDefinition, skill_source: String, parent_event_id := -1) -> void:
	if skill == null or not actor.skill_is_ready(skill):
		log.add_child(turn_entry_id, "%s has no available %s; default attack used." % [actor.unit_name, skill_source])
		_resolve_attack(context, log, turn_entry_id, actor, target, 0, [], parent_event_id, "Physical")
		return
	actor.start_skill_cooldown(skill)
	var event := CombatEventsScript.job_effect(actor, skill.display_name, "uses %s" % skill.action.to_lower())
	log.add_event("%s uses %s %s." % [actor.unit_name, skill_source, skill.display_name], event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])
	var skill_event_id: int = context.publish("skill_used", actor, target, {"skill": skill.display_name, "skill_source": skill_source, "action": skill.action}, parent_event_id, turn_entry_id, ["skill", "action"])
	if skill.action == CombatConstantsScript.ACTION_HEAL:
		_resolve_heal(context, log, turn_entry_id, actor, target, skill.amount_modifier, skill_event_id)
		_publish_skill_completed(context, actor, target, skill, skill_source, skill_event_id, turn_entry_id)
		return
	if skill.action == CombatConstantsScript.ACTION_GUARD:
		_resolve_guard(context, log, turn_entry_id, actor, skill.amount_modifier, skill_event_id)
		_publish_skill_completed(context, actor, target, skill, skill_source, skill_event_id, turn_entry_id)
		return
	if skill.action == CombatConstantsScript.ACTION_APPLY_STATUS:
		StatusResolverScript.apply_status(log, turn_entry_id, target, skill.status, skill.display_name, skill.status_duration_turns, skill.status_is_permanent, context, actor, skill_event_id)
		_publish_skill_completed(context, actor, target, skill, skill_source, skill_event_id, turn_entry_id)
		return
	if skill.action == CombatConstantsScript.ACTION_EFFECTS_ONLY:
		_publish_skill_completed(context, actor, target, skill, skill_source, skill_event_id, turn_entry_id)
		return
	for _attack_index in range(skill.attack_count):
		if target == null or not target.is_alive():
			break
		_resolve_attack(context, log, turn_entry_id, actor, target, skill.amount_modifier, skill.tags, skill_event_id, skill.attack_damage_type)
	_publish_skill_completed(context, actor, target, skill, skill_source, skill_event_id, turn_entry_id)


func _publish_skill_completed(context, actor, target, skill: SkillDefinition, skill_source: String, parent_event_id: int, parent_log_id: int) -> void:
	context.publish("skill_completed", actor, target, {"skill": skill.display_name, "skill_source": skill_source, "action": skill.action}, parent_event_id, parent_log_id, ["skill", "completed"])


func _resolve_attack(context, log, turn_entry_id: int, actor, target, skill_damage_bonus := 0, source_tags: Array = [], parent_event_id := -1, attack_damage_type := "Physical") -> void:
	if attack_damage_type == "Physical" and source_tags.has("magic"):
		attack_damage_type = "Magic"
	var target_request: Dictionary = context.request("attack_target_requested", actor, target, {"target_unit_id": target.unit_id}, parent_event_id, turn_entry_id, ["attack", "target", "request"])
	if bool(target_request["payload"].get("prevented", false)):
		context.publish("attack_prevented", actor, target, target_request["payload"], int(target_request["id"]), turn_entry_id, ["attack", "prevented"])
		return
	target = _unit_by_id(context.units, String(target_request["payload"].get("target_unit_id", target.unit_id)))
	if target == null or not target.is_alive():
		return
	var targeted_event_id: int = context.publish("attack_targeted", actor, target, {}, int(target_request["id"]), turn_entry_id, ["attack", "targeted"])
	var attack_event := CombatEventsScript.attack(actor, target)
	var attack_entry_id: int = log.add_event("%s attacks %s." % [actor.unit_name, target.unit_name], attack_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, attack_event["payload"], attack_event["tags"])
	var attack_hook_id: int = context.publish("attack_performed", actor, target, {"tags": source_tags.duplicate(), "bonus_damage": 0}, targeted_event_id, attack_entry_id, ["attack"])
	var attack_event_data: Dictionary = context.event_by_id(attack_hook_id)
	var bonus_damage: int = skill_damage_bonus + int(attack_event_data.get("payload", {}).get("bonus_damage", 0)) + JobEffectResolverScript.attack_bonus(log, attack_entry_id, actor, context)
	var ancestry_attack_bonuses: Dictionary = AncestryFeatureResolverScript.attack_bonus(log, attack_entry_id, actor, context)
	var item_attack_bonuses: Dictionary = ItemEffectResolverScript.apply_attack_item_effects(log, attack_entry_id, actor, target, context)
	var target_armor: int = target.total_armor()
	var physical_component := int(item_attack_bonuses.get("physical", 0)) + int(ancestry_attack_bonuses.get("physical", 0))
	var magic_component := int(item_attack_bonuses.get("magic", 0)) + int(ancestry_attack_bonuses.get("magic", 0))
	if attack_damage_type == "Magic":
		magic_component += actor.magic_damage + bonus_damage
	elif attack_damage_type == "Split Evenly":
		var split_base: int = actor.physical_damage + bonus_damage
		physical_component += int(ceil(float(split_base) / 2.0))
		magic_component += int(floor(float(split_base) / 2.0))
	else:
		physical_component += actor.physical_damage + bonus_damage
	var physical_damage_taken := 0
	if physical_component > 0:
		physical_damage_taken = max(1, physical_component - target_armor)
	var damage_taken: int = max(1, physical_damage_taken + magic_component)
	var damage_request: Dictionary = context.request("damage_requested", actor, target, {
		"physical_amount": physical_damage_taken,
		"magic_amount": magic_component,
		"amount": damage_taken,
		"prevented": false,
	}, attack_hook_id, attack_entry_id, source_tags + ["attack", "damage", "request"])
	if bool(damage_request["payload"].get("prevented", false)):
		context.publish("damage_prevented", actor, target, damage_request["payload"], int(damage_request["id"]), attack_entry_id, ["damage", "prevented"])
		return
	physical_damage_taken = int(damage_request["payload"].get("physical_amount", physical_damage_taken))
	magic_component = int(damage_request["payload"].get("magic_amount", magic_component))
	damage_taken = max(0, int(damage_request["payload"].get("amount", physical_damage_taken + magic_component)))
	var previous_hp: int = target.hp
	target.hp = max(0, target.hp - damage_taken)
	_assert_damage_event_consistency(damage_taken, previous_hp, target.hp)
	if target.is_alive():
		ItemEffectResolverScript.apply_hit_item_effects(log, attack_entry_id, actor, target, context)
	context.record_damage(actor, target, damage_taken, previous_hp, physical_damage_taken, magic_component, attack_hook_id, attack_entry_id, source_tags + ["attack"])


func _unit_by_id(units: Array, unit_id: String):
	for unit in units:
		if unit.unit_id == unit_id:
			return unit
	return null


func _resolve_heal(context, log, turn_entry_id: int, actor, target, skill_heal_bonus := 0, parent_event_id := -1) -> void:
	var heal_amount: int = CombatConstantsScript.HEAL_AMOUNT + skill_heal_bonus + JobEffectResolverScript.heal_bonus(log, turn_entry_id, actor, context)
	context.apply_healing(actor, target, heal_amount, parent_event_id, turn_entry_id, ["healing", "action"])


func _resolve_guard(context, log, turn_entry_id: int, actor, skill_guard_bonus := 0, parent_event_id := -1) -> void:
	actor.guard_armor = CombatConstantsScript.GUARD_ARMOR_AMOUNT + skill_guard_bonus + JobEffectResolverScript.guard_bonus(log, turn_entry_id, actor, context)
	var guard_event := CombatEventsScript.guard(actor, actor.guard_armor, actor.total_armor())
	log.add_event("%s guards: temporary armor +%d until their next turn. Armor is now %d." % [actor.unit_name, actor.guard_armor, actor.total_armor()], guard_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, guard_event["payload"], guard_event["tags"])
	context.publish("armor_gained", actor, actor, {"amount": actor.guard_armor, "armor_kind": "temporary"}, parent_event_id, turn_entry_id, ["armor"])


func _clear_guard_if_needed(context, log, turn_entry_id: int, actor) -> void:
	if actor.guard_armor == 0:
		return
	var previous_armor: int = actor.total_armor()
	var guard_expire_event := CombatEventsScript.guard_expire(actor, previous_armor, actor.armor)
	log.add_event("%s's guard expires: armor %d -> %d." % [actor.unit_name, previous_armor, actor.armor], guard_expire_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, guard_expire_event["payload"], guard_expire_event["tags"])
	context.publish("armor_lost", actor, actor, {"amount": actor.guard_armor, "armor_kind": "temporary", "reason": "expired"}, -1, turn_entry_id, ["armor"])
	actor.guard_armor = 0


func _build_roster_units(units: Array) -> Array[Dictionary]:
	var roster_units: Array[Dictionary] = []
	for unit in units:
		roster_units.append({
			"id": unit.unit_id,
			"campaign_unit_id": unit.campaign_unit_id,
			"name": unit.unit_name,
			"team": unit.team,
			"max_hp": unit.max_hp,
			"physical_damage": unit.physical_damage,
			"magic_damage": unit.magic_damage,
			"armor": unit.total_armor(),
			"energy_shield": unit.energy_shield,
			"action_interval": unit.action_interval,
			"statuses": unit.status_snapshots(),
			"temporary_modifiers": unit.temporary_modifier_snapshots(),
		})
	return roster_units


func _build_replay_snapshot(root_event_id: int, time: int, units: Array) -> Dictionary:
	var unit_snapshots: Array[Dictionary] = []
	for unit in units:
		unit_snapshots.append({
			"id": unit.unit_id,
			"campaign_unit_id": unit.campaign_unit_id,
			"name": unit.unit_name,
			"team": unit.team,
			"max_hp": unit.max_hp,
			"hp": unit.hp,
			"physical_damage": unit.physical_damage,
			"magic_damage": unit.magic_damage,
			"armor": unit.total_armor(),
			"energy_shield": unit.energy_shield,
			"action_interval": unit.action_interval,
			"next_action_time": unit.next_action_time,
			"is_alive": unit.is_alive(),
			"is_defeated": not unit.is_alive(),
			"statuses": unit.status_snapshots(),
			"temporary_modifiers": unit.temporary_modifier_snapshots(),
		})
	return {
		"root_event_id": root_event_id,
		"time": time,
		"units": unit_snapshots,
	}


func _winner_for_units(units: Array) -> String:
	var allies_alive := TargetingRulesScript.team_has_living_unit(units, CombatConstantsScript.TEAM_ALLY)
	var enemies_alive := TargetingRulesScript.team_has_living_unit(units, CombatConstantsScript.TEAM_ENEMY)
	if allies_alive and not enemies_alive:
		return CombatConstantsScript.TEAM_ALLY
	if enemies_alive and not allies_alive:
		return CombatConstantsScript.TEAM_ENEMY
	return "None"


func _assert_damage_event_consistency(damage_taken: int, previous_hp: int, new_hp: int) -> void:
	assert(damage_taken >= 1, "Damage must be at least 1.")
	assert(new_hp <= previous_hp, "Damage event increased HP unexpectedly.")
	assert(previous_hp - new_hp == damage_taken or new_hp == 0, "Damage/HP delta mismatch.")


func _assert_heal_event_consistency(applied_heal: int, previous_hp: int, new_hp: int, attempted_heal: int) -> void:
	assert(attempted_heal >= 0, "Attempted heal must be non-negative.")
	assert(new_hp >= previous_hp, "Heal event reduced HP unexpectedly.")
	assert(applied_heal == (new_hp - previous_hp), "Heal/HP delta mismatch.")
