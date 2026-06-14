extends RefCounted
class_name StatusResolver

const STATUS_CONFUSION := "Confusion"
const STATUS_TYPE_RECONSTITUTION := "Reconstitution"
const STATUS_TYPE_REGENERATION := "Regeneration"
const STATUS_TYPE_BLEED := "Bleed"
const STATUS_TYPE_NUMB := "Numb"
const STATUS_TYPE_FROST := "Frost"
const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")


static func apply_status(log, parent_entry_id: int, target, status: Resource, source_name: String, duration_turns := 3, is_permanent := false, context = null, source = null, parent_event_id := -1, stack_count := 1) -> bool:
	if target == null:
		return false
	if status == null:
		log.add_child(parent_entry_id, "%s cannot apply a missing status definition." % source_name)
		return false
	var request_event_id := -1
	var previous_stack_count: int = int(target.status_stack_count(status.status_type))
	if context != null:
		var request: Dictionary = context.request("status_application_requested", source, target, {
			"status": status.display_name,
			"status_type": status.status_type,
			"polarity": status.polarity,
			"prevented": false,
		}, parent_event_id, parent_entry_id, ["status", "request"])
		if bool(request["payload"].get("prevented", false)):
			context.publish("status_application_prevented", source, target, {
				"status": status.display_name,
				"reason": String(request["payload"].get("prevented_reason", "prevented")),
			}, int(request["id"]), parent_entry_id, ["status", "prevented"])
			return false
		request_event_id = int(request["id"])
	var result := "invalid"
	for _stack in range(max(1, stack_count)):
		var application_result: String = target.add_status(status, source_name, duration_turns, is_permanent)
		if application_result == "ignored":
			if result == "invalid":
				result = application_result
			break
		result = application_result
	if result == "invalid":
		return false
	if result == "ignored":
		log.add_child(parent_entry_id, "%s already has %s; this status ignores reapplication." % [target.unit_name, status.display_name])
		return false
	var instance: Dictionary = target.status_instance_by_name(status.display_name)
	var resulting_stack_count := int(instance.get("stack_count", 1))
	var added_stack_count: int = max(0, resulting_stack_count - previous_stack_count)
	var resulting_duration := int(instance.get("remaining_turns", duration_turns))
	var resulting_permanent := bool(instance.get("is_permanent", is_permanent))
	var event := CombatEventsScript.status_applied(target, status, source_name, resulting_duration, resulting_permanent, result, resulting_stack_count)
	var duration_text := "permanently" if resulting_permanent else "for %d turns" % resulting_duration
	var verb := "intensifies" if result == "intensified" else ("refreshes" if result == "refreshed" else "gains")
	var stack_text := ""
	if status.stacking_rule == "Intensify":
		stack_text = " at %d/%d stacks" % [resulting_stack_count, status.max_stacks] if status.stack_cap_enabled else " at %d stacks" % resulting_stack_count
	log.add_event("%s %s %s %s%s from %s %s." % [target.unit_name, verb, status.polarity.to_lower(), status.display_name, stack_text, source_name, duration_text], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
	if context != null:
		context.publish("status_applied", source, target, {
			"status": status.display_name,
			"status_type": status.status_type,
			"polarity": status.polarity,
			"application_result": result,
			"stack_count": resulting_stack_count,
			"added_stack_count": added_stack_count,
			"source_name": source_name,
		}, request_event_id, parent_entry_id, ["status", status.polarity.to_lower()])
	return true


static func remove_status(log, parent_entry_id: int, target, status_name: String, reason: String, context = null, source = null, parent_event_id := -1) -> bool:
	var request_event_id := parent_event_id
	var requested_instance: Dictionary = target.status_instance_by_name(status_name)
	var requested_status: Resource = requested_instance.get("definition", null)
	if context != null:
		var request: Dictionary = context.request("status_removal_requested", source, target, {
			"status": status_name,
			"status_type": requested_status.status_type if requested_status != null else "",
			"polarity": requested_status.polarity if requested_status != null else "",
			"reason": reason,
			"prevented": false,
		}, parent_event_id, parent_entry_id, ["status", "request"])
		if bool(request["payload"].get("prevented", false)):
			return false
		request_event_id = int(request["id"])
	var instance: Dictionary = target.remove_status(status_name)
	if instance.is_empty():
		return false
	var status: Resource = instance.get("definition", null)
	if status == null:
		return false
	var event := CombatEventsScript.status_expired(target, status)
	log.add_event("%s %s is removed from %s by %s." % [status.polarity, status.display_name, target.unit_name, reason], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
	if context != null:
		context.publish("status_removed", source, target, {
			"status": status.display_name,
			"status_type": status.status_type,
			"polarity": status.polarity,
			"reason": reason,
		}, request_event_id, parent_entry_id, ["status", "removed", status.polarity.to_lower()])
	return true


static func record_damage(target, damage_taken: int) -> void:
	if target == null or damage_taken <= 0:
		return
	var instance: Dictionary = target.status_instance(STATUS_TYPE_RECONSTITUTION)
	if instance.is_empty():
		return
	instance["damage_since_last_turn"] = int(instance.get("damage_since_last_turn", 0)) + damage_taken


static func apply_turn_start_statuses(log, turn_entry_id: int, actor, context = null) -> void:
	var regeneration: Dictionary = actor.status_instance(STATUS_TYPE_REGENERATION)
	if not regeneration.is_empty():
		var regeneration_status: Resource = regeneration.get("definition", null)
		var regeneration_amount := int(regeneration_status.amount) * int(regeneration.get("stack_count", 1)) if regeneration_status != null else 0
		if regeneration_amount > 0:
			if context != null:
				context.apply_healing(actor, actor, regeneration_amount, -1, turn_entry_id, ["status", "regeneration"])
			else:
				actor.hp = min(actor.max_hp, actor.hp + regeneration_amount)
	var instance: Dictionary = actor.status_instance(STATUS_TYPE_RECONSTITUTION)
	if instance.is_empty():
		return
	var damage_received := int(instance.get("damage_since_last_turn", 0))
	instance["damage_since_last_turn"] = 0
	if damage_received <= 0 or actor.hp >= actor.max_hp:
		return
	var status: Resource = instance.get("definition", null)
	if status == null:
		return
	var stack_count := int(instance.get("stack_count", 1))
	var recovery_percent := _reconstitution_percent(status.amount_percent, stack_count)
	var attempted_heal := int(floor(float(damage_received * recovery_percent) / 100.0))
	if attempted_heal <= 0:
		log.add_child(turn_entry_id, "%s's Reconstitution remembers %d damage, but that is too little to restore HP." % [actor.unit_name, damage_received])
		return
	var previous_hp: int = actor.hp
	actor.hp = min(actor.max_hp, actor.hp + attempted_heal)
	var applied_heal: int = actor.hp - previous_hp
	var remaining_stacks: int = actor.consume_status_stack(status.display_name) if applied_heal > 0 else stack_count
	var event := CombatEventsScript.status_triggered(actor, status, applied_heal, previous_hp, actor.hp, damage_received, stack_count, remaining_stacks)
	var stack_result := "and is consumed" if remaining_stacks == 0 else "then falls to %d stack%s" % [remaining_stacks, "" if remaining_stacks == 1 else "s"]
	log.add_event("Boon Reconstitution (%d stacks, %d%%): %s restores %d HP from %d damage received since their previous turn, %s. HP: %d -> %d." % [stack_count, recovery_percent, actor.unit_name, applied_heal, damage_received, stack_result, previous_hp, actor.hp], event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])
	if context != null:
		var trigger_event_id: int = context.publish("status_triggered", actor, actor, {
			"status": status.display_name,
			"status_type": status.status_type,
			"amount": applied_heal,
			"stack_count": stack_count,
			"remaining_stacks": remaining_stacks,
		}, -1, turn_entry_id, ["status", status.polarity.to_lower()])
		context.publish("healing_received", actor, actor, {
			"amount": applied_heal,
			"attempted_amount": attempted_heal,
			"previous_hp": previous_hp,
			"new_hp": actor.hp,
		}, trigger_event_id, turn_entry_id, ["healing", "status"])
		if remaining_stacks == 0:
			context.publish("status_removed", actor, actor, {
				"status": status.display_name,
				"status_type": status.status_type,
				"polarity": status.polarity,
				"reason": "consumed",
			}, trigger_event_id, turn_entry_id, ["status", "removed", status.polarity.to_lower()])


static func elapse_turn_statuses(log, turn_entry_id: int, actor, active_instance_ids: Array[int], context = null) -> void:
	for instance: Dictionary in actor.elapse_status_turns(active_instance_ids):
		var status: Resource = instance.get("definition", null)
		if status == null:
			continue
		var event := CombatEventsScript.status_expired(actor, status)
		log.add_event("%s %s expires on %s." % [status.polarity, status.display_name, actor.unit_name], event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])
		if context != null:
			context.publish("status_removed", actor, actor, {
				"status": status.display_name,
				"status_type": status.status_type,
				"polarity": status.polarity,
				"reason": "expired",
			}, -1, turn_entry_id, ["status", "removed", "expired", status.polarity.to_lower()])


static func _reconstitution_percent(base_percent: int, stack_count: int) -> int:
	if stack_count >= 3:
		return 100
	if stack_count == 2:
		return 75
	return base_percent
