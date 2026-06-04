extends VBoxContainer
class_name ScenarioListPanel

signal scenario_selected(scenario: Resource)
signal resource_tooltip_requested(source: Control, resource: Resource)
signal tooltip_cleared


func show_scenarios(scenarios: Array, campaign_progress, selected_scenario: Resource) -> void:
	_clear_children()

	var title := Label.new()
	title.text = "Scenarios"
	add_child(title)

	for scenario in scenarios:
		if scenario == null:
			continue
		var button := Button.new()
		var state_text := ""
		if campaign_progress != null and campaign_progress.completed_scenario_ids.has(scenario.scenario_id):
			state_text = " [complete]"
		elif campaign_progress != null and not campaign_progress.is_scenario_unlocked(scenario.scenario_id):
			state_text = " [locked]"
		button.text = "%s%s" % [scenario.display_name, state_text]
		button.toggle_mode = true
		button.button_pressed = selected_scenario != null and selected_scenario.scenario_id == scenario.scenario_id
		button.pressed.connect(_on_scenario_button_pressed.bind(scenario))
		_bind_resource_tooltip(button, scenario)
		add_child(button)


func _on_scenario_button_pressed(scenario: Resource) -> void:
	scenario_selected.emit(scenario)


func _bind_resource_tooltip(control: Control, resource: Resource) -> void:
	control.mouse_entered.connect(_on_resource_mouse_entered.bind(control, resource))
	control.mouse_exited.connect(_on_resource_mouse_exited)


func _on_resource_mouse_entered(source: Control, resource: Resource) -> void:
	resource_tooltip_requested.emit(source, resource)


func _on_resource_mouse_exited() -> void:
	tooltip_cleared.emit()


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
