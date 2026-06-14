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
const EVENT_STATUS_APPLICATION_REQUESTED := "status_application_requested"
const EVENT_HEALING_REQUESTED := "healing_requested"
const EVENT_ATTACK_TARGET_REQUESTED := "attack_target_requested"
const STATUS_TYPE_BURNING := "Burning"
const STATUS_TYPE_WARD := "Ward"
const STATUS_TYPE_ROT := "Rot"
const STATUS_TYPE_RENEWAL := "Renewal"
const SCORCHED_DELAY_PER_BURN_STACK := 2


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
	elif event_type == EVENT_STATUS_APPLICATION_REQUESTED and target != null:
		if not bool(event["payload"].get("prevented", false)):
			JobEffectResolverScript.apply_status_application_reaction(context.log, parent_log_id, target, source, event["payload"], context)
		if not bool(event["payload"].get("prevented", false)) and String(event["payload"].get("polarity", "")) == "Ailment":
			var ward: Dictionary = target.status_instance(STATUS_TYPE_WARD)
			if not ward.is_empty():
				event["payload"]["prevented"] = true
				event["payload"]["prevented_reason"] = "Ward"
				_consume_status_stack(context, event, target, ward, "blocked an ailment")
	elif event_type == EVENT_HEALING_REQUESTED and target != null and not bool(event["payload"].get("prevented", false)):
		JobEffectResolverScript.apply_enemy_healing_request_reactions(context.log, parent_log_id, target, source, event["payload"], context)
	elif event_type == EVENT_ATTACK_TARGET_REQUESTED and target != null:
		var seal_source_id: String = source.consume_attack_seal() if source != null else ""
		if not seal_source_id.is_empty():
			event["payload"]["prevented"] = true
			event["payload"]["prevented_reason"] = "Attack Seal"
			context.log.add_child(parent_log_id, "%s's attack is sealed and does not occur." % source.unit_name)
		var redirector = _active_attack_redirector(context.units, source, target)
		if not bool(event["payload"].get("prevented", false)) and redirector != null:
			event["payload"]["target_unit_id"] = redirector.unit_id
			event["payload"]["redirected_by"] = "Redirect Enemy Attacks"
		elif not bool(event["payload"].get("prevented", false)):
			JobEffectResolverScript.apply_attack_target_reactions(context.log, parent_log_id, source, target, event["payload"], context)
	elif event_type == "attack_performed" and source != null and target != null:
		var count: int = source.record_attack_target(target.unit_id)
		context.publish("consecutive_attack_recorded", source, target, {"count": count}, int(event.get("id", -1)), parent_log_id, ["attack", "streak"])
	elif event_type == EVENT_DAMAGE_REQUESTED and target != null and int(event["payload"].get("physical_amount", 0)) > 0:
		_absorb_magic_damage(context, event, target)
		var frost: Dictionary = target.status_instance(StatusResolverScript.STATUS_TYPE_FROST)
		if not frost.is_empty():
			var frost_status: Resource = frost.get("definition", null)
			var physical_amount := int(event["payload"].get("physical_amount", 0))
			var bonus_percent := int(frost_status.amount_percent) * int(frost.get("stack_count", 1))
			var bonus := int(ceil(float(physical_amount * bonus_percent) / 100.0))
			event["payload"]["physical_amount"] = int(event["payload"].get("physical_amount", 0)) + bonus
			event["payload"]["amount"] = int(event["payload"].get("amount", 0)) + bonus
		_fortify_damage_request(context, event, target)
		if not bool(event["payload"].get("prevented", false)) and event.get("tags", []).has("attack"):
			JobEffectResolverScript.apply_lethal_physical_attack_reaction(context.log, parent_log_id, target, source, event["payload"], context)
	elif event_type == EVENT_DAMAGE_REQUESTED and target != null:
		_absorb_magic_damage(context, event, target)
		_fortify_damage_request(context, event, target)
	elif event_type == EVENT_ACTION_COMPLETED and source != null and source.is_alive():
		_apply_deferred_damage_tick(context, event, source)
		source.elapse_attack_redirection()
		if not source.is_alive():
			return
		var bleed: Dictionary = source.status_instance(StatusResolverScript.STATUS_TYPE_BLEED)
		if not bleed.is_empty():
			var status: Resource = bleed.get("definition", null)
			var amount := int(status.amount) * int(bleed.get("stack_count", 1))
			if amount > 0:
				context.apply_direct_damage(null, source, amount, int(event.get("id", -1)), parent_log_id, ["status", "bleed"])
		var burning: Dictionary = source.status_instance(STATUS_TYPE_BURNING)
		if not burning.is_empty():
			var burning_status: Resource = burning.get("definition", null)
			var burning_amount := int(burning_status.amount) * int(burning.get("stack_count", 1))
			if burning_amount > 0:
				context.apply_direct_damage(null, source, burning_amount, int(event.get("id", -1)), parent_log_id, ["status", "burning"])
			_consume_status_stack(context, event, source, burning, "decayed after triggering")
		source.complete_damage_action_window()
	elif event_type == "status_applied" and target != null:
		JobEffectResolverScript.apply_enemy_status_threshold_reactions(context.log, parent_log_id, target, event["payload"], context)
	elif event_type in ["healing_received", "armor_gained"] and target != null and source != null and int(event["payload"].get("amount", 0)) > 0:
		_apply_burning_support_cost(context, event, source, target)
		if event_type == "healing_received":
			_apply_rot(context, event, target)
	elif event_type == "status_removed" and target != null and String(event["payload"].get("polarity", "")) == "Ailment":
		var renewal: Dictionary = target.status_instance(STATUS_TYPE_RENEWAL)
		if not renewal.is_empty():
			var renewal_status: Resource = renewal.get("definition", null)
			var renewal_amount := int(renewal_status.amount) * int(renewal.get("stack_count", 1))
			if renewal_amount > 0:
				context.apply_healing(target, target, renewal_amount, int(event.get("id", -1)), parent_log_id, ["status", "renewal"])
	elif event_type == EVENT_DAMAGE_DEALT and target != null:
		if int(event["payload"].get("physical_amount", 0)) > 0:
			var frost: Dictionary = target.status_instance(StatusResolverScript.STATUS_TYPE_FROST)
			if not frost.is_empty():
				var frost_status: Resource = frost.get("definition", null)
				StatusResolverScript.remove_status(context.log, parent_log_id, target, frost_status.display_name, "shattered by physical damage", context, source, int(event["id"]))
		if target.is_alive():
			ItemEffectResolverScript.apply_damaged_item_effects(context.log, parent_log_id, target, source, context)
			AncestryFeatureResolverScript.apply_damaged_feature(context.log, parent_log_id, target, source, context)
			JobEffectResolverScript.apply_damage_reaction(context.log, parent_log_id, target, source, event["payload"], context)
	elif event_type == EVENT_UNIT_DEFEATED:
		JobEffectResolverScript.apply_enemy_death_status_reactions(context.log, parent_log_id, target, event["payload"], context)
		if source != null:
			ItemEffectResolverScript.apply_kill_item_effects(context.log, parent_log_id, source, context)
			AncestryFeatureResolverScript.apply_kill_feature(context.log, parent_log_id, source, context)
		if target != null:
			ItemEffectResolverScript.apply_death_item_effects(context.log, parent_log_id, target, source, context)


static func _fortify_damage_request(context, event: Dictionary, target) -> void:
	if bool(event["payload"].get("prevented", false)) or target.fortification_actions_remaining <= 0 or event.get("tags", []).has("deferred_damage"):
		return
	var amount: int = max(0, int(event["payload"].get("amount", 0)))
	if amount <= 0:
		return
	target.defer_damage(amount)
	event["payload"]["prevented"] = true
	event["payload"]["prevented_reason"] = "Fortified"
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s defers %d damage through Fortified." % [target.unit_name, amount])


static func _absorb_magic_damage(context, event: Dictionary, target) -> void:
	var magic_amount: int = max(0, int(event["payload"].get("magic_amount", 0)))
	var absorbed: int = target.absorb_magic_damage(magic_amount)
	if absorbed <= 0:
		return
	event["payload"]["magic_amount"] = magic_amount - absorbed
	event["payload"]["amount"] = max(0, int(event["payload"].get("amount", 0)) - absorbed)
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s's Energy Shield absorbs %d magic damage; %d remains." % [target.unit_name, absorbed, target.energy_shield])
	context.publish("energy_shield_absorbed", target, target, {"amount": absorbed, "remaining": target.energy_shield}, int(event.get("id", -1)), int(event.get("parent_log_id", -1)), ["energy_shield", "magic"])


static func _apply_deferred_damage_tick(context, event: Dictionary, target) -> void:
	var amount: int = target.take_deferred_damage_tick()
	if amount > 0:
		context.apply_direct_damage(null, target, amount, int(event.get("id", -1)), int(event.get("parent_log_id", -1)), ["deferred_damage"])


static func _active_attack_redirector(units: Array, attacker, requested_target):
	if attacker == null or requested_target == null:
		return null
	for unit in units:
		if unit != requested_target and unit.team == requested_target.team and unit.team != attacker.team and unit.redirects_enemy_attacks():
			return unit
	return null


static func _apply_burning_support_cost(context, event: Dictionary, supporter, supported) -> void:
	var burning: Dictionary = supported.status_instance(STATUS_TYPE_BURNING)
	if burning.is_empty():
		return
	var stacks := int(burning.get("stack_count", 1))
	var delay := stacks * SCORCHED_DELAY_PER_BURN_STACK
	supporter.next_action_time += delay
	context.log.add_child(int(event.get("parent_log_id", -1)), "Supporting Burning %s scorches %s, delaying their next action by %d." % [supported.unit_name, supporter.unit_name, delay])
	var scorched_event_id: int = context.publish("scorched", supported, supporter, {
		"amount": delay,
		"burn_stacks": stacks,
		"new_time": supporter.next_action_time,
	}, int(event["id"]), int(event.get("parent_log_id", -1)), ["consequence", "timeline", "burn"])
	context.publish("action_delayed", supported, supporter, {"amount": delay, "reason": "Scorched", "new_time": supporter.next_action_time}, scorched_event_id, int(event.get("parent_log_id", -1)), ["consequence", "timeline"])


static func _apply_rot(context, event: Dictionary, target) -> void:
	var rot: Dictionary = target.status_instance(STATUS_TYPE_ROT)
	if rot.is_empty():
		return
	var status: Resource = rot.get("definition", null)
	var amount := int(status.amount) * int(rot.get("stack_count", 1))
	if amount <= 0:
		return
	var previous_max_hp: int = target.max_hp
	var previous_hp: int = target.hp
	target.max_hp = max(1, target.max_hp - amount)
	target.hp = min(target.hp, target.max_hp)
	rot["max_hp_lost"] = int(rot.get("max_hp_lost", 0)) + previous_max_hp - target.max_hp
	context.log.add_child(int(event.get("parent_log_id", -1)), "Rot reduces %s's maximum HP %d -> %d after healing." % [target.unit_name, previous_max_hp, target.max_hp])
	context.publish("max_hp_changed", target, target, {"amount": target.max_hp - previous_max_hp, "previous": previous_max_hp, "new": target.max_hp, "reason": "Rot"}, int(event["id"]), int(event.get("parent_log_id", -1)), ["status", "rot"])
	if target.hp < previous_hp:
		context.record_damage(null, target, previous_hp - target.hp, previous_hp, 0, previous_hp - target.hp, int(event["id"]), int(event.get("parent_log_id", -1)), ["status", "rot"])


static func _consume_status_stack(context, event: Dictionary, target, instance: Dictionary, reason: String) -> void:
	var status: Resource = instance.get("definition", null)
	if status == null:
		return
	var previous_stacks := int(instance.get("stack_count", 1))
	target.consume_status_stack(status.display_name)
	var remaining_stacks := previous_stacks - 1
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s consumes one stack of %s from %s (%d remaining)." % [reason.capitalize(), status.display_name, target.unit_name, remaining_stacks])
	context.publish("status_stacks_consumed", target, target, {"status": status.display_name, "amount": 1, "reason": reason}, int(event["id"]), int(event.get("parent_log_id", -1)), ["status", "consumed"])
	if previous_stacks == 1:
		context.publish("status_removed", target, target, {"status": status.display_name, "status_type": status.status_type, "polarity": status.polarity, "reason": reason}, int(event["id"]), int(event.get("parent_log_id", -1)), ["status", "removed", status.polarity.to_lower()])
