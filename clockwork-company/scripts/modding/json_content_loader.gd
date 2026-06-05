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

const BASE_ITEMS_DIR := "res://resources/items"
const BASE_JOBS_DIR := "res://resources/jobs"
const BASE_TACTICS_DIR := "res://resources/tactics"
const BASE_LOADOUTS_DIR := "res://resources/loadouts"
const BASE_UNITS_DIR := "res://resources/units"
const BASE_ANCESTRIES_DIR := "res://resources/ancestries"
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
const ITEM_SLOT_VALUES := {"Weapon": true, "Armor": true, "Helmet": true, "Trinket": true}
const EFFECT_TRIGGER_VALUES := {"Battle Start": true, "Attack": true, "Hit": true, "Kill": true, "Death": true, "Damaged": true, "HP Below Threshold": true, "Every N Ticks": true}
const EFFECT_CONDITION_VALUES := {"Always": true, "Self HP Below Percent": true, "Target Has Tag": true, "Target Missing Tag": true}
const EFFECT_TARGET_VALUES := {"Self": true, "Attack Target": true, "Attacker": true, "Killer": true, "All Allies": true, "All Enemies": true, "Adjacent Allies": true}
const EFFECT_TYPE_VALUES := {"Gain Armor": true, "Bonus Damage": true, "Reduce Target Armor": true, "Heal": true, "Heal Self": true, "Damage": true, "Damage Killer": true, "Increase Max HP": true}
const SKILL_ACTION_VALUES := {"Attack": true, "Heal": true, "Guard": true}
const SKILL_TARGET_VALUES := {"Self": true, "Lowest HP Ally": true, "Frontmost Enemy": true}
const PASSIVE_TYPE_VALUES := {"None": true, "Attack Damage Bonus": true, "Heal Bonus": true, "Guard Armor Bonus": true}
const REACTION_TRIGGER_VALUES := {"Damaged": true, "HP Below Threshold": true}
const REACTION_CONDITION_VALUES := {"Always": true, "Self HP Below Percent": true}
const REACTION_TYPE_VALUES := {"Gain Armor": true, "Heal Self": true, "Damage Attacker": true}
const ANCESTRY_FEATURE_TRIGGER_VALUES := {"Battle Start": true, "Attack": true, "Kill": true, "Damaged": true, "HP Below Threshold": true}
const ANCESTRY_FEATURE_CONDITION_VALUES := {"Always": true, "Self HP Below Percent": true}
const ANCESTRY_FEATURE_TYPE_VALUES := {"Gain Armor": true, "Bonus Damage": true, "Heal Self": true, "Damage Attacker": true, "Hasten Self": true, "Gain Physical Damage": true}
const TACTIC_CONDITION_VALUES := {"Always": true, "Self HP Below Half": true, "Ally HP Below Half": true, "Enemy Alive": true}
const TACTIC_ACTION_VALUES := {"Attack": true, "Heal": true, "Guard": true, "Job Skill": true}
const TACTIC_TARGET_VALUES := {"Self": true, "Lowest HP Ally": true, "Frontmost Enemy": true}


static func load_demo_unit_definitions(enabled_mod_pack_ids: Variant = null) -> Array[UnitDefinition]:
	var base_data := _load_base_data_from_resources()
	var merged_data := _apply_mod_packs(base_data, enabled_mod_pack_ids)
	return _build_demo_unit_definitions(merged_data)


static func load_unit_definitions_by_ids(unit_ids: Array[String], enabled_mod_pack_ids: Variant = null) -> Array[UnitDefinition]:
	var base_data := _load_base_data_from_resources()
	var merged_data := _apply_mod_packs(base_data, enabled_mod_pack_ids)
	var content := _build_content_resources(merged_data)
	var units_by_id: Dictionary = content["units"]
	var results: Array[UnitDefinition] = []
	for unit_id in unit_ids:
		var key := String(unit_id)
		if units_by_id.has(key):
			results.append(units_by_id[key])
	return results


static func load_item_definition_by_id(item_id: String, enabled_mod_pack_ids: Variant = null) -> ItemDefinition:
	if item_id.is_empty():
		return null
	var base_data := _load_base_data_from_resources()
	var merged_data := _apply_mod_packs(base_data, enabled_mod_pack_ids)
	var content := _build_content_resources(merged_data)
	var items_by_id: Dictionary = content["items"]
	return items_by_id.get(item_id, null)


static func list_available_mod_packs() -> Array[Dictionary]:
	var descriptors: Array[Dictionary] = []
	_collect_pack_descriptors_from_dir(descriptors, MODS_DIR, true)
	_collect_pack_descriptors_from_dir(descriptors, MODDING_REFERENCE_DIR, false)
	return descriptors


static func _load_base_data_from_resources() -> Dictionary:
	return {
		"ancestries": _load_base_ancestries(),
		"items": _load_base_items(),
		"jobs": _load_base_jobs(),
		"tactics": _load_base_tactics(),
		"loadouts": _load_base_loadouts(),
		"units": _load_base_units(),
		"demo_roster": DEFAULT_DEMO_ROSTER_IDS.duplicate(),
	}


static func _load_base_ancestries() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_ANCESTRIES_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"tags": resource.tags.duplicate(),
			"min_max_hp": resource.min_max_hp,
			"max_max_hp": resource.max_max_hp,
			"min_physical_damage": resource.min_physical_damage,
			"max_physical_damage": resource.max_physical_damage,
			"min_magic_damage": resource.min_magic_damage,
			"max_magic_damage": resource.max_magic_damage,
			"min_armor": resource.min_armor,
			"max_armor": resource.max_armor,
			"min_action_interval": resource.min_action_interval,
			"max_action_interval": resource.max_action_interval,
			"max_hp_growth": resource.max_hp_growth,
			"physical_damage_growth": resource.physical_damage_growth,
			"magic_damage_growth": resource.magic_damage_growth,
			"armor_growth": resource.armor_growth,
			"action_interval_growth": resource.action_interval_growth,
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
			"tags": resource.tags.duplicate(),
			"slot": resource.slot,
			"max_hp_modifier": resource.max_hp_modifier,
			"physical_damage_modifier": resource.physical_damage_modifier,
			"magic_damage_modifier": resource.magic_damage_modifier,
			"armor_modifier": resource.armor_modifier,
			"action_interval_modifier": resource.action_interval_modifier,
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
			"tags": resource.tags.duplicate(),
			"max_hp_growth": resource.max_hp_growth,
			"physical_damage_growth": resource.physical_damage_growth,
			"magic_damage_growth": resource.magic_damage_growth,
			"armor_growth": resource.armor_growth,
			"action_interval_growth": resource.action_interval_growth,
			"forbid_weapon": resource.forbid_weapon,
			"forbid_armor": resource.forbid_armor,
			"forbid_helmet": resource.forbid_helmet,
			"forbid_trinket": resource.forbid_trinket,
			"skill": _skill_resource_to_data(resource.skill),
			"passive": _passive_resource_to_data(resource.passive),
			"reaction": _reaction_resource_to_data(resource.reaction),
			"default_tactic": _tactic_resource_to_data(resource.default_tactic),
			"skill_unlock_level": resource.skill_unlock_level,
			"passive_unlock_level": resource.passive_unlock_level,
			"reaction_unlock_level": resource.reaction_unlock_level,
		}
	return out


static func _load_base_tactics() -> Dictionary:
	var out := {}
	for resource in _load_resources_in_dir(BASE_TACTICS_DIR):
		var id := _resource_id(resource.resource_path)
		out[id] = {
			"id": id,
			"display_name": resource.display_name,
			"tags": resource.tags.duplicate(),
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
			"equipped_skill": _skill_resource_to_data(resource.equipped_skill),
			"equipped_passive": _passive_resource_to_data(resource.equipped_passive),
			"equipped_reaction": _reaction_resource_to_data(resource.equipped_reaction),
			"weapon_id": _resource_ref_id(resource.weapon),
			"armor_id": _resource_ref_id(resource.armor),
			"helmet_id": _resource_ref_id(resource.helmet),
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
			"tags": resource.tags.duplicate(),
			"team": resource.team,
			"ancestry_id": _resource_ref_id(resource.ancestry),
			"max_hp": resource.max_hp,
			"physical_damage": resource.physical_damage,
			"magic_damage": resource.magic_damage,
			"armor": resource.armor,
			"action_interval": resource.action_interval,
			"job_progress": _job_progress_resources_to_data(resource.job_progress),
			"loadout_id": _resource_ref_id(resource.loadout),
		}
	return out


static func _apply_mod_packs(base_data: Dictionary, enabled_mod_pack_ids: Variant = null) -> Dictionary:
	var merged := {
		"ancestries": base_data["ancestries"].duplicate(true),
		"items": base_data["items"].duplicate(true),
		"jobs": base_data["jobs"].duplicate(true),
		"tactics": base_data["tactics"].duplicate(true),
		"loadouts": base_data["loadouts"].duplicate(true),
		"units": base_data["units"].duplicate(true),
		"demo_roster": base_data["demo_roster"].duplicate(),
	}

	for pack in _load_mod_packs(enabled_mod_pack_ids):
		_apply_collection_overrides(merged["ancestries"], pack.get("ancestries", []))
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
	for ancestry_id in data["ancestries"].keys():
		var ancestry: Dictionary = data["ancestries"][ancestry_id]
		var feature: Dictionary = ancestry.get("feature", {})
		if not feature.is_empty():
			assert(ANCESTRY_FEATURE_TRIGGER_VALUES.has(feature.get("trigger", "")), "Invalid ancestry feature trigger for ancestry id %s" % ancestry_id)
			assert(ANCESTRY_FEATURE_CONDITION_VALUES.has(feature.get("condition", "")), "Invalid ancestry feature condition for ancestry id %s" % ancestry_id)
			assert(ANCESTRY_FEATURE_TYPE_VALUES.has(feature.get("feature_type", "")), "Invalid ancestry feature type for ancestry id %s" % ancestry_id)

	for item_id in data["items"].keys():
		var item: Dictionary = data["items"][item_id]
		assert(ITEM_SLOT_VALUES.has(item.get("slot", "")), "Invalid item slot for id %s" % item_id)
		for effect in item.get("effects", []):
			var effect_data: Dictionary = effect
			assert(EFFECT_TRIGGER_VALUES.has(effect_data.get("trigger", "")), "Invalid authored effect trigger for item id %s" % item_id)
			assert(EFFECT_CONDITION_VALUES.has(effect_data.get("condition", "")), "Invalid authored effect condition for item id %s" % item_id)
			assert(EFFECT_TARGET_VALUES.has(effect_data.get("target_selector", "")), "Invalid authored effect target selector for item id %s" % item_id)
			assert(EFFECT_TYPE_VALUES.has(effect_data.get("effect_type", "")), "Invalid authored effect type for item id %s" % item_id)

	for job_id in data["jobs"].keys():
		var job: Dictionary = data["jobs"][job_id]
		var skill: Dictionary = job.get("skill", {})
		if not skill.is_empty():
			assert(SKILL_ACTION_VALUES.has(skill.get("action", "")), "Invalid skill action for job id %s" % job_id)
			assert(SKILL_TARGET_VALUES.has(skill.get("default_target", "")), "Invalid skill default target for job id %s" % job_id)
		var passive: Dictionary = job.get("passive", {})
		if not passive.is_empty():
			assert(PASSIVE_TYPE_VALUES.has(passive.get("passive_type", "")), "Invalid passive type for job id %s" % job_id)
		var reaction: Dictionary = job.get("reaction", {})
		if not reaction.is_empty():
			assert(REACTION_TRIGGER_VALUES.has(reaction.get("trigger", "")), "Invalid reaction trigger for job id %s" % job_id)
			assert(REACTION_CONDITION_VALUES.has(reaction.get("condition", "")), "Invalid reaction condition for job id %s" % job_id)
			assert(REACTION_TYPE_VALUES.has(reaction.get("reaction_type", "")), "Invalid reaction type for job id %s" % job_id)
		var default_tactic: Dictionary = job.get("default_tactic", {})
		if not default_tactic.is_empty():
			assert(TACTIC_CONDITION_VALUES.has(default_tactic.get("condition", "")), "Invalid default tactic condition for job id %s" % job_id)
			assert(TACTIC_ACTION_VALUES.has(default_tactic.get("action", "")), "Invalid default tactic action for job id %s" % job_id)
			assert(TACTIC_TARGET_VALUES.has(default_tactic.get("target", "")), "Invalid default tactic target for job id %s" % job_id)

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
		for item_key in ["weapon_id", "armor_id", "helmet_id", "trinket_id"]:
			var item_id := String(loadout.get(item_key, ""))
			if not item_id.is_empty():
				assert(data["items"].has(item_id), "Unknown item id '%s' in loadout %s" % [item_id, loadout_id])
		for tactic_id in loadout.get("tactic_ids", []):
			assert(data["tactics"].has(String(tactic_id)), "Unknown tactic id '%s' in loadout %s" % [String(tactic_id), loadout_id])
		var equipped_skill: Dictionary = loadout.get("equipped_skill", {})
		if not equipped_skill.is_empty():
			assert(SKILL_ACTION_VALUES.has(equipped_skill.get("action", "")), "Invalid equipped skill action for loadout %s" % loadout_id)
			assert(SKILL_TARGET_VALUES.has(equipped_skill.get("default_target", "")), "Invalid equipped skill default target for loadout %s" % loadout_id)
		var equipped_passive: Dictionary = loadout.get("equipped_passive", {})
		if not equipped_passive.is_empty():
			assert(PASSIVE_TYPE_VALUES.has(equipped_passive.get("passive_type", "")), "Invalid equipped passive type for loadout %s" % loadout_id)
		var equipped_reaction: Dictionary = loadout.get("equipped_reaction", {})
		if not equipped_reaction.is_empty():
			assert(REACTION_TRIGGER_VALUES.has(equipped_reaction.get("trigger", "")), "Invalid equipped reaction trigger for loadout %s" % loadout_id)
			assert(REACTION_CONDITION_VALUES.has(equipped_reaction.get("condition", "")), "Invalid equipped reaction condition for loadout %s" % loadout_id)
			assert(REACTION_TYPE_VALUES.has(equipped_reaction.get("reaction_type", "")), "Invalid equipped reaction type for loadout %s" % loadout_id)

	for unit_id in data["units"].keys():
		var unit: Dictionary = data["units"][unit_id]
		assert(TEAM_VALUES.has(unit.get("team", "")), "Invalid team value for unit id %s" % unit_id)
		var ancestry_id := String(unit.get("ancestry_id", ""))
		if not ancestry_id.is_empty():
			assert(data["ancestries"].has(ancestry_id), "Unknown ancestry id '%s' in unit %s" % [ancestry_id, unit_id])
		var loadout_id := String(unit.get("loadout_id", ""))
		if not loadout_id.is_empty():
			assert(data["loadouts"].has(loadout_id), "Unknown loadout id '%s' in unit %s" % [loadout_id, unit_id])
		for raw_progress in unit.get("job_progress", []):
			var progress: Dictionary = raw_progress
			var job_id := String(progress.get("job_id", ""))
			assert(data["jobs"].has(job_id), "Unknown job id '%s' in job_progress for unit %s" % [job_id, unit_id])

	for roster_unit_id in data.get("demo_roster", []):
		assert(data["units"].has(String(roster_unit_id)), "Unknown unit id '%s' in demo_roster" % String(roster_unit_id))


static func _build_demo_unit_definitions(merged_data: Dictionary) -> Array[UnitDefinition]:
	var content := _build_content_resources(merged_data)
	var units_by_id: Dictionary = content["units"]

	var results: Array[UnitDefinition] = []
	for unit_id in merged_data.get("demo_roster", DEFAULT_DEMO_ROSTER_IDS):
		var key := String(unit_id)
		if units_by_id.has(key):
			results.append(units_by_id[key])
	return results


static func _build_content_resources(merged_data: Dictionary) -> Dictionary:
	var ancestries_by_id := _build_ancestry_resources(merged_data["ancestries"])
	var items_by_id := _build_item_resources(merged_data["items"])
	var jobs_by_id := _build_job_resources(merged_data["jobs"])
	var tactics_by_id := _build_tactic_resources(merged_data["tactics"])
	var loadouts_by_id := _build_loadout_resources(merged_data["loadouts"], jobs_by_id, items_by_id, tactics_by_id)
	var units_by_id := _build_unit_resources(merged_data["units"], loadouts_by_id, jobs_by_id, ancestries_by_id)
	return {
		"ancestries": ancestries_by_id,
		"items": items_by_id,
		"jobs": jobs_by_id,
		"tactics": tactics_by_id,
		"loadouts": loadouts_by_id,
		"units": units_by_id,
	}


static func _build_ancestry_resources(ancestries_data: Dictionary) -> Dictionary:
	var out := {}
	for id in ancestries_data.keys():
		var src: Dictionary = ancestries_data[id]
		var ancestry = AncestryDefinitionScript.new()
		_set_content_id(ancestry, id)
		ancestry.display_name = String(src.get("display_name", id))
		ancestry.tags = _string_array(src.get("tags", []))
		ancestry.min_max_hp = int(src.get("min_max_hp", 1))
		ancestry.max_max_hp = int(src.get("max_max_hp", ancestry.min_max_hp))
		ancestry.min_physical_damage = int(src.get("min_physical_damage", 1))
		ancestry.max_physical_damage = int(src.get("max_physical_damage", ancestry.min_physical_damage))
		ancestry.min_magic_damage = int(src.get("min_magic_damage", 0))
		ancestry.max_magic_damage = int(src.get("max_magic_damage", ancestry.min_magic_damage))
		ancestry.min_armor = int(src.get("min_armor", 0))
		ancestry.max_armor = int(src.get("max_armor", ancestry.min_armor))
		ancestry.min_action_interval = int(src.get("min_action_interval", 10))
		ancestry.max_action_interval = int(src.get("max_action_interval", ancestry.min_action_interval))
		ancestry.max_hp_growth = int(src.get("max_hp_growth", 0))
		ancestry.physical_damage_growth = int(src.get("physical_damage_growth", 0))
		ancestry.magic_damage_growth = int(src.get("magic_damage_growth", 0))
		ancestry.armor_growth = int(src.get("armor_growth", 0))
		ancestry.action_interval_growth = int(src.get("action_interval_growth", 0))
		ancestry.feature = _build_ancestry_feature_resource(src.get("feature", {}))
		ancestry.notes = String(src.get("notes", ""))
		out[id] = ancestry
	return out


static func _build_ancestry_feature_resource(raw: Variant):
	if typeof(raw) != TYPE_DICTIONARY or Dictionary(raw).is_empty():
		return null
	var src: Dictionary = raw
	var feature = AncestryFeatureDefinitionScript.new()
	_set_content_id(feature, String(src.get("id", "")))
	feature.display_name = String(src.get("display_name", "Ancestry Feature"))
	feature.tags = _string_array(src.get("tags", []))
	feature.trigger = String(src.get("trigger", "Battle Start"))
	feature.condition = String(src.get("condition", "Always"))
	feature.feature_type = String(src.get("feature_type", "Gain Armor"))
	feature.amount = int(src.get("amount", 0))
	feature.threshold_percent = int(src.get("threshold_percent", 50))
	feature.cooldown_turns = int(src.get("cooldown_turns", 0))
	feature.notes = String(src.get("notes", ""))
	return feature


static func _build_item_resources(items_data: Dictionary) -> Dictionary:
	var out := {}
	for id in items_data.keys():
		var src: Dictionary = items_data[id]
		var item: ItemDefinition = ItemDefinitionScript.new()
		_set_content_id(item, id)
		item.display_name = String(src.get("display_name", id))
		item.tags = _string_array(src.get("tags", []))
		item.slot = String(src.get("slot", "Weapon"))
		item.max_hp_modifier = int(src.get("max_hp_modifier", 0))
		item.physical_damage_modifier = int(src.get("physical_damage_modifier", 0))
		item.magic_damage_modifier = int(src.get("magic_damage_modifier", 0))
		item.armor_modifier = int(src.get("armor_modifier", 0))
		item.action_interval_modifier = int(src.get("action_interval_modifier", 0))
		item.effects = _build_effect_resources(src.get("effects", []))
		out[id] = item
	return out


static func _build_effect_resources(effects_data: Array) -> Array[EffectDefinition]:
	var effects: Array[EffectDefinition] = []
	for raw in effects_data:
		var src: Dictionary = raw
		var effect: EffectDefinition = EffectDefinitionScript.new()
		_set_content_id(effect, String(src.get("id", "")))
		effect.display_name = String(src.get("display_name", ""))
		effect.tags = _string_array(src.get("tags", []))
		effect.trigger = String(src.get("trigger", "Battle Start"))
		effect.condition = String(src.get("condition", "Always"))
		effect.target_selector = String(src.get("target_selector", "Self"))
		effect.effect_type = String(src.get("effect_type", "Gain Armor"))
		effect.amount = int(src.get("amount", 0))
		effect.threshold_percent = int(src.get("threshold_percent", 50))
		effect.interval_ticks = int(src.get("interval_ticks", 0))
		effect.once_per_battle = bool(src.get("once_per_battle", false))
		effects.append(effect)
	return effects


static func _build_job_resources(jobs_data: Dictionary) -> Dictionary:
	var out := {}
	for id in jobs_data.keys():
		var src: Dictionary = jobs_data[id]
		var job: JobDefinition = JobDefinitionScript.new()
		_set_content_id(job, id)
		job.display_name = String(src.get("display_name", id))
		job.tags = _string_array(src.get("tags", []))
		job.max_hp_growth = int(src.get("max_hp_growth", 0))
		job.physical_damage_growth = int(src.get("physical_damage_growth", 0))
		job.magic_damage_growth = int(src.get("magic_damage_growth", 0))
		job.armor_growth = int(src.get("armor_growth", 0))
		job.action_interval_growth = int(src.get("action_interval_growth", 0))
		job.forbid_weapon = bool(src.get("forbid_weapon", false))
		job.forbid_armor = bool(src.get("forbid_armor", false))
		job.forbid_helmet = bool(src.get("forbid_helmet", false))
		job.forbid_trinket = bool(src.get("forbid_trinket", false))
		job.skill = _build_skill_resource(src.get("skill", {}))
		job.passive = _build_passive_resource(src.get("passive", {}))
		job.reaction = _build_reaction_resource(src.get("reaction", {}))
		job.default_tactic = _build_tactic_resource(src.get("default_tactic", {}))
		job.skill_unlock_level = int(src.get("skill_unlock_level", 1))
		job.passive_unlock_level = int(src.get("passive_unlock_level", 2))
		job.reaction_unlock_level = int(src.get("reaction_unlock_level", 3))
		out[id] = job
	return out


static func _build_skill_resource(raw: Variant) -> SkillDefinition:
	if typeof(raw) != TYPE_DICTIONARY or Dictionary(raw).is_empty():
		return null
	var src: Dictionary = raw
	var skill: SkillDefinition = SkillDefinitionScript.new()
	_set_content_id(skill, String(src.get("id", "")))
	skill.display_name = String(src.get("display_name", "Job Skill"))
	skill.tags = _string_array(src.get("tags", []))
	skill.action = String(src.get("action", "Attack"))
	skill.default_target = String(src.get("default_target", "Frontmost Enemy"))
	skill.amount_modifier = int(src.get("amount_modifier", 0))
	return skill


static func _build_passive_resource(raw: Variant) -> PassiveDefinition:
	if typeof(raw) == TYPE_DICTIONARY and not Dictionary(raw).is_empty():
		var src: Dictionary = raw
		var passive: PassiveDefinition = PassiveDefinitionScript.new()
		_set_content_id(passive, String(src.get("id", "")))
		passive.display_name = String(src.get("display_name", "Job Passive"))
		passive.tags = _string_array(src.get("tags", []))
		passive.passive_type = String(src.get("passive_type", "None"))
		passive.amount = int(src.get("amount", 0))
		passive.cooldown_turns = int(src.get("cooldown_turns", 0))
		return passive
	return null


static func _build_reaction_resource(raw: Variant) -> ReactionDefinition:
	if typeof(raw) != TYPE_DICTIONARY or Dictionary(raw).is_empty():
		return null
	var src: Dictionary = raw
	var reaction: ReactionDefinition = ReactionDefinitionScript.new()
	_set_content_id(reaction, String(src.get("id", "")))
	reaction.display_name = String(src.get("display_name", "Job Reaction"))
	reaction.tags = _string_array(src.get("tags", []))
	reaction.trigger = String(src.get("trigger", "Damaged"))
	reaction.condition = String(src.get("condition", "Always"))
	reaction.reaction_type = String(src.get("reaction_type", "Gain Armor"))
	reaction.amount = int(src.get("amount", 0))
	reaction.threshold_percent = int(src.get("threshold_percent", 50))
	reaction.cooldown_turns = int(src.get("cooldown_turns", 0))
	return reaction


static func _build_tactic_resource(raw: Variant) -> TacticDefinition:
	if typeof(raw) != TYPE_DICTIONARY or Dictionary(raw).is_empty():
		return null
	var src: Dictionary = raw
	var tactic: TacticDefinition = TacticDefinitionScript.new()
	_set_content_id(tactic, String(src.get("id", "")))
	tactic.display_name = String(src.get("display_name", "Use Job Skill"))
	tactic.tags = _string_array(src.get("tags", []))
	tactic.condition = String(src.get("condition", "Enemy Alive"))
	tactic.action = String(src.get("action", "Job Skill"))
	tactic.target = String(src.get("target", "Frontmost Enemy"))
	return tactic


static func _effect_resources_to_data(effects: Array[EffectDefinition]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for effect in effects:
		if effect == null:
			continue
		out.append({
			"display_name": effect.display_name,
			"tags": effect.tags.duplicate(),
			"trigger": effect.trigger,
			"condition": effect.condition,
			"target_selector": effect.target_selector,
			"effect_type": effect.effect_type,
			"amount": effect.amount,
			"threshold_percent": effect.threshold_percent,
			"interval_ticks": effect.interval_ticks,
			"once_per_battle": effect.once_per_battle,
		})
	return out


static func _skill_resource_to_data(skill: SkillDefinition) -> Dictionary:
	if skill == null:
		return {}
	return {
		"display_name": skill.display_name,
		"tags": skill.tags.duplicate(),
		"action": skill.action,
		"default_target": skill.default_target,
		"amount_modifier": skill.amount_modifier,
	}


static func _passive_resource_to_data(passive: PassiveDefinition) -> Dictionary:
	if passive == null:
		return {}
	return {
		"display_name": passive.display_name,
		"tags": passive.tags.duplicate(),
		"passive_type": passive.passive_type,
		"amount": passive.amount,
		"cooldown_turns": passive.cooldown_turns,
	}


static func _reaction_resource_to_data(reaction: ReactionDefinition) -> Dictionary:
	if reaction == null:
		return {}
	return {
		"display_name": reaction.display_name,
		"tags": reaction.tags.duplicate(),
		"trigger": reaction.trigger,
		"condition": reaction.condition,
		"reaction_type": reaction.reaction_type,
		"amount": reaction.amount,
		"threshold_percent": reaction.threshold_percent,
		"cooldown_turns": reaction.cooldown_turns,
	}


static func _ancestry_feature_resource_to_data(feature) -> Dictionary:
	if feature == null:
		return {}
	return {
		"display_name": feature.display_name,
		"tags": feature.tags.duplicate(),
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
		"tags": tactic.tags.duplicate(),
		"condition": tactic.condition,
		"action": tactic.action,
		"target": tactic.target,
	}


static func _job_progress_resources_to_data(job_progress: Array[JobProgressDefinition]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for progress: JobProgressDefinition in job_progress:
		if progress == null or progress.job == null:
			continue
		out.append({
			"job_id": _resource_ref_id(progress.job),
			"level": progress.level,
			"xp": progress.xp,
			"skill_unlocked": progress.skill_unlocked,
			"passive_unlocked": progress.passive_unlocked,
			"reaction_unlocked": progress.reaction_unlocked,
			"pending_unlock_choice": progress.pending_unlock_choice,
		})
	return out


static func _build_job_progress_resources(raw_progress: Variant, jobs_by_id: Dictionary) -> Array[JobProgressDefinition]:
	var results: Array[JobProgressDefinition] = []
	if typeof(raw_progress) != TYPE_ARRAY:
		return results
	for raw in raw_progress:
		var src: Dictionary = raw
		var job_id := String(src.get("job_id", ""))
		if not jobs_by_id.has(job_id):
			continue
		var progress: JobProgressDefinition = JobProgressDefinitionScript.new()
		progress.job = jobs_by_id[job_id]
		progress.level = clamp(int(src.get("level", 0)), 0, 5)
		progress.xp = int(src.get("xp", 0))
		progress.skill_unlocked = bool(src.get("skill_unlocked", false))
		progress.passive_unlocked = bool(src.get("passive_unlocked", false))
		progress.reaction_unlocked = bool(src.get("reaction_unlocked", false))
		progress.pending_unlock_choice = bool(src.get("pending_unlock_choice", false))
		results.append(progress)
	return results


static func _string_array(raw_values: Variant) -> Array[String]:
	var values: Array[String] = []
	if typeof(raw_values) != TYPE_ARRAY:
		return values
	for raw_value in raw_values:
		values.append(String(raw_value))
	return values


static func _build_tactic_resources(tactics_data: Dictionary) -> Dictionary:
	var out := {}
	for id in tactics_data.keys():
		var src: Dictionary = tactics_data[id]
		var tactic: TacticDefinition = TacticDefinitionScript.new()
		_set_content_id(tactic, id)
		tactic.display_name = String(src.get("display_name", id))
		tactic.tags = _string_array(src.get("tags", []))
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
		_set_content_id(loadout, id)
		loadout.display_name = String(src.get("display_name", id))
		loadout.current_job = jobs_by_id.get(String(src.get("current_job_id", "")), null)
		loadout.equipped_skill = _build_skill_resource(src.get("equipped_skill", {}))
		loadout.equipped_passive = _build_passive_resource(src.get("equipped_passive", {}))
		loadout.equipped_reaction = _build_reaction_resource(src.get("equipped_reaction", {}))
		loadout.weapon = items_by_id.get(String(src.get("weapon_id", "")), null)
		loadout.armor = items_by_id.get(String(src.get("armor_id", "")), null)
		loadout.helmet = items_by_id.get(String(src.get("helmet_id", "")), null)
		loadout.trinket = items_by_id.get(String(src.get("trinket_id", "")), null)
		var tactics: Array[TacticDefinition] = []
		for tactic_id in src.get("tactic_ids", []):
			var key := String(tactic_id)
			if tactics_by_id.has(key):
				tactics.append(tactics_by_id[key])
		loadout.tactics = tactics
		out[id] = loadout
	return out


static func _build_unit_resources(units_data: Dictionary, loadouts_by_id: Dictionary, jobs_by_id: Dictionary, ancestries_by_id: Dictionary) -> Dictionary:
	var out := {}
	for id in units_data.keys():
		var src: Dictionary = units_data[id]
		var unit: UnitDefinition = UnitDefinitionScript.new()
		_set_content_id(unit, id)
		unit.display_name = String(src.get("display_name", id))
		unit.tags = _string_array(src.get("tags", []))
		unit.team = String(src.get("team", "Allies"))
		unit.ancestry = ancestries_by_id.get(String(src.get("ancestry_id", "")), null)
		unit.max_hp = int(src.get("max_hp", 1))
		unit.physical_damage = int(src.get("physical_damage", 1))
		unit.magic_damage = int(src.get("magic_damage", 0))
		unit.armor = int(src.get("armor", 0))
		unit.action_interval = int(src.get("action_interval", 10))
		unit.job_progress = _build_job_progress_resources(src.get("job_progress", []), jobs_by_id)
		unit.loadout = loadouts_by_id.get(String(src.get("loadout_id", "")), null)
		out[id] = unit
	return out


static func _set_content_id(resource: Resource, id: String) -> void:
	if resource != null and not id.is_empty():
		resource.set_meta("content_id", id)


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
