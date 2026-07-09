extends RefCounted
class_name TriggeredEffectAmounts

const TriggeredEffectTargetingScript := preload("res://scripts/combat/rules/triggered_effect_targeting.gd")


static func effect_amount(event: Dictionary, owner, target, effect: EffectDefinition, context = null) -> int:
	var value := effect.status_stacks if effect.effect_type == "Apply Status" and effect.amount_source == "Fixed" else effect.amount
	var divisor := effect.amount_divisor
	var formula_status: StatusDefinition = effect.amount_status if effect.amount_status != null else effect.status
	match effect.amount_source:
		"Target Current HP":
			value = target.hp if target != null else 0
		"Target Max HP":
			value = target.max_hp if target != null else 0
		"Target Max HP Times Event Status Stacks":
			value = target.max_hp * int(event["payload"].get("status_stacks", 0)) if target != null else 0
		"Target Recent Damage":
			value = target.recent_damage() if target != null else 0
		"Target Damage Taken Within Interval":
			value = context.target_damage_taken_within_interval(target, effect.interval_time) if context != null else 0
		"Total Allied Magic Damage Taken Within Interval":
			value = context.allied_magic_damage_taken_within_interval(owner, effect.interval_time) if context != null else 0
		"Target Predicted Next Action Damage":
			value = context.predicted_next_action_damage(target) if context != null else 0
		"Target Ailment Stacks":
			value = TriggeredEffectTargetingScript.status_stacks_by_polarity(target, "Ailment")
		"Target Unique Boons":
			value = TriggeredEffectTargetingScript.unique_statuses_by_polarity(target, "Boon")
		"Target Status Stacks":
			value = target.status_stack_count(formula_status.status_type) if target != null and formula_status != null else 0
		"Event Target Status Stacks":
			var event_target = event.get("target", null)
			value = event_target.status_stack_count(formula_status.status_type) if event_target != null and formula_status != null else 0
		"Defeated Target Status Stacks":
			value = TriggeredEffectTargetingScript.snapshot_status_stacks(event["payload"].get("statuses", []), formula_status.status_type) if formula_status != null else int(event["payload"].get("status_stacks", 0))
		"Applied Status Stacks":
			value = int(event["payload"].get("added_stack_count", 0))
		"Total Status Stacks On Selected Group":
			value = TriggeredEffectTargetingScript.total_status_stacks(TriggeredEffectTargetingScript.amount_targets(context, owner, effect.amount_target_selector), formula_status)
		"Total Status Max HP Loss On Selected Group":
			value = TriggeredEffectTargetingScript.total_status_max_hp_loss(TriggeredEffectTargetingScript.amount_targets(context, owner, effect.amount_target_selector), formula_status)
		"Target Pending Status Damage":
			value = target.pending_status_damage(formula_status.status_type) if target != null and formula_status != null else 0
		"Target Action Speed":
			value = target.action_speed if target != null else 0
		"Event Amount":
			value = int(event["payload"].get("amount", 0))
		"Overhealing":
			value = max(0, int(event["payload"].get("attempted_amount", 0)) - int(event["payload"].get("amount", 0)))
		"Overhealing Diminishing":
			value = max(0, int(event["payload"].get("attempted_amount", 0)) - int(event["payload"].get("amount", 0)))
			divisor += target.counter_value(effect.counter_name) if target != null else 0
		"Owner Counter":
			value = owner.counter_value(effect.counter_name) if owner != null else 0
		"Target Counter":
			value = target.counter_value(effect.counter_name) if target != null else 0
	var scaled := float(value * effect.amount_multiplier) / float(max(1, divisor))
	var result := int(ceil(scaled)) if effect.amount_rounding == "Ceil" else int(floor(scaled))
	return result if effect.amount_source == "Fixed" else max(0, result)
