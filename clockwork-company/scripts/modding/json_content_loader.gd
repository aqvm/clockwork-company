extends RefCounted
class_name JsonContentLoader

const UnitDefinitionScript := preload("res://scripts/data/unit_definition.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const JobDefinitionScript := preload("res://scripts/data/job_definition.gd")
const ItemDefinitionScript := preload("res://scripts/data/item_definition.gd")
const TacticDefinitionScript := preload("res://scripts/data/tactic_definition.gd")

const BASE_ITEMS_DIR := "res://resources/items"
const BASE_JOBS_DIR := "res://resources/jobs"
const BASE_TACTICS_DIR := "res://resources/tactics"
const BASE_LOADOUTS_DIR := "res://resources/loadouts"
const BASE_UNITS_DIR := "res://resources/units"
const MODS_DIR := "res://mods"
const MODDING_REFERENCE_DIR := "res://modding/reference"

const DEFAULT_DEMO_ROSTER_IDS := [
	"alden_guard",
	"mira_scout",
	"sol_apprentice",
	"iron_brute",
	"ash_cutpurse",
	"glass_wisp",
]

const TEAM_VALUES := {"Allies": true, "Enemies": true}
const ITEM_SLOT_VALUES := {"Weapon": true, "Armor": true, "Trinket": true}
const ITEM_TRIGGER_VALUES := {"None": true, "Battle Start": true, "Attack": true, "Hit": true, "Kill": true, "Death": true}
const ITEM_EFFECT_VALUES := {"None": true, "Gain Armor": true, "Bonus Damage": true, "Reduce Target Armor": true, "Heal Self": true, "Damage Killer": true}
const JOB_EFFECT_VALUES := {"None": true, "Guard Training": true, "First Aid": true, "Sharpened Edge": true}
const TACTIC_CONDITION_VALUES := {"Always": true, "Self HP Below Half": true, "Ally HP Below Half": true, "Enemy Alive": true}
const TACTIC_ACTION_VALUES := {"Attack": true, "Heal": true, "Guard": true}
const TACTIC_TARGET_VALUES := {"Self": true, "Lowest HP Ally": true, "Frontmost Enemy": true}


static func load_demo_unit_definitions(enabled_mod_pack_ids: Variant = null) -> Array[UnitDefinition]:
	var base_data := _load_base_data_from_resources()
	var merged_data := _apply_mod_packs(base_data, enabled_mod_pack_ids)
	return _build_demo_unit_definitions(merged_data)


static func list_available_mod_packs() -> Array[Dictionary]:
	var descriptors: Array[Dictionary] = []
	_collect_pack_descriptors_from_dir(descriptors, MODS_DIR, true)
	_collect_pack_descriptors_from_dir(descriptors, MODDING_REFERENCE_DIR, false)
	return descriptors


static func _load_base_data_from_resources() -> Dictionary:
	return {
		"items": _load_base_items(),
		"jobs": _load_base_jobs(),
		"tactics": _load_base_tactics(),
		"loadouts": _load_base_loadouts(),
		"units": _load_base_units(),
		"demo_roster": DEFAULT_DEMO_ROSTER_IDS.duplicate(),
	}


static func _load_base_items() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_ITEMS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"slot": resource.slot,
			"max_hp_modifier": resource.max_hp_modifier,
			"damage_modifier": resource.damage_modifier,
			"armor_modifier": resource.armor_modifier,
			"action_interval_modifier": resource.action_interval_modifier,
			"trigger": resource.trigger,
			"effect": resource.effect,
			"effect_amount": resource.effect_amount,
		}
	return out


static func _load_base_jobs() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_JOBS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"max_hp_modifier": resource.max_hp_modifier,
			"damage_modifier": resource.damage_modifier,
			"armor_modifier": resource.armor_modifier,
			"action_interval_modifier": resource.action_interval_modifier,
			"can_equip_weapon": resource.can_equip_weapon,
			"can_equip_armor": resource.can_equip_armor,
			"can_equip_trinket": resource.can_equip_trinket,
			"job_effect": resource.job_effect,
		}
	return out


static func _load_base_tactics() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_TACTICS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"condition": resource.condition,
			"action": resource.action,
			"target": resource.target,
		}
	return out


static func _load_base_loadouts() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_LOADOUTS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"current_job_id": _resource_ref_id(resource.current_job),
			"weapon_id": _resource_ref_id(resource.weapon),
			"armor_id": _resource_ref_id(resource.armor),
			"trinket_id": _resource_ref_id(resource.trinket),
			"tactic_ids": _resource_ref_ids(resource.tactics),
		}
	return out


static func _load_base_units() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_UNITS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"team": resource.team,
			"max_hp": resource.max_hp,
			"damage": resource.damage,
			"armor": resource.armor,
			"action_interval": resource.action_interval,
			"loadout_id": _resource_ref_id(resource.loadout),
		}
	return out


static func _apply_mod_packs(base_data: Dictionary, enabled_mod_pack_ids: Variant = null) -> Dictionary:
	var merged := {
		"items": base_data["items"].duplicate(true),
		"jobs": base_data["jobs"].duplicate(true),
		"tactics": base_data["tactics"].duplicate(true),
		"loadouts": base_data["loadouts"].duplicate(true),
		"units": base_data["units"].duplicate(true),
		"demo_roster": base_data["demo_roster"].duplicate(),
	}

	for pack in _load_mod_packs(enabled_mod_pack_ids):
		_apply_collection_overrides(merged["items"], pack.get("items", []))
		_apply_collection_overrides(merged["jobs"], pack.get("jobs", []))
		_apply_collection_overrides(merged["tactics"], pack.get("tactics", []))
		_apply_collection_overrides(merged["loadouts"], pack.get("loadouts", []))
		_apply_collection_overrides(merged["units"], pack.get("units", []))
		if pack.has("demo_roster"):
			merged["demo_roster"] = pack["demo_roster"].duplicate()

	_validate_merged_data(merged)
	return merged


static func _apply_collection_overrides(target: Dictionary, entries: Array) -> void:
	for raw in entries:
		var entry: Dictionary = raw
		if not entry.has("id"):
			push_warning("Skipping mod entry without id.")
			continue
		var id := String(entry["id"]).strip_edges()
		if id.is_empty():
			push_warning("Skipping mod entry with empty id.")
			continue
		var merged_entry: Dictionary = Dictionary(target.get(id, {})).duplicate(true)
		for key in entry.keys():
			merged_entry[key] = entry[key]
		merged_entry["id"] = id
		target[id] = merged_entry


static func _validate_merged_data(data: Dictionary) -> void:
	for item_id in data["items"].keys():
		var item: Dictionary = data["items"][item_id]
		assert(ITEM_SLOT_VALUES.has(item.get("slot", "")), "Invalid item slot for id %s" % item_id)
		assert(ITEM_TRIGGER_VALUES.has(item.get("trigger", "")), "Invalid item trigger for id %s" % item_id)
		assert(ITEM_EFFECT_VALUES.has(item.get("effect", "")), "Invalid item effect for id %s" % item_id)

	for job_id in data["jobs"].keys():
		var job: Dictionary = data["jobs"][job_id]
		assert(JOB_EFFECT_VALUES.has(job.get("job_effect", "")), "Invalid job effect for id %s" % job_id)

	for tactic_id in data["tactics"].keys():
		var tactic: Dictionary = data["tactics"][tactic_id]
		assert(TACTIC_CONDITION_VALUES.has(tactic.get("condition", "")), "Invalid tactic condition for id %s" % tactic_id)
		assert(TACTIC_ACTION_VALUES.has(tactic.get("action", "")), "Invalid tactic action for id %s" % tactic_id)
		assert(TACTIC_TARGET_VALUES.has(tactic.get("target", "")), "Invalid tactic target for id %s" % tactic_id)

	for loadout_id in data["loadouts"].keys():
		var loadout: Dictionary = data["loadouts"][loadout_id]
		var current_job_id := String(loadout.get("current_job_id", ""))
		if not current_job_id.is_empty():
			assert(data["jobs"].has(current_job_id), "Unknown job id '%s' in loadout %s" % [current_job_id, loadout_id])
		for item_key in ["weapon_id", "armor_id", "trinket_id"]:
			var item_id := String(loadout.get(item_key, ""))
			if not item_id.is_empty():
				assert(data["items"].has(item_id), "Unknown item id '%s' in loadout %s" % [item_id, loadout_id])
		for tactic_id in loadout.get("tactic_ids", []):
			assert(data["tactics"].has(String(tactic_id)), "Unknown tactic id '%s' in loadout %s" % [String(tactic_id), loadout_id])

	for unit_id in data["units"].keys():
		var unit: Dictionary = data["units"][unit_id]
		assert(TEAM_VALUES.has(unit.get("team", "")), "Invalid team value for unit id %s" % unit_id)
		var loadout_id := String(unit.get("loadout_id", ""))
		if not loadout_id.is_empty():
			assert(data["loadouts"].has(loadout_id), "Unknown loadout id '%s' in unit %s" % [loadout_id, unit_id])

	for roster_unit_id in data.get("demo_roster", []):
		assert(data["units"].has(String(roster_unit_id)), "Unknown unit id '%s' in demo_roster" % String(roster_unit_id))


static func _build_demo_unit_definitions(merged_data: Dictionary) -> Array[UnitDefinition]:
	var items_by_id := _build_item_resources(merged_data["items"])
	var jobs_by_id := _build_job_resources(merged_data["jobs"])
	var tactics_by_id := _build_tactic_resources(merged_data["tactics"])
	var loadouts_by_id := _build_loadout_resources(merged_data["loadouts"], jobs_by_id, items_by_id, tactics_by_id)
	var units_by_id := _build_unit_resources(merged_data["units"], loadouts_by_id)

	var results: Array[UnitDefinition] = []
	for unit_id in merged_data.get("demo_roster", DEFAULT_DEMO_ROSTER_IDS):
		var key := String(unit_id)
		if units_by_id.has(key):
			results.append(units_by_id[key])
	return results


static func _build_item_resources(items_data: Dictionary) -> Dictionary:
	var out := {}
	for id in items_data.keys():
		var src: Dictionary = items_data[id]
		var item: ItemDefinition = ItemDefinitionScript.new()
		item.display_name = String(src.get("display_name", id))
		item.slot = String(src.get("slot", "Weapon"))
		item.max_hp_modifier = int(src.get("max_hp_modifier", 0))
		item.damage_modifier = int(src.get("damage_modifier", 0))
		item.armor_modifier = int(src.get("armor_modifier", 0))
		item.action_interval_modifier = int(src.get("action_interval_modifier", 0))
		item.trigger = String(src.get("trigger", "None"))
		item.effect = String(src.get("effect", "None"))
		item.effect_amount = int(src.get("effect_amount", 0))
		out[id] = item
	return out


static func _build_job_resources(jobs_data: Dictionary) -> Dictionary:
	var out := {}
	for id in jobs_data.keys():
		var src: Dictionary = jobs_data[id]
		var job: JobDefinition = JobDefinitionScript.new()
		job.display_name = String(src.get("display_name", id))
		job.max_hp_modifier = int(src.get("max_hp_modifier", 0))
		job.damage_modifier = int(src.get("damage_modifier", 0))
		job.armor_modifier = int(src.get("armor_modifier", 0))
		job.action_interval_modifier = int(src.get("action_interval_modifier", 0))
		job.can_equip_weapon = bool(src.get("can_equip_weapon", true))
		job.can_equip_armor = bool(src.get("can_equip_armor", true))
		job.can_equip_trinket = bool(src.get("can_equip_trinket", true))
		job.job_effect = String(src.get("job_effect", "None"))
		out[id] = job
	return out


static func _build_tactic_resources(tactics_data: Dictionary) -> Dictionary:
	var out := {}
	for id in tactics_data.keys():
		var src: Dictionary = tactics_data[id]
		var tactic: TacticDefinition = TacticDefinitionScript.new()
		tactic.condition = String(src.get("condition", "Always"))
		tactic.action = String(src.get("action", "Attack"))
		tactic.target = String(src.get("target", "Frontmost Enemy"))
		out[id] = tactic
	return out


static func _build_loadout_resources(loadouts_data: Dictionary, jobs_by_id: Dictionary, items_by_id: Dictionary, tactics_by_id: Dictionary) -> Dictionary:
	var out := {}
	for id in loadouts_data.keys():
		var src: Dictionary = loadouts_data[id]
		var loadout: UnitLoadoutDefinition = UnitLoadoutDefinitionScript.new()
		loadout.display_name = String(src.get("display_name", id))
		loadout.current_job = jobs_by_id.get(String(src.get("current_job_id", "")), null)
		loadout.weapon = items_by_id.get(String(src.get("weapon_id", "")), null)
		loadout.armor = items_by_id.get(String(src.get("armor_id", "")), null)
		loadout.trinket = items_by_id.get(String(src.get("trinket_id", "")), null)
		var tactics: Array[TacticDefinition] = []
		for tactic_id in src.get("tactic_ids", []):
			var key := String(tactic_id)
			if tactics_by_id.has(key):
				tactics.append(tactics_by_id[key])
		loadout.tactics = tactics
		out[id] = loadout
	return out


static func _build_unit_resources(units_data: Dictionary, loadouts_by_id: Dictionary) -> Dictionary:
	var out := {}
	for id in units_data.keys():
		var src: Dictionary = units_data[id]
		var unit: UnitDefinition = UnitDefinitionScript.new()
		unit.display_name = String(src.get("display_name", id))
		unit.team = String(src.get("team", "Allies"))
		unit.max_hp = int(src.get("max_hp", 1))
		unit.damage = int(src.get("damage", 1))
		unit.armor = int(src.get("armor", 0))
		unit.action_interval = int(src.get("action_interval", 10))
		unit.loadout = loadouts_by_id.get(String(src.get("loadout_id", "")), null)
		out[id] = unit
	return out


static func _load_mod_packs(enabled_mod_pack_ids: Variant = null) -> Array[Dictionary]:
	var packs: Array[Dictionary] = []

	var enabled_ids := {}
	var filter_enabled := typeof(enabled_mod_pack_ids) == TYPE_ARRAY
	if filter_enabled:
		for raw_id in enabled_mod_pack_ids:
			enabled_ids[String(raw_id)] = true

	if filter_enabled:
		var descriptors := list_available_mod_packs()
		for descriptor: Dictionary in descriptors:
			var pack_id := String(descriptor.get("id", ""))
			if not enabled_ids.has(pack_id):
				continue
			var path := String(descriptor.get("path", ""))
			var parsed: Variant = _read_json_file(path)
			if typeof(parsed) == TYPE_DICTIONARY:
				packs.append(parsed)
		return packs

	# Legacy/default behavior when no explicit enabled list is passed:
	# only load active packs from res://mods/.
	if not DirAccess.dir_exists_absolute(MODS_DIR):
		return packs
	var dir := DirAccess.open(MODS_DIR)
	if dir == null:
		return packs
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".json"):
			continue
		var full_path := "%s/%s" % [MODS_DIR, file_name]
		var parsed: Variant = _read_json_file(full_path)
		if typeof(parsed) == TYPE_DICTIONARY:
			packs.append(parsed)
	dir.list_dir_end()
	return packs


static func _read_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open JSON file: %s" % path)
		return null
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_warning("Failed to parse JSON file: %s" % path)
	return parsed


static func _collect_pack_descriptors_from_dir(descriptors: Array[Dictionary], dir_path: String, default_enabled: bool) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".json"):
			continue

		var full_path := "%s/%s" % [dir_path, file_name]
		var parsed: Variant = _read_json_file(full_path)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue

		var pack: Dictionary = parsed
		var fallback_id := file_name.get_basename()
		var pack_id := String(pack.get("pack_id", fallback_id)).strip_edges()
		if pack_id.is_empty():
			pack_id = fallback_id
		descriptors.append({
			"id": pack_id,
			"display_name": String(pack.get("display_name", pack_id)),
			"file_name": file_name,
			"path": full_path,
			"default_enabled": default_enabled,
			"is_reference": not default_enabled,
		})
	dir.list_dir_end()


static func _load_resources_in_dir(dir_path: String) -> Array:
	var resources: Array = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return resources

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return resources

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".tres"):
			continue
		var full_path := "%s/%s" % [dir_path, file_name]
		var res = load(full_path)
		if res != null:
			resources.append(res)
	dir.list_dir_end()
	return resources


static func _resource_id(resource_path: String) -> String:
	return resource_path.get_file().get_basename()


static func _resource_ref_id(resource: Resource) -> String:
	if resource == null:
		return ""
	return _resource_id(resource.resource_path)


static func _resource_ref_ids(resources: Array) -> Array[String]:
	var ids: Array[String] = []
	for resource in resources:
		ids.append(_resource_ref_id(resource))
	return ids
