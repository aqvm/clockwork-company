extends SceneTree

const CombatTestScene := preload("res://scenes/combat_test_scene.tscn")
const CombatLabStateScript := preload("res://scripts/devtools/combat_lab_state.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Control = CombatTestScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var lab_button := _button_named(scene, "Combat Lab")
	assert(lab_button != null, "Workbench should expose a Combat Lab entry button.")
	lab_button.pressed.emit()
	await process_frame

	assert(bool(scene.get("combat_lab_active")), "Pressing Combat Lab should enter lab mode.")
	var lab_panel: Control = scene.get("combat_lab_panel")
	var planning_panel: Control = scene.get("planning_panel")
	assert(lab_panel != null and lab_panel.visible, "Combat Lab panel should be visible in lab mode.")
	assert(planning_panel != null and not planning_panel.visible, "Planning panel should hide while lab mode is active.")

	var lab_state = scene.get("combat_lab_state")
	assert(lab_state != null, "Workbench should create a CombatLabState.")
	assert(not lab_state.catalog_units.is_empty(), "Lab state should have loaded catalog units.")
	assert(not lab_state.allied_units.is_empty() and not lab_state.enemy_units.is_empty(), "Lab entry should create a usable default matchup.")

	var initial_ally_count: int = lab_state.allied_units.size()
	assert(lab_panel.call("add_selected_catalog_unit_to_team", CombatLabStateScript.TEAM_ALLIES), "Panel add method should add the selected catalog unit.")
	await process_frame
	assert(lab_state.allied_units.size() == initial_ally_count + 1, "Panel add should update state.")
	assert(_label_with_prefix(lab_panel, "%d. " % lab_state.allied_units.size()) != null, "Panel refresh should show the new ordered party row.")

	assert(lab_panel.call("move_unit", CombatLabStateScript.TEAM_ALLIES, lab_state.allied_units.size() - 1, -1), "Panel move method should reorder through state.")
	await process_frame
	assert(_button_named(lab_panel, "Duplicate") != null, "Panel refresh should keep duplicate controls wired.")

	var equipment_item_index: int = _first_equippable_item_index(lab_state, CombatLabStateScript.TEAM_ALLIES, 0)
	var equipment_item: ItemDefinition = null
	if equipment_item_index >= 0:
		equipment_item = lab_state.catalog_items[equipment_item_index]
		assert(lab_panel.call("equip_item", CombatLabStateScript.TEAM_ALLIES, 0, equipment_item.slot, equipment_item_index), "Panel equip method should update state.")
		await process_frame
		assert(_label_containing(lab_panel, equipment_item.display_name) != null, "Panel refresh should show equipped item in the unit equipment summary.")
	if lab_state.catalog_ancestries.is_empty():
		assert(lab_panel.call("set_ancestry", CombatLabStateScript.TEAM_ALLIES, 0, -1), "Panel ancestry method should allow clearing ancestry.")
	else:
		assert(lab_panel.call("set_ancestry", CombatLabStateScript.TEAM_ALLIES, 0, 0), "Panel ancestry method should update state.")
	assert(lab_panel.call("set_current_job", CombatLabStateScript.TEAM_ALLIES, 0, 0), "Panel job method should update state.")
	assert(lab_panel.call("set_equipped_feature", CombatLabStateScript.TEAM_ALLIES, 0, "skill", 0), "Panel skill method should update state.")
	assert(lab_panel.call("set_equipped_feature", CombatLabStateScript.TEAM_ALLIES, 0, "passive", 0), "Panel passive method should update state.")
	assert(lab_panel.call("set_equipped_feature", CombatLabStateScript.TEAM_ALLIES, 0, "reaction", 0), "Panel reaction method should update state.")
	assert(lab_panel.call("set_unit_stat", CombatLabStateScript.TEAM_ALLIES, 0, "armor", 7), "Panel stat method should update state.")
	assert(lab_state.allied_units[0].armor == 7, "Panel stat edit should reach the lab state.")
	assert(lab_panel.call("add_tactic", CombatLabStateScript.TEAM_ALLIES, 0, 0), "Panel tactic add method should update state.")
	await process_frame
	assert(_label_containing(lab_panel, lab_state.catalog_tactics[0].display_name) != null, "Panel refresh should show added authored tactic.")

	var saved_setup_path: String = lab_state.setup_path_for_id("validation_ui_setup")
	if FileAccess.file_exists(saved_setup_path):
		assert(lab_state.delete_setup_at_path(saved_setup_path), "UI validation should remove stale setup fixture before saving.")
	lab_panel.call("set_setup_fields", "Validation UI Setup", "Saved through the headless UI check.")
	assert(lab_panel.call("save_setup", true), "Panel save should write the current Combat Lab setup.")
	await process_frame
	var saved_ally_count: int = lab_state.allied_units.size()
	var saved_enemy_count: int = lab_state.enemy_units.size()
	lab_panel.call("clear_all")
	await process_frame
	assert(not lab_state.can_run(), "Clearing after save should make the lab unable to run.")
	lab_panel.call("refresh_setup_list")
	assert(lab_panel.call("load_selected_setup"), "Panel load should restore the saved setup.")
	await process_frame
	assert(lab_state.allied_units.size() == saved_ally_count, "UI-loaded setup should preserve allied unit count.")
	assert(lab_state.enemy_units.size() == saved_enemy_count, "UI-loaded setup should preserve enemy unit count.")
	if equipment_item != null:
		assert(_label_containing(lab_panel, equipment_item.display_name) != null, "UI-loaded setup should refresh equipment labels.")
	assert(_label_containing(lab_panel, lab_state.catalog_tactics[0].display_name) != null, "UI-loaded setup should refresh tactic labels.")

	lab_panel.call("clear_team", CombatLabStateScript.TEAM_ENEMIES)
	await process_frame
	var run_button := _button_named(scene, "Run Lab Battle")
	assert(run_button != null and run_button.disabled, "Main run button should disable when a lab team is empty.")

	lab_panel.call("add_selected_catalog_unit_to_team", CombatLabStateScript.TEAM_ENEMIES)
	await process_frame
	run_button = _button_named(scene, "Run Lab Battle")
	assert(run_button != null and not run_button.disabled, "Main run button should re-enable after both lab teams have units.")
	run_button.pressed.emit()
	await process_frame

	var report: Dictionary = scene.get("cached_battle_report")
	assert(not report.is_empty(), "Running from UI should cache a real battle report.")
	assert(not scene.get("cached_structured_events").is_empty(), "UI run should hand structured events to replay.")
	assert(not scene.get("cached_roster_units").is_empty(), "UI run should hand roster units to replay.")
	assert(not report.get("contribution_summary", []).is_empty(), "UI-run lab report should include contribution summary rows.")
	var contribution_panel: Control = scene.get("battle_contribution_panel")
	assert(contribution_panel != null and contribution_panel.visible, "Workbench should show contribution panel after a Combat Lab battle report.")
	if equipment_item != null:
		assert(_report_contains_text(report, equipment_item.display_name), "UI-run report should include the equipped lab item.")
	assert(bool(scene.get("replay_is_active")), "UI run should start the existing replay flow.")

	var replay_panel: Control = scene.get("replay_panel")
	replay_panel.call("stop_replay")
	scene.call("_on_replay_finished")
	await process_frame
	assert(bool(scene.get("combat_lab_active")), "Lab replay finishing should not exit lab mode.")

	var leave_button := _button_named(scene, "Leave Lab")
	assert(leave_button != null, "Lab panel should expose a Leave Lab button.")
	leave_button.pressed.emit()
	await process_frame
	assert(not bool(scene.get("combat_lab_active")), "Leave Lab should exit lab mode.")
	assert(planning_panel.visible, "Planning panel should be restored after leaving lab mode.")
	if FileAccess.file_exists(saved_setup_path):
		assert(lab_state.delete_setup_at_path(saved_setup_path), "UI validation should clean up its saved setup fixture.")

	print("Combat Lab UI validation passed: workbench entry, panel operations, run gating, replay handoff, and exit wiring worked.")
	quit(0)


func _button_named(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == text:
			return child
		var nested := _button_named(child, text)
		if nested != null:
			return nested
	return null


func _label_with_prefix(parent: Node, prefix: String) -> Label:
	for child in parent.get_children():
		if child is Label and child.text.begins_with(prefix):
			return child
		var nested := _label_with_prefix(child, prefix)
		if nested != null:
			return nested
	return null


func _label_containing(parent: Node, text: String) -> Label:
	for child in parent.get_children():
		if child is Label and child.text.find(text) != -1:
			return child
		var nested := _label_containing(child, text)
		if nested != null:
			return nested
	return null


func _first_equippable_item_index(state, team: String, unit_index: int) -> int:
	for item_index in state.catalog_items.size():
		var item: ItemDefinition = state.catalog_items[item_index]
		var options: Array[Dictionary] = state.equipment_options(team, unit_index, item.slot)
		for option in options:
			if int(option.get("item_index", -1)) == item_index:
				return item_index
	return -1


func _report_contains_text(report: Dictionary, text: String) -> bool:
	for line in report.get("lines", []):
		if String(line).find(text) != -1:
			return true
	return false
