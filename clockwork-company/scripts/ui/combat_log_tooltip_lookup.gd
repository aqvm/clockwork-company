extends RefCounted
class_name CombatLogTooltipLookup

const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const ResourceTooltipBuilderScript := preload("res://scripts/ui/resource_tooltip_builder.gd")


static func build(definitions: Array[UnitDefinition], roster_units: Array[Dictionary], enabled_mod_pack_ids: Array[String]) -> Dictionary:
	var lookup := {}
	for roster_unit in roster_units:
		var name := String(roster_unit.get("name", ""))
		if not name.is_empty():
			lookup[name] = "Unit: %s\nTeam: %s\nSource: battle roster" % [name, String(roster_unit.get("team", ""))]
	var content := JsonContentLoaderScript.load_content_resources(enabled_mod_pack_ids)
	for status in content.get("statuses", {}).values():
		_register_tooltip_resource(lookup, status)
	for item in content.get("items", {}).values():
		_register_tooltip_resource(lookup, item)
	for tactic in content.get("tactics", {}).values():
		_register_tooltip_resource(lookup, tactic)
	for job in content.get("jobs", {}).values():
		_register_tooltip_resource(lookup, job)
	for unit in definitions:
		_register_tooltip_resource(lookup, unit)
		if unit != null:
			_register_tooltip_resource(lookup, unit.ancestry)
			_register_loadout_tooltip_resources(lookup, unit.loadout)
	return lookup


static func _register_loadout_tooltip_resources(lookup: Dictionary, loadout: UnitLoadoutDefinition) -> void:
	if loadout == null:
		return
	_register_tooltip_resource(lookup, loadout)
	_register_tooltip_resource(lookup, loadout.current_job)
	_register_tooltip_resource(lookup, loadout.equipped_skill)
	_register_tooltip_resource(lookup, loadout.equipped_passive)
	_register_tooltip_resource(lookup, loadout.equipped_reaction)
	_register_tooltip_resource(lookup, loadout.weapon)
	_register_tooltip_resource(lookup, loadout.armor)
	_register_tooltip_resource(lookup, loadout.helmet)
	_register_tooltip_resource(lookup, loadout.trinket)
	for tactic in loadout.tactics:
		_register_tooltip_resource(lookup, tactic)


static func _register_tooltip_resource(lookup: Dictionary, resource) -> void:
	if resource == null:
		return
	var display_value = resource.get("display_name")
	var display_name := String(display_value) if display_value != null else ""
	if display_name.is_empty():
		return
	lookup[display_name] = ResourceTooltipBuilderScript.text_for_resource(resource)
	if resource is JobDefinition:
		_register_tooltip_resource(lookup, resource.skill)
		_register_tooltip_resource(lookup, resource.secondary_skill)
		_register_tooltip_resource(lookup, resource.passive)
		_register_tooltip_resource(lookup, resource.reaction)
		_register_tooltip_resource(lookup, resource.default_tactic)
	elif resource is SkillDefinition:
		_register_tooltip_resource(lookup, resource.status)
		for effect in resource.effects:
			_register_tooltip_resource(lookup, effect)
	elif resource is PassiveDefinition:
		for effect in resource.effects:
			_register_tooltip_resource(lookup, effect)
	elif resource is ReactionDefinition:
		_register_tooltip_resource(lookup, resource.status)
		for status in resource.replacement_statuses:
			_register_tooltip_resource(lookup, status)
		for effect in resource.effects:
			_register_tooltip_resource(lookup, effect)
	elif resource is ItemDefinition:
		for effect in resource.effects:
			_register_tooltip_resource(lookup, effect)
	elif resource is TacticDefinition:
		_register_tooltip_resource(lookup, resource.status)
