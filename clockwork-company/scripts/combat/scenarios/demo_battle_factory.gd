extends RefCounted
class_name DemoBattleFactory

const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")

const DEMO_UNIT_DEFINITIONS = [
	preload("res://resources/units/alden_guard.tres"),
	preload("res://resources/units/mira_scout.tres"),
	preload("res://resources/units/sol_apprentice.tres"),
	preload("res://resources/units/iron_brute.tres"),
	preload("res://resources/units/ash_cutpurse.tres"),
	preload("res://resources/units/glass_wisp.tres"),
]

static func create_demo_units() -> Array:
	var units: Array = []
	for index in DEMO_UNIT_DEFINITIONS.size():
		units.append(UnitStateScript.new(DEMO_UNIT_DEFINITIONS[index], index))
	return units
