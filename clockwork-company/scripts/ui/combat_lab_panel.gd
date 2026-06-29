extends PanelContainer
class_name CombatLabPanel

signal exit_requested
signal run_requested
signal state_changed

const CombatLabStateScript := preload("res://scripts/devtools/combat_lab_state.gd")

var lab_state = null
var catalog_selector: OptionButton = null
var setup_name_edit: LineEdit = null
var setup_notes_edit: LineEdit = null
var setup_selector: OptionButton = null
var feedback_label: Label = null
var allies_list: VBoxContainer = null
var enemies_list: VBoxContainer = null


func _ready() -> void:
	if get_child_count() == 0:
		_build_ui()
	_refresh()


func setup(state) -> void:
	lab_state = state
	if is_inside_tree() and get_child_count() == 0:
		_build_ui()
	_refresh()


func add_selected_catalog_unit_to_team(team: String) -> bool:
	if lab_state == null or catalog_selector == null:
		return false
	var changed: bool = lab_state.add_catalog_unit_by_index(catalog_selector.selected, team)
	_after_possible_change(changed)
	return changed


func remove_unit(team: String, index: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.remove_unit(team, index)
	_after_possible_change(changed)
	return changed


func duplicate_unit(team: String, index: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.duplicate_unit(team, index)
	_after_possible_change(changed)
	return changed


func move_unit(team: String, index: int, direction: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.move_unit(team, index, direction)
	_after_possible_change(changed)
	return changed


func equip_item(team: String, unit_index: int, slot: String, catalog_item_index: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.equip_catalog_item(team, unit_index, slot, catalog_item_index)
	_after_possible_change(changed)
	return changed


func set_ancestry(team: String, unit_index: int, ancestry_index: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.set_ancestry(team, unit_index, ancestry_index)
	_after_possible_change(changed)
	return changed


func set_current_job(team: String, unit_index: int, job_index: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.set_current_job(team, unit_index, job_index)
	_after_possible_change(changed)
	return changed


func set_equipped_feature(team: String, unit_index: int, feature_type: String, feature_index: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.set_equipped_feature(team, unit_index, feature_type, feature_index)
	_after_possible_change(changed)
	return changed


func set_unit_stat(team: String, unit_index: int, stat_name: String, value: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.set_unit_stat(team, unit_index, stat_name, value)
	_after_possible_change(changed)
	return changed


func add_tactic(team: String, unit_index: int, tactic_index: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.add_catalog_tactic(team, unit_index, tactic_index)
	_after_possible_change(changed)
	return changed


func remove_tactic(team: String, unit_index: int, tactic_index: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.remove_tactic(team, unit_index, tactic_index)
	_after_possible_change(changed)
	return changed


func move_tactic(team: String, unit_index: int, tactic_index: int, direction: int) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.move_tactic(team, unit_index, tactic_index, direction)
	_after_possible_change(changed)
	return changed


func clear_team(team: String) -> bool:
	if lab_state == null:
		return false
	var changed: bool = lab_state.clear_team(team)
	_after_possible_change(changed)
	return changed


func clear_all() -> void:
	if lab_state == null:
		return
	lab_state.clear_all()
	_after_possible_change(true)


func setup_default_matchup() -> void:
	if lab_state == null:
		return
	lab_state.setup_default_matchup()
	_after_possible_change(true)


func set_setup_fields(display_name: String, notes: String) -> void:
	if setup_name_edit != null:
		setup_name_edit.text = display_name
	if setup_notes_edit != null:
		setup_notes_edit.text = notes


func save_setup(overwrite := true) -> bool:
	if lab_state == null or setup_name_edit == null:
		return false
	var display_name := setup_name_edit.text.strip_edges()
	if display_name.is_empty():
		lab_state.last_message = "Combat Lab setup save failed: enter a setup name."
		_refresh()
		return false
	var notes := setup_notes_edit.text if setup_notes_edit != null else ""
	var saved: bool = lab_state.save_setup_named(display_name, notes, overwrite)
	if saved:
		lab_state.setup_display_name = display_name
		lab_state.setup_notes = notes
		_refresh_setup_list()
		_select_setup_path(lab_state.setup_path_for_id(display_name))
	_refresh()
	return saved


func load_selected_setup() -> bool:
	if lab_state == null or setup_selector == null or setup_selector.selected < 0:
		if lab_state != null:
			lab_state.last_message = "Combat Lab setup load failed: choose a saved setup."
		_refresh()
		return false
	var path := String(setup_selector.get_item_metadata(setup_selector.selected))
	var loaded: bool = lab_state.load_setup_from_path(path)
	if loaded:
		if setup_name_edit != null:
			setup_name_edit.text = lab_state.setup_display_name
		if setup_notes_edit != null:
			setup_notes_edit.text = lab_state.setup_notes
		_after_possible_change(true)
	else:
		_refresh()
	return loaded


func refresh_setup_list() -> void:
	_refresh_setup_list()
	_refresh()


func refresh() -> void:
	_refresh()


func _build_ui() -> void:
	custom_minimum_size = Vector2(0, 240)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	scroll.add_child(root)

	var header := HFlowContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)

	var title := Label.new()
	title.text = "Combat Lab"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var run_button := Button.new()
	run_button.text = "Run Lab Battle"
	run_button.pressed.connect(func(): run_requested.emit())
	header.add_child(run_button)

	var exit_button := Button.new()
	exit_button.text = "Leave Lab"
	exit_button.pressed.connect(func(): exit_requested.emit())
	header.add_child(exit_button)

	var catalog_row := HFlowContainer.new()
	catalog_row.add_theme_constant_override("separation", 6)
	root.add_child(catalog_row)

	catalog_selector = OptionButton.new()
	catalog_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_selector.custom_minimum_size = Vector2(220, 0)
	catalog_row.add_child(catalog_selector)

	var add_ally_button := Button.new()
	add_ally_button.text = "Add Ally"
	add_ally_button.pressed.connect(func(): add_selected_catalog_unit_to_team(CombatLabStateScript.TEAM_ALLIES))
	catalog_row.add_child(add_ally_button)

	var add_enemy_button := Button.new()
	add_enemy_button.text = "Add Enemy"
	add_enemy_button.pressed.connect(func(): add_selected_catalog_unit_to_team(CombatLabStateScript.TEAM_ENEMIES))
	catalog_row.add_child(add_enemy_button)

	var default_button := Button.new()
	default_button.text = "Default"
	default_button.pressed.connect(setup_default_matchup)
	catalog_row.add_child(default_button)

	var clear_all_button := Button.new()
	clear_all_button.text = "Clear Both"
	clear_all_button.pressed.connect(clear_all)
	catalog_row.add_child(clear_all_button)

	var setup_row := HFlowContainer.new()
	setup_row.add_theme_constant_override("separation", 6)
	root.add_child(setup_row)

	setup_name_edit = LineEdit.new()
	setup_name_edit.placeholder_text = "Setup name"
	setup_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_name_edit.custom_minimum_size = Vector2(180, 0)
	setup_row.add_child(setup_name_edit)

	var save_button := Button.new()
	save_button.text = "Save Setup"
	save_button.pressed.connect(func(): save_setup(true))
	setup_row.add_child(save_button)

	setup_selector = OptionButton.new()
	setup_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_selector.custom_minimum_size = Vector2(180, 0)
	setup_row.add_child(setup_selector)

	var load_button := Button.new()
	load_button.text = "Load Selected"
	load_button.pressed.connect(load_selected_setup)
	setup_row.add_child(load_button)

	var refresh_setups_button := Button.new()
	refresh_setups_button.text = "Refresh Setups"
	refresh_setups_button.pressed.connect(refresh_setup_list)
	setup_row.add_child(refresh_setups_button)

	setup_notes_edit = LineEdit.new()
	setup_notes_edit.placeholder_text = "Setup notes"
	setup_notes_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_notes_edit.custom_minimum_size = Vector2(180, 0)
	root.add_child(setup_notes_edit)

	var parties_row := HFlowContainer.new()
	parties_row.add_theme_constant_override("separation", 10)
	parties_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parties_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(parties_row)

	allies_list = _build_team_column(parties_row, "Allies")
	enemies_list = _build_team_column(parties_row, "Enemies")

	feedback_label = Label.new()
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(feedback_label)


func _build_team_column(parent: Container, team: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(280, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	parent.add_child(column)

	var header := HFlowContainer.new()
	header.add_theme_constant_override("separation", 6)
	column.add_child(header)

	var label := Label.new()
	label.text = "%s Party Order" % team
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(func(): clear_team(team))
	header.add_child(clear_button)

	return column


func _refresh() -> void:
	if catalog_selector == null:
		return
	_refresh_catalog()
	_refresh_setup_controls()
	_refresh_team(CombatLabStateScript.TEAM_ALLIES, allies_list)
	_refresh_team(CombatLabStateScript.TEAM_ENEMIES, enemies_list)
	if feedback_label != null:
		if lab_state == null:
			feedback_label.text = "Combat Lab is not initialized."
		elif not lab_state.can_run():
			feedback_label.text = lab_state.run_validation_message()
		else:
			feedback_label.text = lab_state.last_message


func _refresh_catalog() -> void:
	var selected := catalog_selector.selected
	catalog_selector.clear()
	if lab_state == null:
		return
	for index in lab_state.catalog_units.size():
		catalog_selector.add_item(lab_state.catalog_unit_label(index), index)
	if catalog_selector.item_count > 0:
		catalog_selector.select(clamp(selected, 0, catalog_selector.item_count - 1))


func _refresh_setup_controls() -> void:
	if lab_state == null:
		return
	if setup_name_edit != null and setup_name_edit.text.strip_edges().is_empty() and not lab_state.setup_display_name.is_empty():
		setup_name_edit.text = lab_state.setup_display_name
	if setup_notes_edit != null and setup_notes_edit.text.is_empty() and not lab_state.setup_notes.is_empty():
		setup_notes_edit.text = lab_state.setup_notes
	_refresh_setup_list()


func _refresh_setup_list() -> void:
	if setup_selector == null:
		return
	var selected_path := ""
	if setup_selector.selected >= 0 and setup_selector.selected < setup_selector.item_count:
		selected_path = String(setup_selector.get_item_metadata(setup_selector.selected))
	setup_selector.clear()
	if lab_state == null:
		return
	var setups: Array[Dictionary] = lab_state.list_saved_setups()
	for index in setups.size():
		var setup: Dictionary = setups[index]
		setup_selector.add_item(String(setup.get("display_name", setup.get("setup_id", "Setup"))), index)
		setup_selector.set_item_metadata(index, String(setup.get("path", "")))
	if setup_selector.item_count > 0:
		if not selected_path.is_empty():
			_select_setup_path(selected_path)
		else:
			setup_selector.select(0)


func _select_setup_path(path: String) -> void:
	if setup_selector == null:
		return
	for index in setup_selector.item_count:
		if String(setup_selector.get_item_metadata(index)) == path:
			setup_selector.select(index)
			return


func _refresh_team(team: String, list: VBoxContainer) -> void:
	if list == null:
		return
	while list.get_child_count() > 1:
		var child := list.get_child(1)
		list.remove_child(child)
		child.queue_free()
	if lab_state == null:
		return
	var units: Array[UnitDefinition] = lab_state.team_units(team)
	if units.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No units."
		list.add_child(empty_label)
		return
	for index in units.size():
		list.add_child(_build_unit_row(team, index, units[index], units.size()))


func _build_unit_row(team: String, index: int, unit: UnitDefinition, party_size: int) -> Control:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 3)

	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 4)
	container.add_child(row)

	var label := Label.new()
	label.text = "%d. %s" % [index + 1, unit.display_name]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var up_button := Button.new()
	up_button.text = "Up"
	up_button.disabled = index == 0
	up_button.pressed.connect(func(): move_unit(team, index, -1))
	row.add_child(up_button)

	var down_button := Button.new()
	down_button.text = "Down"
	down_button.disabled = index >= party_size - 1
	down_button.pressed.connect(func(): move_unit(team, index, 1))
	row.add_child(down_button)

	var duplicate_button := Button.new()
	duplicate_button.text = "Duplicate"
	duplicate_button.pressed.connect(func(): duplicate_unit(team, index))
	row.add_child(duplicate_button)

	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(func(): remove_unit(team, index))
	row.add_child(remove_button)

	var equipment_label := Label.new()
	equipment_label.text = lab_state.equipment_summary(unit)
	equipment_label.add_theme_font_size_override("font_size", 12)
	equipment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(equipment_label)

	var equipment_row := HFlowContainer.new()
	equipment_row.add_theme_constant_override("separation", 4)
	container.add_child(equipment_row)
	for slot in ["Weapon", "Armor", "Helmet", "Trinket"]:
		equipment_row.add_child(_build_slot_selector(team, index, slot))

	var identity_row := HFlowContainer.new()
	identity_row.add_theme_constant_override("separation", 4)
	container.add_child(identity_row)
	identity_row.add_child(_build_ancestry_selector(team, index, unit))
	identity_row.add_child(_build_job_selector(team, index, unit))
	identity_row.add_child(_build_feature_selector(team, index, unit, "skill", "Skill"))
	identity_row.add_child(_build_feature_selector(team, index, unit, "passive", "Passive"))
	identity_row.add_child(_build_feature_selector(team, index, unit, "reaction", "Reaction"))

	var stats_row := HFlowContainer.new()
	stats_row.add_theme_constant_override("separation", 4)
	container.add_child(stats_row)
	stats_row.add_child(_build_stat_editor(team, index, "max_hp", "HP", unit.max_hp, 1))
	stats_row.add_child(_build_stat_editor(team, index, "physical_damage", "Phys", unit.physical_damage, 1))
	stats_row.add_child(_build_stat_editor(team, index, "magic_damage", "Magic", unit.magic_damage, 0))
	stats_row.add_child(_build_stat_editor(team, index, "armor", "Armor", unit.armor, 0))
	stats_row.add_child(_build_stat_editor(team, index, "action_speed", "Speed", unit.action_speed, 1))

	container.add_child(_build_tactics_editor(team, index, unit))

	return container


func _build_slot_selector(team: String, unit_index: int, slot: String) -> OptionButton:
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(120, 0)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var options: Array[Dictionary] = lab_state.equipment_options(team, unit_index, slot)
	var selected_index := 0
	for option_index in options.size():
		var option: Dictionary = options[option_index]
		selector.add_item("%s: %s" % [slot, String(option.get("label", "None"))], int(option.get("item_index", -1)))
		if bool(option.get("equipped", false)):
			selected_index = option_index
	selector.select(selected_index)
	selector.item_selected.connect(func(selected_option_index: int):
		var selected_item_index := selector.get_item_id(selected_option_index)
		equip_item(team, unit_index, slot, selected_item_index)
	)
	return selector


func _build_ancestry_selector(team: String, unit_index: int, unit: UnitDefinition) -> OptionButton:
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(130, 0)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.add_item("Ancestry: None", -1)
	var selected_index := 0
	var current_index: int = lab_state.ancestry_index_for_unit(unit)
	for index in lab_state.catalog_ancestries.size():
		selector.add_item("Ancestry: %s" % lab_state.ancestry_label(index), index)
		if index == current_index:
			selected_index = selector.item_count - 1
	selector.select(selected_index)
	selector.item_selected.connect(func(selected_option_index: int):
		set_ancestry(team, unit_index, selector.get_item_id(selected_option_index))
	)
	return selector


func _build_job_selector(team: String, unit_index: int, unit: UnitDefinition) -> OptionButton:
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(130, 0)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.add_item("Job: None", -1)
	var selected_index := 0
	var current_index: int = lab_state.job_index_for_unit(unit)
	for index in lab_state.catalog_jobs.size():
		selector.add_item("Job: %s" % lab_state.job_label(index), index)
		if index == current_index:
			selected_index = selector.item_count - 1
	selector.select(selected_index)
	selector.item_selected.connect(func(selected_option_index: int):
		set_current_job(team, unit_index, selector.get_item_id(selected_option_index))
	)
	return selector


func _build_feature_selector(team: String, unit_index: int, unit: UnitDefinition, feature_type: String, label: String) -> OptionButton:
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(130, 0)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.add_item("%s: None" % label, -1)
	var selected_index := 0
	var current_index: int = lab_state.feature_index_for_unit(unit, feature_type)
	var count: int = _feature_count(feature_type)
	for index in count:
		selector.add_item("%s: %s" % [label, lab_state.feature_label(feature_type, index)], index)
		if index == current_index:
			selected_index = selector.item_count - 1
	selector.select(selected_index)
	selector.item_selected.connect(func(selected_option_index: int):
		set_equipped_feature(team, unit_index, feature_type, selector.get_item_id(selected_option_index))
	)
	return selector


func _build_stat_editor(team: String, unit_index: int, stat_name: String, label_text: String, value: int, min_value: int) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(108, 0)
	row.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = 999
	spin.step = 1
	spin.value = value
	spin.custom_minimum_size = Vector2(64, 0)
	spin.value_changed.connect(func(new_value: float):
		set_unit_stat(team, unit_index, stat_name, int(new_value))
	)
	row.add_child(spin)
	return row


func _build_tactics_editor(team: String, unit_index: int, unit: UnitDefinition) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	var add_row := HFlowContainer.new()
	add_row.add_theme_constant_override("separation", 4)
	box.add_child(add_row)
	var label := Label.new()
	label.text = "Tactics"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(label)
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(180, 0)
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for index in lab_state.catalog_tactics.size():
		selector.add_item(lab_state.tactic_label(index), index)
	add_row.add_child(selector)
	var add_button := Button.new()
	add_button.text = "Add Tactic"
	add_button.disabled = lab_state.catalog_tactics.is_empty()
	add_button.pressed.connect(func():
		add_tactic(team, unit_index, selector.get_item_id(selector.selected))
	)
	add_row.add_child(add_button)

	var tactics: Array[TacticDefinition] = unit.loadout.tactics if unit.loadout != null else []
	if tactics.is_empty():
		var empty := Label.new()
		empty.text = "No unit tactics."
		empty.add_theme_font_size_override("font_size", 12)
		box.add_child(empty)
		return box
	for tactic_index in tactics.size():
		box.add_child(_build_tactic_row(team, unit_index, tactic_index, tactics[tactic_index], tactics.size()))
	return box


func _build_tactic_row(team: String, unit_index: int, tactic_index: int, tactic: TacticDefinition, tactic_count: int) -> Control:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = "%d. %s" % [tactic_index + 1, tactic.display_name]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var up_button := Button.new()
	up_button.text = "Up"
	up_button.disabled = tactic_index == 0
	up_button.pressed.connect(func(): move_tactic(team, unit_index, tactic_index, -1))
	row.add_child(up_button)
	var down_button := Button.new()
	down_button.text = "Down"
	down_button.disabled = tactic_index >= tactic_count - 1
	down_button.pressed.connect(func(): move_tactic(team, unit_index, tactic_index, 1))
	row.add_child(down_button)
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(func(): remove_tactic(team, unit_index, tactic_index))
	row.add_child(remove_button)
	return row


func _feature_count(feature_type: String) -> int:
	if feature_type == "skill":
		return lab_state.catalog_skills.size()
	if feature_type == "passive":
		return lab_state.catalog_passives.size()
	if feature_type == "reaction":
		return lab_state.catalog_reactions.size()
	return 0


func _after_possible_change(changed: bool) -> void:
	_refresh()
	if changed:
		state_changed.emit()
