extends RefCounted
class_name TriggeredEffectResolver

const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")

const SHARED_EFFECT_TYPES := ["Apply Status", "Maintain Status Aura", "Replace Requested Status", "Remove Status", "Consume Status", "Detonate Status", "Gather Status", "Transfer Statuses", "Restore Max HP Lost To Status", "Deal Damage", "Heal", "Grant Armor", "Grant Battle Armor", "Grant Energy Shield", "Disable Armor", "Delay Action", "Hasten Action", "Hasten Action For Battle", "Fortify Damage", "Redirect Enemy Attacks", "Add Attack Damage", "Modify Stat", "Modify Counter", "Reset Counter", "Seal Next Attack", "Prevent Request"]


static func respond(context, event: Dictionary) -> void:
	var event_type := String(event.get("type", ""))
	if event_type == "turn_completed":
		_elapse_modifiers(context, event)
	for unit in context.units:
		for item in unit.equipped_items:
			for effect in item.effects:
				if _can_resolve(context, event, unit, effect, item.display_name):
					_resolve(context, event, unit, effect, item.display_name, ["item"])
		for skill in [unit.current_skill, unit.assigned_skill]:
			if skill == null or String(event["payload"].get("skill", "")) != skill.display_name:
				continue
			for effect in skill.effects:
				if _can_resolve(context, event, unit, effect, skill.display_name):
					_resolve(context, event, unit, effect, skill.display_name, ["skill"])
		if unit.current_passive != null:
			for effect in unit.current_passive.effects:
				if _can_resolve(context, event, unit, effect, unit.current_passive.display_name):
					_resolve(context, event, unit, effect, unit.current_passive.display_name, ["passive"])
		if unit.current_reaction != null:
			for effect in unit.current_reaction.effects:
				if _can_resolve(context, event, unit, effect, unit.current_reaction.display_name):
					_resolve(context, event, unit, effect, unit.current_reaction.display_name, ["reaction"])
	for rule in context.scenario_rules:
		if rule == null:
			continue
		for effect in rule.effects:
			if _can_resolve(context, event, null, effect, rule.display_name):
				_resolve(context, event, null, effect, rule.display_name, ["scenario"])


static func _can_resolve(context, event: Dictionary, owner, effect: EffectDefinition, source_name: String) -> bool:
	if effect == null or not SHARED_EFFECT_TYPES.has(effect.effect_type):
		return false
	if not _trigger_matches(event, owner, effect.trigger):
		return false
	if not _condition_matches(event, owner, effect):
		return false
	if effect.ignore_events_from_same_effect_source and String(event["payload"].get("source_name", "")) == source_name:
		return false
	var key := _usage_key(event, owner, effect, source_name)
	if context.triggered_effect_root_usage.has(key):
		return false
	if effect.once_per_battle and context.triggered_effect_battle_usage.has(_battle_usage_key(owner, effect, source_name)):
		return false
	return true


static func _resolve(context, event: Dictionary, owner, effect: EffectDefinition, source_name: String, source_tags: Array) -> void:
	context.triggered_effect_root_usage[_usage_key(event, owner, effect, source_name)] = true
	if effect.once_per_battle:
		context.triggered_effect_battle_usage[_battle_usage_key(owner, effect, source_name)] = true
	var targets := _targets(context, event, owner, effect.target_selector)
	for target in targets:
		if target == null:
			continue
		var effect_event_id: int = context.publish("triggered_effect_resolved", owner, target, {
			"source_name": source_name,
			"effect_name": effect.display_name,
			"effect_type": effect.effect_type,
			"trigger": effect.trigger,
		}, int(event.get("id", -1)), int(event.get("parent_log_id", -1)), source_tags + ["triggered_effect"])
		if effect.effect_type == "Apply Status":
			var stack_count: int = _effect_amount(event, owner, target, effect, context)
			if stack_count <= 0:
				continue
			StatusResolverScript.apply_status(
				context.log,
				int(event.get("parent_log_id", -1)),
				target,
				effect.status,
				source_name,
				effect.status_duration_turns,
				effect.status_is_permanent,
				context,
				owner,
				effect_event_id,
				stack_count
			)
		elif effect.effect_type == "Maintain Status Aura":
			_maintain_status_aura(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Replace Requested Status":
			_replace_requested_status(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Remove Status":
			_remove_status(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Modify Stat":
			_apply_modifier(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Consume Status":
			_consume_status(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Detonate Status":
			_detonate_status(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Gather Status":
			_gather_status(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Transfer Statuses":
			_transfer_statuses(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Restore Max HP Lost To Status":
			_restore_max_hp_lost_to_status(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Modify Counter":
			_modify_counter(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Reset Counter":
			target.reset_counter(effect.counter_name)
			context.publish("counter_changed", owner, target, {"counter": effect.counter_name, "amount": 0, "new": 0}, effect_event_id, int(event.get("parent_log_id", -1)), ["counter"])
		elif effect.effect_type == "Seal Next Attack":
			if owner != null and target.add_attack_seal(owner.unit_id):
				owner.reset_attack_streak()
				context.log.add_child(int(event.get("parent_log_id", -1)), "%s seals %s's next attack." % [source_name, target.unit_name])
				context.publish("attack_sealed", owner, target, {"source_name": source_name}, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + ["attack", "seal"])
		elif effect.effect_type == "Prevent Request":
			event["payload"]["prevented"] = true
			event["payload"]["prevented_reason"] = source_name
		elif effect.effect_type == "Add Attack Damage":
			event["payload"]["bonus_damage"] = int(event["payload"].get("bonus_damage", 0)) + _effect_amount(event, owner, target, effect, context)
		elif effect.effect_type == "Deal Damage":
			var damage_amount := _effect_amount(event, owner, target, effect, context)
			if effect.damage_type == "Physical":
				context.apply_physical_damage(owner, target, damage_amount, effect_event_id, int(event.get("parent_log_id", -1)), source_tags)
			else:
				context.apply_direct_damage(owner, target, damage_amount, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + [effect.damage_type.to_lower()])
		elif effect.effect_type == "Heal":
			context.apply_healing(owner if owner != null else target, target, _effect_amount(event, owner, target, effect, context), effect_event_id, int(event.get("parent_log_id", -1)), source_tags)
		elif effect.effect_type == "Grant Armor":
			var armor_amount := _effect_amount(event, owner, target, effect, context)
			if armor_amount <= 0:
				continue
			target.guard_armor += armor_amount
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s grants %s %d temporary armor." % [source_name, target.unit_name, armor_amount])
			context.publish("armor_gained", owner, target, {"amount": armor_amount, "armor_kind": "temporary"}, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + ["armor"])
		elif effect.effect_type == "Grant Battle Armor":
			var battle_armor_amount := _effect_amount(event, owner, target, effect, context)
			if battle_armor_amount <= 0:
				continue
			target.battle_armor += battle_armor_amount
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s grants %s %d armor for this battle." % [source_name, target.unit_name, battle_armor_amount])
			context.publish("armor_gained", owner, target, {"amount": battle_armor_amount, "armor_kind": "battle"}, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + ["armor"])
		elif effect.effect_type == "Grant Energy Shield":
			var shield_amount := _effect_amount(event, owner, target, effect, context)
			if shield_amount <= 0:
				continue
			var new_shield: int = target.add_energy_shield(shield_amount)
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s grants %s %d Energy Shield; total %d." % [source_name, target.unit_name, shield_amount, new_shield])
			context.publish("energy_shield_gained", owner, target, {"amount": shield_amount, "new": new_shield}, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + ["energy_shield"])
		elif effect.effect_type == "Disable Armor":
			target.armor_disabled = true
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s prevents %s from benefiting from armor." % [source_name, target.unit_name])
			context.publish("armor_disabled", owner, target, {"source_name": source_name}, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + ["armor"])
		elif effect.effect_type == "Delay Action":
			var delay_amount := _effect_amount(event, owner, target, effect, context)
			if delay_amount <= 0 or not target.is_alive():
				continue
			target.next_action_time += delay_amount
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s delays %s's next action by %d." % [source_name, target.unit_name, delay_amount])
			context.publish("action_delayed", owner, target, {"amount": delay_amount, "reason": source_name, "new_time": target.next_action_time}, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + ["timeline"])
		elif effect.effect_type == "Hasten Action":
			_hasten_action(context, event, owner, target, effect, source_name, effect_event_id, source_tags)
		elif effect.effect_type == "Hasten Action For Battle":
			var event_source = event.get("source", null)
			var current_time: int = event_source.next_action_time if event_source != null else 0
			var applied_haste: int = target.add_battle_action_haste(_effect_amount(event, owner, target, effect, context), current_time)
			if applied_haste > 0:
				context.log.add_child(int(event.get("parent_log_id", -1)), "%s permanently hastens %s by %d for this battle." % [source_name, target.unit_name, applied_haste])
				context.publish("action_hastened", owner, target, {"amount": applied_haste, "interval_amount": applied_haste, "duration_actions": 0, "new_time": target.next_action_time}, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + ["timeline"])
		elif effect.effect_type == "Fortify Damage":
			target.begin_fortification(effect.modifier_duration_turns)
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s fortifies %s against immediate damage for %d completed actions." % [source_name, target.unit_name, effect.modifier_duration_turns])
		elif effect.effect_type == "Redirect Enemy Attacks":
			target.begin_attack_redirection(effect.modifier_duration_turns)
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s redirects enemy attacks to %s for %d completed actions." % [source_name, target.unit_name, effect.modifier_duration_turns])


static func _maintain_status_aura(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	var source_key := _aura_source_key(owner, effect, source_name)
	if owner != null and owner.is_alive():
		var result: String = target.maintain_status(effect.status, source_key, source_name)
		if result == "added":
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s's aura grants %s to %s." % [source_name, effect.status.display_name, target.unit_name])
			context.publish("status_applied", owner, target, {
				"status": effect.status.display_name,
				"status_type": effect.status.status_type,
				"polarity": effect.status.polarity,
				"application_result": "maintained",
				"stack_count": 1,
				"added_stack_count": 1,
				"source_name": source_name,
			}, effect_event_id, int(event.get("parent_log_id", -1)), ["status", "aura", effect.status.polarity.to_lower()])
	elif target.remove_maintained_status_source(effect.status.display_name, source_key):
		context.log.add_child(int(event.get("parent_log_id", -1)), "%s loses %s because %s is no longer active." % [target.unit_name, effect.status.display_name, source_name])
		context.publish("status_removed", owner, target, {
			"status": effect.status.display_name,
			"status_type": effect.status.status_type,
			"polarity": effect.status.polarity,
			"reason": "%s ended" % source_name,
		}, effect_event_id, int(event.get("parent_log_id", -1)), ["status", "aura", "removed"])


static func _replace_requested_status(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	if effect.replacement_statuses.is_empty():
		return
	event["payload"]["prevented"] = true
	event["payload"]["prevented_reason"] = source_name
	var replacement: StatusDefinition = effect.replacement_statuses[int(event.get("id", 0)) % effect.replacement_statuses.size()]
	StatusResolverScript.apply_status(context.log, int(event.get("parent_log_id", -1)), target, replacement, source_name, effect.status_duration_turns, effect.status_is_permanent, context, owner, effect_event_id)


static func _apply_modifier(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	var previous_value: int = target.stat_value(effect.modified_stat)
	var amount := _effect_amount(event, owner, target, effect, context)
	if effect.modifier_mode == "Dynamic Percent":
		if owner != null and not owner.is_alive():
			amount = 0
		var key := _dynamic_modifier_key(owner, effect, source_name)
		var base_value: int = target.stat_value_without_dynamic_modifiers(effect.modified_stat)
		var dynamic_amount := int(ceil(float(base_value * amount) / 100.0))
		if effect.modifier_direction == "Decrease":
			dynamic_amount *= -1
		var result: Dictionary = target.set_dynamic_modifier(key, effect.modified_stat, dynamic_amount, source_name)
		var new_dynamic_value: int = target.stat_value(effect.modified_stat)
		if int(result.get("delta", 0)) != 0:
			context.log.add_child(int(event.get("parent_log_id", -1)), "%s recalculates %s's %s %d -> %d (%+d%%)." % [source_name, target.unit_name, effect.modified_stat.to_lower(), previous_value, new_dynamic_value, amount])
			context.publish("dynamic_modifier_changed", owner, target, {
				"source_name": source_name,
				"stat": effect.modified_stat,
				"amount": dynamic_amount,
				"percent": amount,
				"previous": previous_value,
				"new": new_dynamic_value,
			}, effect_event_id, int(event.get("parent_log_id", -1)), ["modifier", "dynamic"])
		return
	if effect.modifier_direction == "Decrease":
		amount *= -1
	var modifier: Dictionary = target.add_temporary_modifier(effect.modified_stat, amount, effect.modifier_duration_turns, source_name)
	if modifier.is_empty():
		context.log.add_child(int(event.get("parent_log_id", -1)), "%s cannot change %s's %s any further." % [source_name, target.unit_name, effect.modified_stat.to_lower()])
		return
	var new_value: int = target.stat_value(effect.modified_stat)
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s changes %s's %s %d -> %d for %d completed turn%s." % [
		source_name,
		target.unit_name,
		effect.modified_stat.to_lower(),
		previous_value,
		new_value,
		effect.modifier_duration_turns,
		"" if effect.modifier_duration_turns == 1 else "s",
	])
	context.publish("temporary_modifier_applied", owner, target, {
		"source_name": source_name,
		"stat": effect.modified_stat,
		"amount": int(modifier.get("amount", 0)),
		"previous": previous_value,
		"new": new_value,
		"duration_turns": effect.modifier_duration_turns,
	}, effect_event_id, int(event.get("parent_log_id", -1)), ["modifier"])


static func _remove_status(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	var eligible: Array[Dictionary] = []
	for instance: Dictionary in target.statuses:
		var definition := instance.get("definition", null) as StatusDefinition
		if definition == null:
			continue
		if effect.status_polarity != "Any" and definition.polarity != effect.status_polarity:
			continue
		if effect.status_removal_mode == "Specific Status":
			if effect.status == null or definition.status_type != effect.status.status_type:
				continue
		eligible.append(instance)
	if eligible.is_empty():
		context.log.add_child(int(event.get("parent_log_id", -1)), "%s finds no matching status to remove from %s." % [source_name, target.unit_name])
		return
	var selected: Dictionary = eligible[int(event.get("id", 0)) % eligible.size()]
	var status := selected.get("definition", null) as StatusDefinition
	StatusResolverScript.remove_status(
		context.log,
		int(event.get("parent_log_id", -1)),
		target,
		status.display_name,
		source_name,
		context,
		owner,
		effect_event_id
	)


static func _consume_status(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	if effect.status == null:
		return
	var requested: int = _effect_amount(event, owner, target, effect, context)
	var previous_stacks: int = target.status_stack_count(effect.status.status_type)
	var consumed: int = target.consume_status_stacks(effect.status.display_name, requested)
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s consumes %d stack%s of %s from %s." % [source_name, consumed, "" if consumed == 1 else "s", effect.status.display_name, target.unit_name])
	context.publish("status_stacks_consumed", owner, target, {"status": effect.status.display_name, "amount": consumed}, effect_event_id, int(event.get("parent_log_id", -1)), ["status", "consumed"])
	if previous_stacks > 0 and target.status_stack_count(effect.status.status_type) == 0:
		context.publish("status_removed", owner, target, {
			"status": effect.status.display_name,
			"status_type": effect.status.status_type,
			"polarity": effect.status.polarity,
			"reason": "consumed by %s" % source_name,
		}, effect_event_id, int(event.get("parent_log_id", -1)), ["status", "removed", effect.status.polarity.to_lower()])


static func _detonate_status(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	if effect.status == null:
		return
	var damage: int = target.pending_status_damage(effect.status.status_type)
	if damage <= 0:
		return
	StatusResolverScript.remove_status(context.log, int(event.get("parent_log_id", -1)), target, effect.status.display_name, source_name, context, owner, effect_event_id)
	context.apply_direct_damage(owner, target, damage, effect_event_id, int(event.get("parent_log_id", -1)), ["status", "detonation"])


static func _gather_status(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	if effect.status == null:
		return
	var gathered := 0
	for source_target in _amount_targets(context, owner, effect.amount_target_selector):
		var stacks: int = source_target.status_stack_count(effect.status.status_type)
		if stacks <= 0:
			continue
		if StatusResolverScript.remove_status(context.log, int(event.get("parent_log_id", -1)), source_target, effect.status.display_name, source_name, context, owner, effect_event_id):
			gathered += stacks
	if gathered > 0:
		StatusResolverScript.apply_status(context.log, int(event.get("parent_log_id", -1)), target, effect.status, source_name, effect.status_duration_turns, effect.status_is_permanent, context, owner, effect_event_id, gathered)


static func _restore_max_hp_lost_to_status(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	if effect.status == null:
		return
	var instance: Dictionary = target.status_instance(effect.status.status_type)
	var restored: int = int(instance.get("max_hp_lost", 0))
	if restored <= 0:
		return
	if not StatusResolverScript.remove_status(context.log, int(event.get("parent_log_id", -1)), target, effect.status.display_name, source_name, context, owner, effect_event_id):
		return
	var previous_max_hp: int = target.max_hp
	target.max_hp += restored
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s restores %s's maximum HP %d -> %d; the restored HP is empty." % [source_name, target.unit_name, previous_max_hp, target.max_hp])
	context.publish("max_hp_changed", owner, target, {"amount": restored, "previous": previous_max_hp, "new": target.max_hp, "reason": source_name}, effect_event_id, int(event.get("parent_log_id", -1)), ["status", "restored"])


static func _modify_counter(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	var amount: int = _effect_amount(event, owner, target, effect, context)
	var value: int = target.modify_counter(effect.counter_name, amount)
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s changes %s's %s counter to %d." % [source_name, target.unit_name, effect.counter_name, value])
	context.publish("counter_changed", owner, target, {"counter": effect.counter_name, "amount": amount, "new": value}, effect_event_id, int(event.get("parent_log_id", -1)), ["counter"])


static func _transfer_statuses(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	for source_unit in _amount_targets(context, owner, effect.amount_target_selector):
		if source_unit == target:
			continue
		for instance: Dictionary in source_unit.statuses.duplicate():
			var definition: StatusDefinition = instance.get("definition", null)
			if definition == null or (effect.status_polarity != "Any" and definition.polarity != effect.status_polarity):
				continue
			var duration := int(instance.get("remaining_turns", effect.status_duration_turns))
			var permanent := bool(instance.get("is_permanent", false))
			var stacks := int(instance.get("stack_count", 1))
			if StatusResolverScript.remove_status(context.log, int(event.get("parent_log_id", -1)), source_unit, definition.display_name, source_name, context, owner, effect_event_id):
				if not StatusResolverScript.apply_status(context.log, int(event.get("parent_log_id", -1)), target, definition, source_name, duration, permanent, context, owner, effect_event_id, stacks):
					StatusResolverScript.apply_status(context.log, int(event.get("parent_log_id", -1)), source_unit, definition, source_name, duration, permanent, context, owner, effect_event_id, stacks)


static func _hasten_action(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int, source_tags: Array) -> void:
	var amount: int = _effect_amount(event, owner, target, effect, context)
	var event_source = event.get("source", null)
	var current_time: int = event_source.next_action_time if event_source != null else 0
	var previous_interval: int = target.action_interval
	var previous_time: int = target.next_action_time
	var modifier: Dictionary = target.add_capped_action_haste(amount, effect.modifier_duration_turns, source_name, effect.threshold_percent, current_time)
	if modifier.is_empty():
		return
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s hastens %s: interval %d -> %d and next action %d -> %d for %d completed actions." % [source_name, target.unit_name, previous_interval, target.action_interval, previous_time, target.next_action_time, effect.modifier_duration_turns])
	context.publish("action_hastened", owner, target, {
		"amount": previous_time - target.next_action_time,
		"interval_amount": previous_interval - target.action_interval,
		"floor_percent": effect.threshold_percent,
		"duration_actions": effect.modifier_duration_turns,
		"new_time": target.next_action_time,
	}, effect_event_id, int(event.get("parent_log_id", -1)), source_tags + ["timeline", "modifier"])


static func _elapse_modifiers(context, event: Dictionary) -> void:
	var owner = event.get("source", null)
	if owner == null:
		return
	for modifier: Dictionary in owner.elapse_temporary_modifiers():
		var stat_name := String(modifier.get("stat", ""))
		context.log.add_child(int(event.get("parent_log_id", -1)), "%s's temporary %s modifier from %s expires." % [
			owner.unit_name,
			stat_name.to_lower(),
			String(modifier.get("source_name", "an effect")),
		])
		context.publish("temporary_modifier_removed", owner, owner, {
			"source_name": String(modifier.get("source_name", "")),
			"stat": stat_name,
			"amount": int(modifier.get("amount", 0)),
			"reason": "expired",
			"new": owner.stat_value(stat_name),
		}, int(event.get("id", -1)), int(event.get("parent_log_id", -1)), ["modifier", "expired"])


static func _trigger_matches(event: Dictionary, owner, trigger: String) -> bool:
	var event_type := String(event.get("type", ""))
	var source = event.get("source", null)
	var target = event.get("target", null)
	match trigger:
		"Battle Start":
			return event_type == "battle_started"
		"Battle State Changed":
			return event_type in ["battle_started", "status_applied", "status_removed", "status_stacks_consumed", "unit_defeated"]
		"Turn Start":
			return event_type == "turn_started" and (owner == null or source == owner)
		"Turn Complete":
			return event_type == "turn_completed" and (owner == null or source == owner)
		"Action Completed":
			return event_type == "action_completed" and (owner == null or source == owner)
		"Skill Used":
			return event_type == "skill_used" and (owner == null or source == owner)
		"Skill Completed":
			return event_type == "skill_completed" and (owner == null or source == owner)
		"Healing Received":
			return event_type == "healing_received" and (owner == null or target == owner)
		"Ally Overhealed":
			return event_type == "healing_received" and owner != null and source == owner and target != null and target != owner and target.team == owner.team and int(event["payload"].get("attempted_amount", 0)) > int(event["payload"].get("amount", 0))
		"Damage Requested":
			return event_type == "damage_requested" and (owner == null or target == owner)
		"Healing Requested":
			return event_type == "healing_requested" and (owner == null or target == owner)
		"Reaction Requested":
			return event_type == "reaction_requested" and (owner == null or source == owner)
		"Status Application Requested":
			return event_type == "status_application_requested" and (owner == null or target == owner)
		"Status Removal Requested":
			return event_type == "status_removal_requested" and (owner == null or target == owner)
		"Attack":
			return event_type == "attack_performed" and (owner == null or source == owner)
		"Consecutive Attack":
			return event_type == "consecutive_attack_recorded" and (owner == null or source == owner)
		"Enemy Attack Targeted":
			return event_type == "attack_targeted" and owner != null and target == owner and source != null and source.team != owner.team
		"Hit":
			return event_type == "damage_dealt" and event.get("tags", []).has("attack") and int(event["payload"].get("amount", 0)) > 0 and (owner == null or source == owner)
		"Damaged", "HP Below Threshold":
			return event_type == "damage_dealt" and int(event["payload"].get("amount", 0)) > 0 and (owner == null or target == owner)
		"Ailment Damaged":
			return event_type == "damage_dealt" and event.get("tags", []).has("status") and int(event["payload"].get("amount", 0)) > 0 and (owner == null or target == owner)
		"Physically Damaged":
			return event_type == "damage_dealt" and int(event["payload"].get("physical_amount", 0)) > 0 and (owner == null or target == owner)
		"Magically Damaged":
			return event_type == "damage_dealt" and int(event["payload"].get("magic_amount", 0)) > 0 and (owner == null or target == owner)
		"Kill":
			return event_type == "unit_defeated" and (owner == null or source == owner)
		"Death":
			return event_type == "unit_defeated" and (owner == null or target == owner)
		"Status Applied":
			return event_type == "status_applied" and (owner == null or target == owner)
		"Externally Sourced Status Applied":
			return event_type == "status_applied" and owner != null and target == owner and source != owner
		"Enemy Status Applied":
			return event_type == "status_applied" and owner != null and target != null and owner.team != target.team
		"Status Removed":
			return event_type == "status_removed" and (owner == null or target == owner)
		"Reaction Triggered":
			return event_type == "reaction_triggered" and (owner == null or source == owner)
	return false


static func _condition_matches(event: Dictionary, owner, effect: EffectDefinition) -> bool:
	if effect.trigger == "HP Below Threshold":
		var threshold_subject = owner if owner != null else event.get("target", null)
		if threshold_subject == null or threshold_subject.hp * 100 > threshold_subject.max_hp * effect.threshold_percent:
			return false
	if effect.condition == "Self HP Below Percent":
		return owner != null and owner.hp * 100 <= owner.max_hp * effect.threshold_percent
	if effect.condition == "Event Source Is Not Owner":
		return owner != null and event.get("source", null) != owner
	if effect.condition == "Owner Is Unarmed":
		return owner != null and owner.is_unarmed()
	if effect.condition == "Event Count At Least":
		return int(event["payload"].get("count", 0)) >= effect.counter_threshold
	var target = event.get("target", null)
	if effect.condition == "Target Has Tag":
		return _target_has_any_tag(target, effect.tags)
	if effect.condition == "Target Missing Tag":
		return not _target_has_any_tag(target, effect.tags)
	if effect.condition == "Target Status Stacks At Least":
		return target != null and effect.status != null and target.status_stack_count(effect.status.status_type) >= effect.status_stack_threshold
	if effect.condition == "Target Pending Status Damage At Least HP":
		return target != null and effect.status != null and target.pending_status_damage(effect.status.status_type) >= target.hp
	if effect.condition == "Owner Counter At Least":
		return owner != null and owner.counter_value(effect.counter_name) >= effect.counter_threshold
	if effect.condition == "Target Counter At Least":
		return target != null and target.counter_value(effect.counter_name) >= effect.counter_threshold
	if effect.condition == "Requested Status Matches":
		return effect.status != null and String(event["payload"].get("status_type", "")) == effect.status.status_type
	if effect.condition == "Applied Status Matches":
		return effect.condition_status != null and String(event["payload"].get("status_type", "")) == effect.condition_status.status_type
	return true


static func _effect_amount(event: Dictionary, owner, target, effect: EffectDefinition, context = null) -> int:
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
		"Target Ailment Stacks":
			value = _status_stacks_by_polarity(target, "Ailment")
		"Target Unique Boons":
			value = _unique_statuses_by_polarity(target, "Boon")
		"Target Status Stacks":
			value = target.status_stack_count(formula_status.status_type) if target != null and formula_status != null else 0
		"Event Target Status Stacks":
			var event_target = event.get("target", null)
			value = event_target.status_stack_count(formula_status.status_type) if event_target != null and formula_status != null else 0
		"Defeated Target Status Stacks":
			value = _snapshot_status_stacks(event["payload"].get("statuses", []), formula_status.status_type) if formula_status != null else int(event["payload"].get("status_stacks", 0))
		"Applied Status Stacks":
			value = int(event["payload"].get("added_stack_count", 0))
		"Total Status Stacks On Selected Group":
			value = _total_status_stacks(_amount_targets(context, owner, effect.amount_target_selector), formula_status)
		"Total Status Max HP Loss On Selected Group":
			value = _total_status_max_hp_loss(_amount_targets(context, owner, effect.amount_target_selector), formula_status)
		"Target Pending Status Damage":
			value = target.pending_status_damage(formula_status.status_type) if target != null and formula_status != null else 0
		"Target Action Interval":
			value = target.action_interval if target != null else 0
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


static func _targets(context, event: Dictionary, owner, selector: String) -> Array:
	var source = event.get("source", null)
	var target = event.get("target", null)
	match selector:
		"Self":
			return [owner] if owner != null else []
		"Event Source", "Attacker", "Killer":
			return [source] if source != null else []
		"Event Target", "Attack Target":
			return [target] if target != null else []
		"All Units":
			return _living_units(context.units)
		"Allied Units":
			return _living_team_units(context.units, owner.team if owner != null else "Allies")
		"Enemy Units":
			return _living_team_units(context.units, _other_team(owner.team) if owner != null else "Enemies")
		"Lowest HP Allied Unit":
			return _lowest_hp_unit(_living_team_units(context.units, owner.team if owner != null else "Allies"))
		"Random Allied Unit":
			return _one_deterministic(_living_team_units(context.units, owner.team if owner != null else "Allies"), int(event.get("id", 0)))
		"Random Damaged Allied Unit":
			return _one_deterministic(_living_damaged_team_units(context.units, owner.team if owner != null else "Allies"), int(event.get("id", 0)))
		"Random Enemy Unit":
			return _one_deterministic(_living_team_units(context.units, _other_team(owner.team) if owner != null else "Enemies"), int(event.get("id", 0)))
	return []


static func _living_team_units(units: Array, team: String) -> Array:
	var matches: Array = []
	for unit in units:
		if unit.team == team and unit.is_alive():
			matches.append(unit)
	return matches


static func _living_units(units: Array) -> Array:
	var matches: Array = []
	for unit in units:
		if unit.is_alive():
			matches.append(unit)
	return matches


static func _living_damaged_team_units(units: Array, team: String) -> Array:
	var matches: Array = []
	for unit in units:
		if unit.team == team and unit.is_alive() and unit.hp < unit.max_hp:
			matches.append(unit)
	return matches


static func _one_deterministic(candidates: Array, event_id: int) -> Array:
	if candidates.is_empty():
		return []
	return [candidates[event_id % candidates.size()]]


static func _lowest_hp_unit(candidates: Array) -> Array:
	if candidates.is_empty():
		return []
	var lowest = candidates[0]
	for candidate in candidates:
		if candidate.hp < lowest.hp:
			lowest = candidate
	return [lowest]


static func _other_team(team: String) -> String:
	return "Enemies" if team == "Allies" else "Allies"


static func _amount_targets(context, owner, selector: String) -> Array:
	if context == null:
		return []
	match selector:
		"Self":
			return [owner] if owner != null else []
		"All Units":
			return _living_units(context.units)
		"Allied Units":
			return _living_team_units(context.units, owner.team if owner != null else "Allies")
		"Enemy Units":
			return _living_team_units(context.units, _other_team(owner.team) if owner != null else "Enemies")
	return []


static func _total_status_stacks(units: Array, status: StatusDefinition) -> int:
	if status == null:
		return 0
	var total := 0
	for unit in units:
		total += unit.status_stack_count(status.status_type)
	return total


static func _total_status_max_hp_loss(units: Array, status: StatusDefinition) -> int:
	if status == null:
		return 0
	var total := 0
	for unit in units:
		total += int(unit.status_instance(status.status_type).get("max_hp_lost", 0))
	return total


static func _status_stacks_by_polarity(target, polarity: String) -> int:
	if target == null:
		return 0
	var total := 0
	for instance: Dictionary in target.statuses:
		var definition: StatusDefinition = instance.get("definition", null)
		if definition != null and definition.polarity == polarity:
			total += int(instance.get("stack_count", 1))
	return total


static func _snapshot_status_stacks(snapshots: Array, status_type: String) -> int:
	for snapshot: Dictionary in snapshots:
		if String(snapshot.get("status_type", "")) == status_type:
			return int(snapshot.get("stack_count", 0))
	return 0


static func _unique_statuses_by_polarity(target, polarity: String) -> int:
	if target == null:
		return 0
	var unique_types := {}
	for instance: Dictionary in target.statuses:
		var definition: StatusDefinition = instance.get("definition", null)
		if definition != null and definition.polarity == polarity:
			unique_types[definition.status_type] = true
	return unique_types.size()


static func _dynamic_modifier_key(owner, effect: EffectDefinition, source_name: String) -> String:
	return "dynamic|%s|%s|%d" % [owner.unit_id if owner != null else "scenario", source_name, effect.get_instance_id()]


static func _aura_source_key(owner, effect: EffectDefinition, source_name: String) -> String:
	return "aura|%s|%s|%d" % [owner.unit_id if owner != null else "scenario", source_name, effect.get_instance_id()]


static func _target_has_any_tag(target, tags: Array[String]) -> bool:
	if target == null:
		return false
	for tag in tags:
		if target.tags.has(tag):
			return true
	return false


static func _usage_key(event: Dictionary, owner, effect: EffectDefinition, source_name: String) -> String:
	return "%d|%s|%s" % [
		int(event.get("id", -1)) if effect.trigger == "Battle State Changed" or effect.repeat_within_event_chain else int(event.get("root_id", event.get("id", -1))),
		owner.unit_id if owner != null else "scenario",
		_battle_usage_key(owner, effect, source_name),
	]


static func _battle_usage_key(owner, effect: EffectDefinition, source_name: String) -> String:
	return "%s|%s|%s|%s|%d" % [
		owner.unit_id if owner != null else "scenario",
		source_name,
		effect.trigger,
		effect.display_name if not effect.display_name.is_empty() else effect.effect_type,
		effect.get_instance_id(),
	]
