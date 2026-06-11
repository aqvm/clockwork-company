extends RefCounted
class_name CombatHookResolver

const ItemEffectResolverScript := preload("res://scripts/combat/rules/item_effect_resolver.gd")
const AncestryFeatureResolverScript := preload("res://scripts/combat/rules/ancestry_feature_resolver.gd")
const JobEffectResolverScript := preload("res://scripts/combat/rules/job_effect_resolver.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const TriggeredEffectResolverScript := preload("res://scripts/combat/rules/triggered_effect_resolver.gd")

const EVENT_DAMAGE_DEALT := "damage_dealt"
const EVENT_UNIT_DEFEATED := "unit_defeated"
const EVENT_ACTION_COMPLETED := "action_completed"
const EVENT_BATTLE_STARTED := "battle_started"
const EVENT_REACTION_REQUESTED := "reaction_requested"
const EVENT_DAMAGE_REQUESTED := "damage_requested"


static func respond(context, event: Dictionary) -> void:
	TriggeredEffectResolverScript.respond(context, event)
	var event_type := String(event.get("type", ""))
	var source = event.get("source", null)
	var target = event.get("target", null)
	var parent_log_id := int(event.get("parent_log_id", -1))
	if event_type == EVENT_BATTLE_STARTED:
		ItemEffectResolverScript.apply_battle_start_item_effects(context.log, context.units, parent_log_id, context)
		AncestryFeatureResolverScript.apply_battle_start_features(context.log, context.units, parent_log_id, context)
	elif event_type == EVENT_REACTION_REQUESTED and source != null:
		if not source.status_instance(StatusResolverScript.STATUS_TYPE_NUMB).is_empty():
			event["payload"]["prevented"] = true
			event["payload"]["prevented_reason"] = "Numb"
	elif event_type == EVENT_DAMAGE_REQUESTED and target != null and int(event["payload"].get("physical_amount", 0)) > 0:
		var frost: Dictionary = target.status_instance(StatusResolverScript.STATUS_TYPE_FROST)
		if not frost.is_empty():
			var frost_status: Resource = frost.get("definition", null)
			var bonus := int(frost_status.amount) * int(frost.get("stack_count", 1))
			event["payload"]["physical_amount"] = int(event["payload"].get("physical_amount", 0)) + bonus
			event["payload"]["amount"] = int(event["payload"].get("amount", 0)) + bonus
	elif event_type == EVENT_ACTION_COMPLETED and source != null and source.is_alive():
		var bleed: Dictionary = source.status_instance(StatusResolverScript.STATUS_TYPE_BLEED)
		if not bleed.is_empty():
			var status: Resource = bleed.get("definition", null)
			var amount := int(status.amount) * int(bleed.get("stack_count", 1))
			if amount > 0:
				context.apply_direct_damage(null, source, amount, int(event.get("id", -1)), parent_log_id, ["status", "bleed"])
	elif event_type == EVENT_DAMAGE_DEALT and target != null:
		if int(event["payload"].get("physical_amount", 0)) > 0:
			var frost: Dictionary = target.status_instance(StatusResolverScript.STATUS_TYPE_FROST)
			if not frost.is_empty():
				var frost_status: Resource = frost.get("definition", null)
				StatusResolverScript.remove_status(context.log, parent_log_id, target, frost_status.display_name, "shattered by physical damage", context, source, int(event["id"]))
		if target.is_alive():
			ItemEffectResolverScript.apply_damaged_item_effects(context.log, parent_log_id, target, source, context)
			AncestryFeatureResolverScript.apply_damaged_feature(context.log, parent_log_id, target, source, context)
			JobEffectResolverScript.apply_damaged_reaction(context.log, parent_log_id, target, source, context)
	elif event_type == EVENT_UNIT_DEFEATED:
		if source != null:
			ItemEffectResolverScript.apply_kill_item_effects(context.log, parent_log_id, source, context)
			AncestryFeatureResolverScript.apply_kill_feature(context.log, parent_log_id, source, context)
		if target != null:
			ItemEffectResolverScript.apply_death_item_effects(context.log, parent_log_id, target, source, context)
