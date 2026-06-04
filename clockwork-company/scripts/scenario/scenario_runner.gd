extends RefCounted
class_name ScenarioRunner

const ScenarioProgressScript := preload("res://scripts/scenario/scenario_progress.gd")

var scenario: Resource = null
var progress = ScenarioProgressScript.new()


func start(definition: Resource) -> void:
	scenario = definition
	var scenario_id := ""
	if scenario != null:
		scenario_id = scenario.scenario_id
	progress.start(scenario_id)


func current_encounter():
	if scenario == null or scenario.encounters.is_empty():
		return null
	var safe_index: int = clamp(progress.current_encounter_index, 0, scenario.encounters.size() - 1)
	return scenario.encounters[safe_index]


func current_encounter_number() -> int:
	return progress.current_encounter_index + 1


func encounter_count() -> int:
	if scenario == null:
		return 0
	return scenario.encounters.size()


func complete_current_encounter() -> void:
	if scenario == null:
		return
	if progress.current_encounter_index >= scenario.encounters.size() - 1:
		progress.mark_completed()
	else:
		progress.advance_encounter()


func is_completed() -> bool:
	return progress.completed


func status_lines() -> Array[String]:
	var lines: Array[String] = []
	if scenario == null:
		lines.append("Scenario: none")
		return lines

	lines.append("Scenario: %s" % scenario.display_name)
	lines.append("Scenario progress: encounter %d/%d" % [current_encounter_number(), encounter_count()])
	if not scenario.story_intro.is_empty():
		lines.append("Intro: %s" % scenario.story_intro)
	if not scenario.scenario_rules.is_empty():
		lines.append("Scenario rules:")
		for rule in scenario.scenario_rules:
			if rule == null:
				continue
			lines.append("- %s: %s" % [rule.display_name, rule.description])
	return lines
