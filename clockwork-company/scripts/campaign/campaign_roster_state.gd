extends RefCounted
class_name CampaignRosterState

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const UnitDefinitionScript := preload("res://scripts/data/unit_definition.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const ItemDefinitionScript := preload("res://scripts/data/item_definition.gd")
const JobProgressDefinitionScript := preload("res://scripts/data/job_progress_definition.gd")
const META_CAMPAIGN_UNIT_ID := "campaign_unit_id"
const META_CONTENT_ID := "content_id"
const MAX_UNIT_LEVEL := 5
const MAX_JOB_LEVEL := 3

var roster_units: Array[UnitDefinition] = []
var inventory_items: Array[ItemDefinition] = []
var last_progression_summary := ""


func reset(starting_roster_ids: Array[String], enabled_mod_pack_ids: Array[String]) -> void:
	roster_units.clear()
	inventory_items.clear()
	last_progression_summary = ""
	for unit in JsonContentLoaderScript.load_unit_definitions_by_ids(starting_roster_ids, enabled_mod_pack_ids):
		if unit.team == CombatConstantsScript.TEAM_ALLY:
			var copy := _clone_unit_definition(unit)
			_set_campaign_unit_id(copy, _unique_campaign_unit_id(_content_id(copy)))
			roster_units.append(copy)


func active_party_snapshot() -> Array[UnitDefinition]:
	var party: Array[UnitDefinition] = []
	for unit in roster_units:
		party.append(_clone_unit_definition(unit))
	return party


func replace_roster_units(units: Array[UnitDefinition]) -> void:
	roster_units.clear()
	for unit in units:
		if unit != null:
			var copy := _clone_unit_definition(unit)
			if _campaign_unit_id(copy).is_empty():
				_set_campaign_unit_id(copy, _unique_campaign_unit_id(_content_id(copy)))
			roster_units.append(copy)


func commit_from_run(run_state) -> void:
	if run_state == null:
		return
	roster_units.clear()
	for unit: UnitDefinition in run_state.ally_definitions:
		var copy := _clone_unit_definition(unit)
		if _campaign_unit_id(copy).is_empty():
			_set_campaign_unit_id(copy, _unique_campaign_unit_id(_content_id(copy)))
		roster_units.append(copy)
	inventory_items.clear()
	for item: ItemDefinition in run_state.inventory_items:
		inventory_items.append(_clone_item_definition(item))


func award_scenario_level(scenario: Resource, knocked_out_unit_ids: Array[String]) -> void:
	last_progression_summary = ""
	if scenario == null:
		return
	var eligible: Array[UnitDefinition] = []
	var lowest_level := MAX_UNIT_LEVEL + 1
	for unit in roster_units:
		if knocked_out_unit_ids.has(_campaign_unit_id(unit)):
			continue
		if unit.loadout == null or unit.loadout.current_job == null:
			continue
		var unit_level := _total_job_levels(unit)
		if unit_level >= MAX_UNIT_LEVEL or unit_level >= int(scenario.tier) or _job_level(unit, unit.loadout.current_job) >= MAX_JOB_LEVEL:
			continue
		if unit_level < lowest_level:
			lowest_level = unit_level
			eligible.clear()
		if unit_level == lowest_level:
			eligible.append(unit)
	if eligible.is_empty():
		last_progression_summary = "No surviving deployed unit could gain a level from Tier %d." % int(scenario.tier)
		return

	eligible.sort_custom(func(a, b): return _campaign_unit_id(a) < _campaign_unit_id(b))
	var seed_text := "%s|%s" % [String(scenario.scenario_id), _join(_campaign_unit_ids(eligible), "|")]
	var chosen: UnitDefinition = eligible[abs(seed_text.hash()) % eligible.size()]
	var progress := _ensure_job_progress(chosen, chosen.loadout.current_job)
	progress.level += 1
	_apply_job_level_unlock(chosen, progress)
	last_progression_summary = "%s reached unit level %d and %s level %d." % [
		chosen.display_name,
		_total_job_levels(chosen),
		progress.job.display_name,
		progress.level,
	]
	if progress.pending_unlock_choice:
		last_progression_summary += " Choose its first job feature before starting another campaign scenario."


func has_pending_unlock_choices() -> bool:
	for unit in roster_units:
		for progress in unit.job_progress:
			if progress != null and progress.pending_unlock_choice:
				return true
	return false


func pending_unlock_options_for_unit(campaign_unit_id: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var unit := _find_unit(campaign_unit_id)
	if unit == null:
		return options
	for progress in unit.job_progress:
		if progress == null or progress.job == null or not progress.pending_unlock_choice:
			continue
		if not progress.skill_unlocked and progress.job.skill != null:
			options.append({"choice": "skill", "label": "Unlock skill: %s" % progress.job.skill.display_name, "resource": progress.job.skill})
		if not progress.reaction_unlocked and progress.job.reaction != null:
			options.append({"choice": "reaction", "label": "Unlock reaction: %s" % progress.job.reaction.display_name, "resource": progress.job.reaction})
	return options


func resolve_pending_unlock(campaign_unit_id: String, choice: String) -> bool:
	var unit := _find_unit(campaign_unit_id)
	if unit == null:
		return false
	for progress in unit.job_progress:
		if progress == null or progress.job == null or not progress.pending_unlock_choice:
			continue
		if choice == "skill" and not progress.skill_unlocked and progress.job.skill != null:
			progress.skill_unlocked = true
		elif choice == "reaction" and not progress.reaction_unlocked and progress.job.reaction != null:
			progress.reaction_unlocked = true
			if unit.loadout != null and unit.loadout.equipped_reaction == null:
				unit.loadout.equipped_reaction = progress.job.reaction
		else:
			return false
		progress.pending_unlock_choice = false
		last_progression_summary = "%s permanently learned %s." % [unit.display_name, progress.job.skill.display_name if choice == "skill" else progress.job.reaction.display_name]
		return true
	return false


func set_current_job(campaign_unit_id: String, job: JobDefinition) -> bool:
	var unit := _find_unit(campaign_unit_id)
	if unit == null or job == null:
		return false
	if unit.loadout == null:
		unit.loadout = UnitLoadoutDefinitionScript.new()
		unit.loadout.display_name = "%s Campaign Loadout" % unit.display_name
	unit.loadout.current_job = _canonical_job_for_unit(unit, job)
	if _content_id(_job_for_feature(unit, unit.loadout.equipped_skill, "skill")) == _content_id(unit.loadout.current_job):
		unit.loadout.equipped_skill = null
	_return_illegal_equipment_to_inventory(unit)
	return true


func assign_learned_feature(campaign_unit_id: String, feature_type: String, feature: Resource) -> bool:
	var unit := _find_unit(campaign_unit_id)
	if unit == null or unit.loadout == null:
		return false
	if feature != null and not _feature_unlocked(unit, feature_type, feature):
		return false
	if feature_type == "skill":
		if feature != null and _job_for_feature(unit, feature, feature_type) == unit.loadout.current_job:
			return false
		unit.loadout.equipped_skill = feature
		return true
	if feature_type == "passive":
		unit.loadout.equipped_passive = feature
		return true
	if feature_type == "reaction":
		unit.loadout.equipped_reaction = feature
		return true
	return false


func learned_feature_options(campaign_unit_id: String, feature_type: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = [{"feature": null, "label": "None", "equipped": false}]
	var unit := _find_unit(campaign_unit_id)
	if unit == null or unit.loadout == null:
		return options
	var equipped := _equipped_feature(unit.loadout, feature_type)
	options[0]["equipped"] = equipped == null
	for progress in unit.job_progress:
		if progress == null or progress.job == null or not _progress_feature_unlocked(progress, feature_type):
			continue
		if feature_type == "skill" and progress.job == unit.loadout.current_job:
			continue
		var feature := _job_feature(progress.job, feature_type)
		if feature != null:
			options.append({
				"feature": feature,
				"label": "%s (%s)" % [feature.display_name, progress.job.display_name],
				"equipped": feature == equipped,
			})
	return options


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
	if not last_progression_summary.is_empty():
		lines.append("Latest progression: %s" % last_progression_summary)
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
	_set_campaign_unit_id(unit, String(data.get("campaign_unit_id", unit_id)))
	unit.job_progress = _job_progress_from_save_data(data.get("job_progress", []), unit.job_progress, enabled_mod_pack_ids)
	_apply_loadout_save_data(unit, data.get("loadout", {}), enabled_mod_pack_ids)
	return unit


func _unit_to_save_data(unit: UnitDefinition) -> Dictionary:
	var loadout_data := {}
	if unit.loadout != null:
		loadout_data = {
			"current_job_id": _content_id(unit.loadout.current_job),
			"equipped_skill_job_id": _content_id(_job_for_feature(unit, unit.loadout.equipped_skill, "skill")),
			"equipped_passive_job_id": _content_id(_job_for_feature(unit, unit.loadout.equipped_passive, "passive")),
			"equipped_reaction_job_id": _content_id(_job_for_feature(unit, unit.loadout.equipped_reaction, "reaction")),
			"weapon_id": _content_id(unit.loadout.weapon),
			"armor_id": _content_id(unit.loadout.armor),
			"helmet_id": _content_id(unit.loadout.helmet),
			"trinket_id": _content_id(unit.loadout.trinket),
		}
	return {
		"campaign_unit_id": _campaign_unit_id(unit),
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
	var current_job := _job_from_progress_or_load(unit, String(data.get("current_job_id", "")), enabled_mod_pack_ids)
	if current_job != null:
		unit.loadout.current_job = current_job
	unit.loadout.equipped_skill = _saved_job_feature(unit, data, "equipped_skill_job_id", "skill")
	unit.loadout.equipped_passive = _saved_job_feature(unit, data, "equipped_passive_job_id", "passive")
	unit.loadout.equipped_reaction = _saved_job_feature(unit, data, "equipped_reaction_job_id", "reaction")
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
			"skill_unlocked": progress.skill_unlocked,
			"passive_unlocked": progress.passive_unlocked,
			"reaction_unlocked": progress.reaction_unlocked,
			"pending_unlock_choice": progress.pending_unlock_choice,
		})
	return results


func _job_progress_from_save_data(raw_progress: Variant, fallback_progress: Array[JobProgressDefinition], enabled_mod_pack_ids: Array[String]) -> Array[JobProgressDefinition]:
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
			var loaded_job := JsonContentLoaderScript.load_job_definition_by_id(job_id, enabled_mod_pack_ids)
			if loaded_job != null:
				by_job_id[job_id] = loaded_job
		if not by_job_id.has(job_id):
			continue
		var progress: JobProgressDefinition = JobProgressDefinitionScript.new()
		progress.job = by_job_id[job_id]
		progress.level = clamp(int(data.get("level", 0)), 0, MAX_JOB_LEVEL)
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
		parts.append("%s L%d%s" % [progress.job.display_name, progress.level, " choice pending" if progress.pending_unlock_choice else ""])
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
	_copy_campaign_unit_id(source, copy)
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
		copy.skill_unlocked = progress.skill_unlocked
		copy.passive_unlocked = progress.passive_unlocked
		copy.reaction_unlocked = progress.reaction_unlocked
		copy.pending_unlock_choice = progress.pending_unlock_choice
		results.append(copy)
	return results


func _apply_job_level_unlock(unit: UnitDefinition, progress: JobProgressDefinition) -> void:
	if progress.level == 1:
		progress.pending_unlock_choice = true
	elif progress.level == 2:
		progress.passive_unlocked = true
		if unit.loadout != null and unit.loadout.equipped_passive == null:
			unit.loadout.equipped_passive = progress.job.passive
	elif progress.level >= 3:
		if not progress.skill_unlocked:
			progress.skill_unlocked = true
		elif not progress.reaction_unlocked:
			progress.reaction_unlocked = true
			if unit.loadout != null and unit.loadout.equipped_reaction == null:
				unit.loadout.equipped_reaction = progress.job.reaction
		progress.pending_unlock_choice = false


func _ensure_job_progress(unit: UnitDefinition, job: JobDefinition) -> JobProgressDefinition:
	for progress in unit.job_progress:
		if progress != null and progress.job == job:
			return progress
	var progress: JobProgressDefinition = JobProgressDefinitionScript.new()
	progress.job = job
	unit.job_progress.append(progress)
	return progress


func _total_job_levels(unit: UnitDefinition) -> int:
	var total := 0
	for progress in unit.job_progress:
		if progress != null:
			total += progress.level
	return total


func _job_level(unit: UnitDefinition, job: JobDefinition) -> int:
	for progress in unit.job_progress:
		if progress != null and progress.job == job:
			return progress.level
	return 0


func _feature_unlocked(unit: UnitDefinition, feature_type: String, feature: Resource) -> bool:
	for progress in unit.job_progress:
		if progress != null and _job_feature(progress.job, feature_type) == feature:
			return _progress_feature_unlocked(progress, feature_type)
	return false


func _progress_feature_unlocked(progress: JobProgressDefinition, feature_type: String) -> bool:
	if feature_type == "skill":
		return progress.skill_unlocked
	if feature_type == "passive":
		return progress.passive_unlocked
	if feature_type == "reaction":
		return progress.reaction_unlocked
	return false


func _job_feature(job: JobDefinition, feature_type: String) -> Resource:
	if job == null:
		return null
	if feature_type == "skill":
		return job.skill
	if feature_type == "passive":
		return job.passive
	if feature_type == "reaction":
		return job.reaction
	return null


func _job_for_feature(unit: UnitDefinition, feature: Resource, feature_type: String) -> JobDefinition:
	if feature == null:
		return null
	for progress in unit.job_progress:
		if progress != null and _job_feature(progress.job, feature_type) == feature:
			return progress.job
	return null


func _equipped_feature(loadout: UnitLoadoutDefinition, feature_type: String) -> Resource:
	if feature_type == "skill":
		return loadout.equipped_skill
	if feature_type == "passive":
		return loadout.equipped_passive
	if feature_type == "reaction":
		return loadout.equipped_reaction
	return null


func _saved_job_feature(unit: UnitDefinition, data: Dictionary, key: String, feature_type: String) -> Resource:
	var job_id := String(data.get(key, ""))
	for progress in unit.job_progress:
		if progress != null and _content_id(progress.job) == job_id and _progress_feature_unlocked(progress, feature_type):
			return _job_feature(progress.job, feature_type)
	return null


func _job_from_progress_or_load(unit: UnitDefinition, job_id: String, enabled_mod_pack_ids: Array[String]) -> JobDefinition:
	for progress in unit.job_progress:
		if progress != null and _content_id(progress.job) == job_id:
			return progress.job
	return JsonContentLoaderScript.load_job_definition_by_id(job_id, enabled_mod_pack_ids)


func _canonical_job_for_unit(unit: UnitDefinition, job: JobDefinition) -> JobDefinition:
	var job_id := _content_id(job)
	for progress in unit.job_progress:
		if progress != null and _content_id(progress.job) == job_id:
			return progress.job
	return job


func _return_illegal_equipment_to_inventory(unit: UnitDefinition) -> void:
	for slot in ["Weapon", "Armor", "Helmet", "Trinket"]:
		var item := _loadout_item(unit.loadout, slot)
		if item == null or _can_equip_item(unit, item):
			continue
		inventory_items.append(_clone_item_definition(item))
		_set_loadout_item(unit.loadout, slot, null)


func _can_equip_item(unit: UnitDefinition, item: ItemDefinition) -> bool:
	if item == null:
		return false
	var property_name := "forbid_%s" % item.slot.to_lower()
	return not ((unit.loadout != null and unit.loadout.current_job != null and bool(unit.loadout.current_job.get(property_name))) or (unit.ancestry != null and bool(unit.ancestry.get(property_name))))


func _loadout_item(loadout: UnitLoadoutDefinition, slot: String) -> ItemDefinition:
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


func _campaign_unit_ids(units: Array[UnitDefinition]) -> Array[String]:
	var ids: Array[String] = []
	for unit in units:
		ids.append(_campaign_unit_id(unit))
	return ids


func _find_unit(campaign_unit_id: String) -> UnitDefinition:
	for unit in roster_units:
		if _campaign_unit_id(unit) == campaign_unit_id:
			return unit
	return null


func _content_id(resource: Resource) -> String:
	if resource == null:
		return ""
	if resource.has_meta(META_CONTENT_ID):
		return String(resource.get_meta(META_CONTENT_ID))
	if not resource.resource_path.is_empty():
		return resource.resource_path.get_file().get_basename()
	return ""


func _copy_content_id(source: Resource, target: Resource) -> void:
	var id := _content_id(source)
	if not id.is_empty():
		target.set_meta(META_CONTENT_ID, id)


func _campaign_unit_id(unit: UnitDefinition) -> String:
	if unit == null or not unit.has_meta(META_CAMPAIGN_UNIT_ID):
		return ""
	return String(unit.get_meta(META_CAMPAIGN_UNIT_ID))


func _set_campaign_unit_id(unit: UnitDefinition, id: String) -> void:
	if unit != null and not id.is_empty():
		unit.set_meta(META_CAMPAIGN_UNIT_ID, id)


func _copy_campaign_unit_id(source: UnitDefinition, target: UnitDefinition) -> void:
	var id := _campaign_unit_id(source)
	if not id.is_empty():
		_set_campaign_unit_id(target, id)


func _unique_campaign_unit_id(base_id: String) -> String:
	var safe_base := base_id if not base_id.is_empty() else "unit"
	var candidate := safe_base
	var index := 2
	while _campaign_unit_id_exists(candidate):
		candidate = "%s_%d" % [safe_base, index]
		index += 1
	return candidate


func _campaign_unit_id_exists(id: String) -> bool:
	for unit in roster_units:
		if _campaign_unit_id(unit) == id:
			return true
	return false


func _join(parts: Array[String], separator: String) -> String:
	var text := ""
	for part in parts:
		if not text.is_empty():
			text += separator
		text += part
	return text
