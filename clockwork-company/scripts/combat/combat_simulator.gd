extends RefCounted
class_name CombatSimulator

const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatTextFormatterScript := preload("res://scripts/combat/logging/combat_text_formatter.gd")
const TurnSchedulerScript := preload("res://scripts/combat/runtime/turn_scheduler.gd")
const TacticResolverScript := preload("res://scripts/combat/rules/tactic_resolver.gd")
const JobEffectResolverScript := preload("res://scripts/combat/rules/job_effect_resolver.gd")
const ItemEffectResolverScript := preload("res://scripts/combat/rules/item_effect_resolver.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")
const DemoBattleFactoryScript := preload("res://scripts/combat/scenarios/demo_battle_factory.gd")

func run_demo_battle() -> Array[String]:
	var units: Array = DemoBattleFactoryScript.create_demo_units()
	var log = CombatLogScript.new()
	var actions_taken := 0

	log.add("Phase 6 demo battle")
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
	ItemEffectResolverScript.apply_battle_start_item_effects(log, units)
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
		var turn_entry_id: int = log.add_at_time(current_time, "%s takes a turn." % actor.unit_name)

		_clear_guard_if_needed(log, turn_entry_id, actor)
		_take_tactical_action(log, turn_entry_id, actor, units)
		actions_taken += 1
		TurnSchedulerScript.schedule_next_turn(actor)

	log.add("")
	log.add(CombatTextFormatterScript.build_result_line(units, actions_taken))
	return log.to_lines()


func _append_jobs_summary(log, units: Array) -> void:
	var jobs_entry_id: int = log.add("Jobs:")
	for unit in units:
		log.add_child(jobs_entry_id, "%s: %s loadout, %s job. Job effect: %s. Final stats before battle-start effects: HP %d, damage %d, armor %d, interval %d." % [unit.unit_name, unit.loadout_name(), unit.current_job_name(), unit.job_effect().to_lower(), unit.max_hp, unit.damage, unit.total_armor(), unit.action_interval])


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
				log.add_child(team_entry_id, "%s | HP %d | damage %d | armor %d | interval %d | item %s | tactics %d" % [unit.unit_name, unit.max_hp, unit.damage, unit.total_armor(), unit.action_interval, CombatTextFormatterScript.item_name_or_none(unit), unit.tactics.size()])


func _take_tactical_action(log, turn_entry_id: int, actor, units: Array) -> void:
	var decision: Dictionary = TacticResolverScript.choose_action(actor, units)
	for skipped_reason: String in decision.get("skipped_reasons", []):
		log.add_child(turn_entry_id, skipped_reason)
	log.add_child(turn_entry_id, decision["reason"])
	_resolve_tactic_action(log, turn_entry_id, actor, decision["target"], decision["action"])


func _resolve_tactic_action(log, turn_entry_id: int, actor, target, action: String) -> void:
	if action == CombatConstantsScript.ACTION_HEAL:
		_resolve_heal(log, turn_entry_id, actor, target)
		return
	if action == CombatConstantsScript.ACTION_GUARD:
		_resolve_guard(log, turn_entry_id, actor)
		return
	_resolve_attack(log, turn_entry_id, actor, target)


func _resolve_attack(log, turn_entry_id: int, actor, target) -> void:
	var attack_entry_id: int = log.add_child(turn_entry_id, "%s attacks %s." % [actor.unit_name, target.unit_name])
	var bonus_damage: int = JobEffectResolverScript.attack_bonus(log, attack_entry_id, actor)
	bonus_damage += ItemEffectResolverScript.apply_attack_item_effects(log, attack_entry_id, actor, target)
	var target_armor: int = target.total_armor()
	var damage_taken: int = max(1, actor.damage + bonus_damage - target_armor)
	var previous_hp: int = target.hp
	target.hp = max(0, target.hp - damage_taken)
	log.add_child(attack_entry_id, "Damage dealt: %d. %s armor: %d. HP: %d -> %d." % [damage_taken, target.unit_name, target_armor, previous_hp, target.hp])
	if target.is_alive():
		ItemEffectResolverScript.apply_hit_item_effects(log, attack_entry_id, actor, target)
	if not target.is_alive():
		log.add_child(attack_entry_id, "%s is defeated." % target.unit_name)
		ItemEffectResolverScript.apply_kill_item_effects(log, attack_entry_id, actor)
		ItemEffectResolverScript.apply_death_item_effects(log, attack_entry_id, target, actor)


func _resolve_heal(log, turn_entry_id: int, actor, target) -> void:
	var previous_hp: int = target.hp
	var heal_amount: int = CombatConstantsScript.HEAL_AMOUNT + JobEffectResolverScript.heal_bonus(log, turn_entry_id, actor)
	target.hp = min(target.max_hp, target.hp + heal_amount)
	log.add_child(turn_entry_id, "%s heals %s for %d HP. HP: %d -> %d." % [actor.unit_name, target.unit_name, target.hp - previous_hp, previous_hp, target.hp])


func _resolve_guard(log, turn_entry_id: int, actor) -> void:
	actor.guard_armor = CombatConstantsScript.GUARD_ARMOR_AMOUNT + JobEffectResolverScript.guard_bonus(log, turn_entry_id, actor)
	log.add_child(turn_entry_id, "%s guards: temporary armor +%d until their next turn. Armor is now %d." % [actor.unit_name, actor.guard_armor, actor.total_armor()])


func _clear_guard_if_needed(log, turn_entry_id: int, actor) -> void:
	if actor.guard_armor == 0:
		return
	var previous_armor: int = actor.total_armor()
	log.add_child(turn_entry_id, "%s's guard expires: armor %d -> %d." % [actor.unit_name, previous_armor, actor.armor])
	actor.guard_armor = 0
