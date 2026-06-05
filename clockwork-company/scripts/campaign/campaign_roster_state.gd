extends RefCounted
class_name CampaignRosterState

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const UnitDefinitionScript := preload("res://scripts/data/unit_definition.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const ItemDefinitionScript := preload("res://scripts/data/item_definition.gd")
const JobProgressDefinitionScript := preload("res://scripts/data/job_progress_definition.gd")

var roster_units: Array[UnitDefinition] = []
var inventory_items: Array[ItemDefinition] = []


func reset(starting_roster_ids: Array[String], enabled_mod_pack_ids: Array[String]) -> void:
	roster_units.clear()
	inventory_items.clear()
	for unit in JsonContentLoaderScript.load_unit_definitions_by_ids(starting_roster_ids, enabled_mod_pack_ids):
		if unit.team == CombatConstantsScript.TEAM_ALLY:
			roster_units.append(_clone_unit_definition(unit))


func active_party_snapshot() -> Array[UnitDefinition]:
	var party: Array[UnitDefinition] = []
	for unit in roster_units:
		party.append(_clone_unit_definition(unit))
	return party


func replace_roster_units(units: Array[UnitDefinition]) -> void:
	roster_units.clear()
	for unit in units:
		if unit != null:
			roster_units.append(_clone_unit_definition(unit))


func commit_from_run(run_state) -> void:
	if run_state == null:
		return
	roster_units.clear()
	for unit: UnitDefinition in run_state.ally_definitions:
		roster_units.append(_clone_unit_definition(unit))
	inventory_items.clear()
	for item: ItemDefinition in run_state.inventory_items:
		inventory_items.append(_clone_item_definition(item))


func status_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("Campaign roster: %d unit%s" % [roster_units.size(), "" if roster_units.size() == 1 else "s"])
	if roster_units.is_empty():
		lines.append("- none")
	else:
		for unit in roster_units:
			lines.append("- %s: %s; %s" % [unit.display_name, _equipment_summary(unit), _job_progress_summary(unit)])
	if inventory_items.is_empty():
		lines.append("Campaign inventory: empty")
	else:
		lines.append("Campaign inventory:")
		for item in inventory_items:
			lines.append("- %s (%s)" % [item.display_name, item.slot])
	return lines


func to_save_data() -> Dictionary:
	var unit_data: Array[Dictionary] = []
	for unit in roster_units:
		unit_data.append(_unit_to_save_data(unit))
	var item_data: Array[Dictionary] = []
	for item in inventory_items:
		var item_id := _content_id(item)
		if not item_id.is_empty():
			item_data.append({"item_id": item_id})
	return {
		"roster_units": unit_data,
		"inventory_items": item_data,
	}


func apply_save_data(data: Dictionary, fallback_roster_ids: Array[String], enabled_mod_pack_ids: Array[String]) -> void:
	reset(fallback_roster_ids, enabled_mod_pack_ids)
	var saved_units = data.get("roster_units", [])
	if saved_units is Array and not saved_units.is_empty():
		var loaded_units: Array[UnitDefinition] = []
		for raw_unit in saved_units:
			if not (raw_unit is Dictionary):
				continue
			var restored := _unit_from_save_data(raw_unit, enabled_mod_pack_ids)
			if restored != null:
				loaded_units.append(restored)
		if not loaded_units.is_empty():
			roster_units = loaded_units

	inventory_items.clear()
	var saved_items = data.get("inventory_items", [])
	if saved_items is Array:
		for raw_item in saved_items:
			if not (raw_item is Dictionary):
				continue
			var item_id := String(raw_item.get("item_id", ""))
			var item := JsonContentLoaderScript.load_item_definition_by_id(item_id, enabled_mod_pack_ids)
			if item != null:
				inventory_items.append(_clone_item_definition(item))


func _unit_from_save_data(data: Dictionary, enabled_mod_pack_ids: Array[String]) -> UnitDefinition:
	var unit_id := String(data.get("unit_id", ""))
	if unit_id.is_empty():
		return null
	var units := JsonContentLoaderScript.load_unit_definitions_by_ids([unit_id], enabled_mod_pack_ids)
	if units.is_empty():
		return null
	var unit := _clone_unit_definition(units[0])
	unit.team = CombatConstantsScript.TEAM_ALLY
	unit.job_progress = _job_progress_from_save_data(data.get("job_progress", []), unit.job_progress)
	_apply_loadout_save_data(unit, data.get("loadout", {}), enabled_mod_pack_ids)
	return unit


func _unit_to_save_data(unit: UnitDefinition) -> Dictionary:
	var loadout_data := {}
	if unit.loadout != null:
		loadout_data = {
			"current_job_id": _content_id(unit.loadout.current_job),
			"equipped_skill_id": _content_id(unit.loadout.equipped_skill),
			"equipped_passive_id": _content_id(unit.loadout.equipped_passive),
			"equipped_reaction_id": _content_id(unit.loadout.equipped_reaction),
			"weapon_id": _content_id(unit.loadout.weapon),
			"armor_id": _content_id(unit.loadout.armor),
			"helmet_id": _content_id(unit.loadout.helmet),
			"trinket_id": _content_id(unit.loadout.trinket),
		}
	return {
		"unit_id": _content_id(unit),
		"display_name": unit.display_name,
		"job_progress": _job_progress_to_save_data(unit.job_progress),
		"loadout": loadout_data,
	}


func _apply_loadout_save_data(unit: UnitDefinition, raw_loadout: Variant, enabled_mod_pack_ids: Array[String]) -> void:
	if not (raw_loadout is Dictionary):
		return
	var data: Dictionary = raw_loadout
	if unit.loadout == null:
		unit.loadout = UnitLoadoutDefinitionScript.new()
		unit.loadout.display_name = "%s Campaign Loadout" % unit.display_name
	unit.loadout.weapon = _load_item_or_keep(data, "weapon_id", unit.loadout.weapon, enabled_mod_pack_ids)
	unit.loadout.armor = _load_item_or_keep(data, "armor_id", unit.loadout.armor, enabled_mod_pack_ids)
	unit.loadout.helmet = _load_item_or_keep(data, "helmet_id", unit.loadout.helmet, enabled_mod_pack_ids)
	unit.loadout.trinket = _load_item_or_keep(data, "trinket_id", unit.loadout.trinket, enabled_mod_pack_ids)


func _load_item_or_keep(data: Dictionary, key: String, current: ItemDefinition, enabled_mod_pack_ids: Array[String]) -> ItemDefinition:
	var item_id := String(data.get(key, ""))
	if item_id.is_empty():
		return null
	var item := JsonContentLoaderScript.load_item_definition_by_id(item_id, enabled_mod_pack_ids)
	if item == null:
		return current
	return _clone_item_definition(item)


func _job_progress_to_save_data(job_progress: Array[JobProgressDefinition]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for progress in job_progress:
		if progress == null or progress.job == null:
			continue
		results.append({
			"job_id": _content_id(progress.job),
			"level": progress.level,
			"xp": progress.xp,
			"skill_unlocked": progress.skill_unlocked,
			"passive_unlocked": progress.passive_unlocked,
			"reaction_unlocked": progress.reaction_unlocked,
			"pending_unlock_choice": progress.pending_unlock_choice,
		})
	return results


func _job_progress_from_save_data(raw_progress: Variant, fallback_progress: Array[JobProgressDefinition]) -> Array[JobProgressDefinition]:
	var by_job_id := {}
	for progress in fallback_progress:
		if progress != null and progress.job != null:
			by_job_id[_content_id(progress.job)] = progress.job

	var results: Array[JobProgressDefinition] = []
	if not (raw_progress is Array):
		return fallback_progress
	for raw in raw_progress:
		if not (raw is Dictionary):
			continue
		var data: Dictionary = raw
		var job_id := String(data.get("job_id", ""))
		if not by_job_id.has(job_id):
			continue
		var progress: JobProgressDefinition = JobProgressDefinitionScript.new()
		progress.job = by_job_id[job_id]
		progress.level = clamp(int(data.get("level", 0)), 0, 5)
		progress.xp = int(data.get("xp", 0))
		progress.skill_unlocked = bool(data.get("skill_unlocked", false))
		progress.passive_unlocked = bool(data.get("passive_unlocked", false))
		progress.reaction_unlocked = bool(data.get("reaction_unlocked", false))
		progress.pending_unlock_choice = bool(data.get("pending_unlock_choice", false))
		results.append(progress)
	return results


func _equipment_summary(unit: UnitDefinition) -> String:
	if unit.loadout == null:
		return "no loadout"
	return "weapon %s, armor %s, helmet %s, trinket %s" % [
		_item_name_or_empty(unit.loadout.weapon),
		_item_name_or_empty(unit.loadout.armor),
		_item_name_or_empty(unit.loadout.helmet),
		_item_name_or_empty(unit.loadout.trinket),
	]


func _job_progress_summary(unit: UnitDefinition) -> String:
	if unit.job_progress.is_empty():
		return "job progress none"
	var parts: Array[String] = []
	for progress in unit.job_progress:
		if progress == null or progress.job == null:
			continue
		parts.append("%s L%d XP%d" % [progress.job.display_name, progress.level, progress.xp])
	if parts.is_empty():
		return "job progress none"
	return "job progress %s" % _join(parts, "; ")


func _item_name_or_empty(item: ItemDefinition) -> String:
	if item == null:
		return "none"
	return item.display_name


func _clone_unit_definition(source: UnitDefinition) -> UnitDefinition:
	var copy: UnitDefinition = UnitDefinitionScript.new()
	_copy_content_id(source, copy)
	copy.display_name = source.display_name
	copy.tags = source.tags.duplicate()
	copy.team = source.team
	copy.ancestry = source.ancestry
	copy.max_hp = source.max_hp
	copy.physical_damage = source.physical_damage
	copy.magic_damage = source.magic_damage
	copy.armor = source.armor
	copy.action_interval = source.action_interval
	copy.job_progress = _clone_job_progress(source.job_progress)
	copy.loadout = _clone_loadout_definition(source.loadout) if source.loadout != null else null
	return copy


func _clone_loadout_definition(source: UnitLoadoutDefinition) -> UnitLoadoutDefinition:
	var copy: UnitLoadoutDefinition = UnitLoadoutDefinitionScript.new()
	_copy_content_id(source, copy)
	copy.display_name = source.display_name
	copy.current_job = source.current_job
	copy.equipped_skill = source.equipped_skill
	copy.equipped_passive = source.equipped_passive
	copy.equipped_reaction = source.equipped_reaction
	copy.weapon = _clone_item_definition(source.weapon) if source.weapon != null else null
	copy.armor = _clone_item_definition(source.armor) if source.armor != null else null
	copy.helmet = _clone_item_definition(source.helmet) if source.helmet != null else null
	copy.trinket = _clone_item_definition(source.trinket) if source.trinket != null else null
	copy.tactics = source.tactics.duplicate()
	return copy


func _clone_item_definition(source: ItemDefinition) -> ItemDefinition:
	var copy: ItemDefinition = ItemDefinitionScript.new()
	_copy_content_id(source, copy)
	copy.display_name = source.display_name
	copy.tags = source.tags.duplicate()
	copy.slot = source.slot
	copy.max_hp_modifier = source.max_hp_modifier
	copy.physical_damage_modifier = source.physical_damage_modifier
	copy.magic_damage_modifier = source.magic_damage_modifier
	copy.armor_modifier = source.armor_modifier
	copy.action_interval_modifier = source.action_interval_modifier
	copy.effects = source.effects.duplicate()
	return copy


func _clone_job_progress(source: Array[JobProgressDefinition]) -> Array[JobProgressDefinition]:
	var results: Array[JobProgressDefinition] = []
	for progress in source:
		if progress == null:
			continue
		var copy: JobProgressDefinition = JobProgressDefinitionScript.new()
		copy.job = progress.job
		copy.level = progress.level
		copy.xp = progress.xp
		copy.skill_unlocked = progress.skill_unlocked
		copy.passive_unlocked = progress.passive_unlocked
		copy.reaction_unlocked = progress.reaction_unlocked
		copy.pending_unlock_choice = progress.pending_unlock_choice
		results.append(copy)
	return results


func _content_id(resource: Resource) -> String:
	if resource == null:
		return ""
	if resource.has_meta("content_id"):
		return String(resource.get_meta("content_id"))
	if not resource.resource_path.is_empty():
		return resource.resource_path.get_file().get_basename()
	return ""


func _copy_content_id(source: Resource, target: Resource) -> void:
	var id := _content_id(source)
	if not id.is_empty():
		target.set_meta("content_id", id)


func _join(parts: Array[String], separator: String) -> String:
	var text := ""
	for part in parts:
		if not text.is_empty():
			text += separator
		text += part
	return text
