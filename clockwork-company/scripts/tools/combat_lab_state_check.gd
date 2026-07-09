extends SceneTree

const CombatLabStateScript := preload("res://scripts/devtools/combat_lab_state.gd")
const DefinitionCloneHelperScript := preload("res://scripts/data/definition_clone_helper.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")


func _init() -> void:
	var state = CombatLabStateScript.new()
	state.load_catalog([])
	assert(not state.catalog_units.is_empty(), "Combat Lab should load catalog units.")

	var allied_catalog := _first_catalog_unit_for_team(state, CombatLabStateScript.TEAM_ALLIES)
	var enemy_catalog := _first_catalog_unit_for_team(state, CombatLabStateScript.TEAM_ENEMIES)
	assert(allied_catalog != null, "Combat Lab needs at least one allied catalog unit.")
	assert(enemy_catalog != null, "Combat Lab needs at least one enemy catalog unit.")
	var original_allied_hp := allied_catalog.max_hp

	assert(state.add_catalog_unit_to_team(allied_catalog, CombatLabStateScript.TEAM_ALLIES), "Adding an allied catalog unit should succeed.")
	assert(state.add_catalog_unit_to_team(enemy_catalog, CombatLabStateScript.TEAM_ENEMIES), "Adding an enemy catalog unit should succeed.")
	assert(state.allied_units[0] != allied_catalog, "Added allied unit should be a clone, not the canonical catalog Resource.")
	assert(state.enemy_units[0] != enemy_catalog, "Added enemy unit should be a clone, not the canonical catalog Resource.")
	assert(DefinitionCloneHelperScript.content_id(state.allied_units[0]) == DefinitionCloneHelperScript.content_id(allied_catalog), "Clone should preserve catalog content id metadata.")
	assert(not state.catalog_jobs.is_empty(), "Combat Lab should load authored jobs.")
	assert(not state.catalog_skills.is_empty(), "Combat Lab should expose authored job skills.")
	assert(not state.catalog_passives.is_empty(), "Combat Lab should expose authored job passives.")
	assert(not state.catalog_reactions.is_empty(), "Combat Lab should expose authored job reactions.")
	assert(not state.catalog_tactics.is_empty(), "Combat Lab should load authored tactic templates.")
	_assert_template_pyromancer_job_kit_is_active(state)

	assert(state.duplicate_unit(CombatLabStateScript.TEAM_ALLIES, 0), "Duplicate should succeed for an existing allied unit.")
	assert(state.allied_units.size() == 2, "Duplicate should add one allied unit.")
	assert(state.allied_units[0] != state.allied_units[1], "Duplicate should create an independent clone.")

	var enemy_count: int = state.enemy_units.size()
	assert(state.remove_unit(CombatLabStateScript.TEAM_ALLIES, 1), "Remove should succeed for the duplicate.")
	assert(state.allied_units.size() == 1, "Remove should change the intended team.")
	assert(state.enemy_units.size() == enemy_count, "Remove should not change the other team.")

	var second_ally := _second_catalog_unit_for_team(state, CombatLabStateScript.TEAM_ALLIES, allied_catalog)
	assert(second_ally != null, "Combat Lab state check needs a second allied catalog unit for ordering.")
	state.add_catalog_unit_to_team(second_ally, CombatLabStateScript.TEAM_ALLIES)
	var first_name: String = state.allied_units[0].display_name
	var second_name: String = state.allied_units[1].display_name
	assert(state.move_unit(CombatLabStateScript.TEAM_ALLIES, 1, -1), "Move should succeed inside party bounds.")
	assert(state.allied_units[0].display_name == second_name and state.allied_units[1].display_name == first_name, "Move should reorder deterministic party order.")

	assert(state.clear_team(CombatLabStateScript.TEAM_ENEMIES), "Clear should succeed for enemies.")
	assert(state.enemy_units.is_empty(), "Clear should empty the intended party.")
	assert(not state.can_run(), "Empty enemy team should prevent running.")
	assert(state.run_battle_report().is_empty(), "Invalid empty-team run should not return a battle report.")

	state.add_catalog_unit_to_team(enemy_catalog, CombatLabStateScript.TEAM_ENEMIES)
	var equipment_item_index: int = _first_equippable_item_index(state, CombatLabStateScript.TEAM_ALLIES, 0)
	var catalog_item: ItemDefinition = null
	var equipped_item: ItemDefinition = null
	var original_item_name := ""
	if equipment_item_index >= 0:
		catalog_item = state.catalog_items[equipment_item_index]
		original_item_name = catalog_item.display_name
		assert(state.equip_catalog_item(CombatLabStateScript.TEAM_ALLIES, 0, catalog_item.slot, equipment_item_index), "Equipment edit should equip a catalog item clone.")
		equipped_item = _equipped_item_for_slot(state.allied_units[0], catalog_item.slot)
		assert(equipped_item != null and equipped_item != catalog_item, "Equipped lab item should be a clone, not the canonical catalog item.")
		equipped_item.display_name = "%s Lab Copy" % original_item_name
		assert(catalog_item.display_name == original_item_name, "Mutating equipped lab item clone must not mutate the catalog item.")
	if state.catalog_ancestries.is_empty():
		assert(state.set_ancestry(CombatLabStateScript.TEAM_ALLIES, 0, -1), "Combat Lab should allow clearing ancestry when no authored ancestries exist.")
		assert(state.allied_units[0].ancestry == null, "Ancestry assignment should stay empty when no authored ancestry catalog exists.")
	else:
		assert(state.set_ancestry(CombatLabStateScript.TEAM_ALLIES, 0, 0), "Combat Lab should assign an authored ancestry.")
		assert(state.allied_units[0].ancestry == state.catalog_ancestries[0], "Ancestry assignment should update the intended lab clone.")
	assert(state.set_current_job(CombatLabStateScript.TEAM_ALLIES, 0, 0), "Combat Lab should assign an authored current job.")
	assert(state.allied_units[0].loadout.current_job == state.catalog_jobs[0], "Job assignment should update the intended lab clone.")
	assert(state.set_equipped_feature(CombatLabStateScript.TEAM_ALLIES, 0, "skill", 0), "Combat Lab should assign an authored skill.")
	assert(state.set_equipped_feature(CombatLabStateScript.TEAM_ALLIES, 0, "passive", 0), "Combat Lab should assign an authored passive.")
	assert(state.set_equipped_feature(CombatLabStateScript.TEAM_ALLIES, 0, "reaction", 0), "Combat Lab should assign an authored reaction.")
	assert(state.allied_units[0].loadout.equipped_skill == state.catalog_skills[0], "Skill assignment should update the clone loadout.")
	assert(state.allied_units[0].loadout.equipped_passive == state.catalog_passives[0], "Passive assignment should update the clone loadout.")
	assert(state.allied_units[0].loadout.equipped_reaction == state.catalog_reactions[0], "Reaction assignment should update the clone loadout.")
	assert(state.set_unit_stat(CombatLabStateScript.TEAM_ALLIES, 0, "max_hp", original_allied_hp + 7), "Combat Lab should edit clone stats.")
	assert(state.allied_units[0].max_hp == original_allied_hp + 7, "Stat edits should affect only the lab clone.")
	assert(allied_catalog.max_hp == original_allied_hp, "Stat edits must not mutate the catalog unit.")
	assert(state.add_catalog_tactic(CombatLabStateScript.TEAM_ALLIES, 0, 0), "Combat Lab should add an authored tactic template.")
	var added_tactic: TacticDefinition = state.allied_units[0].loadout.tactics[state.allied_units[0].loadout.tactics.size() - 1]
	assert(added_tactic != state.catalog_tactics[0], "Added lab tactic should be a clone, not the canonical tactic template.")
	assert(state.add_catalog_tactic(CombatLabStateScript.TEAM_ALLIES, 0, 0), "Combat Lab should add a second tactic template for reorder coverage.")
	assert(state.move_tactic(CombatLabStateScript.TEAM_ALLIES, 0, state.allied_units[0].loadout.tactics.size() - 1, -1), "Combat Lab should reorder lab tactics.")
	assert(state.remove_tactic(CombatLabStateScript.TEAM_ALLIES, 0, state.allied_units[0].loadout.tactics.size() - 1), "Combat Lab should remove lab tactics.")
	_assert_setup_save_load_round_trip(state, catalog_item, original_item_name)
	var first_report: Dictionary = state.run_battle_report()
	_assert_report_surfaces(first_report)
	if equipped_item != null:
		assert(_report_contains_text(first_report, equipped_item.display_name), "Equipment edits should affect the battle report.")
	state.remove_unit(CombatLabStateScript.TEAM_ALLIES, 1)
	var second_report: Dictionary = state.run_battle_report()
	_assert_report_surfaces(second_report)
	assert(first_report != second_report, "Changing the matchup and rerunning should produce a newly resolved report.")
	if equipped_item != null:
		assert(_report_contains_text(second_report, equipped_item.display_name), "Equipment edits should survive a rerun after changing the matchup.")
	_assert_large_lab_matchup_runs()

	state.allied_units[0].max_hp = original_allied_hp + 99
	assert(allied_catalog.max_hp == original_allied_hp, "Mutating a lab clone must not mutate the original catalog unit.")

	print("Combat Lab state validation passed: catalog loading, clone safety, party editing, validation, and real simulator reports worked.")
	quit(0)


func _assert_report_surfaces(report: Dictionary) -> void:
	assert(not report.is_empty(), "Valid Combat Lab battle should return a report.")
	assert(report.has("lines") and not report["lines"].is_empty(), "Report should include rendered log lines.")
	assert(report.has("events") and not report["events"].is_empty(), "Report should include structured events.")
	assert(report.has("combat_events") and report["combat_events"] is Array, "Report should include combat event snapshots.")
	assert(report.has("roster_units") and not report["roster_units"].is_empty(), "Report should include replay roster units.")
	assert(report.has("replay_snapshots") and not report["replay_snapshots"].is_empty(), "Report should include replay snapshots.")
	assert(report.has("contribution_summary") and not report["contribution_summary"].is_empty(), "Report should include battle contribution rows.")
	assert(report.has("winner"), "Report should include a winner.")


func _assert_template_pyromancer_job_kit_is_active(state) -> void:
	for unit in state.catalog_units:
		if DefinitionCloneHelperScript.content_id(unit) != "template_pyromancer":
			continue
		var runtime_unit = UnitStateScript.new(unit, 0)
		assert(runtime_unit.current_skill != null and runtime_unit.current_skill.display_name == "Apply Burn", "Template Pyromancer should use the Pyromancer primary action.")
		assert(runtime_unit.current_secondary_skill != null and runtime_unit.current_secondary_skill.display_name == "Hot on Their Heels", "Template Pyromancer should use the Pyromancer bridge action.")
		assert(runtime_unit.current_passive != null and runtime_unit.current_passive.display_name == "Fiery Soul", "Template Pyromancer should activate the Pyromancer passive.")
		assert(runtime_unit.current_reaction != null and runtime_unit.current_reaction.display_name == "Ember Reversal", "Template Pyromancer should activate the Pyromancer reaction.")
		return
	assert(false, "Combat Lab catalog should include template_pyromancer.")


func _assert_large_lab_matchup_runs() -> void:
	var large_state = CombatLabStateScript.new()
	large_state.load_catalog([])
	large_state.clear_all()
	_add_units_for_team(large_state, CombatLabStateScript.TEAM_ALLIES, 3)
	_add_units_for_team(large_state, CombatLabStateScript.TEAM_ENEMIES, 4)
	assert(large_state.allied_units.size() == 3 and large_state.enemy_units.size() == 4, "Large lab matchup fixture should build the intended party sizes.")
	var report: Dictionary = large_state.run_battle_report()
	_assert_report_surfaces(report)
	assert(not String("\n".join(report.get("lines", []))).contains("Combat event count exceeded"), "Large lab matchup should not hit the structured event safety limit.")


func _add_units_for_team(state, team: String, count: int) -> void:
	for unit in state.catalog_units:
		if unit.team != team:
			continue
		state.add_catalog_unit_to_team(unit, team)
		if state.team_units(team).size() >= count:
			return


func _first_catalog_unit_for_team(state, team: String) -> UnitDefinition:
	for unit in state.catalog_units:
		if unit.team == team:
			return unit
	return null


func _second_catalog_unit_for_team(state, team: String, first: UnitDefinition) -> UnitDefinition:
	for unit in state.catalog_units:
		if unit.team == team and unit != first:
			return unit
	return null


func _first_equippable_item_index(state, team: String, unit_index: int) -> int:
	var unit: UnitDefinition = state.unit_at(team, unit_index)
	if unit == null:
		return -1
	for item_index in state.catalog_items.size():
		var item: ItemDefinition = state.catalog_items[item_index]
		var options: Array[Dictionary] = state.equipment_options(team, unit_index, item.slot)
		for option in options:
			if int(option.get("item_index", -1)) == item_index:
				return item_index
	return -1


func _equipped_item_for_slot(unit: UnitDefinition, slot: String) -> ItemDefinition:
	if unit == null or unit.loadout == null:
		return null
	if slot == "Weapon":
		return unit.loadout.weapon
	if slot == "Armor":
		return unit.loadout.armor
	if slot == "Helmet":
		return unit.loadout.helmet
	if slot == "Trinket":
		return unit.loadout.trinket
	return null


func _report_contains_text(report: Dictionary, text: String) -> bool:
	for line in report.get("lines", []):
		if String(line).find(text) != -1:
			return true
	return false


func _assert_setup_save_load_round_trip(state, catalog_item: ItemDefinition, original_item_name: String) -> void:
	var setup: Dictionary = state.setup_to_dictionary("Validation Combat Lab Setup", "Round-trip save/load validation.")
	assert(setup.get("schema_version", 0) == 1, "Serialized setup should include a schema version.")
	assert(String(setup.get("setup_id", "")).is_empty() == false, "Serialized setup should include a setup id.")
	assert(not _contains_resource(setup), "Serialized setup dictionary should contain content ids, not Resource objects.")
	assert(_first_unit_entry(setup, "allied_units").get("base_unit_id", "") is String, "Serialized setup should include unit content ids.")
	if catalog_item != null:
		assert(_first_unit_entry(setup, "allied_units").get("equipment", {}).get(catalog_item.slot, null) is String, "Serialized equipment should use item content ids.")

	var loaded = CombatLabStateScript.new()
	loaded.load_catalog([])
	assert(loaded.apply_setup_dictionary(setup), "A serialized setup should apply to a fresh CombatLabState.")
	_assert_same_setup(state, loaded)
	assert(loaded.run_battle_report().has("winner"), "A loaded setup should run through the real CombatSimulator.")

	if catalog_item != null:
		var loaded_item := _equipped_item_for_slot(loaded.allied_units[0], catalog_item.slot)
		assert(loaded_item != null and loaded_item != catalog_item, "Loaded equipment should be cloned away from catalog content.")
		loaded_item.display_name = "%s Loaded Copy" % original_item_name
		assert(catalog_item.display_name == original_item_name, "Mutating loaded equipment must not mutate catalog content.")

	var loaded_tactic: TacticDefinition = loaded.allied_units[0].loadout.tactics[0]
	var catalog_tactic: TacticDefinition = loaded.catalog_tactics[0]
	var original_tactic_name := catalog_tactic.display_name
	assert(loaded_tactic != catalog_tactic, "Loaded tactics should be cloned away from catalog tactic templates.")
	loaded_tactic.display_name = "%s Loaded Copy" % original_tactic_name
	assert(catalog_tactic.display_name == original_tactic_name, "Mutating a loaded tactic must not mutate catalog content.")

	var invalid_setup: Dictionary = setup.duplicate(true)
	invalid_setup["allied_units"][0]["base_unit_id"] = "missing_unit_for_validation"
	var invalid_loaded = CombatLabStateScript.new()
	invalid_loaded.load_catalog([])
	assert(not invalid_loaded.apply_setup_dictionary(invalid_setup), "Missing content ids should fail setup load gracefully.")
	assert(invalid_loaded.last_message.find("missing_unit_for_validation") != -1, "Missing content id failures should name the missing id.")

	var setup_path: String = state.setup_path_for_id("_validation_combat_lab_setup")
	if FileAccess.file_exists(setup_path):
		assert(state.delete_setup_at_path(setup_path), "Validation cleanup should remove a stale setup fixture.")
	assert(state.save_setup_to_path(setup_path, "Validation Combat Lab Setup", "Saved by validation.", false), "Saving a setup should write JSON to the developer setup directory.")
	assert(FileAccess.file_exists(setup_path), "Saving a setup should create an inspectable JSON file.")
	var saved_text := FileAccess.get_file_as_string(setup_path)
	assert(saved_text.find("\"base_unit_id\"") != -1, "Saved setup JSON should be inspectable content-id data.")
	assert(not state.save_setup_to_path(setup_path, "Validation Combat Lab Setup", "Saved by validation.", false), "Saving over an existing setup should require explicit overwrite.")
	assert(state.save_setup_to_path(setup_path, "Validation Combat Lab Setup", "Saved by validation.", true), "Explicit overwrite should replace an existing setup.")
	var listed: Array[Dictionary] = state.list_saved_setups()
	assert(_setup_list_has_path(listed, setup_path), "Listing saved setups should find the saved fixture.")
	var loaded_from_file = CombatLabStateScript.new()
	loaded_from_file.load_catalog([])
	assert(loaded_from_file.load_setup_from_path(setup_path), "Loading saved JSON should reconstruct the setup.")
	_assert_same_setup(state, loaded_from_file)
	assert(state.delete_setup_at_path(setup_path), "Validation cleanup should remove its saved setup fixture.")


func _assert_same_setup(expected, actual) -> void:
	assert(actual.allied_units.size() == expected.allied_units.size(), "Loaded allies should preserve unit count.")
	assert(actual.enemy_units.size() == expected.enemy_units.size(), "Loaded enemies should preserve unit count.")
	for index in expected.allied_units.size():
		_assert_same_unit(expected.allied_units[index], actual.allied_units[index])
	for index in expected.enemy_units.size():
		_assert_same_unit(expected.enemy_units[index], actual.enemy_units[index])


func _assert_same_unit(expected: UnitDefinition, actual: UnitDefinition) -> void:
	assert(DefinitionCloneHelperScript.content_id(actual) == DefinitionCloneHelperScript.content_id(expected), "Loaded units should preserve base unit content id and order.")
	assert(actual != expected, "Loaded units should be fresh lab clones.")
	assert(actual.team == expected.team, "Loaded units should preserve team.")
	assert(actual.display_name == expected.display_name, "Loaded units should preserve display name overrides.")
	assert(actual.max_hp == expected.max_hp, "Loaded units should preserve max HP.")
	assert(actual.physical_damage == expected.physical_damage, "Loaded units should preserve physical damage.")
	assert(actual.magic_damage == expected.magic_damage, "Loaded units should preserve magic damage.")
	assert(actual.armor == expected.armor, "Loaded units should preserve armor.")
	assert(actual.action_speed == expected.action_speed, "Loaded units should preserve action speed.")
	assert(_resource_id(actual.ancestry) == _resource_id(expected.ancestry), "Loaded units should preserve ancestry content id.")
	assert(actual.loadout != null, "Loaded units should have a loadout.")
	assert(_resource_id(actual.loadout.current_job) == _resource_id(expected.loadout.current_job), "Loaded units should preserve current job content id.")
	for slot in ["Weapon", "Armor", "Helmet", "Trinket"]:
		assert(_resource_id(_equipped_item_for_slot(actual, slot)) == _resource_id(_equipped_item_for_slot(expected, slot)), "Loaded units should preserve equipment content ids.")
	assert(_resource_id(actual.loadout.equipped_skill) == _resource_id(expected.loadout.equipped_skill), "Loaded units should preserve equipped skill.")
	assert(_resource_id(actual.loadout.equipped_passive) == _resource_id(expected.loadout.equipped_passive), "Loaded units should preserve equipped passive.")
	assert(_resource_id(actual.loadout.equipped_reaction) == _resource_id(expected.loadout.equipped_reaction), "Loaded units should preserve equipped reaction.")
	assert(_resource_ids(actual.loadout.tactics) == _resource_ids(expected.loadout.tactics), "Loaded units should preserve tactic content ids and order.")


func _contains_resource(value: Variant) -> bool:
	if value is Resource:
		return true
	if value is Dictionary:
		for nested in value.values():
			if _contains_resource(nested):
				return true
	elif value is Array:
		for nested in value:
			if _contains_resource(nested):
				return true
	return false


func _first_unit_entry(setup: Dictionary, key: String) -> Dictionary:
	var entries: Array = setup.get(key, [])
	assert(not entries.is_empty(), "Serialized setup should include %s." % key)
	return entries[0]


func _setup_list_has_path(setups: Array[Dictionary], path: String) -> bool:
	for setup in setups:
		if String(setup.get("path", "")) == path:
			return true
	return false


func _resource_id(resource: Resource) -> String:
	return DefinitionCloneHelperScript.content_id(resource)


func _resource_ids(resources: Array) -> Array[String]:
	var ids: Array[String] = []
	for resource in resources:
		ids.append(_resource_id(resource))
	return ids
