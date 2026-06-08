extends RefCounted
class_name CampaignProgress

var current_scenario_id := ""
var attempted_scenario_ids: Array[String] = []
var completed_scenario_ids: Array[String] = []
var unlocked_scenario_ids: Array[String] = []
var unlocked_content_ids: Array[String] = []
var campaign_completed := false


func reset(starting_scenario_ids: Array[String], starting_unlocks: Array[String]) -> void:
	current_scenario_id = ""
	attempted_scenario_ids.clear()
	completed_scenario_ids.clear()
	unlocked_scenario_ids = starting_scenario_ids.duplicate()
	unlocked_content_ids = starting_unlocks.duplicate()
	campaign_completed = false


func is_scenario_unlocked(scenario_id: String) -> bool:
	return unlocked_scenario_ids.has(scenario_id)


func mark_scenario_started(scenario_id: String) -> void:
	current_scenario_id = scenario_id


func mark_scenario_attempted(scenario_id: String) -> void:
	if not scenario_id.is_empty() and not attempted_scenario_ids.has(scenario_id):
		attempted_scenario_ids.append(scenario_id)
	current_scenario_id = ""


func mark_scenario_completed(scenario_id: String) -> void:
	mark_scenario_attempted(scenario_id)
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


func to_save_data() -> Dictionary:
	return {
		"current_scenario_id": "",
		"attempted_scenario_ids": attempted_scenario_ids.duplicate(),
		"completed_scenario_ids": completed_scenario_ids.duplicate(),
		"unlocked_scenario_ids": unlocked_scenario_ids.duplicate(),
		"unlocked_content_ids": unlocked_content_ids.duplicate(),
		"campaign_completed": campaign_completed,
	}


func apply_save_data(data: Dictionary, valid_scenario_ids: Array[String]) -> void:
	current_scenario_id = ""
	attempted_scenario_ids = _valid_scenario_id_array(data.get("attempted_scenario_ids", []), valid_scenario_ids)
	completed_scenario_ids = _valid_scenario_id_array(data.get("completed_scenario_ids", []), valid_scenario_ids)
	unlocked_scenario_ids = _valid_scenario_id_array(data.get("unlocked_scenario_ids", []), valid_scenario_ids)
	unlocked_content_ids = _string_array(data.get("unlocked_content_ids", []))
	campaign_completed = bool(data.get("campaign_completed", false))


func _valid_scenario_id_array(values: Variant, valid_scenario_ids: Array[String]) -> Array[String]:
	var results: Array[String] = []
	if not (values is Array):
		return results
	for value in values:
		var id_text := String(value)
		if valid_scenario_ids.has(id_text) and not results.has(id_text):
			results.append(id_text)
	return results


func _string_array(values: Variant) -> Array[String]:
	var results: Array[String] = []
	if not (values is Array):
		return results
	for value in values:
		var text := String(value)
		if not text.is_empty() and not results.has(text):
			results.append(text)
	return results
