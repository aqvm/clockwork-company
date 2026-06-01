extends RefCounted
class_name TacticResolver

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")

static func choose_action(actor, units: Array) -> Dictionary:
	var skipped_reasons: Array[String] = []
	for tactic: TacticDefinition in actor.tactics:
		if not _condition_matches(tactic.condition, actor, units):
			continue
		var target = _find_tactic_target(tactic.target, actor, units)
		if target == null:
			skipped_reasons.append("Tactic skipped: %s. No valid target." % _describe_tactic(tactic))
			continue
		return {
			"action": tactic.action,
			"target": target,
			"reason": "Tactic selected: %s. Condition true; target is %s." % [_describe_tactic(tactic), target.unit_name],
			"skipped_reasons": skipped_reasons,
		}
	var fallback_target = TargetingRulesScript.find_frontmost_target(units, TargetingRulesScript.opposing_team(actor.team))
	return {
		"action": CombatConstantsScript.ACTION_ATTACK,
		"target": fallback_target,
		"reason": "No tactic matched; default attack used against %s." % fallback_target.unit_name,
		"skipped_reasons": skipped_reasons,
	}

static func _condition_matches(condition: String, actor, units: Array) -> bool:
	if condition == CombatConstantsScript.CONDITION_ALWAYS:
		return true
	if condition == CombatConstantsScript.CONDITION_SELF_HP_BELOW_HALF:
		return TargetingRulesScript.is_below_half_hp(actor)
	if condition == CombatConstantsScript.CONDITION_ALLY_HP_BELOW_HALF:
		return TargetingRulesScript.find_lowest_hp_ally_below_half(units, actor.team) != null
	if condition == CombatConstantsScript.CONDITION_ENEMY_ALIVE:
		return TargetingRulesScript.team_has_living_unit(units, TargetingRulesScript.opposing_team(actor.team))
	return false

static func _find_tactic_target(target_rule: String, actor, units: Array):
	if target_rule == CombatConstantsScript.TARGET_SELF:
		return actor
	if target_rule == CombatConstantsScript.TARGET_LOWEST_HP_ALLY:
		return TargetingRulesScript.find_lowest_hp_ally_below_half(units, actor.team)
	if target_rule == CombatConstantsScript.TARGET_FRONTMOST_ENEMY:
		return TargetingRulesScript.find_frontmost_target(units, TargetingRulesScript.opposing_team(actor.team))
	return null

static func _describe_tactic(tactic: TacticDefinition) -> String:
	return "%s -> %s -> %s" % [tactic.condition, tactic.action, tactic.target]
