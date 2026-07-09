extends RefCounted
class_name ContentResourceBuilder

const UnitDefinitionScript := preload("res://scripts/data/unit_definition.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const JobDefinitionScript := preload("res://scripts/data/job_definition.gd")
const ItemDefinitionScript := preload("res://scripts/data/item_definition.gd")
const TacticDefinitionScript := preload("res://scripts/data/tactic_definition.gd")
const SkillDefinitionScript := preload("res://scripts/data/skill_definition.gd")
const PassiveDefinitionScript := preload("res://scripts/data/passive_definition.gd")
const ReactionDefinitionScript := preload("res://scripts/data/reaction_definition.gd")
const JobProgressDefinitionScript := preload("res://scripts/data/job_progress_definition.gd")
const AncestryDefinitionScript := preload("res://scripts/data/ancestry_definition.gd")
const AncestryFeatureDefinitionScript := preload("res://scripts/data/ancestry_feature_definition.gd")
const StatusDefinitionScript := preload("res://scripts/data/status_definition.gd")
const ContentResourceValuesScript := preload("res://scripts/modding/content_resource_values.gd")


static func build_demo_unit_definitions(merged_data: Dictionary) -> Array[UnitDefinition]:
	var content := build_content_resources(merged_data)
	var units_by_id: Dictionary = content["units"]

	var results: Array[UnitDefinition] = []
	for unit_id in merged_data.get("demo_roster", []):
		var key := String(unit_id)
		if units_by_id.has(key):
			results.append(units_by_id[key])
	return results


static func build_content_resources(merged_data: Dictionary) -> Dictionary:
	var statuses_by_id := _build_status_resources(merged_data["statuses"])
	var ancestries_by_id := _build_ancestry_resources(merged_data["ancestries"])
	var items_by_id := _build_item_resources(merged_data["items"], statuses_by_id)
	var jobs_by_id := _build_job_resources(merged_data["jobs"], statuses_by_id)
	var tactics_by_id := _build_tactic_resources(merged_data["tactics"], statuses_by_id)
	var loadouts_by_id := _build_loadout_resources(merged_data["loadouts"], jobs_by_id, items_by_id, tactics_by_id)
	var units_by_id := _build_unit_resources(merged_data["units"], loadouts_by_id, jobs_by_id, ancestries_by_id)
	return {
		"statuses": statuses_by_id,
		"ancestries": ancestries_by_id,
		"items": items_by_id,
		"jobs": jobs_by_id,
		"tactics": tactics_by_id,
		"loadouts": loadouts_by_id,
		"units": units_by_id,
	}


static func _build_status_resources(statuses_data: Dictionary) -> Dictionary:
	var out := {}
	for id in statuses_data.keys():
		var src: Dictionary = statuses_data[id]
		var status: Resource = StatusDefinitionScript.new()
		ContentResourceValuesScript.set_content_id(status, id)
		status.display_name = String(src.get("display_name", id))
		status.polarity = String(src.get("polarity", "Boon"))
		status.status_type = String(src.get("status_type", "Reconstitution"))
		status.stacking_rule = String(src.get("stacking_rule", "Refresh"))
		status.default_duration_turns = int(src.get("default_duration_turns", 3))
		status.default_is_permanent = bool(src.get("default_is_permanent", false))
		status.stack_cap_enabled = bool(src.get("stack_cap_enabled", true))
		status.max_stacks = int(src.get("max_stacks", 1))
		status.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
		status.amount = int(src.get("amount", 0))
		status.amount_percent = int(src.get("amount_percent", 50))
		status.propagation_percent = int(src.get("propagation_percent", 25))
		status.elapses_naturally = bool(src.get("elapses_naturally", true))
		status.description = String(src.get("description", ""))
		out[id] = status
	return out


static func _build_ancestry_resources(ancestries_data: Dictionary) -> Dictionary:
	var out := {}
	for id in ancestries_data.keys():
		var src: Dictionary = ancestries_data[id]
		var ancestry = AncestryDefinitionScript.new()
		ContentResourceValuesScript.set_content_id(ancestry, id)
		ancestry.display_name = String(src.get("display_name", id))
		ancestry.tooltip_text = String(src.get("tooltip_text", ""))
		ancestry.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
		ancestry.min_max_hp = int(src.get("min_max_hp", 1))
		ancestry.max_max_hp = int(src.get("max_max_hp", ancestry.min_max_hp))
		ancestry.min_physical_damage = int(src.get("min_physical_damage", 1))
		ancestry.max_physical_damage = int(src.get("max_physical_damage", ancestry.min_physical_damage))
		ancestry.min_magic_damage = int(src.get("min_magic_damage", 0))
		ancestry.max_magic_damage = int(src.get("max_magic_damage", ancestry.min_magic_damage))
		ancestry.min_armor = int(src.get("min_armor", 0))
		ancestry.max_armor = int(src.get("max_armor", ancestry.min_armor))
		ancestry.min_action_speed = int(src.get("min_action_speed", 10))
		ancestry.max_action_speed = int(src.get("max_action_speed", ancestry.min_action_speed))
		ancestry.max_hp_growth = int(src.get("max_hp_growth", 0))
		ancestry.physical_damage_growth = int(src.get("physical_damage_growth", 0))
		ancestry.magic_damage_growth = int(src.get("magic_damage_growth", 0))
		ancestry.armor_growth = int(src.get("armor_growth", 0))
		ancestry.action_speed_growth = int(src.get("action_speed_growth", 0))
		ancestry.forbid_weapon = bool(src.get("forbid_weapon", false))
		ancestry.forbid_armor = bool(src.get("forbid_armor", false))
		ancestry.forbid_helmet = bool(src.get("forbid_helmet", false))
		ancestry.forbid_trinket = bool(src.get("forbid_trinket", false))
		ancestry.feature = _build_ancestry_feature_resource(src.get("feature", {}))
		ancestry.notes = String(src.get("notes", ""))
		out[id] = ancestry
	return out


static func _build_ancestry_feature_resource(raw: Variant):
	if typeof(raw) != TYPE_DICTIONARY or Dictionary(raw).is_empty():
		return null
	var src: Dictionary = raw
	var feature = AncestryFeatureDefinitionScript.new()
	ContentResourceValuesScript.set_content_id(feature, String(src.get("id", "")))
	feature.display_name = String(src.get("display_name", "Ancestry Feature"))
	feature.tooltip_text = String(src.get("tooltip_text", ""))
	feature.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
	feature.trigger = String(src.get("trigger", "Battle Start"))
	feature.condition = String(src.get("condition", "Always"))
	feature.feature_type = String(src.get("feature_type", "Gain Armor"))
	feature.amount = int(src.get("amount", 0))
	feature.threshold_percent = int(src.get("threshold_percent", 50))
	feature.cooldown_turns = int(src.get("cooldown_turns", 0))
	feature.notes = String(src.get("notes", ""))
	return feature


static func _build_item_resources(items_data: Dictionary, statuses_by_id: Dictionary) -> Dictionary:
	var out := {}
	for id in items_data.keys():
		var src: Dictionary = items_data[id]
		var item: ItemDefinition = ItemDefinitionScript.new()
		ContentResourceValuesScript.set_content_id(item, id)
		item.display_name = String(src.get("display_name", id))
		item.tooltip_text = String(src.get("tooltip_text", ""))
		item.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
		item.slot = String(src.get("slot", "Weapon"))
		item.max_hp_modifier = int(src.get("max_hp_modifier", 0))
		item.physical_damage_modifier = int(src.get("physical_damage_modifier", 0))
		item.magic_damage_modifier = int(src.get("magic_damage_modifier", 0))
		item.armor_modifier = int(src.get("armor_modifier", 0))
		item.action_speed_modifier = int(src.get("action_speed_modifier", 0))
		item.effects = ContentResourceValuesScript.effect_resources(src.get("effects", []), statuses_by_id)
		out[id] = item
	return out


static func _build_job_resources(jobs_data: Dictionary, statuses_by_id: Dictionary) -> Dictionary:
	var out := {}
	for id in jobs_data.keys():
		var src: Dictionary = jobs_data[id]
		var job: JobDefinition = JobDefinitionScript.new()
		ContentResourceValuesScript.set_content_id(job, id)
		job.display_name = String(src.get("display_name", id))
		job.tooltip_text = String(src.get("tooltip_text", ""))
		job.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
		job.max_hp_growth = int(src.get("max_hp_growth", 0))
		job.physical_damage_growth = int(src.get("physical_damage_growth", 0))
		job.magic_damage_growth = int(src.get("magic_damage_growth", 0))
		job.armor_growth = int(src.get("armor_growth", 0))
		job.action_speed_growth = int(src.get("action_speed_growth", 0))
		job.forbid_weapon = bool(src.get("forbid_weapon", false))
		job.forbid_armor = bool(src.get("forbid_armor", false))
		job.forbid_helmet = bool(src.get("forbid_helmet", false))
		job.forbid_trinket = bool(src.get("forbid_trinket", false))
		job.skill = _build_skill_resource(src.get("skill", {}), statuses_by_id)
		job.secondary_skill = _build_skill_resource(src.get("secondary_skill", {}), statuses_by_id)
		job.passive = _build_passive_resource(src.get("passive", {}), statuses_by_id)
		job.reaction = _build_reaction_resource(src.get("reaction", {}), statuses_by_id)
		job.default_tactic = _build_tactic_resource(src.get("default_tactic", {}), statuses_by_id)
		out[id] = job
	return out


static func _build_skill_resource(raw: Variant, statuses_by_id: Dictionary) -> SkillDefinition:
	if typeof(raw) != TYPE_DICTIONARY or Dictionary(raw).is_empty():
		return null
	var src: Dictionary = raw
	var skill: SkillDefinition = SkillDefinitionScript.new()
	ContentResourceValuesScript.set_content_id(skill, String(src.get("id", "")))
	skill.display_name = String(src.get("display_name", "Job Skill"))
	skill.tooltip_text = String(src.get("tooltip_text", ""))
	skill.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
	skill.action = String(src.get("action", "Attack"))
	skill.default_target = String(src.get("default_target", "Frontmost Enemy"))
	skill.attack_damage_type = String(src.get("attack_damage_type", "Physical"))
	skill.attack_count = int(src.get("attack_count", 1))
	skill.status = statuses_by_id.get(String(src.get("status_id", "")), null)
	skill.override_status_duration = bool(src.get("override_status_duration", src.has("status_duration_turns") or src.has("status_is_permanent")))
	skill.status_duration_turns = int(src.get("status_duration_turns", 3))
	skill.status_is_permanent = bool(src.get("status_is_permanent", false))
	skill.amount_modifier = int(src.get("amount_modifier", 0))
	skill.cooldown_turns = int(src.get("cooldown_turns", 0))
	skill.effects = ContentResourceValuesScript.effect_resources(src.get("effects", []), statuses_by_id)
	return skill


static func _build_passive_resource(raw: Variant, statuses_by_id: Dictionary) -> PassiveDefinition:
	if typeof(raw) == TYPE_DICTIONARY and not Dictionary(raw).is_empty():
		var src: Dictionary = raw
		var passive: PassiveDefinition = PassiveDefinitionScript.new()
		ContentResourceValuesScript.set_content_id(passive, String(src.get("id", "")))
		passive.display_name = String(src.get("display_name", "Job Passive"))
		passive.tooltip_text = String(src.get("tooltip_text", ""))
		passive.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
		passive.passive_type = String(src.get("passive_type", "None"))
		passive.amount = int(src.get("amount", 0))
		passive.cooldown_turns = int(src.get("cooldown_turns", 0))
		passive.effects = ContentResourceValuesScript.effect_resources(src.get("effects", []), statuses_by_id)
		return passive
	return null


static func _build_reaction_resource(raw: Variant, statuses_by_id: Dictionary) -> ReactionDefinition:
	if typeof(raw) != TYPE_DICTIONARY or Dictionary(raw).is_empty():
		return null
	var src: Dictionary = raw
	var reaction: ReactionDefinition = ReactionDefinitionScript.new()
	ContentResourceValuesScript.set_content_id(reaction, String(src.get("id", "")))
	reaction.display_name = String(src.get("display_name", "Job Reaction"))
	reaction.tooltip_text = String(src.get("tooltip_text", ""))
	reaction.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
	reaction.trigger = String(src.get("trigger", "Damaged"))
	reaction.condition = String(src.get("condition", "Always"))
	reaction.reaction_type = String(src.get("reaction_type", "Gain Armor"))
	reaction.amount = int(src.get("amount", 0))
	reaction.threshold_percent = int(src.get("threshold_percent", 50))
	reaction.status = statuses_by_id.get(String(src.get("status_id", "")), null)
	reaction.status_stack_threshold = int(src.get("status_stack_threshold", 1))
	reaction.prevents_triggering_request = bool(src.get("prevents_triggering_request", false))
	for replacement_id in src.get("replacement_status_ids", []):
		var replacement = statuses_by_id.get(String(replacement_id), null)
		if replacement != null:
			reaction.replacement_statuses.append(replacement)
	reaction.cooldown_turns = int(src.get("cooldown_turns", 0))
	reaction.effects = ContentResourceValuesScript.effect_resources(src.get("effects", []), statuses_by_id)
	return reaction


static func _build_tactic_resource(raw: Variant, statuses_by_id: Dictionary) -> TacticDefinition:
	if typeof(raw) != TYPE_DICTIONARY or Dictionary(raw).is_empty():
		return null
	var src: Dictionary = raw
	var tactic: TacticDefinition = TacticDefinitionScript.new()
	ContentResourceValuesScript.set_content_id(tactic, String(src.get("id", "")))
	tactic.display_name = String(src.get("display_name", "Use Job Skill"))
	tactic.tooltip_text = String(src.get("tooltip_text", ""))
	tactic.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
	tactic.condition = String(src.get("condition", "Enemy Alive"))
	tactic.action = String(src.get("action", "Job Skill"))
	tactic.target = String(src.get("target", "Frontmost Enemy"))
	tactic.status = statuses_by_id.get(String(src.get("status_id", "")), null)
	tactic.status_stack_threshold = int(src.get("status_stack_threshold", 1))
	tactic.foretell_enabled = bool(src.get("foretell_enabled", false))
	return tactic


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
		progress.level = clamp(int(src.get("level", 0)), 0, 3)
		progress.skill_unlocked = bool(src.get("skill_unlocked", false))
		progress.passive_unlocked = bool(src.get("passive_unlocked", false))
		progress.reaction_unlocked = bool(src.get("reaction_unlocked", false))
		progress.pending_unlock_choice = bool(src.get("pending_unlock_choice", false))
		results.append(progress)
	return results


static func _build_tactic_resources(tactics_data: Dictionary, statuses_by_id: Dictionary) -> Dictionary:
	var out := {}
	for id in tactics_data.keys():
		var src: Dictionary = tactics_data[id]
		var tactic: TacticDefinition = TacticDefinitionScript.new()
		ContentResourceValuesScript.set_content_id(tactic, id)
		tactic.display_name = String(src.get("display_name", id))
		tactic.tooltip_text = String(src.get("tooltip_text", ""))
		tactic.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
		tactic.condition = String(src.get("condition", "Always"))
		tactic.action = String(src.get("action", "Attack"))
		tactic.target = String(src.get("target", "Frontmost Enemy"))
		tactic.status = statuses_by_id.get(String(src.get("status_id", "")), null)
		tactic.status_stack_threshold = int(src.get("status_stack_threshold", 1))
		tactic.foretell_enabled = bool(src.get("foretell_enabled", false))
		out[id] = tactic
	return out


static func _build_loadout_resources(loadouts_data: Dictionary, jobs_by_id: Dictionary, items_by_id: Dictionary, tactics_by_id: Dictionary) -> Dictionary:
	var out := {}
	for id in loadouts_data.keys():
		var src: Dictionary = loadouts_data[id]
		var loadout: UnitLoadoutDefinition = UnitLoadoutDefinitionScript.new()
		ContentResourceValuesScript.set_content_id(loadout, id)
		loadout.display_name = String(src.get("display_name", id))
		loadout.tooltip_text = String(src.get("tooltip_text", ""))
		loadout.current_job = jobs_by_id.get(String(src.get("current_job_id", "")), null)
		var skill_job: JobDefinition = jobs_by_id.get(String(src.get("equipped_skill_job_id", "")), null)
		var passive_job: JobDefinition = jobs_by_id.get(String(src.get("equipped_passive_job_id", "")), null)
		var reaction_job: JobDefinition = jobs_by_id.get(String(src.get("equipped_reaction_job_id", "")), null)
		loadout.equipped_skill = skill_job.skill if skill_job != null else null
		loadout.equipped_passive = passive_job.passive if passive_job != null else null
		loadout.equipped_reaction = reaction_job.reaction if reaction_job != null else null
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
		ContentResourceValuesScript.set_content_id(unit, id)
		unit.display_name = String(src.get("display_name", id))
		unit.tooltip_text = String(src.get("tooltip_text", ""))
		unit.tags = ContentResourceValuesScript.tag_array(src.get("tags", []))
		unit.team = String(src.get("team", "Allies"))
		unit.ancestry = ancestries_by_id.get(String(src.get("ancestry_id", "")), null)
		unit.max_hp = int(src.get("max_hp", 1))
		unit.physical_damage = int(src.get("physical_damage", 1))
		unit.magic_damage = int(src.get("magic_damage", 0))
		unit.armor = int(src.get("armor", 0))
		unit.action_speed = int(src.get("action_speed", 10))
		unit.job_progress = _build_job_progress_resources(src.get("job_progress", []), jobs_by_id)
		unit.loadout = loadouts_by_id.get(String(src.get("loadout_id", "")), null)
		out[id] = unit
	return out
