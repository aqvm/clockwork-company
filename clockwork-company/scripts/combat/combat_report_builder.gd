extends RefCounted

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatTextFormatterScript := preload("res://scripts/combat/logging/combat_text_formatter.gd")


static func append_jobs_summary(log, units: Array) -> void:
	var jobs_entry_id: int = log.add("Jobs:")
	for unit in units:
		log.add_child(jobs_entry_id, "%s: %s ancestry (%s), %s loadout, %s job. Job skill: %s. Secondary skill: %s. Assigned skill: %s. Passive: %s. Reaction: %s. Final stats before battle-start effects: HP %d, physical %d, magic %d, armor %d, action speed %d." % [unit.unit_name, unit.ancestry_name(), unit.ancestry_feature_name(), unit.loadout_name(), unit.current_job_name(), unit.skill_name(), unit.secondary_skill_name(), unit.assigned_skill_name(), unit.job_effect(), unit.reaction_name(), unit.max_hp, unit.physical_damage, unit.magic_damage, unit.total_armor(), unit.action_speed])


static func append_gear_summary(log, units: Array) -> void:
	var gear_entry_id: int = log.add("Equipped gear:")
	for unit in units:
		if unit.equipped_items.is_empty() and unit.skipped_items.is_empty():
			log.add_child(gear_entry_id, "%s: none" % unit.unit_name)
			continue
		for item in unit.equipped_items:
			log.add_child(gear_entry_id, "%s: %s allowed by %s." % [unit.unit_name, CombatTextFormatterScript.describe_item(item), unit.current_job_name()])
		for item in unit.skipped_items:
			log.add_child(gear_entry_id, "%s: %s skipped. %s cannot equip %s." % [unit.unit_name, CombatTextFormatterScript.describe_item(item), unit.current_job_name(), item.slot.to_lower()])


static func append_tactics_summary(log, units: Array) -> void:
	var tactics_entry_id: int = log.add("Loadout tactics:")
	for unit in units:
		var tactic_texts: Array[String] = []
		for tactic: TacticDefinition in unit.tactics:
			tactic_texts.append(CombatTextFormatterScript.describe_tactic(tactic))
		if tactic_texts.is_empty():
			log.add_child(tactics_entry_id, "%s: none" % unit.unit_name)
		else:
			log.add_child(tactics_entry_id, "%s: %s" % [unit.unit_name, CombatTextFormatterScript.join_text_parts(tactic_texts, "; ")])


static func append_roster(log, units: Array) -> void:
	var roster_entry_id: int = log.add("Roster:")
	for team in [CombatConstantsScript.TEAM_ALLY, CombatConstantsScript.TEAM_ENEMY]:
		var team_entry_id: int = log.add_child(roster_entry_id, "%s" % team)
		for unit in units:
			if unit.team == team:
				log.add_child(team_entry_id, "%s | HP %d | physical %d | magic %d | armor %d | action speed %d | item %s | tactics %d" % [unit.unit_name, unit.max_hp, unit.physical_damage, unit.magic_damage, unit.total_armor(), unit.action_speed, CombatTextFormatterScript.item_name_or_none(unit), unit.tactics.size()])


static func roster_units(units: Array) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for unit in units:
		snapshots.append({
			"id": unit.unit_id,
			"campaign_unit_id": unit.campaign_unit_id,
			"name": unit.unit_name,
			"team": unit.team,
			"max_hp": unit.max_hp,
			"physical_damage": unit.physical_damage,
			"magic_damage": unit.magic_damage,
			"armor": unit.total_armor(),
			"energy_shield": unit.energy_shield,
			"action_speed": unit.action_speed,
			"statuses": unit.status_snapshots(),
			"temporary_modifiers": unit.temporary_modifier_snapshots(),
		})
	return snapshots


static func replay_snapshot(root_event_id: int, time: int, units: Array) -> Dictionary:
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
			"action_speed": unit.action_speed,
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
