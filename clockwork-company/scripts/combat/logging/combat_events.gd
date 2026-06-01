extends RefCounted
class_name CombatEvents

const Schema := preload("res://scripts/combat/logging/combat_event_schema.gd")


static func turn_start(actor, next_action_time_before: int) -> Dictionary:
	return {
		"event_type": Schema.EVENT_TURN_START,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"action_interval": actor.action_interval,
			"next_action_time_before": next_action_time_before,
		},
		"tags": ["replay", "turn"],
	}


static func tactic_skipped(actor, reason: String) -> Dictionary:
	return {
		"event_type": Schema.EVENT_TACTIC_SKIPPED,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"reason": reason,
		},
		"tags": ["replay", "tactic"],
	}


static func tactic_selected(actor, action: String, target, tactic_text: String) -> Dictionary:
	return {
		"event_type": Schema.EVENT_TACTIC_SELECTED,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"action": action,
			"target_id": target.unit_id,
			"target": target.unit_name,
			"tactic": tactic_text,
		},
		"tags": ["replay", "tactic"],
	}


static func tactic_fallback(actor, target) -> Dictionary:
	return {
		"event_type": Schema.EVENT_TACTIC_FALLBACK,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"target_id": target.unit_id,
			"target": target.unit_name,
		},
		"tags": ["replay", "tactic"],
	}


static func attack(actor, target) -> Dictionary:
	return {
		"event_type": Schema.EVENT_ATTACK,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"target_id": target.unit_id,
			"target": target.unit_name,
		},
		"tags": ["replay", "attack"],
	}


static func damage(actor, target, amount: int, target_armor: int, previous_hp: int, new_hp: int) -> Dictionary:
	return {
		"event_type": Schema.EVENT_DAMAGE,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"target_id": target.unit_id,
			"target": target.unit_name,
			"amount": amount,
			"target_armor": target_armor,
			"previous_hp": previous_hp,
			"new_hp": new_hp,
		},
		"tags": ["replay", "hp_change"],
	}


static func heal(actor, target, amount: int, previous_hp: int, new_hp: int) -> Dictionary:
	return {
		"event_type": Schema.EVENT_HEAL,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"target_id": target.unit_id,
			"target": target.unit_name,
			"amount": amount,
			"previous_hp": previous_hp,
			"new_hp": new_hp,
		},
		"tags": ["replay", "hp_change"],
	}


static func guard(actor, guard_armor: int, new_total_armor: int) -> Dictionary:
	return {
		"event_type": Schema.EVENT_GUARD,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"guard_armor": guard_armor,
			"new_total_armor": new_total_armor,
		},
		"tags": ["replay", "guard"],
	}


static func guard_expire(actor, previous_armor: int, new_armor: int) -> Dictionary:
	return {
		"event_type": Schema.EVENT_GUARD_EXPIRE,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"previous_armor": previous_armor,
			"new_armor": new_armor,
		},
		"tags": ["replay", "guard"],
	}


static func defeat(target) -> Dictionary:
	return {
		"event_type": Schema.EVENT_DEFEAT,
		"payload": {
			"target_id": target.unit_id,
			"target": target.unit_name,
		},
		"tags": ["replay", "defeat"],
	}


static func job_effect(actor, effect_name: String, details: String) -> Dictionary:
	return {
		"event_type": Schema.EVENT_JOB_EFFECT,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"effect": effect_name,
			"details": details,
		},
		"tags": ["job_effect"],
	}


static func item_trigger(actor, item_name: String, trigger_name: String, effect_name: String, details: String) -> Dictionary:
	return {
		"event_type": Schema.EVENT_ITEM_TRIGGER,
		"payload": {
			"actor_id": actor.unit_id,
			"actor": actor.unit_name,
			"item": item_name,
			"trigger": trigger_name,
			"effect": effect_name,
			"details": details,
		},
		"tags": ["item_trigger"],
	}


static func result(result_text: String) -> Dictionary:
	return {
		"event_type": Schema.EVENT_RESULT,
		"payload": {
			"result_text": result_text,
		},
		"tags": ["result"],
	}
