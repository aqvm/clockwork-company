extends RefCounted
class_name ForecastService

const TurnSchedulerScript := preload("res://scripts/combat/runtime/turn_scheduler.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")


static func foretell_target(actor, units: Array, tactic: TacticDefinition, execute_current_action: Callable, execute_future_turn: Callable, evaluate_target: Callable):
	if actor == null or not actor.forecast_capable():
		return null

	var speculative_units: Array = []
	var speculative_actor = null
	for unit in units:
		var clone = unit.clone_runtime_state()
		speculative_units.append(clone)
		if unit == actor:
			speculative_actor = clone

	execute_current_action.call(speculative_actor, speculative_units)
	var result: Dictionary = evaluate_target.call(tactic, speculative_actor, speculative_units)
	if bool(result.get("matched", false)):
		return _mapped_target(units, result.get("target", null))
	if speculative_actor.is_alive():
		TurnSchedulerScript.schedule_next_turn(speculative_actor)

	while true:
		if not TargetingRulesScript.team_has_living_unit(speculative_units, speculative_actor.team):
			break
		if not TargetingRulesScript.team_has_living_unit(speculative_units, TargetingRulesScript.opposing_team(speculative_actor.team)):
			break
		var next_actor = TurnSchedulerScript.find_next_actor(speculative_units)
		if next_actor == null or next_actor == speculative_actor:
			break
		execute_future_turn.call(next_actor, speculative_units)
		result = evaluate_target.call(tactic, speculative_actor, speculative_units)
		if bool(result.get("matched", false)):
			return _mapped_target(units, result.get("target", null))
	return null


static func _mapped_target(units: Array, speculative_target):
	if speculative_target == null:
		return null
	return _real_unit_for_id(units, speculative_target.unit_id)


static func _real_unit_for_id(units: Array, unit_id: String):
	for unit in units:
		if unit.unit_id == unit_id and unit.is_alive():
			return unit
	return null
