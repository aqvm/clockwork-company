extends RefCounted
class_name TargetingRules

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")

static func opposing_team(team: String) -> String:
	if team == CombatConstantsScript.TEAM_ALLY:
		return CombatConstantsScript.TEAM_ENEMY
	return CombatConstantsScript.TEAM_ALLY

static func team_has_living_unit(units: Array, team: String) -> bool:
	for unit in units:
		if unit.team == team and unit.is_alive():
			return true
	return false

static func is_below_half_hp(unit) -> bool:
	return unit.hp * 2 < unit.max_hp

static func find_lowest_hp_ally_below_half(units: Array, team: String):
	var lowest_ally = null
	for unit in units:
		if unit.team != team or not unit.is_alive() or not is_below_half_hp(unit):
			continue
		if lowest_ally == null:
			lowest_ally = unit
		elif unit.hp < lowest_ally.hp:
			lowest_ally = unit
		elif unit.hp == lowest_ally.hp and unit.slot_index < lowest_ally.slot_index:
			lowest_ally = unit
	return lowest_ally

static func find_frontmost_target(units: Array, target_team: String):
	for unit in units:
		if unit.team == target_team and unit.is_alive():
			return unit
	return null
