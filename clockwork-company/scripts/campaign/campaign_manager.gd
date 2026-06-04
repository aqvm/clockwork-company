extends RefCounted
class_name CampaignManager

const CampaignProgressScript := preload("res://scripts/campaign/campaign_progress.gd")

var campaign: Resource = null
var progress = CampaignProgressScript.new()


func start(definition: Resource) -> void:
	campaign = definition
	if campaign == null:
		progress.reset([], [])
		return
	progress.reset(campaign.starting_scenario_ids, campaign.starting_unlocks)


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
	if campaign == null:
		return scenarios
	for node in campaign.scenario_nodes:
		if node != null and node.scenario != null:
			scenarios.append(node.scenario)
	return scenarios


func start_scenario(scenario_id: String):
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


func status_lines() -> Array[String]:
	var lines: Array[String] = []
	if campaign == null:
		lines.append("Campaign: none")
		return lines
	lines.append("Campaign: %s" % campaign.display_name)
	lines.append("Campaign completed: %s" % ("yes" if progress.campaign_completed else "no"))
	lines.append("Unlocked scenarios: %s" % _join_or_none(progress.unlocked_scenario_ids))
	lines.append("Completed scenarios: %s" % _join_or_none(progress.completed_scenario_ids))
	lines.append("Unlocked content: %s" % _join_or_none(progress.unlocked_content_ids))
	return lines


func _find_node(scenario_id: String):
	if campaign == null:
		return null
	for node in campaign.scenario_nodes:
		if node != null and node.scenario != null and node.scenario.scenario_id == scenario_id:
			return node
	return null


func _join_or_none(values: Array[String]) -> String:
	if values.is_empty():
		return "none"
	var text := ""
	for value in values:
		if not text.is_empty():
			text += ", "
		text += value
	return text
