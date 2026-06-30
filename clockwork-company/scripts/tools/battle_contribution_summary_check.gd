extends SceneTree

const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const TacticDefinitionScript := preload("res://scripts/data/tactic_definition.gd")


func _init() -> void:
	var simulator: CombatSimulator = CombatSimulatorScript.new()
	var report: Dictionary = simulator.run_battle_report(_battle_definitions(), "Contribution summary check")
	var contributions: Array = report.get("contribution_summary", [])
	assert(not contributions.is_empty(), "Battle report should include contribution summary rows.")
	assert(contributions.size() == 3, "Contribution summary should include one row per roster unit.")

	var tank := _row_named(contributions, "Mitigation Tank")
	var healer := _row_named(contributions, "Field Healer")
	var enemy := _row_named(contributions, "Iron Caller")
	assert(not tank.is_empty() and not healer.is_empty() and not enemy.is_empty(), "Contribution rows should be keyed by unit names from roster data.")
	assert(int(enemy.get("damage_dealt", 0)) > 0, "Enemy should receive damage dealt credit from structured damage events.")
	assert(int(tank.get("damage_taken", 0)) > 0, "Tank should receive damage taken credit from structured damage events.")
	assert(int(tank.get("mitigation_prevention", 0)) > 0, "Armor mitigation should be credited from simulator-authored structured damage payloads.")
	assert(int(healer.get("healing_done", 0)) > 0, "Healer should receive healing credit from structured healing events.")
	assert(_total(contributions, "actions") == int(report.get("actions_taken", -1)), "Contribution action count should match simulator actions taken.")
	assert(_total(contributions, "kills") >= 1, "At least one unit should receive kill credit in the resolved battle.")
	assert(report.has("combat_events") and not report.get("combat_events", []).is_empty(), "Contribution summary check should use a real structured-event battle report.")

	print("Battle contribution validation passed: real report tracked actions, damage, healing, damage taken, kills, and mitigation.")
	quit(0)


func _battle_definitions() -> Array[UnitDefinition]:
	var tank := _unit("Mitigation Tank", "Allies", 24, 8, 4, 9)
	var healer := _unit("Field Healer", "Allies", 16, 1, 0, 10)
	var healer_loadout := UnitLoadoutDefinitionScript.new()
	healer_loadout.display_name = "Contribution Check Healer"
	healer_loadout.tactics = [_heal_tactic()]
	healer.loadout = healer_loadout
	var enemy := _unit("Iron Caller", "Enemies", 18, 17, 5, 20)
	return [tank, healer, enemy]


func _unit(display_name: String, team: String, hp: int, physical_damage: int, armor: int, action_speed: int) -> UnitDefinition:
	var unit := UnitDefinition.new()
	unit.display_name = display_name
	unit.team = team
	unit.max_hp = hp
	unit.physical_damage = physical_damage
	unit.magic_damage = 0
	unit.armor = armor
	unit.action_speed = action_speed
	return unit


func _heal_tactic() -> TacticDefinition:
	var tactic := TacticDefinitionScript.new()
	tactic.display_name = "Patch Up Ally"
	tactic.condition = "Ally HP Below Half"
	tactic.action = "Heal"
	tactic.target = "Lowest HP Ally"
	return tactic


func _row_named(rows: Array, unit_name: String) -> Dictionary:
	for row in rows:
		if row is Dictionary and String(row.get("name", "")) == unit_name:
			return row
	return {}


func _total(rows: Array, key: String) -> int:
	var total := 0
	for row in rows:
		if row is Dictionary:
			total += int(row.get(key, 0))
	return total
