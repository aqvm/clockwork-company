extends RefCounted
class_name ScenarioProgress

var current_scenario_id := ""
var current_encounter_index := 0
var completed := false


func start(scenario_id: String) -> void:
	current_scenario_id = scenario_id
	current_encounter_index = 0
	completed = false


func advance_encounter() -> void:
	current_encounter_index += 1


func mark_completed() -> void:
	completed = true
