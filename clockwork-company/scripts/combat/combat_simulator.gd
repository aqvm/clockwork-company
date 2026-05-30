extends RefCounted

class_name CombatSimulator

const TEAM_ALLY := "Allies"
const TEAM_ENEMY := "Enemies"
const MAX_ACTIONS := 100


class UnitState:
	var unit_name := ""
	var team := ""
	var max_hp := 1
	var hp := 1
	var damage := 1
	var armor := 0
	var action_interval := 10
	var next_action_time := 10
	var slot_index := 0

	func _init(definition: Dictionary, unit_slot_index: int) -> void:
		unit_name = definition["name"]
		team = definition["team"]
		max_hp = definition["max_hp"]
		hp = max_hp
		damage = definition["damage"]
		armor = definition["armor"]
		action_interval = definition["action_interval"]
		next_action_time = action_interval
		slot_index = unit_slot_index

	func is_alive() -> bool:
		return hp > 0


func run_demo_battle() -> Array[String]:
	var units := _create_demo_units()
	var log: Array[String] = []
	var actions_taken := 0

	log.append("Phase 1 demo battle")
	log.append("Random seed: none yet. This fight is deterministic because there are no random rolls.")
	log.append("Tie-breaker: if two units are ready at the same time, earlier roster position acts first.")
	log.append("")
	_append_roster(log, units)
	log.append("")
	log.append("Combat log:")

	while _team_has_living_unit(units, TEAM_ALLY) and _team_has_living_unit(units, TEAM_ENEMY):
		if actions_taken >= MAX_ACTIONS:
			log.append("Battle stopped after %d actions to avoid an infinite fight." % MAX_ACTIONS)
			break

		var actor: UnitState = _find_next_actor(units)
		var target: UnitState = _find_frontmost_target(units, _opposing_team(actor.team))
		var current_time := actor.next_action_time
		var damage_taken: int = max(1, actor.damage - target.armor)
		var previous_hp := target.hp

		target.hp = max(0, target.hp - damage_taken)
		actions_taken += 1

		log.append(
			"t=%03d | %s attacks %s for %d damage. HP: %d -> %d"
			% [current_time, actor.unit_name, target.unit_name, damage_taken, previous_hp, target.hp]
		)

		if not target.is_alive():
			log.append("      %s is defeated." % target.unit_name)

		actor.next_action_time += actor.action_interval

	log.append("")
	log.append(_build_result_line(units, actions_taken))
	return log


func _create_demo_units() -> Array:
	var definitions: Array[Dictionary] = [
		{
			"name": "Alden Guard",
			"team": TEAM_ALLY,
			"max_hp": 34,
			"damage": 6,
			"armor": 2,
			"action_interval": 12,
		},
		{
			"name": "Mira Scout",
			"team": TEAM_ALLY,
			"max_hp": 22,
			"damage": 5,
			"armor": 1,
			"action_interval": 8,
		},
		{
			"name": "Sol Apprentice",
			"team": TEAM_ALLY,
			"max_hp": 20,
			"damage": 8,
			"armor": 0,
			"action_interval": 10,
		},
		{
			"name": "Iron Brute",
			"team": TEAM_ENEMY,
			"max_hp": 32,
			"damage": 7,
			"armor": 2,
			"action_interval": 13,
		},
		{
			"name": "Ash Cutpurse",
			"team": TEAM_ENEMY,
			"max_hp": 20,
			"damage": 6,
			"armor": 1,
			"action_interval": 9,
		},
		{
			"name": "Glass Wisp",
			"team": TEAM_ENEMY,
			"max_hp": 16,
			"damage": 9,
			"armor": 0,
			"action_interval": 14,
		},
	]

	var units: Array = []
	for index in definitions.size():
		units.append(UnitState.new(definitions[index], index))
	return units


func _append_roster(log: Array[String], units: Array) -> void:
	log.append("Roster:")
	for team in [TEAM_ALLY, TEAM_ENEMY]:
		log.append("  %s" % team)
		for unit: UnitState in units:
			if unit.team == team:
				log.append(
					"    %s | HP %d | damage %d | armor %d | interval %d"
					% [unit.unit_name, unit.max_hp, unit.damage, unit.armor, unit.action_interval]
				)


func _find_next_actor(units: Array) -> UnitState:
	var next_actor: UnitState = null
	for unit: UnitState in units:
		if not unit.is_alive():
			continue

		if next_actor == null:
			next_actor = unit
		elif unit.next_action_time < next_actor.next_action_time:
			next_actor = unit
		elif unit.next_action_time == next_actor.next_action_time and unit.slot_index < next_actor.slot_index:
			next_actor = unit

	return next_actor


func _find_frontmost_target(units: Array, target_team: String) -> UnitState:
	for unit: UnitState in units:
		if unit.team == target_team and unit.is_alive():
			return unit

	return null


func _team_has_living_unit(units: Array, team: String) -> bool:
	for unit: UnitState in units:
		if unit.team == team and unit.is_alive():
			return true

	return false


func _opposing_team(team: String) -> String:
	if team == TEAM_ALLY:
		return TEAM_ENEMY

	return TEAM_ALLY


func _build_result_line(units: Array, actions_taken: int) -> String:
	if _team_has_living_unit(units, TEAM_ALLY) and not _team_has_living_unit(units, TEAM_ENEMY):
		return "Result: Allies win after %d actions." % actions_taken

	if _team_has_living_unit(units, TEAM_ENEMY) and not _team_has_living_unit(units, TEAM_ALLY):
		return "Result: Enemies win after %d actions." % actions_taken

	return "Result: No winner after %d actions." % actions_taken
