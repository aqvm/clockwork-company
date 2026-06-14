extends RefCounted
class_name TacticResolver

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")

static func choose_action(actor, units: Array, evaluate_foretell: Callable = Callable(), allow_foretell := true) -> Dictionary:
	var skipped_reasons: Array[String] = []
	var confusion_can_skip: bool = actor.has_status(StatusResolverScript.STATUS_CONFUSION)
	for tactic: TacticDefinition in actor.tactics:
		var target = null
		var used_foretell := tactic.foretell_enabled and allow_foretell
		if used_foretell:
			if not actor.forecast_capable():
				skipped_reasons.append("Tactic unavailable: %s. An equipped Forecast passive is required for Foretell." % _describe_tactic(tactic))
				continue
			if evaluate_foretell.is_null():
				continue
			target = evaluate_foretell.call(tactic)
			if target == null:
				continue
		else:
			target = find_tactic_target(tactic.target, actor, units, tactic)
			if not condition_matches(tactic.condition, actor, units, target, tactic):
				continue
		if tactic.action == CombatConstantsScript.ACTION_JOB_SKILL and actor.current_skill == null:
			skipped_reasons.append("Tactic skipped: %s. Current job skill is not unlocked." % _describe_tactic(tactic))
			continue
		if tactic.action == CombatConstantsScript.ACTION_JOB_SKILL and not actor.skill_is_ready(actor.current_skill):
			skipped_reasons.append("Tactic skipped: %s. Current job skill is on cooldown." % _describe_tactic(tactic))
			continue
		if tactic.action == CombatConstantsScript.ACTION_ASSIGNED_SKILL and actor.assigned_skill == null:
			skipped_reasons.append("Tactic skipped: %s. No eligible learned skill is assigned." % _describe_tactic(tactic))
			continue
		if tactic.action == CombatConstantsScript.ACTION_ASSIGNED_SKILL and not actor.skill_is_ready(actor.assigned_skill):
			skipped_reasons.append("Tactic skipped: %s. Assigned skill is on cooldown." % _describe_tactic(tactic))
			continue
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
			"reason": "Tactic selected: %s. %s; target is %s." % [_describe_tactic(tactic), "First future condition match" if used_foretell else "Condition true", target.unit_name],
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

static func condition_matches(condition: String, actor, units: Array, target = null, tactic: TacticDefinition = null) -> bool:
	if condition == CombatConstantsScript.CONDITION_ALWAYS:
		return true
	if condition == CombatConstantsScript.CONDITION_SELF_HP_BELOW_HALF:
		return TargetingRulesScript.is_below_half_hp(actor)
	if condition == CombatConstantsScript.CONDITION_ALLY_HP_BELOW_HALF:
		return TargetingRulesScript.find_lowest_hp_ally_below_half(units, actor.team) != null
	if condition == CombatConstantsScript.CONDITION_ENEMY_ALIVE:
		return TargetingRulesScript.team_has_living_unit(units, TargetingRulesScript.opposing_team(actor.team))
	if condition == "Target Has Status":
		return target != null and tactic != null and tactic.status != null and target.status_stack_count(tactic.status.status_type) > 0
	if condition == "Target Status Stacks At Least":
		return target != null and tactic != null and tactic.status != null and target.status_stack_count(tactic.status.status_type) >= tactic.status_stack_threshold
	if condition == "Target Pending Status Damage At Least HP":
		return target != null and tactic != null and tactic.status != null and target.pending_status_damage(tactic.status.status_type) >= target.hp
	if condition == "Target Slower Than Self":
		return target != null and target.action_interval > actor.action_interval
	return false

static func find_tactic_target(target_rule: String, actor, units: Array, tactic: TacticDefinition = null):
	if target_rule == CombatConstantsScript.TARGET_SELF:
		return actor
	if target_rule == CombatConstantsScript.TARGET_LOWEST_HP_ALLY:
		return TargetingRulesScript.find_lowest_hp_ally_below_half(units, actor.team)
	if target_rule == "Lowest HP Ally With Status":
		return _lowest_hp_ally_with_status(units, actor.team, tactic.status if tactic != null else null)
	if target_rule == CombatConstantsScript.TARGET_FRONTMOST_ENEMY:
		return TargetingRulesScript.find_frontmost_target(units, TargetingRulesScript.opposing_team(actor.team))
	return null


static func _lowest_hp_ally_with_status(units: Array, team: String, status: StatusDefinition):
	if status == null:
		return null
	var lowest = null
	for unit in units:
		if unit.team != team or not unit.is_alive() or unit.status_stack_count(status.status_type) <= 0:
			continue
		if lowest == null or unit.hp < lowest.hp:
			lowest = unit
	return lowest


static func _describe_tactic(tactic: TacticDefinition) -> String:
	var rules_text := "%s -> %s -> %s" % [tactic.condition, tactic.action, tactic.target]
	if tactic.foretell_enabled:
		rules_text = "Foretell: %s" % rules_text
	if tactic.display_name.is_empty():
		return rules_text
	return "%s (%s)" % [tactic.display_name, rules_text]
