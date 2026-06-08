extends VBoxContainer
class_name UnitActionPanel

signal start_scenario_requested
signal practice_scenario_requested
signal planning_item_requested(option: Dictionary)
signal equip_option_requested(option_index: int)
signal unlock_choice_requested(choice: String)
signal planning_job_requested(job: JobDefinition)
signal planning_feature_requested(feature_type: String, feature: Resource)
signal planning_tactic_add_requested(tactic: TacticDefinition)
signal planning_tactic_remove_requested(index: int)
signal planning_tactic_move_requested(index: int, direction: int)
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
	unlock_options: Array,
	job_options: Array,
	learned_feature_options: Dictionary,
	tactic_options: Array
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
		_show_planning_or_locked_actions(has_active_campaign_scenario, planning_item_options, job_options, learned_feature_options, tactic_options)
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


func _show_planning_or_locked_actions(has_active_campaign_scenario: bool, planning_item_options: Array, job_options: Array, learned_feature_options: Dictionary, tactic_options: Array) -> void:
	if has_active_campaign_scenario:
		var hint := Label.new()
		hint.text = "Planning changes unlock after the scenario."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(hint)
		return

	_show_job_selector(job_options)
	for feature_type in ["skill", "passive", "reaction"]:
		_show_feature_selector(feature_type, learned_feature_options.get(feature_type, []))
	_show_tactic_editor(tactic_options)
	_show_planning_equipment_browser(planning_item_options)


func _show_tactic_editor(options: Array) -> void:
	var label := Label.new()
	label.text = "Ordered Tactics"
	add_child(label)
	var add_options: Array = []
	var equipped_count := 0
	for option in options:
		if bool(option.get("equipped", false)):
			equipped_count += 1
	for index in options.size():
		var option: Dictionary = options[index]
		if bool(option.get("equipped", false)):
			_add_tactic_row(index, option, equipped_count)
		else:
			add_options.append(option)
	if add_options.is_empty():
		return
	var selector := OptionButton.new()
	selector.add_item("Add Tactic")
	selector.set_item_disabled(0, true)
	for option in add_options:
		selector.add_item(String(option["label"]))
	selector.select(0)
	selector.item_selected.connect(_on_tactic_add_selected.bind(add_options))
	add_child(selector)


func _add_tactic_row(index: int, option: Dictionary, tactic_count: int) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(row)
	var tactic: TacticDefinition = option["tactic"]
	var name_button := Button.new()
	name_button.text = "%d. %s" % [index + 1, tactic.display_name]
	name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bind_resource_tooltip(name_button, tactic)
	row.add_child(name_button)
	for spec in [["Up", -1, index == 0], ["Down", 1, index == tactic_count - 1]]:
		var button := Button.new()
		button.text = spec[0]
		button.disabled = spec[2]
		button.pressed.connect(func(): planning_tactic_move_requested.emit(index, spec[1]))
		row.add_child(button)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(func(): planning_tactic_remove_requested.emit(index))
	row.add_child(remove_button)


func _show_job_selector(job_options: Array) -> void:
	if job_options.is_empty():
		return
	var selector := OptionButton.new()
	selector.add_item("Current Job")
	selector.set_item_disabled(0, true)
	var selected_index := 1
	for index in job_options.size():
		var option: Dictionary = job_options[index]
		selector.add_item(String(option["label"]))
		if bool(option.get("equipped", false)):
			selected_index = index + 1
	selector.select(selected_index)
	selector.item_selected.connect(_on_job_selected.bind(job_options))
	add_child(selector)


func _show_feature_selector(feature_type: String, options: Array) -> void:
	if options.is_empty():
		return
	var selector := OptionButton.new()
	selector.add_item("Assigned %s" % feature_type.capitalize())
	selector.set_item_disabled(0, true)
	var selected_index := 1
	for index in options.size():
		var option: Dictionary = options[index]
		selector.add_item(String(option["label"]))
		if bool(option.get("equipped", false)):
			selected_index = index + 1
	selector.select(selected_index)
	selector.item_selected.connect(_on_feature_selected.bind(feature_type, options))
	add_child(selector)


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
	var selected_item = slot_options[selected_index]["item"]
	if selected_item != null:
		_bind_resource_tooltip(selector, selected_item)
	selector.item_selected.connect(_on_planning_item_option_selected.bind(slot_options))


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


func _on_planning_item_option_selected(selected_index: int, slot_options: Array) -> void:
	if selected_index < 0 or selected_index >= slot_options.size():
		return
	planning_item_requested.emit(slot_options[selected_index])


func _on_equip_button_pressed(option_index: int) -> void:
	equip_option_requested.emit(option_index)


func _on_job_selected(selected_index: int, options: Array) -> void:
	var option_index := selected_index - 1
	if option_index >= 0 and option_index < options.size():
		planning_job_requested.emit(options[option_index]["job"])


func _on_feature_selected(selected_index: int, feature_type: String, options: Array) -> void:
	var option_index := selected_index - 1
	if option_index >= 0 and option_index < options.size():
		planning_feature_requested.emit(feature_type, options[option_index].get("feature", null))


func _on_tactic_add_selected(selected_index: int, options: Array) -> void:
	var option_index := selected_index - 1
	if option_index >= 0 and option_index < options.size():
		planning_tactic_add_requested.emit(options[option_index]["tactic"])


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _bind_resource_tooltip(control: Control, resource: Resource) -> void:
	control.mouse_entered.connect(func(): resource_tooltip_requested.emit(control, resource))
	control.mouse_exited.connect(func(): tooltip_cleared.emit())
