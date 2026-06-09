extends RefCounted
class_name CombatSimulator

const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatTextFormatterScript := preload("res://scripts/combat/logging/combat_text_formatter.gd")
const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")
const TurnSchedulerScript := preload("res://scripts/combat/runtime/turn_scheduler.gd")
const TacticResolverScript := preload("res://scripts/combat/rules/tactic_resolver.gd")
const JobEffectResolverScript := preload("res://scripts/combat/rules/job_effect_resolver.gd")
const AncestryFeatureResolverScript := preload("res://scripts/combat/rules/ancestry_feature_resolver.gd")
const ItemEffectResolverScript := preload("res://scripts/combat/rules/item_effect_resolver.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")
const DemoBattleFactoryScript := preload("res://scripts/combat/scenarios/demo_battle_factory.gd")
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
	ItemEffectResolverScript.apply_battle_start_item_effects(log, units, battle_start_entry_id)
	AncestryFeatureResolverScript.apply_battle_start_features(log, units, battle_start_entry_id)
	StatusResolverScript.apply_scenario_rule_statuses(log, units, scenario_rules, battle_start_entry_id)
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
		_clear_guard_if_needed(log, turn_entry_id, actor)
		var active_status_instance_ids: Array[int] = actor.status_instance_ids()
		StatusResolverScript.apply_turn_start_statuses(log, turn_entry_id, actor)
		_take_tactical_action(log, turn_entry_id, actor, units)
		StatusResolverScript.elapse_turn_statuses(log, turn_entry_id, actor, active_status_instance_ids)
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


func _take_tactical_action(log, turn_entry_id: int, actor, units: Array) -> void:
	var decision: Dictionary = TacticResolverScript.choose_action(actor, units)
	for skipped_reason: String in decision.get("skipped_reasons", []):
		var skipped_event := CombatEventsScript.tactic_skipped(actor, skipped_reason)
		log.add_event(skipped_reason, skipped_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, skipped_event["payload"], skipped_event["tags"])
	if String(decision.get("reason_type", "")) == "selected":
		var selected_event := CombatEventsScript.tactic_selected(actor, decision["action"], decision["target"], String(decision.get("reason_tactic", "")))
		log.add_event(decision["reason"], selected_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, selected_event["payload"], selected_event["tags"])
	else:
		var fallback_event := CombatEventsScript.tactic_fallback(actor, decision["target"])
		log.add_event(decision["reason"], fallback_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, fallback_event["payload"], fallback_event["tags"])
	_resolve_tactic_action(log, turn_entry_id, actor, decision["target"], decision["action"])


func _resolve_tactic_action(log, turn_entry_id: int, actor, target, action: String) -> void:
	if action == CombatConstantsScript.ACTION_JOB_SKILL:
		_resolve_skill(log, turn_entry_id, actor, target, actor.current_skill, "job skill")
		return
	if action == CombatConstantsScript.ACTION_ASSIGNED_SKILL:
		_resolve_skill(log, turn_entry_id, actor, target, actor.assigned_skill, "assigned skill")
		return
	if action == CombatConstantsScript.ACTION_HEAL:
		_resolve_heal(log, turn_entry_id, actor, target)
		return
	if action == CombatConstantsScript.ACTION_GUARD:
		_resolve_guard(log, turn_entry_id, actor)
		return
	_resolve_attack(log, turn_entry_id, actor, target)


func _resolve_skill(log, turn_entry_id: int, actor, target, skill: SkillDefinition, skill_source: String) -> void:
	if skill == null:
		log.add_child(turn_entry_id, "%s has no available %s; default attack used." % [actor.unit_name, skill_source])
		_resolve_attack(log, turn_entry_id, actor, target)
		return
	var event := CombatEventsScript.job_effect(actor, skill.display_name, "uses %s" % skill.action.to_lower())
	log.add_event("%s uses %s %s." % [actor.unit_name, skill_source, skill.display_name], event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])
	if skill.action == CombatConstantsScript.ACTION_HEAL:
		_resolve_heal(log, turn_entry_id, actor, target, skill.amount_modifier)
		return
	if skill.action == CombatConstantsScript.ACTION_GUARD:
		_resolve_guard(log, turn_entry_id, actor, skill.amount_modifier)
		return
	if skill.action == CombatConstantsScript.ACTION_APPLY_STATUS:
		StatusResolverScript.apply_status(log, turn_entry_id, target, skill.status, skill.display_name, skill.status_duration_turns, skill.status_is_permanent)
		return
	_resolve_attack(log, turn_entry_id, actor, target, skill.amount_modifier, skill.tags)


func _resolve_attack(log, turn_entry_id: int, actor, target, skill_damage_bonus := 0, source_tags: Array[String] = []) -> void:
	var attack_event := CombatEventsScript.attack(actor, target)
	var attack_entry_id: int = log.add_event("%s attacks %s." % [actor.unit_name, target.unit_name], attack_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, attack_event["payload"], attack_event["tags"])
	var bonus_damage: int = skill_damage_bonus + JobEffectResolverScript.attack_bonus(log, attack_entry_id, actor)
	var ancestry_attack_bonuses: Dictionary = AncestryFeatureResolverScript.attack_bonus(log, attack_entry_id, actor)
	var item_attack_bonuses: Dictionary = ItemEffectResolverScript.apply_attack_item_effects(log, attack_entry_id, actor, target)
	var is_magic_damage := source_tags.has("magic")
	var base_damage: int = actor.magic_damage if is_magic_damage else actor.physical_damage
	var target_armor: int = target.total_armor()
	var physical_component := int(item_attack_bonuses.get("physical", 0)) + int(ancestry_attack_bonuses.get("physical", 0))
	var magic_component := int(item_attack_bonuses.get("magic", 0)) + int(ancestry_attack_bonuses.get("magic", 0))
	if is_magic_damage:
		magic_component += base_damage + bonus_damage
	else:
		physical_component += base_damage + bonus_damage
	var physical_damage_taken := 0
	if physical_component > 0:
		physical_damage_taken = max(1, physical_component - target_armor)
	var damage_taken: int = max(1, physical_damage_taken + magic_component)
	var previous_hp: int = target.hp
	target.hp = max(0, target.hp - damage_taken)
	StatusResolverScript.record_damage(target, previous_hp - target.hp)
	_assert_damage_event_consistency(damage_taken, previous_hp, target.hp)
	var damage_event := CombatEventsScript.damage(actor, target, damage_taken, target_armor, previous_hp, target.hp)
	log.add_event("Damage dealt: %d. Physical %d after armor %d, magic %d. HP: %d -> %d." % [damage_taken, physical_damage_taken, target_armor, magic_component, previous_hp, target.hp], damage_event["event_type"], CombatLogScript.NO_TIME, attack_entry_id, damage_event["payload"], damage_event["tags"])
	if target.is_alive():
		ItemEffectResolverScript.apply_hit_item_effects(log, attack_entry_id, actor, target)
		ItemEffectResolverScript.apply_damaged_item_effects(log, attack_entry_id, target, actor)
		AncestryFeatureResolverScript.apply_damaged_feature(log, attack_entry_id, target, actor)
		JobEffectResolverScript.apply_damaged_reaction(log, attack_entry_id, target, actor)
	if not target.is_alive():
		var defeat_event := CombatEventsScript.defeat(target)
		log.add_event("%s is defeated." % target.unit_name, defeat_event["event_type"], CombatLogScript.NO_TIME, attack_entry_id, defeat_event["payload"], defeat_event["tags"])
		ItemEffectResolverScript.apply_kill_item_effects(log, attack_entry_id, actor)
		AncestryFeatureResolverScript.apply_kill_feature(log, attack_entry_id, actor)
		ItemEffectResolverScript.apply_death_item_effects(log, attack_entry_id, target, actor)


func _resolve_heal(log, turn_entry_id: int, actor, target, skill_heal_bonus := 0) -> void:
	var previous_hp: int = target.hp
	var heal_amount: int = CombatConstantsScript.HEAL_AMOUNT + skill_heal_bonus + JobEffectResolverScript.heal_bonus(log, turn_entry_id, actor)
	target.hp = min(target.max_hp, target.hp + heal_amount)
	var applied_heal: int = target.hp - previous_hp
	_assert_heal_event_consistency(applied_heal, previous_hp, target.hp, heal_amount)
	var heal_event := CombatEventsScript.heal(actor, target, applied_heal, previous_hp, target.hp)
	log.add_event("%s heals %s for %d HP. HP: %d -> %d." % [actor.unit_name, target.unit_name, applied_heal, previous_hp, target.hp], heal_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, heal_event["payload"], heal_event["tags"])


func _resolve_guard(log, turn_entry_id: int, actor, skill_guard_bonus := 0) -> void:
	actor.guard_armor = CombatConstantsScript.GUARD_ARMOR_AMOUNT + skill_guard_bonus + JobEffectResolverScript.guard_bonus(log, turn_entry_id, actor)
	var guard_event := CombatEventsScript.guard(actor, actor.guard_armor, actor.total_armor())
	log.add_event("%s guards: temporary armor +%d until their next turn. Armor is now %d." % [actor.unit_name, actor.guard_armor, actor.total_armor()], guard_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, guard_event["payload"], guard_event["tags"])


func _clear_guard_if_needed(log, turn_entry_id: int, actor) -> void:
	if actor.guard_armor == 0:
		return
	var previous_armor: int = actor.total_armor()
	var guard_expire_event := CombatEventsScript.guard_expire(actor, previous_armor, actor.armor)
	log.add_event("%s's guard expires: armor %d -> %d." % [actor.unit_name, previous_armor, actor.armor], guard_expire_event["event_type"], CombatLogScript.NO_TIME, turn_entry_id, guard_expire_event["payload"], guard_expire_event["tags"])
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
			"action_interval": unit.action_interval,
			"statuses": unit.status_snapshots(),
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
			"action_interval": unit.action_interval,
			"next_action_time": unit.next_action_time,
			"is_alive": unit.is_alive(),
			"is_defeated": not unit.is_alive(),
			"statuses": unit.status_snapshots(),
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
