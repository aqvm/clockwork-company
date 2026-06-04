extends RefCounted
class_name CampaignProgress

var current_scenario_id := ""
var completed_scenario_ids: Array[String] = []
var unlocked_scenario_ids: Array[String] = []
var unlocked_content_ids: Array[String] = []
var campaign_completed := false


func reset(starting_scenario_ids: Array[String], starting_unlocks: Array[String]) -> void:
	current_scenario_id = ""
	completed_scenario_ids.clear()
	unlocked_scenario_ids = starting_scenario_ids.duplicate()
	unlocked_content_ids = starting_unlocks.duplicate()
	campaign_completed = false


func is_scenario_unlocked(scenario_id: String) -> bool:
	return unlocked_scenario_ids.has(scenario_id)


func mark_scenario_started(scenario_id: String) -> void:
	current_scenario_id = scenario_id


func mark_scenario_completed(scenario_id: String) -> void:
	if not completed_scenario_ids.has(scenario_id):
		completed_scenario_ids.append(scenario_id)
	current_scenario_id = ""


func unlock_scenario(scenario_id: String) -> void:
	if scenario_id.is_empty() or unlocked_scenario_ids.has(scenario_id):
		return
	unlocked_scenario_ids.append(scenario_id)


func unlock_content(content_id: String) -> void:
	if content_id.is_empty() or unlocked_content_ids.has(content_id):
		return
	unlocked_content_ids.append(content_id)
