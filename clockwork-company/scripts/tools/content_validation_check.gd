extends SceneTree

const CAMPAIGN_PATH := "res://resources/campaigns/first_road_campaign.tres"
const SCENARIO_DIR := "res://resources/scenarios"
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")


func _init() -> void:
	var errors: Array[String] = []
	var scenarios_by_id := _load_scenarios_by_id(errors)
	_validate_campaign(scenarios_by_id, errors)
	var pack_count := _validate_json_packs()

	if errors.is_empty():
		print("Content validation passed: %d scenarios and %d JSON packs checked." % [scenarios_by_id.size(), pack_count])
		quit(0)
		return

	for error in errors:
		push_error(error)
	quit(1)


func _load_scenarios_by_id(errors: Array[String]) -> Dictionary:
	var scenarios_by_id := {}
	var directory := DirAccess.open(SCENARIO_DIR)
	if directory == null:
		errors.append("Missing scenario directory: %s" % SCENARIO_DIR)
		return scenarios_by_id

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			var path := "%s/%s" % [SCENARIO_DIR, file_name]
			var scenario = load(path)
			_validate_scenario(path, scenario, scenarios_by_id, errors)
		file_name = directory.get_next()
	directory.list_dir_end()
	return scenarios_by_id


func _validate_scenario(path: String, scenario, scenarios_by_id: Dictionary, errors: Array[String]) -> void:
	if scenario == null:
		errors.append("Could not load scenario: %s" % path)
		return
	if not "scenario_id" in scenario:
		errors.append("Resource is not a ScenarioDefinition: %s" % path)
		return
	if scenario.scenario_id.is_empty():
		errors.append("Scenario has empty scenario_id: %s" % path)
		return
	if scenarios_by_id.has(scenario.scenario_id):
		errors.append("Duplicate scenario_id '%s': %s" % [scenario.scenario_id, path])
	else:
		scenarios_by_id[scenario.scenario_id] = scenario
	if String(scenario.display_name).is_empty():
		errors.append("Scenario '%s' has empty display_name." % scenario.scenario_id)
	if scenario.encounters.is_empty():
		errors.append("Scenario '%s' has no encounters." % scenario.scenario_id)
	for encounter in scenario.encounters:
		if encounter == null:
			errors.append("Scenario '%s' has a missing encounter reference." % scenario.scenario_id)
	for reward in scenario.rewards:
		if reward == null:
			errors.append("Scenario '%s' has a missing reward reference." % scenario.scenario_id)


func _validate_campaign(scenarios_by_id: Dictionary, errors: Array[String]) -> void:
	var campaign = load(CAMPAIGN_PATH)
	if campaign == null:
		errors.append("Could not load campaign: %s" % CAMPAIGN_PATH)
		return

	var node_scenario_ids: Array[String] = []
	for node in campaign.scenario_nodes:
		if node == null or node.scenario == null:
			errors.append("Campaign has a missing scenario node or scenario reference.")
			continue
		var scenario_id: String = node.scenario.scenario_id
		if not scenarios_by_id.has(scenario_id):
			errors.append("Campaign references unknown scenario_id '%s'." % scenario_id)
		if node_scenario_ids.has(scenario_id):
			errors.append("Campaign includes duplicate scenario node '%s'." % scenario_id)
		node_scenario_ids.append(scenario_id)
		for unlock_id in node.unlock_scenario_ids_on_completion:
			if not scenarios_by_id.has(unlock_id):
				errors.append("Campaign node '%s' unlocks unknown scenario_id '%s'." % [scenario_id, unlock_id])

	for starting_id in campaign.starting_scenario_ids:
		if not scenarios_by_id.has(starting_id):
			errors.append("Campaign starts with unknown scenario_id '%s'." % starting_id)


func _validate_json_packs() -> int:
	var descriptors: Array[Dictionary] = JsonContentLoaderScript.list_available_mod_packs()
	for descriptor: Dictionary in descriptors:
		var pack_id := String(descriptor.get("id", ""))
		if pack_id.is_empty():
			continue
		JsonContentLoaderScript.load_demo_unit_definitions([pack_id])
	return descriptors.size()
