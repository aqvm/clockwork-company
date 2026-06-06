extends VBoxContainer
class_name UnitActionPanel

signal start_scenario_requested
signal practice_scenario_requested
signal planning_item_requested(slot: String, item: ItemDefinition)
signal equip_option_requested(option_index: int)
signal unlock_choice_requested(choice: String)
signal resource_tooltip_requested(source: Control, resource: Resource)
signal tooltip_cleared


func show_actions(
	selected_scenario: Resource,
	selected_unit: UnitDefinition,
	selected_unit_name: String,
	selected_scenario_status: String,
	can_start_scenario: bool,
	can_practice_scenario: bool,
	has_active_campaign_scenario: bool,
	is_replay_active: bool,
	is_equipment_state: bool,
	planning_item_options: Array,
	equip_options: Array,
	unlock_options: Array
) -> void:
	_clear_children()
	_add_start_button(selected_scenario, selected_scenario_status, can_start_scenario, has_active_campaign_scenario, is_replay_active)
	_add_practice_button(selected_scenario, can_practice_scenario, has_active_campaign_scenario, is_replay_active)

	if selected_unit == null:
		return

	var unit_label := Label.new()
	unit_label.text = "Unit Actions"
	add_child(unit_label)
	_show_unlock_options(unlock_options)

	if not is_equipment_state:
		_show_planning_or_locked_actions(has_active_campaign_scenario, planning_item_options)
		return

	_show_equipment_options(selected_unit_name, equip_options)


func _show_unlock_options(unlock_options: Array) -> void:
	if unlock_options.is_empty():
		return
	var label := Label.new()
	label.text = "Pending Job Unlock"
	add_child(label)
	for option in unlock_options:
		var button := Button.new()
		button.text = String(option.get("label", "Choose Unlock"))
		button.pressed.connect(func(): unlock_choice_requested.emit(String(option.get("choice", ""))))
		add_child(button)


func _add_start_button(
	selected_scenario: Resource,
	selected_scenario_status: String,
	can_start_scenario: bool,
	has_active_campaign_scenario: bool,
	is_replay_active: bool
) -> void:
	var button := Button.new()
	button.text = _start_button_text(selected_scenario, selected_scenario_status)
	button.disabled = selected_scenario == null or has_active_campaign_scenario or is_replay_active or not can_start_scenario
	button.pressed.connect(_on_start_button_pressed)
	add_child(button)


func _add_practice_button(
	selected_scenario: Resource,
	can_practice_scenario: bool,
	has_active_campaign_scenario: bool,
	is_replay_active: bool
) -> void:
	if selected_scenario == null:
		return
	var button := Button.new()
	button.text = "Practice %s" % selected_scenario.display_name
	button.disabled = has_active_campaign_scenario or is_replay_active or not can_practice_scenario
	button.pressed.connect(_on_practice_button_pressed)
	add_child(button)


func _start_button_text(selected_scenario: Resource, selected_scenario_status: String) -> String:
	if selected_scenario == null:
		return "Start Selected Scenario"
	if selected_scenario_status == "locked":
		return "Locked: %s" % selected_scenario.display_name
	if selected_scenario_status == "complete":
		return "Complete: %s" % selected_scenario.display_name
	if selected_scenario_status == "active":
		return "Active: %s" % selected_scenario.display_name
	return "Start %s" % selected_scenario.display_name


func _show_planning_or_locked_actions(has_active_campaign_scenario: bool, planning_item_options: Array) -> void:
	if has_active_campaign_scenario:
		var hint := Label.new()
		hint.text = "Equipment changes unlock between fights."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(hint)
		return

	_show_planning_equipment_browser(planning_item_options)


func _show_planning_equipment_browser(planning_item_options: Array) -> void:
	var browser_label := Label.new()
	browser_label.text = "Planning Equipment"
	add_child(browser_label)

	var shown_any := false
	for slot in ["Weapon", "Armor", "Helmet", "Trinket"]:
		var slot_options := _options_for_slot(planning_item_options, slot)
		if slot_options.is_empty():
			continue
		shown_any = true
		_add_planning_slot_selector(slot, slot_options)

	if not shown_any:
		var no_options := Label.new()
		no_options.text = "No valid planning equipment for this unit."
		no_options.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(no_options)


func _options_for_slot(options: Array, slot: String) -> Array:
	var out := []
	for option in options:
		if String(option.get("slot", "")) == slot:
			out.append(option)
	return out


func _add_planning_slot_selector(slot: String, slot_options: Array) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(row)

	var slot_label := Label.new()
	slot_label.text = "%s:" % slot
	slot_label.custom_minimum_size = Vector2(54, 0)
	row.add_child(slot_label)

	var selector := OptionButton.new()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(selector)

	var selected_index := 0
	for index in slot_options.size():
		var option: Dictionary = slot_options[index]
		selector.add_item(String(option["label"]))
		if bool(option.get("equipped", false)):
			selected_index = index
	selector.select(selected_index)
	var selected_item: ItemDefinition = slot_options[selected_index]["item"]
	_bind_resource_tooltip(selector, selected_item)
	selector.item_selected.connect(_on_planning_item_option_selected.bind(slot, slot_options))


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


func _on_practice_button_pressed() -> void:
	practice_scenario_requested.emit()


func _on_planning_item_option_selected(selected_index: int, slot: String, slot_options: Array) -> void:
	if selected_index < 0 or selected_index >= slot_options.size():
		return
	var item: ItemDefinition = slot_options[selected_index]["item"]
	planning_item_requested.emit(slot, item)


func _on_equip_button_pressed(option_index: int) -> void:
	equip_option_requested.emit(option_index)


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _bind_resource_tooltip(control: Control, resource: Resource) -> void:
	control.mouse_entered.connect(func(): resource_tooltip_requested.emit(control, resource))
	control.mouse_exited.connect(func(): tooltip_cleared.emit())
