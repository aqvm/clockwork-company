extends RefCounted
class_name JsonContentLoader

const UnitDefinitionScript := preload("res://scripts/data/unit_definition.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const JobDefinitionScript := preload("res://scripts/data/job_definition.gd")
const ItemDefinitionScript := preload("res://scripts/data/item_definition.gd")
const TacticDefinitionScript := preload("res://scripts/data/tactic_definition.gd")
const EffectDefinitionScript := preload("res://scripts/data/effect_definition.gd")
const SkillDefinitionScript := preload("res://scripts/data/skill_definition.gd")
const PassiveDefinitionScript := preload("res://scripts/data/passive_definition.gd")
const ReactionDefinitionScript := preload("res://scripts/data/reaction_definition.gd")
const JobProgressDefinitionScript := preload("res://scripts/data/job_progress_definition.gd")
const AncestryDefinitionScript := preload("res://scripts/data/ancestry_definition.gd")
const AncestryFeatureDefinitionScript := preload("res://scripts/data/ancestry_feature_definition.gd")
const StatusDefinitionScript := preload("res://scripts/data/status_definition.gd")
const TagDefinitionScript := preload("res://scripts/data/tag_definition.gd")
const TagUtilsScript := preload("res://scripts/data/tag_utils.gd")
const ContentIssueCollectorScript := preload("res://scripts/modding/content_issue_collector.gd")
const ContentLoadResultScript := preload("res://scripts/modding/content_load_result.gd")
const ContentMergerScript := preload("res://scripts/modding/content_merger.gd")
const ContentResourceBuilderScript := preload("res://scripts/modding/content_resource_builder.gd")
const ContentValidatorScript := preload("res://scripts/modding/content_validator.gd")

const BASE_ITEMS_DIR := "res://resources/items"
const BASE_JOBS_DIR := "res://resources/jobs"
const BASE_TACTICS_DIR := "res://resources/tactics"
const BASE_LOADOUTS_DIR := "res://resources/loadouts"
const BASE_UNITS_DIR := "res://resources/units"
const BASE_ANCESTRIES_DIR := "res://resources/ancestries"
const BASE_STATUSES_DIR := "res://resources/statuses"
const MODS_DIR := "res://mods"
const MODDING_REFERENCE_DIR := "res://modding/reference"

const DEFAULT_DEMO_ROSTER_IDS := [
	"template_pyromancer",
	"template_bruiser",
	"template_bard",
	"sparring_vanguard",
	"sparring_adept",
	"sparring_support",
]

const LEGACY_ACTION_INTERVAL_FIELDS := {
	"action_interval": true,
	"base_action_interval": true,
	"min_action_interval": true,
	"max_action_interval": true,
	"action_interval_growth": true,
	"action_interval_modifier": true,
}


static func load_demo_unit_definitions(enabled_mod_pack_ids: Variant = null) -> Array[UnitDefinition]:
	var result = load_content_result(enabled_mod_pack_ids)
	assert(result.succeeded(), "Content load failed:\n%s" % "\n".join(result.error_messages()))
	return ContentResourceBuilderScript.build_demo_unit_definitions(result.merged_data)


static func load_unit_definitions_by_ids(unit_ids: Array[String], enabled_mod_pack_ids: Variant = null) -> Array[UnitDefinition]:
	var content := load_content_resources(enabled_mod_pack_ids)
	var units_by_id: Dictionary = content["units"]
	var results: Array[UnitDefinition] = []
	for unit_id in unit_ids:
		var key := String(unit_id)
		if units_by_id.has(key):
			results.append(units_by_id[key])
	return results


static func load_content_resources(enabled_mod_pack_ids: Variant = null) -> Dictionary:
	var result = load_content_result(enabled_mod_pack_ids)
	assert(result.succeeded(), "Content load failed:\n%s" % "\n".join(result.error_messages()))
	return result.resources


static func load_content_result(enabled_mod_pack_ids: Variant = null):
	var result = ContentLoadResultScript.new()
	var base_data := _load_base_data_from_resources()
	var merged_data := _apply_mod_packs(base_data, enabled_mod_pack_ids)
	result.merged_data = merged_data
	ContentIssueCollectorScript.collect_validation_issues(merged_data, result)
	if result.succeeded():
		ContentValidatorScript.validate_merged_data(merged_data)
		result.resources = ContentResourceBuilderScript.build_content_resources(merged_data)
	return result


static func load_item_definition_by_id(item_id: String, enabled_mod_pack_ids: Variant = null) -> ItemDefinition:
	if item_id.is_empty():
		return null
	var content := load_content_resources(enabled_mod_pack_ids)
	var items_by_id: Dictionary = content["items"]
	return items_by_id.get(item_id, null)


static func load_job_definition_by_id(job_id: String, enabled_mod_pack_ids: Variant = null) -> JobDefinition:
	if job_id.is_empty():
		return null
	var content := load_content_resources(enabled_mod_pack_ids)
	var jobs_by_id: Dictionary = content["jobs"]
	return jobs_by_id.get(job_id, null)


static func load_job_definitions(enabled_mod_pack_ids: Variant = null) -> Array[JobDefinition]:
	var content := load_content_resources(enabled_mod_pack_ids)
	var jobs_by_id: Dictionary = content["jobs"]
	var results: Array[JobDefinition] = []
	for job_id in jobs_by_id.keys():
		results.append(jobs_by_id[job_id])
	results.sort_custom(func(a, b): return a.display_name < b.display_name)
	return results


static func load_tactic_definitions(enabled_mod_pack_ids: Variant = null) -> Array[TacticDefinition]:
	var content := load_content_resources(enabled_mod_pack_ids)
	var tactics_by_id: Dictionary = content["tactics"]
	var results: Array[TacticDefinition] = []
	for tactic_id in tactics_by_id.keys():
		results.append(tactics_by_id[tactic_id])
	results.sort_custom(func(a, b): return a.display_name < b.display_name)
	return results


static func load_tactic_definition_by_id(tactic_id: String, enabled_mod_pack_ids: Variant = null) -> TacticDefinition:
	if tactic_id.is_empty():
		return null
	for tactic in load_tactic_definitions(enabled_mod_pack_ids):
		if String(tactic.get_meta("content_id", "")) == tactic_id:
			return tactic
	return null


static func load_status_definitions(enabled_mod_pack_ids: Variant = null) -> Array[StatusDefinition]:
	var content := load_content_resources(enabled_mod_pack_ids)
	var statuses_by_id: Dictionary = content["statuses"]
	var results: Array[StatusDefinition] = []
	for status_id in statuses_by_id.keys():
		results.append(statuses_by_id[status_id])
	results.sort_custom(func(a, b): return a.display_name < b.display_name)
	return results


static func load_status_definition_by_id(status_id: String, enabled_mod_pack_ids: Variant = null) -> StatusDefinition:
	if status_id.is_empty():
		return null
	for status in load_status_definitions(enabled_mod_pack_ids):
		if String(status.get_meta("content_id", "")) == status_id:
			return status
	return null


static func list_available_mod_packs() -> Array[Dictionary]:
	var descriptors: Array[Dictionary] = []
	_collect_pack_descriptors_from_dir(descriptors, MODS_DIR, true)
	_collect_pack_descriptors_from_dir(descriptors, MODDING_REFERENCE_DIR, false)
	return descriptors


static func _load_base_data_from_resources() -> Dictionary:
	return {
		"ancestries": _load_base_ancestries(),
		"statuses": _load_base_statuses(),
		"items": _load_base_items(),
		"jobs": _load_base_jobs(),
		"tactics": _load_base_tactics(),
		"loadouts": _load_base_loadouts(),
		"units": _load_base_units(),
		"demo_roster": DEFAULT_DEMO_ROSTER_IDS.duplicate(),
	}


static func _load_base_statuses() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_STATUSES_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"polarity": resource.polarity,
			"status_type": resource.status_type,
			"stacking_rule": resource.stacking_rule,
			"default_duration_turns": resource.default_duration_turns,
			"default_is_permanent": resource.default_is_permanent,
			"stack_cap_enabled": resource.stack_cap_enabled,
			"max_stacks": resource.max_stacks,
			"tags": TagUtilsScript.ids(resource.tags),
			"amount": resource.amount,
			"amount_percent": resource.amount_percent,
			"propagation_percent": resource.propagation_percent,
			"elapses_naturally": resource.elapses_naturally,
			"description": resource.description,
		}
	return out


static func _load_base_ancestries() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_ANCESTRIES_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"tooltip_text": resource.tooltip_text,
			"tags": TagUtilsScript.ids(resource.tags),
			"min_max_hp": resource.min_max_hp,
			"max_max_hp": resource.max_max_hp,
			"min_physical_damage": resource.min_physical_damage,
			"max_physical_damage": resource.max_physical_damage,
			"min_magic_damage": resource.min_magic_damage,
			"max_magic_damage": resource.max_magic_damage,
			"min_armor": resource.min_armor,
			"max_armor": resource.max_armor,
			"min_action_speed": resource.min_action_speed,
			"max_action_speed": resource.max_action_speed,
			"max_hp_growth": resource.max_hp_growth,
			"physical_damage_growth": resource.physical_damage_growth,
			"magic_damage_growth": resource.magic_damage_growth,
			"armor_growth": resource.armor_growth,
			"action_speed_growth": resource.action_speed_growth,
			"forbid_weapon": resource.forbid_weapon,
			"forbid_armor": resource.forbid_armor,
			"forbid_helmet": resource.forbid_helmet,
			"forbid_trinket": resource.forbid_trinket,
			"feature": _ancestry_feature_resource_to_data(resource.feature),
			"notes": resource.notes,
		}
	return out


static func _load_base_items() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_ITEMS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"tooltip_text": resource.tooltip_text,
			"tags": TagUtilsScript.ids(resource.tags),
			"slot": resource.slot,
			"max_hp_modifier": resource.max_hp_modifier,
			"physical_damage_modifier": resource.physical_damage_modifier,
			"magic_damage_modifier": resource.magic_damage_modifier,
			"armor_modifier": resource.armor_modifier,
			"action_speed_modifier": resource.action_speed_modifier,
			"effects": _effect_resources_to_data(resource.effects),
		}
	return out


static func _load_base_jobs() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_JOBS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"tooltip_text": resource.tooltip_text,
			"tags": TagUtilsScript.ids(resource.tags),
			"max_hp_growth": resource.max_hp_growth,
			"physical_damage_growth": resource.physical_damage_growth,
			"magic_damage_growth": resource.magic_damage_growth,
			"armor_growth": resource.armor_growth,
			"action_speed_growth": resource.action_speed_growth,
			"forbid_weapon": resource.forbid_weapon,
			"forbid_armor": resource.forbid_armor,
			"forbid_helmet": resource.forbid_helmet,
			"forbid_trinket": resource.forbid_trinket,
			"skill": _skill_resource_to_data(resource.skill, "%s:skill" % id),
			"secondary_skill": _skill_resource_to_data(resource.secondary_skill, "%s:secondary_skill" % id),
			"passive": _passive_resource_to_data(resource.passive, "%s:passive" % id),
			"reaction": _reaction_resource_to_data(resource.reaction, "%s:reaction" % id),
			"default_tactic": _tactic_resource_to_data(resource.default_tactic),
		}
	return out


static func _load_base_tactics() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_TACTICS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"tooltip_text": resource.tooltip_text,
			"tags": TagUtilsScript.ids(resource.tags),
			"condition": resource.condition,
			"action": resource.action,
			"target": resource.target,
			"status_id": _resource_ref_id(resource.status),
			"status_stack_threshold": resource.status_stack_threshold,
			"foretell_enabled": resource.foretell_enabled,
		}
	return out


static func _load_base_loadouts() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_LOADOUTS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"tooltip_text": resource.tooltip_text,
			"current_job_id": _resource_ref_id(resource.current_job),
			"equipped_skill_job_id": _base_job_id_for_feature(resource.equipped_skill, "skill"),
			"equipped_passive_job_id": _base_job_id_for_feature(resource.equipped_passive, "passive"),
			"equipped_reaction_job_id": _base_job_id_for_feature(resource.equipped_reaction, "reaction"),
			"weapon_id": _resource_ref_id(resource.weapon),
			"armor_id": _resource_ref_id(resource.armor),
			"helmet_id": _resource_ref_id(resource.helmet),
			"trinket_id": _resource_ref_id(resource.trinket),
			"tactic_ids": _resource_ref_ids(resource.tactics),
		}
	return out


static func _base_job_id_for_feature(feature: Resource, feature_type: String) -> String:
	if feature == null:
		return ""
	for job in _load_resources_in_dir(BASE_JOBS_DIR):
		if job.get(feature_type) == feature:
			return _resource_id(job.resource_path)
	return ""


static func _load_base_units() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_UNITS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"tooltip_text": resource.tooltip_text,
			"tags": TagUtilsScript.ids(resource.tags),
			"team": resource.team,
			"ancestry_id": _resource_ref_id(resource.ancestry),
			"max_hp": resource.max_hp,
			"physical_damage": resource.physical_damage,
			"magic_damage": resource.magic_damage,
			"armor": resource.armor,
			"action_speed": resource.action_speed,
			"job_progress": _job_progress_resources_to_data(resource.job_progress),
			"loadout_id": _resource_ref_id(resource.loadout),
		}
	return out


static func _apply_mod_packs(base_data: Dictionary, enabled_mod_pack_ids: Variant = null) -> Dictionary:
	return ContentMergerScript.merge(base_data, _load_mod_packs(enabled_mod_pack_ids))
static func _effect_resources_to_data(effects: Array[EffectDefinition]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for effect in effects:
		if effect == null:
			continue
		out.append({
			"display_name": effect.display_name,
			"tooltip_text": effect.tooltip_text,
			"tags": TagUtilsScript.ids(effect.tags),
			"trigger": effect.trigger,
			"condition": effect.condition,
			"target_selector": effect.target_selector,
			"effect_type": effect.effect_type,
			"status_id": _resource_ref_id(effect.status),
			"condition_status_id": _resource_ref_id(effect.condition_status),
			"amount_status_id": _resource_ref_id(effect.amount_status),
			"replacement_status_ids": _resource_ref_ids(effect.replacement_statuses),
			"override_status_duration": effect.override_status_duration,
			"status_duration_turns": effect.status_duration_turns,
			"status_is_permanent": effect.status_is_permanent,
			"status_stacks": effect.status_stacks,
			"status_stack_threshold": effect.status_stack_threshold,
			"status_polarity": effect.status_polarity,
			"status_removal_mode": effect.status_removal_mode,
			"modified_stat": effect.modified_stat,
			"modifier_mode": effect.modifier_mode,
			"modifier_direction": effect.modifier_direction,
			"modifier_duration_turns": effect.modifier_duration_turns,
			"amount_source": effect.amount_source,
			"amount_rounding": effect.amount_rounding,
			"amount_target_selector": effect.amount_target_selector,
			"counter_name": effect.counter_name,
			"counter_threshold": effect.counter_threshold,
			"amount_multiplier": effect.amount_multiplier,
			"amount_divisor": effect.amount_divisor,
			"interval_time": effect.interval_time,
			"amount": effect.amount,
			"damage_type": effect.damage_type,
			"threshold_percent": effect.threshold_percent,
			"max_action_speed_percent": effect.max_action_speed_percent,
			"once_per_battle": effect.once_per_battle,
			"ignore_events_from_same_effect_source": effect.ignore_events_from_same_effect_source,
			"repeat_within_event_chain": effect.repeat_within_event_chain,
		})
	return out


static func _skill_resource_to_data(skill: SkillDefinition, id := "") -> Dictionary:
	if skill == null:
		return {}
	return {
		"id": id,
		"display_name": skill.display_name,
		"tooltip_text": skill.tooltip_text,
		"tags": TagUtilsScript.ids(skill.tags),
		"action": skill.action,
		"default_target": skill.default_target,
		"attack_damage_type": skill.attack_damage_type,
		"attack_count": skill.attack_count,
		"status_id": _resource_ref_id(skill.status),
		"override_status_duration": skill.override_status_duration,
		"status_duration_turns": skill.status_duration_turns,
		"status_is_permanent": skill.status_is_permanent,
		"amount_modifier": skill.amount_modifier,
		"cooldown_turns": skill.cooldown_turns,
		"effects": _effect_resources_to_data(skill.effects),
	}


static func _passive_resource_to_data(passive: PassiveDefinition, id := "") -> Dictionary:
	if passive == null:
		return {}
	return {
		"id": id,
		"display_name": passive.display_name,
		"tooltip_text": passive.tooltip_text,
		"tags": TagUtilsScript.ids(passive.tags),
		"passive_type": passive.passive_type,
		"amount": passive.amount,
		"cooldown_turns": passive.cooldown_turns,
		"effects": _effect_resources_to_data(passive.effects),
	}


static func _reaction_resource_to_data(reaction: ReactionDefinition, id := "") -> Dictionary:
	if reaction == null:
		return {}
	return {
		"id": id,
		"display_name": reaction.display_name,
		"tooltip_text": reaction.tooltip_text,
		"tags": TagUtilsScript.ids(reaction.tags),
		"trigger": reaction.trigger,
		"condition": reaction.condition,
		"reaction_type": reaction.reaction_type,
		"amount": reaction.amount,
		"threshold_percent": reaction.threshold_percent,
		"status_id": _resource_ref_id(reaction.status),
		"status_stack_threshold": reaction.status_stack_threshold,
		"prevents_triggering_request": reaction.prevents_triggering_request,
		"replacement_status_ids": _resource_ref_ids(reaction.replacement_statuses),
		"cooldown_turns": reaction.cooldown_turns,
		"effects": _effect_resources_to_data(reaction.effects),
	}


static func _ancestry_feature_resource_to_data(feature) -> Dictionary:
	if feature == null:
		return {}
	return {
		"display_name": feature.display_name,
		"tooltip_text": feature.tooltip_text,
		"tags": TagUtilsScript.ids(feature.tags),
		"trigger": feature.trigger,
		"condition": feature.condition,
		"feature_type": feature.feature_type,
		"amount": feature.amount,
		"threshold_percent": feature.threshold_percent,
		"cooldown_turns": feature.cooldown_turns,
		"notes": feature.notes,
	}


static func _tactic_resource_to_data(tactic: TacticDefinition) -> Dictionary:
	if tactic == null:
		return {}
	return {
		"display_name": tactic.display_name,
		"tooltip_text": tactic.tooltip_text,
		"tags": TagUtilsScript.ids(tactic.tags),
		"condition": tactic.condition,
		"action": tactic.action,
		"target": tactic.target,
		"status_id": _resource_ref_id(tactic.status),
		"status_stack_threshold": tactic.status_stack_threshold,
		"foretell_enabled": tactic.foretell_enabled,
	}


static func _job_progress_resources_to_data(job_progress: Array[JobProgressDefinition]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for progress: JobProgressDefinition in job_progress:
		if progress == null or progress.job == null:
			continue
		out.append({
			"job_id": _resource_ref_id(progress.job),
			"level": progress.level,
			"skill_unlocked": progress.skill_unlocked,
			"passive_unlocked": progress.passive_unlocked,
			"reaction_unlocked": progress.reaction_unlocked,
			"pending_unlock_choice": progress.pending_unlock_choice,
		})
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
	else:
		_assert_no_legacy_action_interval_fields(parsed, path)
	return parsed


static func _assert_no_legacy_action_interval_fields(value: Variant, path: String) -> void:
	if value is Dictionary:
		for key in value.keys():
			assert(not LEGACY_ACTION_INTERVAL_FIELDS.has(String(key)), "Legacy action-interval field '%s' in %s; author action-speed fields instead." % [key, path])
			_assert_no_legacy_action_interval_fields(value[key], path)
	elif value is Array:
		for child in value:
			_assert_no_legacy_action_interval_fields(child, path)


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
