extends RefCounted
class_name JobEffectResolver

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")

static func attack_bonus(log, parent_entry_id: int, actor) -> int:
	if actor.job_effect() != CombatConstantsScript.JOB_EFFECT_SHARPENED_EDGE:
		return 0
	var event := CombatEventsScript.job_effect(actor, "Sharpened Edge", "+1 damage")
	log.add_event("Job effect Sharpened Edge: +1 damage.", event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
	return 1

static func heal_bonus(log, turn_entry_id: int, actor) -> int:
	if actor.job_effect() != CombatConstantsScript.JOB_EFFECT_FIRST_AID:
		return 0
	var event := CombatEventsScript.job_effect(actor, "First Aid", "+2 healing")
	log.add_event("Job effect First Aid: +2 healing.", event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])
	return 2

static func guard_bonus(log, turn_entry_id: int, actor) -> int:
	if actor.job_effect() != CombatConstantsScript.JOB_EFFECT_GUARD_TRAINING:
		return 0
	var event := CombatEventsScript.job_effect(actor, "Guard Training", "+1 temporary armor")
	log.add_event("Job effect Guard Training: +1 temporary armor.", event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])
	return 1
