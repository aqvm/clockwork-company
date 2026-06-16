extends RefCounted
class_name CampaignManager

const CampaignProgressScript := preload("res://scripts/campaign/campaign_progress.gd")
const CampaignRosterStateScript := preload("res://scripts/campaign/campaign_roster_state.gd")
const ContentCatalogScript := preload("res://scripts/content/content_catalog.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const SAVE_VERSION := 5

var campaign: Resource = null
var progress = CampaignProgressScript.new()
var roster_state = CampaignRosterStateScript.new()
var enabled_mod_pack_ids: Array[String] = []


func start(definition: Resource, active_mod_pack_ids: Array[String] = []) -> void:
	campaign = definition
	enabled_mod_pack_ids = active_mod_pack_ids.duplicate()
	if campaign == null:
		progress.reset([], [])
		roster_state.reset([], enabled_mod_pack_ids)
		return
	progress.reset(campaign.starting_scenario_ids, campaign.starting_unlocks)
	roster_state.reset(campaign.starting_roster_ids, enabled_mod_pack_ids)


func available_scenarios() -> Array:
	var scenarios: Array = []
	if campaign == null:
		return scenarios
	for node in campaign.scenario_nodes:
		if node == null or node.scenario == null:
			continue
		var scenario_id: String = node.scenario.scenario_id
		if progress.is_scenario_unlocked(scenario_id) and not progress.completed_scenario_ids.has(scenario_id):
			scenarios.append(node.scenario)
	return scenarios


func all_scenarios() -> Array:
	var scenarios: Array = []
	var included_ids: Array[String] = []
	if campaign != null:
		for node in campaign.scenario_nodes:
			if node != null and node.scenario != null:
				scenarios.append(node.scenario)
				included_ids.append(String(node.scenario.scenario_id))
	for scenario in ContentCatalogScript.load_scenarios():
		if not included_ids.has(String(scenario.scenario_id)):
			scenarios.append(scenario)
	return scenarios


func scenario_is_in_campaign(scenario_id: String) -> bool:
	return _find_node(scenario_id) != null


func campaign_scenario_ids() -> Array[String]:
	return _scenario_ids()


func start_scenario(scenario_id: String):
	if has_pending_unlock_choices():
		return null
	if not progress.is_scenario_unlocked(scenario_id):
		return null
	var node = _find_node(scenario_id)
	if node == null or node.scenario == null:
		return null
	progress.mark_scenario_started(scenario_id)
	return node.scenario


func complete_scenario(scenario_id: String) -> void:
	var node = _find_node(scenario_id)
	progress.mark_scenario_completed(scenario_id)
	if node == null:
		return
	for unlock_id in node.unlock_scenario_ids_on_completion:
		progress.unlock_scenario(unlock_id)
	for content_id in node.content_unlocks_on_completion:
		progress.unlock_content(content_id)
	if node.scenario != null:
		for content_id in node.scenario.content_unlocks:
			progress.unlock_content(content_id)
	if node.completes_campaign:
		progress.campaign_completed = true


func fail_scenario(scenario_id: String) -> void:
	progress.mark_scenario_attempted(scenario_id)


func campaign_party_snapshot() -> Array[UnitDefinition]:
	return roster_state.active_party_snapshot()


func campaign_inventory_snapshot() -> Array[ItemDefinition]:
	var items: Array[ItemDefinition] = []
	for item in roster_state.inventory_items:
		items.append(item)
	return items


func commit_completed_run(run_state) -> void:
	roster_state.commit_from_run(run_state)
	roster_state.award_scenario_level(run_state.active_scenario, run_state.knocked_out_unit_ids)


func commit_planning_roster(units: Array[UnitDefinition]) -> void:
	roster_state.replace_roster_units(units)


func has_pending_unlock_choices() -> bool:
	return roster_state.has_pending_unlock_choices()


func pending_unlock_options_for_unit(campaign_unit_id: String) -> Array[Dictionary]:
	return roster_state.pending_unlock_options_for_unit(campaign_unit_id)


func resolve_pending_unlock(campaign_unit_id: String, choice: String) -> bool:
	return roster_state.resolve_pending_unlock(campaign_unit_id, choice)


func available_jobs() -> Array[JobDefinition]:
	return JsonContentLoaderScript.load_job_definitions(enabled_mod_pack_ids)


func set_current_job(campaign_unit_id: String, job: JobDefinition) -> bool:
	return roster_state.set_current_job(campaign_unit_id, job)


func learned_feature_options(campaign_unit_id: String, feature_type: String) -> Array[Dictionary]:
	return roster_state.learned_feature_options(campaign_unit_id, feature_type)


func assign_learned_feature(campaign_unit_id: String, feature_type: String, feature: Resource) -> bool:
	return roster_state.assign_learned_feature(campaign_unit_id, feature_type, feature)


func available_tactics() -> Array[TacticDefinition]:
	return JsonContentLoaderScript.load_tactic_definitions(enabled_mod_pack_ids)


func available_statuses() -> Array[StatusDefinition]:
	return JsonContentLoaderScript.load_status_definitions(enabled_mod_pack_ids)


func set_tactics(campaign_unit_id: String, tactics: Array[TacticDefinition]) -> bool:
	return roster_state.set_tactics(campaign_unit_id, tactics)


func planning_item_options(campaign_unit_id: String) -> Array[Dictionary]:
	return roster_state.planning_item_options(campaign_unit_id)


func equip_planning_item(campaign_unit_id: String, slot: String, inventory_index: int) -> bool:
	return roster_state.equip_planning_item(campaign_unit_id, slot, inventory_index)


func status_lines() -> Array[String]:
	var lines: Array[String] = []
	if campaign == null:
		lines.append("Campaign: none")
		return lines
	lines.append("Campaign: %s" % campaign.display_name)
	lines.append("Campaign completed: %s" % ("yes" if progress.campaign_completed else "no"))
	lines.append("Unlocked scenarios: %s" % _join_or_none(progress.unlocked_scenario_ids))
	lines.append("Attempted scenarios: %s" % _join_or_none(progress.attempted_scenario_ids))
	lines.append("Completed scenarios: %s" % _join_or_none(progress.completed_scenario_ids))
	lines.append("Unlocked content: %s" % _join_or_none(progress.unlocked_content_ids))
	for roster_line in roster_state.status_lines():
		lines.append(roster_line)
	return lines


func save_to_path(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_save_data(), "\t"))
	return OK


func load_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false
	return apply_save_data(parsed)


func to_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"campaign_id": campaign.campaign_id if campaign != null else "",
		"progress": progress.to_save_data(),
		"roster_state": roster_state.to_save_data(),
	}


func apply_save_data(data: Dictionary) -> bool:
	if campaign == null:
		return false
	var save_version := int(data.get("save_version", 0))
	if save_version < 1 or save_version > SAVE_VERSION:
		return false
	if String(data.get("campaign_id", "")) != campaign.campaign_id:
		return false
	var progress_data = data.get("progress", {})
	if not (progress_data is Dictionary):
		return false
	progress.apply_save_data(progress_data, _scenario_ids())
	var roster_data = data.get("roster_state", {})
	if roster_data is Dictionary:
		roster_state.apply_save_data(roster_data, campaign.starting_roster_ids, enabled_mod_pack_ids)
	return true


func _find_node(scenario_id: String):
	if campaign == null:
		return null
	for node in campaign.scenario_nodes:
		if node != null and node.scenario != null and node.scenario.scenario_id == scenario_id:
			return node
	return null


func _scenario_ids() -> Array[String]:
	var ids: Array[String] = []
	if campaign == null:
		return ids
	for node in campaign.scenario_nodes:
		if node != null and node.scenario != null:
			ids.append(String(node.scenario.scenario_id))
	return ids


func _join_or_none(values: Array[String]) -> String:
	if values.is_empty():
		return "none"
	var text := ""
	for value in values:
		if not text.is_empty():
			text += ", "
		text += value
	return text
