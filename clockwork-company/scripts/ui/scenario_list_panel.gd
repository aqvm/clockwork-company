extends PanelContainer
class_name ScenarioListPanel

const UIStyleHelperScript := preload("res://scripts/ui/ui_style_helper.gd")

signal scenario_selected(scenario: Resource)
signal resource_tooltip_requested(source: Control, resource: Resource)
signal tooltip_cleared

var content: VBoxContainer = null


func _ready() -> void:
	UIStyleHelperScript.apply_panel(self)
	_ensure_content()


func show_scenarios(scenarios: Array, campaign_progress, selected_scenario: Resource, active_scenario_id := "", campaign_scenario_ids: Array[String] = []) -> void:
	_clear_children()

	var title := Label.new()
	title.text = "Scenarios"
	UIStyleHelperScript.style_heading(title)
	content.add_child(title)

	for scenario in scenarios:
		if scenario == null:
			continue
		var button := Button.new()
		button.text = "%s [%s]" % [scenario.display_name, _scenario_label(scenario, campaign_progress, active_scenario_id, campaign_scenario_ids)]
		button.toggle_mode = true
		button.button_pressed = selected_scenario != null and selected_scenario.scenario_id == scenario.scenario_id
		button.pressed.connect(_on_scenario_button_pressed.bind(scenario))
		_bind_resource_tooltip(button, scenario)
		content.add_child(button)


func _on_scenario_button_pressed(scenario: Resource) -> void:
	scenario_selected.emit(scenario)


func _state_label(scenario: Resource, campaign_progress, active_scenario_id: String, campaign_scenario_ids: Array[String]) -> String:
	if campaign_progress == null:
		return "debug"
	if active_scenario_id == scenario.scenario_id or campaign_progress.current_scenario_id == scenario.scenario_id:
		return "active"
	if campaign_progress.completed_scenario_ids.has(scenario.scenario_id):
		return "complete"
	if campaign_progress.attempted_scenario_ids.has(scenario.scenario_id):
		return "attempted"
	if campaign_progress.is_scenario_unlocked(scenario.scenario_id):
		return "available"
	if not campaign_scenario_ids.has(String(scenario.scenario_id)):
		return "practice"
	return "locked"


func _scenario_label(scenario: Resource, campaign_progress, active_scenario_id: String, campaign_scenario_ids: Array[String]) -> String:
	var label := _state_label(scenario, campaign_progress, active_scenario_id, campaign_scenario_ids)
	var content_label := _content_unlock_label(scenario, campaign_progress)
	if content_label.is_empty():
		return label
	return "%s, %s" % [label, content_label]


func _content_unlock_label(scenario: Resource, campaign_progress) -> String:
	if campaign_progress == null or scenario.content_unlocks.is_empty():
		return ""
	var unlocked_count := 0
	for content_id in scenario.content_unlocks:
		if campaign_progress.unlocked_content_ids.has(content_id):
			unlocked_count += 1
	if unlocked_count == scenario.content_unlocks.size():
		return "content unlocked"
	if unlocked_count > 0:
		return "content %d/%d" % [unlocked_count, scenario.content_unlocks.size()]
	return "content reward"


func _bind_resource_tooltip(control: Control, resource: Resource) -> void:
	control.mouse_entered.connect(_on_resource_mouse_entered.bind(control, resource))
	control.mouse_exited.connect(_on_resource_mouse_exited)


func _on_resource_mouse_entered(source: Control, resource: Resource) -> void:
	resource_tooltip_requested.emit(source, resource)


func _on_resource_mouse_exited() -> void:
	tooltip_cleared.emit()


func _clear_children() -> void:
	_ensure_content()
	for child in content.get_children():
		child.queue_free()


func _ensure_content() -> void:
	if content != null:
		return
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	add_child(content)
