extends RefCounted
class_name TurnScheduler

const BASE_ACTION_TIME := 100


static func action_delay(action_speed: int) -> int:
	return maxi(1, ceili(float(BASE_ACTION_TIME) / float(maxi(1, action_speed))))


static func find_next_actor(units: Array):
	var next_actor = null
	for unit in units:
		if not unit.is_alive():
			continue
		if next_actor == null:
			next_actor = unit
		elif unit.next_action_time < next_actor.next_action_time:
			next_actor = unit
		elif unit.next_action_time == next_actor.next_action_time and unit.slot_index < next_actor.slot_index:
			next_actor = unit
	return next_actor

static func schedule_next_turn(actor) -> void:
	actor.next_action_time += action_delay(actor.action_speed)
