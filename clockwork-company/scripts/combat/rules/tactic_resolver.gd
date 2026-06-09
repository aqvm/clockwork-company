extends RefCounted
class_name TacticResolver

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")

static func choose_action(actor, units: Array, forecast: Dictionary = {}, allow_forecast := true) -> Dictionary:
	var skipped_reasons: Array[String] = []
	var confusion_can_skip: bool = actor.has_status(StatusResolverScript.STATUS_CONFUSION)
	for tactic: TacticDefinition in actor.tactics:
		var forecast_tactic := _is_forecast_tactic(tactic)
		if forecast_tactic and (not allow_forecast or not actor.forecast_capable()):
			if allow_forecast:
				skipped_reasons.append("Tactic unavailable: %s. An equipped Forecast passive is required." % _describe_tactic(tactic))
			continue
		if not _condition_matches(tactic.condition, actor, units, forecast):
			continue
		if tactic.action == CombatConstantsScript.ACTION_JOB_SKILL and actor.current_skill == null:
			skipped_reasons.append("Tactic skipped: %s. Current job skill is not unlocked." % _describe_tactic(tactic))
			continue
		if tactic.action == CombatConstantsScript.ACTION_ASSIGNED_SKILL and actor.assigned_skill == null:
			skipped_reasons.append("Tactic skipped: %s. No eligible learned skill is assigned." % _describe_tactic(tactic))
			continue
		var target = _find_tactic_target(tactic.target, actor, units, forecast)
		if target == null:
			skipped_reasons.append("Tactic skipped: %s. No valid target." % _describe_tactic(tactic))
			continue
		if confusion_can_skip:
			confusion_can_skip = false
			skipped_reasons.append("Confusion skips the first otherwise-valid tactic: %s." % _describe_tactic(tactic))
			continue
		return {
			"action": tactic.action,
			"target": target,
			"reason": "Tactic selected: %s. Condition true; target is %s." % [_describe_tactic(tactic), target.unit_name],
			"reason_type": "selected",
			"reason_tactic": _describe_tactic(tactic),
			"skipped_reasons": skipped_reasons,
		}
	var fallback_target = TargetingRulesScript.find_frontmost_target(units, TargetingRulesScript.opposing_team(actor.team))
	return {
		"action": CombatConstantsScript.ACTION_ATTACK,
		"target": fallback_target,
		"reason": "No tactic matched; default attack used against %s." % fallback_target.unit_name,
		"reason_type": "fallback",
		"reason_tactic": "",
		"skipped_reasons": skipped_reasons,
	}

static func _condition_matches(condition: String, actor, units: Array, forecast: Dictionary) -> bool:
	if condition == CombatConstantsScript.CONDITION_ALWAYS:
		return true
	if condition == CombatConstantsScript.CONDITION_SELF_HP_BELOW_HALF:
		return TargetingRulesScript.is_below_half_hp(actor)
	if condition == CombatConstantsScript.CONDITION_ALLY_HP_BELOW_HALF:
		return TargetingRulesScript.find_lowest_hp_ally_below_half(units, actor.team) != null
	if condition == CombatConstantsScript.CONDITION_ENEMY_ALIVE:
		return TargetingRulesScript.team_has_living_unit(units, TargetingRulesScript.opposing_team(actor.team))
	if condition == CombatConstantsScript.CONDITION_ALLY_WOULD_BE_DEFEATED:
		return forecast.has("first_defeated_ally")
	return false

static func _find_tactic_target(target_rule: String, actor, units: Array, forecast: Dictionary):
	if target_rule == CombatConstantsScript.TARGET_SELF:
		return actor
	if target_rule == CombatConstantsScript.TARGET_LOWEST_HP_ALLY:
		return TargetingRulesScript.find_lowest_hp_ally_below_half(units, actor.team)
	if target_rule == CombatConstantsScript.TARGET_FRONTMOST_ENEMY:
		return TargetingRulesScript.find_frontmost_target(units, TargetingRulesScript.opposing_team(actor.team))
	if target_rule == CombatConstantsScript.TARGET_FIRST_FORESEEN_ALLY:
		return forecast.get("first_defeated_ally", null)
	return null


static func _is_forecast_tactic(tactic: TacticDefinition) -> bool:
	return tactic.condition == CombatConstantsScript.CONDITION_ALLY_WOULD_BE_DEFEATED or tactic.target == CombatConstantsScript.TARGET_FIRST_FORESEEN_ALLY

static func _describe_tactic(tactic: TacticDefinition) -> String:
	var rules_text := "%s -> %s -> %s" % [tactic.condition, tactic.action, tactic.target]
	if tactic.display_name.is_empty():
		return rules_text
	return "%s (%s)" % [tactic.display_name, rules_text]
