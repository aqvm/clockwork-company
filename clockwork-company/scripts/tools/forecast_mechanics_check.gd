extends SceneTree

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const PassiveDefinitionScript := preload("res://scripts/data/passive_definition.gd")
const TacticDefinitionScript := preload("res://scripts/data/tactic_definition.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")


func _init() -> void:
	var simulator = CombatSimulatorScript.new()
	var forecaster = _unit("Forecaster", "Allies", 1, 20, 1, 10)
	var endangered = _unit("Endangered", "Allies", 0, 3, 1, 30)
	var enemy = _unit("Enemy", "Enemies", 2, 20, 5, 11)
	forecaster.current_passive = _forecast_passive()
	forecaster.tactics.append(_forecast_tactic())
	forecaster.tactics.append(_attack_tactic())
	enemy.tactics.append(_attack_tactic())
	var units := [endangered, forecaster, enemy]

	var forecast: Dictionary = simulator.forecast_for_actor(forecaster, units)
	assert(forecast.get("first_defeated_ally", null) == endangered, "Forecast should identify the first ally defeated before the forecaster's next turn.")
	assert(endangered.hp == 3 and enemy.hp == 20, "Speculative combat must not mutate real runtime state.")
	var decision: Dictionary = TacticResolver.choose_action(forecaster, units, forecast)
	assert(decision["action"] == CombatConstantsScript.ACTION_HEAL and decision["target"] == endangered, "Forecast-aware tactic should heal the first foreseen ally.")

	forecaster.current_passive = null
	decision = TacticResolver.choose_action(forecaster, units, forecast)
	assert(decision["action"] == CombatConstantsScript.ACTION_ATTACK, "Forecast-aware tactics must be unavailable without an equipped Forecast passive.")
	forecaster.current_passive = _forecast_passive()

	var late_enemy = _unit("Late Enemy", "Enemies", 4, 20, 5, 21)
	assert(simulator.forecast_for_actor(forecaster, [endangered, forecaster, late_enemy]).is_empty(), "Forecast horizon should end before the forecaster's next turn.")

	var final_enemy = _unit("Final Enemy", "Enemies", 5, 1, 1, 11)
	forecaster.physical_damage = 50
	assert(simulator.forecast_for_actor(forecaster, [forecaster, final_enemy]).is_empty(), "Forecast should stop cleanly when the baseline action ends combat.")
	forecaster.physical_damage = 1

	var blocking_forecaster = _unit("Blocking Forecaster", "Allies", 1, 20, 1, 11)
	blocking_forecaster.current_passive = _forecast_passive()
	var blocked_forecast: Dictionary = simulator.forecast_for_actor(forecaster, [endangered, forecaster, blocking_forecaster, enemy])
	assert(blocked_forecast.is_empty(), "Forecast should stop before another living forecast-capable unit acts.")

	var mod_job: JobDefinition = JsonContentLoaderScript.load_job_definition_by_id("warden_it", ["integration_test_mod_pack"])
	assert(mod_job != null and mod_job.passive != null and mod_job.passive.passive_type == "Forecast", "JSON jobs should preserve the Forecast passive capability.")
	var mod_tactic: TacticDefinition = JsonContentLoaderScript.load_tactic_definition_by_id("avert_foreseen_defeat_it", ["integration_test_mod_pack"])
	assert(mod_tactic != null and mod_tactic.condition == CombatConstantsScript.CONDITION_ALLY_WOULD_BE_DEFEATED, "JSON tactics should preserve forecast-aware conditions.")
	var marra_definitions: Array[UnitDefinition] = JsonContentLoaderScript.load_unit_definitions_by_ids(["marra_archivist"], [])
	var marra = UnitStateScript.new(marra_definitions[0], 0)
	assert(marra.forecast_capable() and marra.tactics[0].condition == CombatConstantsScript.CONDITION_ALLY_WOULD_BE_DEFEATED, "Marra should expose the first Resource-authored forecast build.")

	print("Forecast mechanics validation passed: gating, baseline simulation, horizon, forecaster stop, immutability, and JSON authoring worked.")
	quit(0)


func _unit(name: String, team: String, slot: int, hp: int, damage: int, next_time: int):
	var unit = UnitStateScript.new()
	unit.unit_name = name
	unit.unit_id = name.to_lower().replace(" ", "_")
	unit.team = team
	unit.slot_index = slot
	unit.max_hp = hp
	unit.hp = hp
	unit.physical_damage = damage
	unit.action_interval = 10
	unit.next_action_time = next_time
	return unit


func _forecast_passive() -> PassiveDefinition:
	var passive: PassiveDefinition = PassiveDefinitionScript.new()
	passive.display_name = "Read Ahead"
	passive.passive_type = "Forecast"
	return passive


func _forecast_tactic() -> TacticDefinition:
	var tactic: TacticDefinition = TacticDefinitionScript.new()
	tactic.display_name = "Avert Foreseen Defeat"
	tactic.condition = CombatConstantsScript.CONDITION_ALLY_WOULD_BE_DEFEATED
	tactic.action = CombatConstantsScript.ACTION_HEAL
	tactic.target = CombatConstantsScript.TARGET_FIRST_FORESEEN_ALLY
	return tactic


func _attack_tactic() -> TacticDefinition:
	var tactic: TacticDefinition = TacticDefinitionScript.new()
	tactic.display_name = "Attack"
	tactic.condition = CombatConstantsScript.CONDITION_ALWAYS
	tactic.action = CombatConstantsScript.ACTION_ATTACK
	tactic.target = CombatConstantsScript.TARGET_FRONTMOST_ENEMY
	return tactic
