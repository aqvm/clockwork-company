extends VBoxContainer
class_name UnitActionPanel

signal start_scenario_requested
signal cycle_equipment_requested(slot: String)
signal equip_option_requested(option_index: int)


func show_actions(
	selected_scenario: Resource,
	selected_unit: UnitDefinition,
	selected_unit_name: String,
	can_start_scenario: bool,
	has_active_campaign_scenario: bool,
	is_replay_active: bool,
	is_equipment_state: bool,
	equip_options: Array
) -> void:
	_clear_children()
	_add_start_button(selected_scenario, can_start_scenario, has_active_campaign_scenario, is_replay_active)

	if selected_unit == null:
		return

	var unit_label := Label.new()
	unit_label.text = "Unit Actions"
	add_child(unit_label)

	if not is_equipment_state:
		_show_planning_or_locked_actions(has_active_campaign_scenario)
		return

	_show_equipment_options(selected_unit_name, equip_options)


func _add_start_button(
	selected_scenario: Resource,
	can_start_scenario: bool,
	has_active_campaign_scenario: bool,
	is_replay_active: bool
) -> void:
	var button := Button.new()
	button.text = "Start %s" % selected_scenario.display_name if selected_scenario != null else "Start Selected Scenario"
	button.disabled = selected_scenario == null or has_active_campaign_scenario or is_replay_active or not can_start_scenario
	button.pressed.connect(_on_start_button_pressed)
	add_child(button)


func _show_planning_or_locked_actions(has_active_campaign_scenario: bool) -> void:
	if not has_active_campaign_scenario:
		for slot in ["Weapon", "Armor", "Helmet", "Trinket"]:
			var button := Button.new()
			button.text = "Cycle %s" % slot
			button.pressed.connect(_on_cycle_button_pressed.bind(slot))
			add_child(button)
	else:
		var hint := Label.new()
		hint.text = "Equipment changes unlock between fights."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(hint)


func _show_equipment_options(selected_unit_name: String, equip_options: Array) -> void:
	var added_option := false
	for index in equip_options.size():
		var option: Dictionary = equip_options[index]
		if String(option["unit_name"]) != selected_unit_name:
			continue
		added_option = true
		var button := Button.new()
		button.text = String(option["label"])
		button.pressed.connect(_on_equip_button_pressed.bind(index))
		add_child(button)

	if not added_option:
		var no_options := Label.new()
		no_options.text = "No valid equipment changes for this unit."
		no_options.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(no_options)


func _on_start_button_pressed() -> void:
	start_scenario_requested.emit()


func _on_cycle_button_pressed(slot: String) -> void:
	cycle_equipment_requested.emit(slot)


func _on_equip_button_pressed(option_index: int) -> void:
	equip_option_requested.emit(option_index)


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
