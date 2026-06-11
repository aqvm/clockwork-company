extends RefCounted
class_name JobEffectResolver

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")

const PASSIVE_ATTACK_DAMAGE_BONUS := "Attack Damage Bonus"
const PASSIVE_HEAL_BONUS := "Heal Bonus"
const PASSIVE_GUARD_ARMOR_BONUS := "Guard Armor Bonus"
const REACTION_GAIN_ARMOR := "Gain Armor"
const REACTION_HEAL_SELF := "Heal Self"
const REACTION_DAMAGE_ATTACKER := "Damage Attacker"
const CONDITION_SELF_HP_BELOW_PERCENT := "Self HP Below Percent"
const TRIGGER_HP_BELOW_THRESHOLD := "HP Below Threshold"

static func attack_bonus(log, parent_entry_id: int, actor, context = null) -> int:
	if not _passive_can_fire(actor, PASSIVE_ATTACK_DAMAGE_BONUS):
		return 0
	_mark_passive_fired(actor)
	var passive: PassiveDefinition = actor.current_passive
	if context != null:
		context.publish("passive_triggered", actor, actor, {"passive": passive.display_name, "passive_type": passive.passive_type}, -1, parent_entry_id, ["passive", "trigger"])
	var event := CombatEventsScript.job_effect(actor, passive.display_name, "+%d damage" % passive.amount)
	log.add_event("Passive %s: +%d damage." % [passive.display_name, passive.amount], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
	return passive.amount

static func heal_bonus(log, turn_entry_id: int, actor, context = null) -> int:
	if not _passive_can_fire(actor, PASSIVE_HEAL_BONUS):
		return 0
	_mark_passive_fired(actor)
	var passive: PassiveDefinition = actor.current_passive
	if context != null:
		context.publish("passive_triggered", actor, actor, {"passive": passive.display_name, "passive_type": passive.passive_type}, -1, turn_entry_id, ["passive", "trigger"])
	var event := CombatEventsScript.job_effect(actor, passive.display_name, "+%d healing" % passive.amount)
	log.add_event("Passive %s: +%d healing." % [passive.display_name, passive.amount], event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])
	return passive.amount

static func guard_bonus(log, turn_entry_id: int, actor, context = null) -> int:
	if not _passive_can_fire(actor, PASSIVE_GUARD_ARMOR_BONUS):
		return 0
	_mark_passive_fired(actor)
	var passive: PassiveDefinition = actor.current_passive
	if context != null:
		context.publish("passive_triggered", actor, actor, {"passive": passive.display_name, "passive_type": passive.passive_type}, -1, turn_entry_id, ["passive", "trigger"])
	var event := CombatEventsScript.job_effect(actor, passive.display_name, "+%d temporary armor" % passive.amount)
	log.add_event("Passive %s: +%d temporary armor." % [passive.display_name, passive.amount], event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])
	return passive.amount


static func apply_damaged_reaction(log, parent_entry_id: int, damaged_unit, attacker, context = null) -> void:
	var reaction: ReactionDefinition = damaged_unit.current_reaction
	if reaction == null or reaction.amount == 0:
		return
	if not _reaction_can_fire(damaged_unit, reaction):
		return
	var reaction_request_id := -1
	if context != null:
		var request: Dictionary = context.request("reaction_requested", damaged_unit, attacker, {
			"reaction": reaction.display_name,
			"reaction_type": reaction.reaction_type,
			"prevented": false,
		}, -1, parent_entry_id, ["reaction", "request"])
		if bool(request["payload"].get("prevented", false)):
			context.publish("reaction_suppressed", damaged_unit, attacker, {
				"reaction": reaction.display_name,
				"reason": String(request["payload"].get("prevented_reason", "prevented")),
			}, int(request["id"]), parent_entry_id, ["reaction", "status"])
			return
		reaction_request_id = int(request["id"])
	_mark_reaction_fired(damaged_unit, reaction)
	if context != null:
		context.publish("reaction_triggered", damaged_unit, attacker, {"reaction": reaction.display_name, "reaction_type": reaction.reaction_type}, reaction_request_id, parent_entry_id, ["reaction"])
	if reaction.reaction_type == REACTION_GAIN_ARMOR:
		damaged_unit.guard_armor += reaction.amount
		var armor_event := CombatEventsScript.job_effect(damaged_unit, reaction.display_name, "+%d temporary armor" % reaction.amount)
		log.add_event("Reaction %s: %s gains %d temporary armor." % [reaction.display_name, damaged_unit.unit_name, reaction.amount], armor_event["event_type"], -1, parent_entry_id, armor_event["payload"], armor_event["tags"])
		if context != null:
			context.publish("armor_gained", damaged_unit, damaged_unit, {"amount": reaction.amount, "armor_kind": "temporary"}, -1, parent_entry_id, ["armor", "reaction"])
	elif reaction.reaction_type == REACTION_HEAL_SELF:
		if context != null:
			context.apply_healing(damaged_unit, damaged_unit, reaction.amount, -1, parent_entry_id, ["reaction"])
		else:
			var previous_hp: int = damaged_unit.hp
			damaged_unit.hp = min(damaged_unit.max_hp, damaged_unit.hp + reaction.amount)
			var heal_event := CombatEventsScript.job_effect(damaged_unit, reaction.display_name, "HP %d -> %d" % [previous_hp, damaged_unit.hp])
			log.add_event("Reaction %s: %s HP %d -> %d." % [reaction.display_name, damaged_unit.unit_name, previous_hp, damaged_unit.hp], heal_event["event_type"], -1, parent_entry_id, heal_event["payload"], heal_event["tags"])
	elif reaction.reaction_type == REACTION_DAMAGE_ATTACKER and attacker != null:
		if context != null:
			context.apply_direct_damage(damaged_unit, attacker, reaction.amount, -1, parent_entry_id, ["reaction"])
		else:
			var previous_attacker_hp: int = attacker.hp
			attacker.hp = max(0, attacker.hp - reaction.amount)
			StatusResolverScript.record_damage(attacker, previous_attacker_hp - attacker.hp)
			var damage_event := CombatEventsScript.job_effect(damaged_unit, reaction.display_name, "%s HP %d -> %d" % [attacker.unit_name, previous_attacker_hp, attacker.hp])
			log.add_event("Reaction %s: %s HP %d -> %d." % [reaction.display_name, attacker.unit_name, previous_attacker_hp, attacker.hp], damage_event["event_type"], -1, parent_entry_id, damage_event["payload"], damage_event["tags"])


static func _passive_can_fire(actor, passive_type: String) -> bool:
	var passive: PassiveDefinition = actor.current_passive
	if passive == null or passive.passive_type != passive_type or passive.amount == 0:
		return false
	return actor.ability_is_ready(_passive_key(passive))


static func _mark_passive_fired(actor) -> void:
	var passive: PassiveDefinition = actor.current_passive
	if passive == null:
		return
	actor.start_ability_cooldown(_passive_key(passive), passive.cooldown_turns)


static func _reaction_can_fire(owner, reaction: ReactionDefinition) -> bool:
	if reaction.trigger == TRIGGER_HP_BELOW_THRESHOLD or reaction.condition == CONDITION_SELF_HP_BELOW_PERCENT:
		if owner.hp * 100 > owner.max_hp * reaction.threshold_percent:
			return false
	return owner.ability_is_ready(_reaction_key(reaction))


static func _mark_reaction_fired(owner, reaction: ReactionDefinition) -> void:
	owner.start_ability_cooldown(_reaction_key(reaction), reaction.cooldown_turns)


static func _passive_key(passive: PassiveDefinition) -> String:
	return "passive|%s|%s" % [passive.passive_type, passive.display_name]


static func _reaction_key(reaction: ReactionDefinition) -> String:
	return "reaction|%s|%s" % [reaction.trigger, reaction.display_name]
