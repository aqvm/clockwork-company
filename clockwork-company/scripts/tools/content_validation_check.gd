extends SceneTree

const CAMPAIGN_PATH := "res://resources/campaigns/first_road_campaign.tres"
const SCENARIO_DIR := "res://resources/scenarios"
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")


func _init() -> void:
	var errors: Array[String] = []
	var scenarios_by_id := _load_scenarios_by_id(errors)
	_validate_campaign(scenarios_by_id, errors)
	var pack_count := _validate_json_packs(errors)

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
	for rule in scenario.scenario_rules:
		_validate_scenario_rule(scenario.scenario_id, rule, errors)
	for reward in scenario.rewards:
		_validate_scenario_reward(scenario.scenario_id, reward, errors)


func _validate_scenario_rule(scenario_id: String, rule, errors: Array[String]) -> void:
	if rule == null:
		errors.append("Scenario '%s' has a missing rule reference." % scenario_id)
		return
	if not "rule_id" in rule:
		errors.append("Scenario '%s' references a Resource that is not a ScenarioRuleDefinition." % scenario_id)
		return
	if String(rule.rule_id).is_empty():
		errors.append("Scenario '%s' has a scenario rule with empty rule_id." % scenario_id)
	if String(rule.display_name).is_empty():
		errors.append("Scenario '%s' has scenario rule '%s' with empty display_name." % [scenario_id, rule.rule_id])


func _validate_scenario_reward(scenario_id: String, reward, errors: Array[String]) -> void:
	if reward == null:
		errors.append("Scenario '%s' has a missing reward reference." % scenario_id)
		return
	if not "item" in reward:
		errors.append("Scenario '%s' references a Resource that is not a RewardDefinition." % scenario_id)
		return
	if String(reward.display_name).is_empty():
		errors.append("Scenario '%s' has a reward with empty display_name." % scenario_id)
	if reward.item == null:
		errors.append("Scenario '%s' reward '%s' has no item." % [scenario_id, reward.display_name])


func _validate_campaign(scenarios_by_id: Dictionary, errors: Array[String]) -> void:
	var campaign = load(CAMPAIGN_PATH)
	if campaign == null:
		errors.append("Could not load campaign: %s" % CAMPAIGN_PATH)
		return
	if not "campaign_id" in campaign:
		errors.append("Resource is not a CampaignDefinition: %s" % CAMPAIGN_PATH)
		return
	if String(campaign.campaign_id).is_empty():
		errors.append("Campaign has empty campaign_id: %s" % CAMPAIGN_PATH)
	if String(campaign.display_name).is_empty():
		errors.append("Campaign '%s' has empty display_name." % String(campaign.campaign_id))

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

	for node in campaign.scenario_nodes:
		if node == null or node.scenario == null:
			continue
		var scenario_id: String = node.scenario.scenario_id
		for unlock_id in node.unlock_scenario_ids_on_completion:
			if not scenarios_by_id.has(unlock_id):
				errors.append("Campaign node '%s' unlocks unknown scenario_id '%s'." % [scenario_id, unlock_id])
			elif not node_scenario_ids.has(unlock_id):
				errors.append("Campaign node '%s' unlocks scenario_id '%s' that is not part of this campaign." % [scenario_id, unlock_id])

	for starting_id in campaign.starting_scenario_ids:
		if not scenarios_by_id.has(starting_id):
			errors.append("Campaign starts with unknown scenario_id '%s'." % starting_id)
		elif not node_scenario_ids.has(starting_id):
			errors.append("Campaign starts with scenario_id '%s' that is not part of this campaign." % starting_id)

	_validate_campaign_reachability(campaign, node_scenario_ids, errors)
	_validate_campaign_starting_roster(campaign, errors)


func _validate_campaign_reachability(campaign, node_scenario_ids: Array[String], errors: Array[String]) -> void:
	var reachable_ids: Array[String] = []
	var pending_ids: Array[String] = []
	for starting_id in campaign.starting_scenario_ids:
		if node_scenario_ids.has(starting_id) and not pending_ids.has(starting_id):
			pending_ids.append(starting_id)

	while not pending_ids.is_empty():
		var scenario_id := String(pending_ids.pop_front())
		if reachable_ids.has(scenario_id):
			continue
		reachable_ids.append(scenario_id)
		for node in campaign.scenario_nodes:
			if node == null or node.scenario == null or node.scenario.scenario_id != scenario_id:
				continue
			for unlock_id in node.unlock_scenario_ids_on_completion:
				if node_scenario_ids.has(unlock_id) and not reachable_ids.has(unlock_id):
					pending_ids.append(unlock_id)
			break

	for scenario_id in node_scenario_ids:
		if not reachable_ids.has(scenario_id):
			errors.append("Campaign node '%s' is unreachable from the starting scenarios." % scenario_id)


func _validate_campaign_starting_roster(campaign, errors: Array[String]) -> void:
	if campaign.starting_roster_ids.is_empty():
		errors.append("Campaign '%s' has no starting roster ids." % String(campaign.campaign_id))
		return
	for unit_id in campaign.starting_roster_ids:
		var id_text := String(unit_id)
		var units := JsonContentLoaderScript.load_unit_definitions_by_ids([id_text], [])
		if units.is_empty():
			errors.append("Campaign '%s' starts with unknown unit id '%s'." % [String(campaign.campaign_id), id_text])
			continue
		var unit: UnitDefinition = units[0]
		if unit.team != "Allies":
			errors.append("Campaign '%s' starting roster id '%s' is not an ally unit." % [String(campaign.campaign_id), id_text])


func _validate_json_packs(errors: Array[String]) -> int:
	var descriptors: Array[Dictionary] = JsonContentLoaderScript.list_available_mod_packs()
	for descriptor: Dictionary in descriptors:
		_validate_json_pack_sidecar(descriptor, errors)
		var pack_id := String(descriptor.get("id", ""))
		if pack_id.is_empty():
			continue
		JsonContentLoaderScript.load_demo_unit_definitions([pack_id])
	return descriptors.size()


func _validate_json_pack_sidecar(descriptor: Dictionary, errors: Array[String]) -> void:
	var json_path := String(descriptor.get("path", ""))
	if json_path.is_empty():
		errors.append("JSON pack descriptor is missing a path for pack '%s'." % String(descriptor.get("id", "")))
		return
	var sidecar_path := "%s.options.md" % json_path.trim_suffix(".json")
	if not FileAccess.file_exists(sidecar_path):
		errors.append("JSON pack '%s' is missing sidecar docs: %s" % [String(descriptor.get("id", json_path)), sidecar_path])
