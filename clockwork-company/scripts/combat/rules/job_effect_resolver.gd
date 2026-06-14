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
const CONDITION_REQUESTED_STATUS_IS_AILMENT := "Requested Status Is Ailment"
const TRIGGER_HP_BELOW_THRESHOLD := "HP Below Threshold"
const TRIGGER_DAMAGED := "Damaged"
const TRIGGER_STATUS_APPLICATION_REQUESTED := "Status Application Requested"
const TRIGGER_ENEMY_HEALING_REQUESTED := "Enemy Healing Requested"
const TRIGGER_ATTACK_TARGETS_ANOTHER_ALLY := "Attack Targets Another Ally"
const TRIGGER_LETHAL_PHYSICAL_ATTACK_REQUESTED := "Lethal Physical Attack Requested"
const TRIGGER_ENEMY_DIED_WITH_STATUS := "Enemy Died With Status"

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
	var payload := {}
	_apply_reaction(log, parent_entry_id, damaged_unit, attacker, TRIGGER_DAMAGED, payload, context)


static func apply_damage_reaction(log, parent_entry_id: int, damaged_unit, attacker, damage_payload: Dictionary, context = null) -> void:
	var reaction: ReactionDefinition = damaged_unit.current_reaction
	if reaction == null:
		return
	if reaction.trigger == "Physically Damaged" and int(damage_payload.get("physical_amount", 0)) > 0:
		_apply_reaction(log, parent_entry_id, damaged_unit, attacker, reaction.trigger, damage_payload, context)
	elif reaction.trigger == "Magically Damaged" and int(damage_payload.get("magic_amount", 0)) > 0:
		_apply_reaction(log, parent_entry_id, damaged_unit, attacker, reaction.trigger, damage_payload, context)
	elif reaction.trigger in [TRIGGER_DAMAGED, TRIGGER_HP_BELOW_THRESHOLD]:
		_apply_reaction(log, parent_entry_id, damaged_unit, attacker, reaction.trigger, damage_payload, context)


static func apply_status_application_reaction(log, parent_entry_id: int, target, source, request_payload: Dictionary, context = null) -> void:
	if _apply_reaction(log, parent_entry_id, target, source, TRIGGER_STATUS_APPLICATION_REQUESTED, request_payload, context) and target.current_reaction.prevents_triggering_request:
		_prevent_request(request_payload, target.current_reaction)
		var replacements: Array[StatusDefinition] = target.current_reaction.replacement_statuses
		if context != null and not replacements.is_empty():
			var replacement: StatusDefinition = replacements[context.history.size() % replacements.size()]
			StatusResolverScript.apply_status(log, parent_entry_id, target, replacement, target.current_reaction.display_name, 3, false, context, target)


static func apply_enemy_healing_request_reactions(log, parent_entry_id: int, healed_unit, healer, request_payload: Dictionary, context = null) -> void:
	if context == null or healed_unit == null:
		return
	for owner in context.units:
		if owner == null or not owner.is_alive() or owner.team == healed_unit.team:
			continue
		var reaction: ReactionDefinition = owner.current_reaction
		if reaction == null or reaction.trigger != TRIGGER_ENEMY_HEALING_REQUESTED:
			continue
		if _apply_reaction(log, parent_entry_id, owner, healed_unit, reaction.trigger, request_payload, context) and reaction.prevents_triggering_request:
			_prevent_request(request_payload, reaction)
			return


static func apply_attack_target_reactions(log, parent_entry_id: int, attacker, requested_target, request_payload: Dictionary, context = null) -> void:
	if context == null or attacker == null or requested_target == null:
		return
	for owner in context.units:
		if owner == null or not owner.is_alive() or owner == requested_target or owner.team != requested_target.team or owner.team == attacker.team:
			continue
		var reaction: ReactionDefinition = owner.current_reaction
		if reaction == null or reaction.trigger != TRIGGER_ATTACK_TARGETS_ANOTHER_ALLY:
			continue
		if _apply_reaction(log, parent_entry_id, owner, attacker, reaction.trigger, request_payload, context):
			request_payload["target_unit_id"] = owner.unit_id
			request_payload["redirected_by"] = reaction.display_name
			return


static func apply_lethal_physical_attack_reaction(log, parent_entry_id: int, target, attacker, request_payload: Dictionary, context = null) -> void:
	if target == null or attacker == null or bool(request_payload.get("prevented", false)):
		return
	if int(request_payload.get("physical_amount", 0)) <= 0 or int(request_payload.get("amount", 0)) < target.hp:
		return
	if _apply_reaction(log, parent_entry_id, target, attacker, TRIGGER_LETHAL_PHYSICAL_ATTACK_REQUESTED, request_payload, context) and target.current_reaction.prevents_triggering_request:
		_prevent_request(request_payload, target.current_reaction)


static func apply_enemy_status_threshold_reactions(log, parent_entry_id: int, status_target, status_payload: Dictionary, context = null) -> void:
	if context == null or status_target == null:
		return
	for owner in context.units:
		if owner == null or not owner.is_alive() or owner.team == status_target.team:
			continue
		var reaction: ReactionDefinition = owner.current_reaction
		if reaction == null or reaction.trigger != "Enemy Status Threshold Reached" or reaction.status == null:
			continue
		if String(status_payload.get("status_type", "")) != reaction.status.status_type:
			continue
		if status_target.status_stack_count(reaction.status.status_type) < reaction.status_stack_threshold:
			continue
		_apply_reaction(log, parent_entry_id, owner, status_target, reaction.trigger, status_payload, context)


static func apply_enemy_death_status_reactions(log, parent_entry_id: int, defeated_unit, defeat_payload: Dictionary, context = null) -> void:
	if context == null or defeated_unit == null:
		return
	for owner in context.units:
		if owner == null or not owner.is_alive() or owner.team == defeated_unit.team:
			continue
		var reaction: ReactionDefinition = owner.current_reaction
		if reaction == null or reaction.trigger != TRIGGER_ENEMY_DIED_WITH_STATUS or reaction.status == null:
			continue
		var stacks := _snapshot_status_stacks(defeat_payload.get("statuses", []), reaction.status.status_type)
		if stacks <= 0:
			continue
		var payload := defeat_payload.duplicate(true)
		payload["status_type"] = reaction.status.status_type
		payload["status_stacks"] = stacks
		_apply_reaction(log, parent_entry_id, owner, defeated_unit, reaction.trigger, payload, context)


static func _apply_reaction(log, parent_entry_id: int, owner, other, trigger: String, trigger_payload: Dictionary, context = null) -> bool:
	var reaction: ReactionDefinition = owner.current_reaction
	if reaction == null or (reaction.amount == 0 and reaction.effects.is_empty() and reaction.replacement_statuses.is_empty() and reaction.trigger != TRIGGER_ATTACK_TARGETS_ANOTHER_ALLY):
		return false
	if reaction.trigger != trigger or not _reaction_can_fire(owner, reaction, trigger_payload):
		return false
	var reaction_request_id := -1
	if context != null:
		var request: Dictionary = context.request("reaction_requested", owner, other, {
			"reaction": reaction.display_name,
			"reaction_type": reaction.reaction_type,
			"prevented": false,
		}, -1, parent_entry_id, ["reaction", "request"])
		if bool(request["payload"].get("prevented", false)):
			context.publish("reaction_suppressed", owner, other, {
				"reaction": reaction.display_name,
				"reason": String(request["payload"].get("prevented_reason", "prevented")),
			}, int(request["id"]), parent_entry_id, ["reaction", "status"])
			return false
		reaction_request_id = int(request["id"])
	_mark_reaction_fired(owner, reaction)
	if context != null:
		var reaction_payload := trigger_payload.duplicate(true)
		reaction_payload.merge({"reaction": reaction.display_name, "reaction_type": reaction.reaction_type, "trigger": trigger}, true)
		context.publish("reaction_triggered", owner, other, reaction_payload, reaction_request_id, parent_entry_id, ["reaction"])
	if reaction.reaction_type == REACTION_GAIN_ARMOR:
		owner.guard_armor += reaction.amount
		var armor_event := CombatEventsScript.job_effect(owner, reaction.display_name, "+%d temporary armor" % reaction.amount)
		log.add_event("Reaction %s: %s gains %d temporary armor." % [reaction.display_name, owner.unit_name, reaction.amount], armor_event["event_type"], -1, parent_entry_id, armor_event["payload"], armor_event["tags"])
		if context != null:
			context.publish("armor_gained", owner, owner, {"amount": reaction.amount, "armor_kind": "temporary"}, -1, parent_entry_id, ["armor", "reaction"])
	elif reaction.reaction_type == REACTION_HEAL_SELF:
		if context != null:
			context.apply_healing(owner, owner, reaction.amount, -1, parent_entry_id, ["reaction"])
		else:
			var previous_hp: int = owner.hp
			owner.hp = min(owner.max_hp, owner.hp + reaction.amount)
			var heal_event := CombatEventsScript.job_effect(owner, reaction.display_name, "HP %d -> %d" % [previous_hp, owner.hp])
			log.add_event("Reaction %s: %s HP %d -> %d." % [reaction.display_name, owner.unit_name, previous_hp, owner.hp], heal_event["event_type"], -1, parent_entry_id, heal_event["payload"], heal_event["tags"])
	elif reaction.reaction_type == REACTION_DAMAGE_ATTACKER and other != null:
		if context != null:
			context.apply_direct_damage(owner, other, reaction.amount, -1, parent_entry_id, ["reaction"])
		else:
			var previous_other_hp: int = other.hp
			other.hp = max(0, other.hp - reaction.amount)
			StatusResolverScript.record_damage(other, previous_other_hp - other.hp)
			var damage_event := CombatEventsScript.job_effect(owner, reaction.display_name, "%s HP %d -> %d" % [other.unit_name, previous_other_hp, other.hp])
			log.add_event("Reaction %s: %s HP %d -> %d." % [reaction.display_name, other.unit_name, previous_other_hp, other.hp], damage_event["event_type"], -1, parent_entry_id, damage_event["payload"], damage_event["tags"])
	return true


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


static func _reaction_can_fire(owner, reaction: ReactionDefinition, trigger_payload := {}) -> bool:
	if reaction.trigger == TRIGGER_HP_BELOW_THRESHOLD or reaction.condition == CONDITION_SELF_HP_BELOW_PERCENT:
		if owner.hp * 100 > owner.max_hp * reaction.threshold_percent:
			return false
	if reaction.condition == "Self Status Stacks At Least":
		if reaction.status == null or owner.status_stack_count(reaction.status.status_type) < reaction.status_stack_threshold:
			return false
	if reaction.condition == CONDITION_REQUESTED_STATUS_IS_AILMENT and String(trigger_payload.get("polarity", "")) != "Ailment":
		return false
	if reaction.condition == "Requested Status Matches":
		if reaction.status == null or String(trigger_payload.get("status_type", "")) != reaction.status.status_type:
			return false
	return owner.ability_is_ready(_reaction_key(reaction))


static func _mark_reaction_fired(owner, reaction: ReactionDefinition) -> void:
	owner.start_ability_cooldown(_reaction_key(reaction), reaction.cooldown_turns)


static func _prevent_request(request_payload: Dictionary, reaction: ReactionDefinition) -> void:
	request_payload["prevented"] = true
	request_payload["prevented_reason"] = reaction.display_name


static func _passive_key(passive: PassiveDefinition) -> String:
	return "passive|%s|%s" % [passive.passive_type, passive.display_name]


static func _reaction_key(reaction: ReactionDefinition) -> String:
	return "reaction|%s|%s" % [reaction.trigger, reaction.display_name]


static func _snapshot_status_stacks(snapshots: Array, status_type: String) -> int:
	for snapshot: Dictionary in snapshots:
		if String(snapshot.get("status_type", "")) == status_type:
			return int(snapshot.get("stack_count", 0))
	return 0
