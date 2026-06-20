extends RefCounted
class_name CombatLabState

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const DefinitionCloneHelperScript := preload("res://scripts/data/definition_clone_helper.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")

const TEAM_ALLIES := "Allies"
const TEAM_ENEMIES := "Enemies"
const SETUP_SCHEMA_VERSION := 1
const DEFAULT_SETUP_DIR := "res://devtools/combat_lab_setups"
const SETUP_FILE_EXTENSION := ".json"
const SETUP_STATS := ["max_hp", "physical_damage", "magic_damage", "armor", "action_speed"]
const EQUIPMENT_SLOTS := ["Weapon", "Armor", "Helmet", "Trinket"]

var catalog_units: Array[UnitDefinition] = []
var catalog_items: Array[ItemDefinition] = []
var catalog_ancestries: Array[AncestryDefinition] = []
var catalog_jobs: Array[JobDefinition] = []
var catalog_skills: Array[SkillDefinition] = []
var catalog_passives: Array[PassiveDefinition] = []
var catalog_reactions: Array[ReactionDefinition] = []
var catalog_tactics: Array[TacticDefinition] = []
var allied_units: Array[UnitDefinition] = []
var enemy_units: Array[UnitDefinition] = []
var last_message := ""
var last_report := {}
var setup_id := ""
var setup_display_name := ""
var setup_notes := ""
var _enabled_mod_pack_ids: Array[String] = []
var _next_lab_unit_id := 1


func load_catalog(enabled_mod_pack_ids: Array[String] = []) -> void:
	_enabled_mod_pack_ids = enabled_mod_pack_ids.duplicate()
	catalog_units.clear()
	catalog_items.clear()
	catalog_ancestries.clear()
	catalog_jobs.clear()
	catalog_skills.clear()
	catalog_passives.clear()
	catalog_reactions.clear()
	catalog_tactics.clear()
	var content: Dictionary = JsonContentLoaderScript.load_content_resources(_enabled_mod_pack_ids)
	var units_by_id: Dictionary = content.get("units", {})
	for unit_id in units_by_id.keys():
		var unit := units_by_id[unit_id] as UnitDefinition
		if unit != null:
			catalog_units.append(unit)
	catalog_units.sort_custom(func(a, b): return a.display_name < b.display_name)
	var items_by_id: Dictionary = content.get("items", {})
	for item_id in items_by_id.keys():
		var item := items_by_id[item_id] as ItemDefinition
		if item != null:
			catalog_items.append(item)
	catalog_items.sort_custom(func(a, b): return a.slot < b.slot if a.slot != b.slot else a.display_name < b.display_name)
	_load_resource_catalog(content.get("ancestries", {}), catalog_ancestries)
	_load_resource_catalog(content.get("jobs", {}), catalog_jobs)
	_load_resource_catalog(content.get("tactics", {}), catalog_tactics)
	_collect_job_features()
	last_message = "Loaded %d catalog units, %d catalog items, %d jobs, and %d tactics." % [catalog_units.size(), catalog_items.size(), catalog_jobs.size(), catalog_tactics.size()]


func setup_default_matchup() -> void:
	clear_all()
	if catalog_units.is_empty():
		load_catalog(_enabled_mod_pack_ids)
	var allies_added := 0
	var enemies_added := 0
	for unit in catalog_units:
		if allies_added < 2 and unit.team == TEAM_ALLIES:
			add_catalog_unit_to_team(unit, TEAM_ALLIES)
			allies_added += 1
		elif enemies_added < 2 and unit.team == TEAM_ENEMIES:
			add_catalog_unit_to_team(unit, TEAM_ENEMIES)
			enemies_added += 1
		if allies_added >= 2 and enemies_added >= 2:
			break
	if allied_units.is_empty() and not catalog_units.is_empty():
		add_catalog_unit_to_team(catalog_units[0], TEAM_ALLIES)
	if enemy_units.is_empty() and catalog_units.size() > 1:
		add_catalog_unit_to_team(catalog_units[1], TEAM_ENEMIES)
	last_message = "Default Combat Lab matchup ready."


func clear_all() -> void:
	allied_units.clear()
	enemy_units.clear()
	last_report.clear()
	last_message = "Cleared both Combat Lab parties."


func clear_team(team: String) -> bool:
	if not _is_known_team(team):
		last_message = "Unknown team: %s." % team
		return false
	var party: Array[UnitDefinition] = _party_for_team(team)
	party.clear()
	last_report.clear()
	last_message = "Cleared %s." % team
	return true


func add_catalog_unit_by_index(catalog_index: int, team: String) -> bool:
	if catalog_index < 0 or catalog_index >= catalog_units.size():
		last_message = "Choose a catalog unit before adding."
		return false
	return add_catalog_unit_to_team(catalog_units[catalog_index], team)


func add_catalog_unit_to_team(catalog_unit: UnitDefinition, team: String) -> bool:
	if not _is_known_team(team):
		last_message = "Unknown team: %s." % team
		return false
	var party: Array[UnitDefinition] = _party_for_team(team)
	if catalog_unit == null:
		last_message = "Choose a catalog unit before adding."
		return false
	var copy := _clone_for_lab(catalog_unit, team)
	party.append(copy)
	last_report.clear()
	last_message = "Added %s to %s at position %d." % [copy.display_name, team, party.size()]
	return true


func duplicate_unit(team: String, index: int) -> bool:
	if not _is_known_team(team):
		last_message = "Unknown team: %s." % team
		return false
	var party: Array[UnitDefinition] = _party_for_team(team)
	if not _index_in_party(party, index):
		last_message = "Choose a valid %s unit to duplicate." % team
		return false
	var copy := _clone_for_lab(party[index], team)
	party.insert(index + 1, copy)
	last_report.clear()
	last_message = "Duplicated %s in %s." % [copy.display_name, team]
	return true


func remove_unit(team: String, index: int) -> bool:
	if not _is_known_team(team):
		last_message = "Unknown team: %s." % team
		return false
	var party: Array[UnitDefinition] = _party_for_team(team)
	if not _index_in_party(party, index):
		last_message = "Choose a valid %s unit to remove." % team
		return false
	var removed: UnitDefinition = party[index]
	party.remove_at(index)
	last_report.clear()
	last_message = "Removed %s from %s." % [removed.display_name, team]
	return true


func move_unit(team: String, index: int, direction: int) -> bool:
	if not _is_known_team(team):
		last_message = "Unknown team: %s." % team
		return false
	var party: Array[UnitDefinition] = _party_for_team(team)
	if not _index_in_party(party, index):
		last_message = "Choose a valid %s unit to move." % team
		return false
	var destination := index + direction
	if destination < 0 or destination >= party.size():
		last_message = "%s is already at that edge of %s." % [party[index].display_name, team]
		return false
	var unit: UnitDefinition = party[index]
	party.remove_at(index)
	party.insert(destination, unit)
	last_report.clear()
	last_message = "Moved %s to position %d in %s." % [unit.display_name, destination + 1, team]
	return true


func equipment_options(team: String, unit_index: int, slot: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = [{"label": "None", "item_index": -1, "item": null, "equipped": false}]
	var unit := unit_at(team, unit_index)
	if unit == null or not _is_known_slot(slot):
		return options
	var equipped_item := _loadout_item(unit.loadout, slot) if unit.loadout != null else null
	options[0]["equipped"] = equipped_item == null
	for item_index in catalog_items.size():
		var item := catalog_items[item_index]
		if item.slot != slot or not _can_equip_item(unit, item):
			continue
		options.append({
			"label": item.display_name,
			"item_index": item_index,
			"item": item,
			"equipped": _content_id(item) == _content_id(equipped_item),
		})
	return options


func equip_catalog_item(team: String, unit_index: int, slot: String, catalog_item_index: int) -> bool:
	var unit := unit_at(team, unit_index)
	if unit == null:
		last_message = "Choose a valid %s unit before changing equipment." % team
		return false
	if not _is_known_slot(slot):
		last_message = "Unknown equipment slot: %s." % slot
		return false
	var item: ItemDefinition = null
	if catalog_item_index >= 0:
		if catalog_item_index >= catalog_items.size():
			last_message = "Choose a valid catalog item before equipping."
			return false
		item = catalog_items[catalog_item_index]
		if item.slot != slot:
			last_message = "%s is a %s item, not a %s item." % [item.display_name, item.slot, slot]
			return false
		if not _can_equip_item(unit, item):
			last_message = "%s cannot equip %s." % [unit.display_name, item.display_name]
			return false
	var loadout := _ensure_loadout(unit)
	_set_loadout_item(loadout, slot, DefinitionCloneHelperScript.clone_item_definition(item) if item != null else null)
	last_report.clear()
	last_message = "%s %s set to %s." % [unit.display_name, slot.to_lower(), item.display_name if item != null else "none"]
	return true


func set_ancestry(team: String, unit_index: int, ancestry_index: int) -> bool:
	var unit := unit_at(team, unit_index)
	if unit == null:
		last_message = "Choose a valid %s unit before changing ancestry." % team
		return false
	if ancestry_index < 0:
		unit.ancestry = null
	elif ancestry_index < catalog_ancestries.size():
		unit.ancestry = catalog_ancestries[ancestry_index]
	else:
		last_message = "Choose a valid authored ancestry."
		return false
	_remove_illegal_equipment(unit)
	last_report.clear()
	last_message = "%s ancestry set to %s." % [unit.display_name, unit.ancestry.display_name if unit.ancestry != null else "none"]
	return true


func set_current_job(team: String, unit_index: int, job_index: int) -> bool:
	var unit := unit_at(team, unit_index)
	if unit == null:
		last_message = "Choose a valid %s unit before changing job." % team
		return false
	var loadout := _ensure_loadout(unit)
	if job_index < 0:
		loadout.current_job = null
	elif job_index < catalog_jobs.size():
		loadout.current_job = catalog_jobs[job_index]
		_unlock_job_features(unit, loadout.current_job)
	else:
		last_message = "Choose a valid authored job."
		return false
	_remove_illegal_equipment(unit)
	last_report.clear()
	last_message = "%s job set to %s." % [unit.display_name, loadout.current_job.display_name if loadout.current_job != null else "none"]
	return true


func set_equipped_feature(team: String, unit_index: int, feature_type: String, feature_index: int) -> bool:
	var unit := unit_at(team, unit_index)
	if unit == null:
		last_message = "Choose a valid %s unit before changing features." % team
		return false
	var loadout := _ensure_loadout(unit)
	var feature: Resource = null
	if feature_index >= 0:
		feature = _feature_at(feature_type, feature_index)
		if feature == null:
			last_message = "Choose a valid authored %s." % feature_type
			return false
		var feature_job := _job_for_feature(feature_type, feature)
		if feature_job != null:
			_unlock_job_features(unit, feature_job)
	if feature_type == "skill":
		loadout.equipped_skill = feature as SkillDefinition
	elif feature_type == "passive":
		loadout.equipped_passive = feature as PassiveDefinition
	elif feature_type == "reaction":
		loadout.equipped_reaction = feature as ReactionDefinition
	else:
		last_message = "Unknown feature type: %s." % feature_type
		return false
	last_report.clear()
	last_message = "%s %s set to %s." % [unit.display_name, feature_type, feature.display_name if feature != null else "none"]
	return true


func set_unit_stat(team: String, unit_index: int, stat_name: String, value: int) -> bool:
	var unit := unit_at(team, unit_index)
	if unit == null:
		last_message = "Choose a valid %s unit before changing stats." % team
		return false
	if stat_name == "max_hp":
		unit.max_hp = max(1, value)
	elif stat_name == "physical_damage":
		unit.physical_damage = max(1, value)
	elif stat_name == "magic_damage":
		unit.magic_damage = max(0, value)
	elif stat_name == "armor":
		unit.armor = max(0, value)
	elif stat_name == "action_speed":
		unit.action_speed = max(1, value)
	else:
		last_message = "Unknown stat: %s." % stat_name
		return false
	last_report.clear()
	last_message = "%s %s set to %d." % [unit.display_name, stat_name.replace("_", " "), int(unit.get(stat_name))]
	return true


func add_catalog_tactic(team: String, unit_index: int, tactic_index: int) -> bool:
	var unit := unit_at(team, unit_index)
	if unit == null:
		last_message = "Choose a valid %s unit before adding tactics." % team
		return false
	if tactic_index < 0 or tactic_index >= catalog_tactics.size():
		last_message = "Choose a valid authored tactic."
		return false
	var loadout := _ensure_loadout(unit)
	loadout.tactics.append(DefinitionCloneHelperScript.clone_tactic(catalog_tactics[tactic_index]))
	last_report.clear()
	last_message = "Added tactic %s to %s." % [catalog_tactics[tactic_index].display_name, unit.display_name]
	return true


func remove_tactic(team: String, unit_index: int, tactic_index: int) -> bool:
	var unit := unit_at(team, unit_index)
	if unit == null or unit.loadout == null or tactic_index < 0 or tactic_index >= unit.loadout.tactics.size():
		last_message = "Choose a valid tactic to remove."
		return false
	var tactic: TacticDefinition = unit.loadout.tactics[tactic_index]
	unit.loadout.tactics.remove_at(tactic_index)
	last_report.clear()
	last_message = "Removed tactic %s from %s." % [tactic.display_name, unit.display_name]
	return true


func move_tactic(team: String, unit_index: int, tactic_index: int, direction: int) -> bool:
	var unit := unit_at(team, unit_index)
	if unit == null or unit.loadout == null or tactic_index < 0 or tactic_index >= unit.loadout.tactics.size():
		last_message = "Choose a valid tactic to move."
		return false
	var destination := tactic_index + direction
	if destination < 0 or destination >= unit.loadout.tactics.size():
		last_message = "Tactic is already at that edge."
		return false
	var tactic: TacticDefinition = unit.loadout.tactics[tactic_index]
	unit.loadout.tactics.remove_at(tactic_index)
	unit.loadout.tactics.insert(destination, tactic)
	last_report.clear()
	last_message = "Moved tactic %s to position %d." % [tactic.display_name, destination + 1]
	return true


func unit_at(team: String, index: int) -> UnitDefinition:
	if not _is_known_team(team):
		return null
	var party: Array[UnitDefinition] = _party_for_team(team)
	if not _index_in_party(party, index):
		return null
	return party[index]


func equipment_summary(unit: UnitDefinition) -> String:
	if unit == null or unit.loadout == null:
		return "equipment none"
	return "weapon %s, armor %s, helmet %s, trinket %s" % [
		_item_name_or_none(unit.loadout.weapon),
		_item_name_or_none(unit.loadout.armor),
		_item_name_or_none(unit.loadout.helmet),
		_item_name_or_none(unit.loadout.trinket),
	]


func ancestry_index_for_unit(unit: UnitDefinition) -> int:
	if unit == null or unit.ancestry == null:
		return -1
	return _resource_index(catalog_ancestries, unit.ancestry)


func job_index_for_unit(unit: UnitDefinition) -> int:
	if unit == null or unit.loadout == null or unit.loadout.current_job == null:
		return -1
	return _resource_index(catalog_jobs, unit.loadout.current_job)


func feature_index_for_unit(unit: UnitDefinition, feature_type: String) -> int:
	if unit == null or unit.loadout == null:
		return -1
	var feature: Resource = null
	if feature_type == "skill":
		feature = unit.loadout.equipped_skill
	elif feature_type == "passive":
		feature = unit.loadout.equipped_passive
	elif feature_type == "reaction":
		feature = unit.loadout.equipped_reaction
	if feature == null:
		return -1
	return _resource_index(_feature_catalog(feature_type), feature)


func can_run() -> bool:
	return not allied_units.is_empty() and not enemy_units.is_empty()


func run_validation_message() -> String:
	if allied_units.is_empty() and enemy_units.is_empty():
		return "Add at least one allied unit and one enemy unit before running."
	if allied_units.is_empty():
		return "Add at least one allied unit before running."
	if enemy_units.is_empty():
		return "Add at least one enemy unit before running."
	return ""


func build_battle_definitions() -> Array[UnitDefinition]:
	var definitions: Array[UnitDefinition] = []
	for ally in allied_units:
		definitions.append(_clone_for_lab(ally, TEAM_ALLIES))
	for enemy in enemy_units:
		definitions.append(_clone_for_lab(enemy, TEAM_ENEMIES))
	return definitions


func run_battle_report() -> Dictionary:
	if not can_run():
		last_message = run_validation_message()
		return {}
	var simulator: CombatSimulator = CombatSimulatorScript.new()
	last_report = simulator.run_battle_report(build_battle_definitions(), "Combat Lab battle")
	last_message = "Resolved Combat Lab battle: %s won in %d actions." % [String(last_report.get("winner", "None")), int(last_report.get("actions_taken", 0))]
	return last_report.duplicate(true)


func setup_to_dictionary(display_name: String = "", notes: String = "", id: String = "") -> Dictionary:
	var resolved_display_name := display_name.strip_edges()
	if resolved_display_name.is_empty():
		resolved_display_name = setup_display_name.strip_edges()
	if resolved_display_name.is_empty():
		resolved_display_name = "Combat Lab Setup"
	var resolved_id := id.strip_edges()
	if resolved_id.is_empty():
		resolved_id = setup_id.strip_edges()
	if resolved_id.is_empty():
		resolved_id = sanitize_setup_id(resolved_display_name)
	return {
		"schema_version": SETUP_SCHEMA_VERSION,
		"setup_id": resolved_id,
		"display_name": resolved_display_name,
		"notes": notes if not notes.is_empty() else setup_notes,
		"allied_units": _units_to_setup_entries(allied_units),
		"enemy_units": _units_to_setup_entries(enemy_units),
	}


func apply_setup_dictionary(setup: Dictionary) -> bool:
	var errors: Array[String] = []
	if int(setup.get("schema_version", 0)) != SETUP_SCHEMA_VERSION:
		errors.append("Unsupported Combat Lab setup schema version: %s." % str(setup.get("schema_version", null)))
	var new_allies: Array[UnitDefinition] = []
	var new_enemies: Array[UnitDefinition] = []
	_load_setup_party(setup.get("allied_units", []), TEAM_ALLIES, new_allies, errors)
	_load_setup_party(setup.get("enemy_units", []), TEAM_ENEMIES, new_enemies, errors)
	if not errors.is_empty():
		last_message = "Combat Lab setup load failed: %s" % " ".join(errors)
		return false
	allied_units = new_allies
	enemy_units = new_enemies
	setup_id = String(setup.get("setup_id", ""))
	setup_display_name = String(setup.get("display_name", ""))
	setup_notes = String(setup.get("notes", ""))
	last_report.clear()
	last_message = "Loaded Combat Lab setup: %s." % (setup_display_name if not setup_display_name.is_empty() else setup_id)
	return true


func save_setup_to_path(path: String, display_name: String = "", notes: String = "", overwrite := false) -> bool:
	if path.strip_edges().is_empty():
		last_message = "Combat Lab setup save failed: empty file path."
		return false
	if FileAccess.file_exists(path) and not overwrite:
		last_message = "Combat Lab setup save failed: %s already exists." % path
		return false
	var setup := setup_to_dictionary(display_name, notes, path.get_file().get_basename())
	var dir_path := path.get_base_dir()
	var dir_err := _ensure_directory(dir_path)
	if dir_err != OK:
		last_message = "Combat Lab setup save failed: could not create %s (error %d)." % [dir_path, dir_err]
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_message = "Combat Lab setup save failed: could not write %s." % path
		return false
	file.store_string(JSON.stringify(setup, "\t"))
	file.close()
	setup_id = String(setup.get("setup_id", ""))
	setup_display_name = String(setup.get("display_name", ""))
	setup_notes = String(setup.get("notes", ""))
	last_message = "Saved Combat Lab setup: %s." % path
	return true


func save_setup_named(display_name: String, notes: String = "", overwrite := false, setup_dir := DEFAULT_SETUP_DIR) -> bool:
	var id := sanitize_setup_id(display_name)
	if id.is_empty():
		last_message = "Combat Lab setup save failed: enter a setup name."
		return false
	return save_setup_to_path(setup_path_for_id(id, setup_dir), display_name.strip_edges(), notes, overwrite)


func load_setup_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		last_message = "Combat Lab setup load failed: %s was not found." % path
		return false
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK or not (json.data is Dictionary):
		last_message = "Combat Lab setup load failed: invalid JSON in %s." % path
		return false
	return apply_setup_dictionary(json.data)


func list_saved_setups(setup_dir := DEFAULT_SETUP_DIR) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var dir := DirAccess.open(setup_dir)
	if dir == null:
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(SETUP_FILE_EXTENSION):
			var path := "%s/%s" % [setup_dir.trim_suffix("/"), file_name]
			var entry := {
				"setup_id": file_name.get_basename(),
				"display_name": file_name.get_basename(),
				"notes": "",
				"path": path,
			}
			var text := FileAccess.get_file_as_string(path)
			var json := JSON.new()
			if json.parse(text) == OK and json.data is Dictionary:
				entry["setup_id"] = String(json.data.get("setup_id", entry["setup_id"]))
				entry["display_name"] = String(json.data.get("display_name", entry["display_name"]))
				entry["notes"] = String(json.data.get("notes", ""))
			results.append(entry)
		file_name = dir.get_next()
	dir.list_dir_end()
	results.sort_custom(func(a, b): return String(a.get("display_name", "")) < String(b.get("display_name", "")))
	return results


func delete_setup_at_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		last_message = "Combat Lab setup delete skipped: %s was not found." % path
		return false
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if err != OK:
		last_message = "Combat Lab setup delete failed for %s (error %d)." % [path, err]
		return false
	last_message = "Deleted Combat Lab setup: %s." % path
	return true


func setup_path_for_id(id: String, setup_dir := DEFAULT_SETUP_DIR) -> String:
	return "%s/%s%s" % [setup_dir.trim_suffix("/"), sanitize_setup_id(id), SETUP_FILE_EXTENSION]


func sanitize_setup_id(value: String) -> String:
	var sanitized := value.strip_edges().to_lower()
	var out := ""
	var previous_was_separator := false
	for index in sanitized.length():
		var character := sanitized.substr(index, 1)
		var is_alnum := (character >= "a" and character <= "z") or (character >= "0" and character <= "9")
		if is_alnum:
			out += character
			previous_was_separator = false
		elif not previous_was_separator:
			out += "_"
			previous_was_separator = true
	return out.strip_edges().trim_prefix("_").trim_suffix("_")


func team_units(team: String) -> Array[UnitDefinition]:
	if not _is_known_team(team):
		return []
	var party: Array[UnitDefinition] = _party_for_team(team)
	return party


func catalog_unit_label(index: int) -> String:
	if index < 0 or index >= catalog_units.size():
		return ""
	var unit := catalog_units[index]
	return "%s [%s]" % [unit.display_name, unit.team]


func catalog_item_label(index: int) -> String:
	if index < 0 or index >= catalog_items.size():
		return ""
	var item := catalog_items[index]
	return "%s [%s]" % [item.display_name, item.slot]


func ancestry_label(index: int) -> String:
	return catalog_ancestries[index].display_name if index >= 0 and index < catalog_ancestries.size() else ""


func job_label(index: int) -> String:
	return catalog_jobs[index].display_name if index >= 0 and index < catalog_jobs.size() else ""


func feature_label(feature_type: String, index: int) -> String:
	var feature := _feature_at(feature_type, index)
	return feature.display_name if feature != null else ""


func tactic_label(index: int) -> String:
	return catalog_tactics[index].display_name if index >= 0 and index < catalog_tactics.size() else ""


func _clone_for_lab(source: UnitDefinition, team: String) -> UnitDefinition:
	var copy: UnitDefinition = DefinitionCloneHelperScript.clone_unit_definition(source)
	copy.team = team
	DefinitionCloneHelperScript.set_campaign_unit_id(copy, "lab_%d" % _next_lab_unit_id)
	_next_lab_unit_id += 1
	return copy


func _units_to_setup_entries(units: Array[UnitDefinition]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for unit in units:
		entries.append(_unit_to_setup_entry(unit))
	return entries


func _unit_to_setup_entry(unit: UnitDefinition) -> Dictionary:
	var base := _catalog_unit_by_id(_content_id(unit))
	var loadout := unit.loadout
	var display_override = null
	if base == null or unit.display_name != base.display_name:
		display_override = unit.display_name
	var stat_overrides := {}
	for stat_name in SETUP_STATS:
		stat_overrides[stat_name] = int(unit.get(stat_name))
	return {
		"lab_id": DefinitionCloneHelperScript.campaign_unit_id(unit),
		"base_unit_id": _content_id(unit),
		"team": unit.team,
		"display_name_override": display_override,
		"stat_overrides": stat_overrides,
		"ancestry_id": _nullable_content_id(unit.ancestry),
		"current_job_id": _nullable_content_id(loadout.current_job) if loadout != null else null,
		"equipment": {
			"Weapon": _nullable_content_id(loadout.weapon) if loadout != null else null,
			"Armor": _nullable_content_id(loadout.armor) if loadout != null else null,
			"Helmet": _nullable_content_id(loadout.helmet) if loadout != null else null,
			"Trinket": _nullable_content_id(loadout.trinket) if loadout != null else null,
		},
		"equipped": {
			"skill": _nullable_content_id(loadout.equipped_skill) if loadout != null else null,
			"passive": _nullable_content_id(loadout.equipped_passive) if loadout != null else null,
			"reaction": _nullable_content_id(loadout.equipped_reaction) if loadout != null else null,
		},
		"tactics": _content_ids(loadout.tactics) if loadout != null else [],
	}


func _load_setup_party(entries_variant: Variant, expected_team: String, target: Array[UnitDefinition], errors: Array[String]) -> void:
	if not (entries_variant is Array):
		errors.append("%s entries must be an array." % expected_team)
		return
	var entries: Array = entries_variant
	for index in entries.size():
		if not (entries[index] is Dictionary):
			errors.append("%s unit %d must be a dictionary." % [expected_team, index + 1])
			continue
		var unit := _unit_from_setup_entry(entries[index], expected_team, index, errors)
		if unit != null:
			target.append(unit)


func _unit_from_setup_entry(entry: Dictionary, expected_team: String, index: int, errors: Array[String]) -> UnitDefinition:
	var base_id := String(entry.get("base_unit_id", ""))
	var base := _catalog_unit_by_id(base_id)
	if base == null:
		errors.append("%s unit %d references missing unit content id '%s'." % [expected_team, index + 1, base_id])
		return null
	var team := String(entry.get("team", expected_team))
	if not _is_known_team(team):
		errors.append("%s unit %d has unknown team '%s'." % [expected_team, index + 1, team])
		return null
	if team != expected_team:
		errors.append("%s unit %d has mismatched team '%s'." % [expected_team, index + 1, team])
		return null
	var unit := _clone_for_lab(base, expected_team)
	var lab_id := String(entry.get("lab_id", ""))
	if not lab_id.is_empty():
		DefinitionCloneHelperScript.set_campaign_unit_id(unit, lab_id)
	var display_override = entry.get("display_name_override", null)
	if display_override != null:
		unit.display_name = String(display_override)
	var stats: Dictionary = entry.get("stat_overrides", {})
	for stat_name in SETUP_STATS:
		if stats.has(stat_name):
			unit.set(stat_name, int(stats[stat_name]))
	var ancestry := _resource_or_error(entry.get("ancestry_id", null), catalog_ancestries, "ancestry", expected_team, index, errors) as AncestryDefinition
	if not errors.is_empty():
		return null
	unit.ancestry = ancestry
	var loadout := _ensure_loadout(unit)
	loadout.current_job = _resource_or_error(entry.get("current_job_id", null), catalog_jobs, "job", expected_team, index, errors) as JobDefinition
	if loadout.current_job != null:
		_unlock_job_features(unit, loadout.current_job)
	var equipment: Dictionary = entry.get("equipment", {})
	for slot in EQUIPMENT_SLOTS:
		var item := _resource_or_error(equipment.get(slot, null), catalog_items, slot.to_lower(), expected_team, index, errors) as ItemDefinition
		_set_loadout_item(loadout, slot, DefinitionCloneHelperScript.clone_item_definition(item) if item != null else null)
	var equipped: Dictionary = entry.get("equipped", {})
	loadout.equipped_skill = _resource_or_error(equipped.get("skill", null), catalog_skills, "skill", expected_team, index, errors) as SkillDefinition
	loadout.equipped_passive = _resource_or_error(equipped.get("passive", null), catalog_passives, "passive", expected_team, index, errors) as PassiveDefinition
	loadout.equipped_reaction = _resource_or_error(equipped.get("reaction", null), catalog_reactions, "reaction", expected_team, index, errors) as ReactionDefinition
	for feature_type in ["skill", "passive", "reaction"]:
		var feature = loadout.get("equipped_%s" % feature_type)
		var feature_job := _job_for_feature(feature_type, feature)
		if feature_job != null:
			_unlock_job_features(unit, feature_job)
	loadout.tactics.clear()
	var tactic_ids: Array = entry.get("tactics", [])
	for tactic_index in tactic_ids.size():
		var tactic := _resource_or_error(tactic_ids[tactic_index], catalog_tactics, "tactic", expected_team, index, errors) as TacticDefinition
		if tactic != null:
			loadout.tactics.append(DefinitionCloneHelperScript.clone_tactic(tactic))
	if not errors.is_empty():
		return null
	return unit


func _ensure_loadout(unit: UnitDefinition) -> UnitLoadoutDefinition:
	if unit.loadout == null:
		unit.loadout = UnitLoadoutDefinition.new()
		unit.loadout.display_name = "%s Combat Lab Loadout" % unit.display_name
	return unit.loadout


func _load_resource_catalog(source: Dictionary, target: Array) -> void:
	for id in source.keys():
		var resource: Resource = source[id]
		if resource != null:
			target.append(resource)
	target.sort_custom(func(a, b): return a.display_name < b.display_name)


func _collect_job_features() -> void:
	var skill_ids := {}
	var passive_ids := {}
	var reaction_ids := {}
	for job in catalog_jobs:
		if job.skill != null and not skill_ids.has(_content_id(job.skill)):
			skill_ids[_content_id(job.skill)] = true
			catalog_skills.append(job.skill)
		if job.passive != null and not passive_ids.has(_content_id(job.passive)):
			passive_ids[_content_id(job.passive)] = true
			catalog_passives.append(job.passive)
		if job.reaction != null and not reaction_ids.has(_content_id(job.reaction)):
			reaction_ids[_content_id(job.reaction)] = true
			catalog_reactions.append(job.reaction)
	catalog_skills.sort_custom(func(a, b): return a.display_name < b.display_name)
	catalog_passives.sort_custom(func(a, b): return a.display_name < b.display_name)
	catalog_reactions.sort_custom(func(a, b): return a.display_name < b.display_name)


func _unlock_job_features(unit: UnitDefinition, job: JobDefinition) -> void:
	if unit == null or job == null:
		return
	var progress := _ensure_job_progress(unit, job)
	progress.level = max(progress.level, 3)
	progress.skill_unlocked = true
	progress.passive_unlocked = true
	progress.reaction_unlocked = true
	progress.pending_unlock_choice = false


func _ensure_job_progress(unit: UnitDefinition, job: JobDefinition) -> JobProgressDefinition:
	for progress in unit.job_progress:
		if progress != null and progress.job == job:
			return progress
	var progress := JobProgressDefinition.new()
	progress.job = job
	unit.job_progress.append(progress)
	return progress


func _feature_at(feature_type: String, index: int) -> Resource:
	if index < 0:
		return null
	if feature_type == "skill" and index < catalog_skills.size():
		return catalog_skills[index]
	if feature_type == "passive" and index < catalog_passives.size():
		return catalog_passives[index]
	if feature_type == "reaction" and index < catalog_reactions.size():
		return catalog_reactions[index]
	return null


func _job_for_feature(feature_type: String, feature: Resource) -> JobDefinition:
	if feature == null:
		return null
	for job in catalog_jobs:
		if feature_type == "skill" and job.skill == feature:
			return job
		if feature_type == "passive" and job.passive == feature:
			return job
		if feature_type == "reaction" and job.reaction == feature:
			return job
	return null


func _remove_illegal_equipment(unit: UnitDefinition) -> void:
	if unit == null or unit.loadout == null:
		return
	for slot in ["Weapon", "Armor", "Helmet", "Trinket"]:
		var item := _loadout_item(unit.loadout, slot)
		if item != null and not _can_equip_item(unit, item):
			_set_loadout_item(unit.loadout, slot, null)


func _feature_catalog(feature_type: String) -> Array:
	if feature_type == "skill":
		return catalog_skills
	if feature_type == "passive":
		return catalog_passives
	if feature_type == "reaction":
		return catalog_reactions
	return []


func _resource_index(resources: Array, resource: Resource) -> int:
	var target_id := _content_id(resource)
	for index in resources.size():
		if _content_id(resources[index]) == target_id:
			return index
	return -1


func _catalog_unit_by_id(id: String) -> UnitDefinition:
	for unit in catalog_units:
		if _content_id(unit) == id:
			return unit
	return null


func _resource_by_id(resources: Array, id: String) -> Resource:
	for resource: Resource in resources:
		if _content_id(resource) == id:
			return resource
	return null


func _resource_or_error(id_variant: Variant, resources: Array, label: String, team: String, unit_index: int, errors: Array[String]) -> Resource:
	if id_variant == null:
		return null
	var id := String(id_variant)
	if id.is_empty():
		return null
	var resource := _resource_by_id(resources, id)
	if resource == null:
		errors.append("%s unit %d references missing %s content id '%s'." % [team, unit_index + 1, label, id])
	return resource


func _nullable_content_id(resource: Resource) -> Variant:
	var id := _content_id(resource)
	return id if not id.is_empty() else null


func _content_ids(resources: Array) -> Array[String]:
	var ids: Array[String] = []
	for resource: Resource in resources:
		var id := _content_id(resource)
		if not id.is_empty():
			ids.append(id)
	return ids


func _ensure_directory(path: String) -> int:
	if path.strip_edges().is_empty():
		return ERR_INVALID_PARAMETER
	var absolute_path := ProjectSettings.globalize_path(path)
	return DirAccess.make_dir_recursive_absolute(absolute_path)


func _can_equip_item(unit: UnitDefinition, item: ItemDefinition) -> bool:
	if unit == null or item == null:
		return false
	var property_name := "forbid_%s" % item.slot.to_lower()
	return not ((unit.loadout != null and unit.loadout.current_job != null and bool(unit.loadout.current_job.get(property_name))) or (unit.ancestry != null and bool(unit.ancestry.get(property_name))))


func _loadout_item(loadout: UnitLoadoutDefinition, slot: String) -> ItemDefinition:
	if loadout == null:
		return null
	if slot == "Weapon":
		return loadout.weapon
	if slot == "Armor":
		return loadout.armor
	if slot == "Helmet":
		return loadout.helmet
	if slot == "Trinket":
		return loadout.trinket
	return null


func _set_loadout_item(loadout: UnitLoadoutDefinition, slot: String, item: ItemDefinition) -> void:
	if slot == "Weapon":
		loadout.weapon = item
	elif slot == "Armor":
		loadout.armor = item
	elif slot == "Helmet":
		loadout.helmet = item
	elif slot == "Trinket":
		loadout.trinket = item


func _item_name_or_none(item: ItemDefinition) -> String:
	if item == null:
		return "none"
	return item.display_name


func _content_id(resource: Resource) -> String:
	return DefinitionCloneHelperScript.content_id(resource)


func _party_for_team(team: String) -> Array[UnitDefinition]:
	if team == TEAM_ALLIES or team == CombatConstantsScript.TEAM_ALLY:
		return allied_units
	if team == TEAM_ENEMIES or team == CombatConstantsScript.TEAM_ENEMY:
		return enemy_units
	return []


func _is_known_team(team: String) -> bool:
	return team == TEAM_ALLIES or team == TEAM_ENEMIES or team == CombatConstantsScript.TEAM_ALLY or team == CombatConstantsScript.TEAM_ENEMY


func _is_known_slot(slot: String) -> bool:
	return slot == "Weapon" or slot == "Armor" or slot == "Helmet" or slot == "Trinket"


func _index_in_party(party: Array[UnitDefinition], index: int) -> bool:
	return index >= 0 and index < party.size()
