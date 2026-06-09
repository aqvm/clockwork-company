extends RefCounted
class_name ForecastService

const TurnSchedulerScript := preload("res://scripts/combat/runtime/turn_scheduler.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")


static func forecast(actor, units: Array, execute_current_action: Callable, execute_future_turn: Callable) -> Dictionary:
	if actor == null or not actor.forecast_capable():
		return {}

	var speculative_units: Array = []
	var speculative_actor = null
	for unit in units:
		var clone = unit.clone_runtime_state()
		speculative_units.append(clone)
		if unit == actor:
			speculative_actor = clone

	var first_defeated_ally_id := _execute_and_find_first_defeated(
		speculative_actor.team,
		speculative_units,
		execute_current_action.bind(speculative_actor, speculative_units)
	)
	if speculative_actor.is_alive():
		TurnSchedulerScript.schedule_next_turn(speculative_actor)

	while first_defeated_ally_id.is_empty():
		if not TargetingRulesScript.team_has_living_unit(speculative_units, speculative_actor.team):
			break
		if not TargetingRulesScript.team_has_living_unit(speculative_units, TargetingRulesScript.opposing_team(speculative_actor.team)):
			break
		var next_actor = TurnSchedulerScript.find_next_actor(speculative_units)
		if next_actor == null or next_actor == speculative_actor:
			break
		if next_actor.forecast_capable():
			break
		first_defeated_ally_id = _execute_and_find_first_defeated(
			speculative_actor.team,
			speculative_units,
			execute_future_turn.bind(next_actor, speculative_units)
		)

	if first_defeated_ally_id.is_empty():
		return {}
	for unit in units:
		if unit.unit_id == first_defeated_ally_id and unit.is_alive():
			return {
				"first_defeated_ally": unit,
				"first_defeated_ally_id": first_defeated_ally_id,
			}
	return {}


static func _execute_and_find_first_defeated(team: String, units: Array, execute: Callable) -> String:
	var living_ally_ids: Array[String] = []
	for unit in units:
		if unit.team == team and unit.is_alive():
			living_ally_ids.append(unit.unit_id)
	execute.call()
	for unit in units:
		if unit.unit_id in living_ally_ids and not unit.is_alive():
			return unit.unit_id
	return ""
