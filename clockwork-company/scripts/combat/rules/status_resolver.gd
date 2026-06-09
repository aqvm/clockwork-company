extends RefCounted
class_name StatusResolver

const STATUS_CONFUSION := "Confusion"
const STATUS_TYPE_RECONSTITUTION := "Reconstitution"
const RULE_ASH_CHAPEL_CONFUSION := "ash_chapel_confusion"
const ConfusionStatus := preload("res://resources/statuses/confusion.tres")
const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")


static func apply_scenario_rule_statuses(log, units: Array, scenario_rules: Array, battle_start_entry_id: int) -> void:
	for rule in scenario_rules:
		if rule == null or String(rule.rule_id) != RULE_ASH_CHAPEL_CONFUSION:
			continue
		for unit in units:
			apply_status(log, battle_start_entry_id, unit, ConfusionStatus, rule.display_name, 1, true)


static func apply_status(log, parent_entry_id: int, target, status: Resource, source_name: String, duration_turns := 3, is_permanent := false) -> bool:
	if target == null:
		return false
	if status == null:
		log.add_child(parent_entry_id, "%s cannot apply a missing status definition." % source_name)
		return false
	var result: String = target.add_status(status, source_name, duration_turns, is_permanent)
	if result == "invalid":
		return false
	if result == "ignored":
		log.add_child(parent_entry_id, "%s already has %s; this status ignores reapplication." % [target.unit_name, status.display_name])
		return false
	var instance: Dictionary = target.status_instance_by_name(status.display_name)
	var stack_count := int(instance.get("stack_count", 1))
	var resulting_duration := int(instance.get("remaining_turns", duration_turns))
	var resulting_permanent := bool(instance.get("is_permanent", is_permanent))
	var event := CombatEventsScript.status_applied(target, status, source_name, resulting_duration, resulting_permanent, result, stack_count)
	var duration_text := "permanently" if resulting_permanent else "for %d turns" % resulting_duration
	var verb := "intensifies" if result == "intensified" else ("refreshes" if result == "refreshed" else "gains")
	var stack_text := " at %d/%d stacks" % [stack_count, status.max_stacks] if status.max_stacks > 1 else ""
	log.add_event("%s %s %s %s%s from %s %s." % [target.unit_name, verb, status.polarity.to_lower(), status.display_name, stack_text, source_name, duration_text], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
	return true


static func record_damage(target, damage_taken: int) -> void:
	if target == null or damage_taken <= 0:
		return
	var instance: Dictionary = target.status_instance(STATUS_TYPE_RECONSTITUTION)
	if instance.is_empty():
		return
	instance["damage_since_last_turn"] = int(instance.get("damage_since_last_turn", 0)) + damage_taken


static func apply_turn_start_statuses(log, turn_entry_id: int, actor) -> void:
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


static func elapse_turn_statuses(log, turn_entry_id: int, actor, active_instance_ids: Array[int]) -> void:
	for instance: Dictionary in actor.elapse_status_turns(active_instance_ids):
		var status: Resource = instance.get("definition", null)
		if status == null:
			continue
		var event := CombatEventsScript.status_expired(actor, status)
		log.add_event("%s %s expires on %s." % [status.polarity, status.display_name, actor.unit_name], event["event_type"], -1, turn_entry_id, event["payload"], event["tags"])


static func _reconstitution_percent(base_percent: int, stack_count: int) -> int:
	if stack_count >= 3:
		return 100
	if stack_count == 2:
		return 75
	return base_percent
