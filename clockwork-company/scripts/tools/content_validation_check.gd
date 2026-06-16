extends SceneTree

const CAMPAIGN_PATH := "res://resources/campaigns/first_road_campaign.tres"
const SCENARIO_DIR := "res://resources/scenarios"
const ITEM_DIR := "res://resources/items"
const ANCESTRY_DIR := "res://resources/ancestries"
const JOB_DIR := "res://resources/jobs"
const TACTIC_DIR := "res://resources/tactics"
const UNIT_DIR := "res://resources/units"
const ContentCatalogScript := preload("res://scripts/content/content_catalog.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")


func _init() -> void:
	var errors: Array[String] = []
	var scenarios_by_id := _load_scenarios_by_id(errors)
	_validate_scenario_catalog(scenarios_by_id, errors)
	_validate_campaign(scenarios_by_id, errors)
	_validate_authored_resources(errors)
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
	if int(scenario.tier) < 1 or int(scenario.tier) > 5:
		errors.append("Scenario '%s' has invalid tier %d." % [scenario.scenario_id, scenario.tier])
	for encounter in scenario.encounters:
		if encounter == null:
			errors.append("Scenario '%s' has a missing encounter reference." % scenario.scenario_id)
	for rule in scenario.scenario_rules:
		_validate_scenario_rule(scenario.scenario_id, rule, errors)
	for reward in scenario.rewards:
		_validate_scenario_reward(scenario.scenario_id, reward, errors)


func _validate_scenario_catalog(scenarios_by_id: Dictionary, errors: Array[String]) -> void:
	var catalog_ids: Array[String] = []
	for scenario in ContentCatalogScript.load_scenarios():
		catalog_ids.append(String(scenario.scenario_id))
	for scenario_id in scenarios_by_id:
		if not catalog_ids.has(String(scenario_id)):
			errors.append("Runtime scenario catalog did not discover scenario_id '%s'." % scenario_id)


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
	for effect_index in rule.effects.size():
		var effect: EffectDefinition = rule.effects[effect_index]
		if effect == null:
			errors.append("Scenario '%s' rule '%s' has a missing effect at index %d." % [scenario_id, rule.rule_id, effect_index])
			continue
		if effect.target_selector == "Self":
			errors.append("Scenario '%s' rule '%s' effect %d cannot target Self because scenario rules have no owner." % [scenario_id, rule.rule_id, effect_index])
		if effect.condition == "Self HP Below Percent":
			errors.append("Scenario '%s' rule '%s' effect %d cannot use Self HP Below Percent because scenario rules have no owner." % [scenario_id, rule.rule_id, effect_index])
		var support_error: String = effect.support_error()
		if not support_error.is_empty():
			errors.append("Scenario '%s' rule '%s' effect %d is unsupported: %s" % [scenario_id, rule.rule_id, effect_index, support_error])


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


func _validate_authored_resources(errors: Array[String]) -> void:
	for entry in _load_resources(ITEM_DIR, errors):
		var item := entry["resource"] as ItemDefinition
		if item == null:
			errors.append("Resource is not an ItemDefinition: %s" % entry["path"])
			continue
		for effect_index in item.effects.size():
			var effect := item.effects[effect_index]
			if effect == null:
				errors.append("Item '%s' has a missing effect at index %d." % [item.display_name, effect_index])
				continue
			var support_error := effect.support_error()
			if not support_error.is_empty():
				errors.append("Item '%s' effect %d is unsupported: %s" % [item.display_name, effect_index, support_error])

	for entry in _load_resources(ANCESTRY_DIR, errors):
		var ancestry := entry["resource"] as AncestryDefinition
		if ancestry == null:
			errors.append("Resource is not an AncestryDefinition: %s" % entry["path"])
			continue
		if ancestry.feature != null and not ancestry.feature.support_error().is_empty():
			errors.append("Ancestry '%s' feature is unsupported: %s" % [ancestry.display_name, ancestry.feature.support_error()])

	for entry in _load_resources(JOB_DIR, errors):
		var job := entry["resource"] as JobDefinition
		if job == null:
			errors.append("Resource is not a JobDefinition: %s" % entry["path"])
			continue
		if job.skill != null and job.skill.action == "Apply Status" and job.skill.status == null:
			errors.append("Job '%s' has an Apply Status skill with no status." % job.display_name)
		if job.skill != null and job.skill.action == "Effects Only" and job.skill.effects.is_empty():
			errors.append("Job '%s' has an Effects Only skill with no effects." % job.display_name)
		if job.skill != null:
			if job.skill.attack_count < 1:
				errors.append("Job '%s' skill must attack at least once." % job.display_name)
			_validate_effects(job.skill.effects, "Job '%s' skill" % job.display_name, errors, "Skill")
		if job.passive != null:
			_validate_effects(job.passive.effects, "Job '%s' passive" % job.display_name, errors)
		if job.reaction != null:
			if job.reaction.reaction_type == "Effects Only" and job.reaction.effects.is_empty() and job.reaction.replacement_statuses.is_empty() and job.reaction.trigger != "Attack Targets Another Ally":
				errors.append("Job '%s' has an Effects Only reaction with no effects." % job.display_name)
			if job.reaction.condition == "Self Status Stacks At Least" and job.reaction.status == null:
				errors.append("Job '%s' reaction has a status-stack condition with no status." % job.display_name)
			if job.reaction.trigger == "Enemy Status Threshold Reached" and job.reaction.status == null:
				errors.append("Job '%s' enemy-status threshold reaction has no status." % job.display_name)
			if job.reaction.trigger == "Enemy Died With Status" and job.reaction.status == null:
				errors.append("Job '%s' enemy-death status reaction has no status." % job.display_name)
			if job.reaction.condition == "Requested Status Matches" and job.reaction.status == null:
				errors.append("Job '%s' requested-status reaction has no status." % job.display_name)
			if job.reaction.prevents_triggering_request and not job.reaction.trigger in ["Status Application Requested", "Enemy Healing Requested", "Lethal Physical Attack Requested"]:
				errors.append("Job '%s' reaction prevents its triggering request but does not use a request trigger." % job.display_name)
			for replacement in job.reaction.replacement_statuses:
				if replacement == null or replacement.polarity != "Boon":
					errors.append("Job '%s' reaction has a replacement status that is not a boon." % job.display_name)
			_validate_effects(job.reaction.effects, "Job '%s' reaction" % job.display_name, errors)
		if job.default_tactic != null:
			_validate_tactic(job.default_tactic, "Job '%s' default tactic" % job.display_name, errors)

	for entry in _load_resources(TACTIC_DIR, errors):
		var tactic := entry["resource"] as TacticDefinition
		if tactic == null:
			errors.append("Resource is not a TacticDefinition: %s" % entry["path"])
			continue
		_validate_tactic(tactic, "Tactic '%s'" % tactic.display_name, errors)

	for entry in _load_resources(UNIT_DIR, errors):
		var unit := entry["resource"] as UnitDefinition
		if unit == null:
			errors.append("Resource is not a UnitDefinition: %s" % entry["path"])
			continue
		if unit.loadout == null:
			errors.append("Unit '%s' has no loadout." % unit.display_name)
			continue
		_validate_item_slot(unit, "weapon", unit.loadout.weapon, "Weapon", errors)
		_validate_item_slot(unit, "armor", unit.loadout.armor, "Armor", errors)
		_validate_item_slot(unit, "helmet", unit.loadout.helmet, "Helmet", errors)
		_validate_item_slot(unit, "trinket", unit.loadout.trinket, "Trinket", errors)


func _validate_effects(effects: Array[EffectDefinition], label: String, errors: Array[String], required_trigger := "") -> void:
	for effect_index in effects.size():
		var effect: EffectDefinition = effects[effect_index]
		if effect == null:
			errors.append("%s has a missing effect at index %d." % [label, effect_index])
			continue
		if required_trigger == "Skill" and not effect.trigger in ["Skill Used", "Skill Completed"]:
			errors.append("%s effect %d must use Skill Used or Skill Completed." % [label, effect_index])
		elif not required_trigger.is_empty() and required_trigger != "Skill" and effect.trigger != required_trigger:
			errors.append("%s effect %d must use the %s trigger." % [label, effect_index, required_trigger])
		var support_error: String = effect.support_error()
		if not support_error.is_empty():
			errors.append("%s effect %d is unsupported: %s" % [label, effect_index, support_error])


func _validate_tactic(tactic: TacticDefinition, label: String, errors: Array[String]) -> void:
	if (tactic.condition in ["Target Has Status", "Target Status Stacks At Least", "Target Pending Status Damage At Least HP"] or tactic.target == "Lowest HP Ally With Status") and tactic.status == null:
		errors.append("%s has a status-aware condition with no status." % label)


func _validate_item_slot(unit: UnitDefinition, slot_name: String, item: ItemDefinition, expected_slot: String, errors: Array[String]) -> void:
	if item != null and item.slot != expected_slot:
		errors.append("Unit '%s' equips %s item '%s' in its %s slot." % [unit.display_name, item.slot, item.display_name, slot_name])


func _load_resources(directory_path: String, errors: Array[String]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		errors.append("Missing resource directory: %s" % directory_path)
		return entries
	var file_names := directory.get_files()
	file_names.sort()
	for file_name in file_names:
		if not file_name.ends_with(".tres"):
			continue
		var path := "%s/%s" % [directory_path, file_name]
		entries.append({"path": path, "resource": load(path)})
	return entries


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
