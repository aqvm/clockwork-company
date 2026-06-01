extends RefCounted
class_name DemoBattleFactory

const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")

static func create_demo_units(enabled_mod_pack_ids: Variant = null) -> Array:
	return create_units_from_definitions(JsonContentLoaderScript.load_demo_unit_definitions(enabled_mod_pack_ids))


static func create_units_from_definitions(definitions: Array[UnitDefinition]) -> Array:
	var units: Array = []
	for index in definitions.size():
		units.append(UnitStateScript.new(definitions[index], index))
	return units
