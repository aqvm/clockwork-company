extends ScrollContainer
class_name ScenarioDetailPanel

signal resource_tooltip_requested(source: Control, resource: Resource)
signal tooltip_cleared

var content: VBoxContainer = null


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ensure_content()


func show_scenario(scenario: Resource, status_text: String, campaign_progress = null) -> void:
	_ensure_content()
	_clear_content()
	if scenario == null:
		_add_plain_text("Select a scenario to inspect its mission data.")
		return

	_add_resource_text(scenario, scenario.display_name)
	_add_plain_text(scenario.description)
	if not scenario.story_intro.is_empty():
		_add_plain_text("Intro: %s" % scenario.story_intro)
	_add_plain_text("")
	_add_plain_text("Encounters: %d" % scenario.encounters.size())
	for encounter in scenario.encounters:
		if encounter != null:
			_add_resource_text(encounter, "- %s" % encounter.display_name)
	_add_scouting_reports(scenario.encounters)
	_add_plain_text("Party size: %d" % scenario.party_size)
	_add_plain_text("Recommended level: %d-%d" % [scenario.recommended_level_min, scenario.recommended_level_max])
	_add_plain_text("Status: %s" % _status_summary(status_text))
	_add_attempt_state(scenario, campaign_progress)
	_add_plain_text("Tags: %s" % _join_values(scenario.tags, ", "))
	_add_plain_text("Content unlocks: %s" % _join_values(scenario.content_unlocks, ", "))
	_add_content_unlock_state(scenario, campaign_progress)
	if not scenario.story_outro.is_empty():
		_add_plain_text("Outro: %s" % scenario.story_outro)
	if not scenario.scenario_rules.is_empty():
		_add_plain_text("")
		_add_plain_text("Rules:")
		for rule in scenario.scenario_rules:
			if rule != null:
				_add_resource_text(rule, "- %s: %s" % [rule.display_name, rule.description])
	if not scenario.rewards.is_empty():
		_add_plain_text("")
		_add_plain_text("Scenario rewards:")
		for reward in scenario.rewards:
			if reward != null:
				_add_resource_text(reward, "- %s: %s" % [reward.display_name, reward.description])


func _add_plain_text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(label)
	return label


func _add_resource_text(resource: Resource, text: String) -> Label:
	var label := _add_plain_text(text)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.mouse_entered.connect(_on_resource_mouse_entered.bind(label, resource))
	label.mouse_exited.connect(_on_resource_mouse_exited)
	return label


func _add_scouting_reports(encounters: Array) -> void:
	var has_report := false
	for encounter in encounters:
		if encounter != null and "scout_text" in encounter and not String(encounter.scout_text).is_empty():
			has_report = true
			break
	if not has_report:
		return
	_add_plain_text("")
	_add_plain_text("Scouting reports:")
	for encounter in encounters:
		if encounter != null and "scout_text" in encounter and not String(encounter.scout_text).is_empty():
			_add_resource_text(encounter, "- %s: %s" % [encounter.display_name, encounter.scout_text])


func _add_content_unlock_state(scenario: Resource, campaign_progress) -> void:
	if campaign_progress == null or scenario.content_unlocks.is_empty():
		return
	var unlocked: Array[String] = []
	var pending: Array[String] = []
	for content_id in scenario.content_unlocks:
		var id_text := String(content_id)
		if campaign_progress.unlocked_content_ids.has(id_text):
			unlocked.append(id_text)
		else:
			pending.append(id_text)
	_add_plain_text("Unlocked from this scenario: %s" % _join_values(unlocked, ", "))
	_add_plain_text("Still pending from this scenario: %s" % _join_values(pending, ", "))


func _add_attempt_state(scenario: Resource, campaign_progress) -> void:
	if campaign_progress == null:
		return
	if campaign_progress.completed_scenario_ids.has(scenario.scenario_id):
		_add_plain_text("Attempt knowledge: completed")
	elif campaign_progress.attempted_scenario_ids.has(scenario.scenario_id):
		_add_plain_text("Attempt knowledge: attempted - no rewards or progression awarded yet")
	else:
		_add_plain_text("Attempt knowledge: none")


func _on_resource_mouse_entered(source: Control, resource: Resource) -> void:
	resource_tooltip_requested.emit(source, resource)


func _on_resource_mouse_exited() -> void:
	tooltip_cleared.emit()


func _clear_content() -> void:
	_ensure_content()
	for child in content.get_children():
		child.queue_free()


func _ensure_content() -> void:
	if content != null:
		return
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(content)


func _join_values(values: Array, separator: String) -> String:
	if values.is_empty():
		return "none"
	var text := ""
	for value in values:
		if not text.is_empty():
			text += separator
		text += String(value)
	return text


func _status_summary(status_text: String) -> String:
	if status_text == "active":
		return "active - finish the current scenario before starting another"
	if status_text == "practice":
		return "practice - standalone run active, campaign progress will not change"
	if status_text == "available":
		return "available - ready to start"
	if status_text == "complete":
		return "complete - campaign replay is not implemented yet"
	if status_text == "attempted":
		return "attempted - retry is available, but rewards and progression wait for completion"
	if status_text == "locked":
		return "locked - complete prerequisite scenarios first"
	return status_text
