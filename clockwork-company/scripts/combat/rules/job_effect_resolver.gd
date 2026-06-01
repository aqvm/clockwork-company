extends RefCounted
class_name JobEffectResolver

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")

static func attack_bonus(log, parent_entry_id: int, actor) -> int:
	if actor.job_effect() != CombatConstantsScript.JOB_EFFECT_SHARPENED_EDGE:
		return 0
	log.add_child(parent_entry_id, "Job effect Sharpened Edge: +1 damage.")
	return 1

static func heal_bonus(log, turn_entry_id: int, actor) -> int:
	if actor.job_effect() != CombatConstantsScript.JOB_EFFECT_FIRST_AID:
		return 0
	log.add_child(turn_entry_id, "Job effect First Aid: +2 healing.")
	return 2

static func guard_bonus(log, turn_entry_id: int, actor) -> int:
	if actor.job_effect() != CombatConstantsScript.JOB_EFFECT_GUARD_TRAINING:
		return 0
	log.add_child(turn_entry_id, "Job effect Guard Training: +1 temporary armor.")
	return 1
