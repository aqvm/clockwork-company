extends RefCounted
class_name DefinitionCloneHelper

const UnitDefinitionScript := preload("res://scripts/data/unit_definition.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const ItemDefinitionScript := preload("res://scripts/data/item_definition.gd")
const TacticDefinitionScript := preload("res://scripts/data/tactic_definition.gd")
const JobProgressDefinitionScript := preload("res://scripts/data/job_progress_definition.gd")
const META_CAMPAIGN_UNIT_ID := "campaign_unit_id"
const META_CONTENT_ID := "content_id"


static func clone_unit_definition(source: UnitDefinition) -> UnitDefinition:
	if source == null:
		return null
	var copy: UnitDefinition = UnitDefinitionScript.new()
	_copy_content_id(source, copy)
	_copy_campaign_unit_id(source, copy)
	copy.display_name = source.display_name
	copy.tooltip_text = source.tooltip_text
	copy.tags = source.tags.duplicate()
	copy.team = source.team
	copy.ancestry = source.ancestry
	copy.max_hp = source.max_hp
	copy.physical_damage = source.physical_damage
	copy.magic_damage = source.magic_damage
	copy.armor = source.armor
	copy.action_speed = source.action_speed
	copy.job_progress = clone_job_progress(source.job_progress)
	copy.loadout = clone_loadout_definition(source.loadout) if source.loadout != null else null
	return copy


static func clone_loadout_definition(source: UnitLoadoutDefinition) -> UnitLoadoutDefinition:
	if source == null:
		return null
	var copy: UnitLoadoutDefinition = UnitLoadoutDefinitionScript.new()
	_copy_content_id(source, copy)
	copy.display_name = source.display_name
	copy.tooltip_text = source.tooltip_text
	copy.current_job = source.current_job
	copy.equipped_skill = source.equipped_skill
	copy.equipped_passive = source.equipped_passive
	copy.equipped_reaction = source.equipped_reaction
	copy.weapon = clone_item_definition(source.weapon) if source.weapon != null else null
	copy.armor = clone_item_definition(source.armor) if source.armor != null else null
	copy.helmet = clone_item_definition(source.helmet) if source.helmet != null else null
	copy.trinket = clone_item_definition(source.trinket) if source.trinket != null else null
	copy.tactics = clone_tactics(source.tactics)
	return copy


static func clone_tactics(source: Array[TacticDefinition]) -> Array[TacticDefinition]:
	var results: Array[TacticDefinition] = []
	for tactic in source:
		if tactic != null:
			results.append(clone_tactic(tactic))
	return results


static func clone_tactic(source: TacticDefinition) -> TacticDefinition:
	if source == null:
		return null
	var copy: TacticDefinition = TacticDefinitionScript.new()
	_copy_content_id(source, copy)
	copy.display_name = source.display_name
	copy.tooltip_text = source.tooltip_text
	copy.tags = source.tags.duplicate()
	copy.condition = source.condition
	copy.action = source.action
	copy.target = source.target
	copy.status = source.status
	copy.status_stack_threshold = source.status_stack_threshold
	copy.foretell_enabled = source.foretell_enabled
	return copy


static func clone_item_definition(source: ItemDefinition) -> ItemDefinition:
	if source == null:
		return null
	var copy: ItemDefinition = ItemDefinitionScript.new()
	_copy_content_id(source, copy)
	copy.display_name = source.display_name
	copy.tooltip_text = source.tooltip_text
	copy.tags = source.tags.duplicate()
	copy.slot = source.slot
	copy.max_hp_modifier = source.max_hp_modifier
	copy.physical_damage_modifier = source.physical_damage_modifier
	copy.magic_damage_modifier = source.magic_damage_modifier
	copy.armor_modifier = source.armor_modifier
	copy.action_speed_modifier = source.action_speed_modifier
	copy.effects = source.effects.duplicate()
	return copy


static func clone_job_progress(source: Array[JobProgressDefinition]) -> Array[JobProgressDefinition]:
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


static func content_id(resource: Resource) -> String:
	if resource == null:
		return ""
	if resource.has_meta(META_CONTENT_ID):
		return String(resource.get_meta(META_CONTENT_ID))
	if not resource.resource_path.is_empty():
		return resource.resource_path.get_file().get_basename()
	return ""


static func campaign_unit_id(unit: UnitDefinition) -> String:
	if unit == null:
		return ""
	if unit.has_meta(META_CAMPAIGN_UNIT_ID):
		return String(unit.get_meta(META_CAMPAIGN_UNIT_ID))
	return unit.display_name


static func set_campaign_unit_id(unit: UnitDefinition, id: String) -> void:
	if unit != null and not id.is_empty():
		unit.set_meta(META_CAMPAIGN_UNIT_ID, id)


static func _copy_content_id(source: Resource, target: Resource) -> void:
	var id := content_id(source)
	if not id.is_empty():
		target.set_meta(META_CONTENT_ID, id)


static func _copy_campaign_unit_id(source: UnitDefinition, target: UnitDefinition) -> void:
	var id := campaign_unit_id(source)
	if not id.is_empty():
		set_campaign_unit_id(target, id)
