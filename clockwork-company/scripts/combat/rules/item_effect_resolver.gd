extends RefCounted
class_name ItemEffectResolver

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const TRIGGER_DAMAGED := "Damaged"
const TRIGGER_HP_BELOW_THRESHOLD := "HP Below Threshold"
const EFFECT_INCREASE_MAX_HP := "Increase Max HP"
const TARGET_SELF := "Self"
const TARGET_ATTACK_TARGET := "Attack Target"
const TARGET_ATTACKER := "Attacker"
const TARGET_KILLER := "Killer"

static func apply_battle_start_item_effects(log, units: Array, battle_start_entry_id := -1, context = null) -> void:
	if battle_start_entry_id < 0:
		battle_start_entry_id = log.add("Battle start item effects:")
	else:
		log.add_child(battle_start_entry_id, "Item effects:")
	var any_effects := false
	for unit in units:
		for item in unit.equipped_items:
			var effects := _effects_for_trigger(item, CombatConstantsScript.TRIGGER_BATTLE_START)
			if effects.is_empty():
				continue
			any_effects = true
			for effect in effects:
				if not _effect_can_fire(unit, effect, unit):
					continue
				if effect.effect_type == CombatConstantsScript.EFFECT_GAIN_ARMOR:
					_mark_effect_fired(unit, effect)
					_publish_trigger(context, unit, unit, item, effect, battle_start_entry_id)
					unit.armor = max(0, unit.armor + effect.amount)
					var event := CombatEventsScript.item_trigger(unit, item.display_name, CombatConstantsScript.TRIGGER_BATTLE_START, effect.effect_type, "gains %d armor for this battle" % effect.amount)
					log.add_event("%s triggers %s: gains %d armor for this battle." % [unit.unit_name, item.display_name, effect.amount], event["event_type"], -1, battle_start_entry_id, event["payload"], event["tags"])
					if context != null:
						context.publish("armor_gained", unit, unit, {"amount": effect.amount, "armor_kind": "base"}, -1, battle_start_entry_id, ["armor", "item"])
				else:
					if not ["Apply Status", "Remove Status", "Modify Stat"].has(effect.effect_type):
						log.add_child(battle_start_entry_id, _unsupported_effect_text(unit, item, effect))
	if not any_effects:
		log.add_child(battle_start_entry_id, "none")

static func apply_attack_item_effects(log, parent_entry_id: int, actor, target, context = null) -> Dictionary:
	var bonus_damage := 0
	var magic_bonus_damage := 0
	for item in actor.equipped_items:
		for effect in _effects_for_trigger(item, CombatConstantsScript.TRIGGER_ATTACK):
			if not _effect_can_fire(actor, effect, target):
				continue
			if effect.effect_type == CombatConstantsScript.EFFECT_BONUS_DAMAGE:
				_mark_effect_fired(actor, effect)
				_publish_trigger(context, actor, target, item, effect, parent_entry_id)
				var damage_type := "magic" if effect.tags.has("magic") else "physical"
				var event := CombatEventsScript.item_trigger(actor, item.display_name, CombatConstantsScript.TRIGGER_ATTACK, effect.effect_type, "+%d %s damage against %s" % [effect.amount, damage_type, target.unit_name])
				log.add_event("%s triggers %s on attack: +%d %s damage against %s." % [actor.unit_name, item.display_name, effect.amount, damage_type, target.unit_name], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
				if effect.tags.has("magic"):
					magic_bonus_damage += effect.amount
				else:
					bonus_damage += effect.amount
			else:
				log.add_child(parent_entry_id, _unsupported_effect_text(actor, item, effect))
	return {
		"physical": bonus_damage,
		"magic": magic_bonus_damage,
	}

static func apply_hit_item_effects(log, parent_entry_id: int, actor, target, context = null) -> void:
	for item in actor.equipped_items:
		for effect in _effects_for_trigger(item, CombatConstantsScript.TRIGGER_HIT):
			if not _effect_can_fire(actor, effect, target):
				continue
			if effect.effect_type == CombatConstantsScript.EFFECT_REDUCE_TARGET_ARMOR:
				_mark_effect_fired(actor, effect)
				_publish_trigger(context, actor, target, item, effect, parent_entry_id)
				_reduce_target_armor(log, parent_entry_id, actor, target, item, effect, context)
			else:
				log.add_child(parent_entry_id, _unsupported_effect_text(actor, item, effect))

static func apply_damaged_item_effects(log, parent_entry_id: int, damaged_unit, attacker, context = null) -> void:
	for item in damaged_unit.equipped_items:
		var effects := _effects_for_trigger(item, TRIGGER_DAMAGED)
		effects.append_array(_effects_for_trigger(item, TRIGGER_HP_BELOW_THRESHOLD))
		for effect in effects:
			if not _effect_can_fire(damaged_unit, effect, attacker):
				continue
			if effect.effect_type == EFFECT_INCREASE_MAX_HP:
				_mark_effect_fired(damaged_unit, effect)
				_publish_trigger(context, damaged_unit, damaged_unit, item, effect, parent_entry_id)
				var previous_max_hp: int = damaged_unit.max_hp
				var previous_hp: int = damaged_unit.hp
				damaged_unit.max_hp = max(1, damaged_unit.max_hp + effect.amount)
				damaged_unit.hp = min(damaged_unit.max_hp, damaged_unit.hp + effect.amount)
				var event := CombatEventsScript.item_trigger(damaged_unit, item.display_name, effect.trigger, effect.effect_type, "max HP %d -> %d, HP %d -> %d" % [previous_max_hp, damaged_unit.max_hp, previous_hp, damaged_unit.hp])
				log.add_event("%s triggers %s: max HP %d -> %d, HP %d -> %d." % [damaged_unit.unit_name, item.display_name, previous_max_hp, damaged_unit.max_hp, previous_hp, damaged_unit.hp], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
				if context != null:
					context.publish("max_hp_changed", damaged_unit, damaged_unit, {"previous": previous_max_hp, "new": damaged_unit.max_hp}, -1, parent_entry_id, ["item", "hp"])
					context.publish("healing_received", damaged_unit, damaged_unit, {"amount": damaged_unit.hp - previous_hp, "previous_hp": previous_hp, "new_hp": damaged_unit.hp}, -1, parent_entry_id, ["item", "healing"])
			elif effect.effect_type == CombatConstantsScript.EFFECT_HEAL_SELF:
				_mark_effect_fired(damaged_unit, effect)
				_publish_trigger(context, damaged_unit, damaged_unit, item, effect, parent_entry_id)
				_heal_unit(log, parent_entry_id, damaged_unit, damaged_unit, item, effect, context)
			else:
				log.add_child(parent_entry_id, _unsupported_effect_text(damaged_unit, item, effect))

static func apply_kill_item_effects(log, parent_entry_id: int, actor, context = null) -> void:
	for item in actor.equipped_items:
		for effect in _effects_for_trigger(item, CombatConstantsScript.TRIGGER_KILL):
			if not _effect_can_fire(actor, effect, actor):
				continue
			if effect.effect_type == CombatConstantsScript.EFFECT_HEAL_SELF:
				_mark_effect_fired(actor, effect)
				_publish_trigger(context, actor, actor, item, effect, parent_entry_id)
				_heal_unit(log, parent_entry_id, actor, actor, item, effect, context)
			else:
				log.add_child(parent_entry_id, _unsupported_effect_text(actor, item, effect))

static func apply_death_item_effects(log, parent_entry_id: int, defeated_unit, killer, context = null) -> void:
	for item in defeated_unit.equipped_items:
		for effect in _effects_for_trigger(item, CombatConstantsScript.TRIGGER_DEATH):
			if not _effect_can_fire(defeated_unit, effect, killer):
				continue
			if effect.effect_type == CombatConstantsScript.EFFECT_DAMAGE_KILLER:
				_mark_effect_fired(defeated_unit, effect)
				_publish_trigger(context, defeated_unit, killer, item, effect, parent_entry_id)
				if context != null:
					context.apply_direct_damage(defeated_unit, killer, effect.amount, -1, parent_entry_id, ["item", "death"])
				else:
					var previous_hp: int = killer.hp
					killer.hp = max(0, killer.hp - effect.amount)
					StatusResolverScript.record_damage(killer, previous_hp - killer.hp)
					var event := CombatEventsScript.item_trigger(defeated_unit, item.display_name, CombatConstantsScript.TRIGGER_DEATH, effect.effect_type, "%s HP %d -> %d" % [killer.unit_name, previous_hp, killer.hp])
					log.add_event("%s triggers %s on death: %s HP %d -> %d." % [defeated_unit.unit_name, item.display_name, killer.unit_name, previous_hp, killer.hp], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
			else:
				log.add_child(parent_entry_id, _unsupported_effect_text(defeated_unit, item, effect))

static func _heal_unit(log, parent_entry_id: int, owner, target, item: ItemDefinition, effect, context = null) -> void:
	if context != null:
		context.apply_healing(owner, target, effect.amount, -1, parent_entry_id, ["item"])
		return
	var previous_hp: int = target.hp
	target.hp = min(target.max_hp, target.hp + effect.amount)
	var event := CombatEventsScript.item_trigger(owner, item.display_name, effect.trigger, effect.effect_type, "heals %d -> %d HP" % [previous_hp, target.hp])
	log.add_event("%s triggers %s: %s HP %d -> %d." % [owner.unit_name, item.display_name, target.unit_name, previous_hp, target.hp], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])

static func _reduce_target_armor(log, parent_entry_id: int, actor, target, item, effect, context = null) -> void:
	var previous_base_armor: int = target.armor
	var previous_battle_armor: int = target.battle_armor
	var previous_guard_armor: int = target.guard_armor
	var remaining_reduction: int = effect.amount
	if target.armor > 0:
		var base_reduction: int = min(target.armor, remaining_reduction)
		target.armor -= base_reduction
		remaining_reduction -= base_reduction
	if remaining_reduction > 0 and target.battle_armor > 0:
		var battle_reduction: int = min(target.battle_armor, remaining_reduction)
		target.battle_armor -= battle_reduction
		remaining_reduction -= battle_reduction
	if remaining_reduction > 0 and target.guard_armor > 0:
		var guard_reduction: int = min(target.guard_armor, remaining_reduction)
		target.guard_armor -= guard_reduction
	var event := CombatEventsScript.item_trigger(actor, item.display_name, CombatConstantsScript.TRIGGER_HIT, effect.effect_type, "%s base armor %d -> %d, battle armor %d -> %d, temporary armor %d -> %d" % [target.unit_name, previous_base_armor, target.armor, previous_battle_armor, target.battle_armor, previous_guard_armor, target.guard_armor])
	log.add_event("%s triggers %s on hit: %s base armor %d -> %d, battle armor %d -> %d, temporary armor %d -> %d." % [actor.unit_name, item.display_name, target.unit_name, previous_base_armor, target.armor, previous_battle_armor, target.battle_armor, previous_guard_armor, target.guard_armor], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
	if context != null:
		context.publish("armor_lost", actor, target, {
			"amount": (previous_base_armor - target.armor) + (previous_battle_armor - target.battle_armor) + (previous_guard_armor - target.guard_armor),
			"armor_kind": "mixed",
			"reason": item.display_name,
		}, -1, parent_entry_id, ["armor", "item"])

static func _effects_for_trigger(item: ItemDefinition, trigger: String) -> Array:
	var effects: Array = []
	if item == null:
		return effects
	for effect in item.effects:
		if effect != null and ["Apply Status", "Remove Status", "Modify Stat"].has(effect.effect_type):
			continue
		if effect != null and effect.trigger == trigger and (effect.amount != 0 or effect.effect_type == CombatConstantsScript.EFFECT_APPLY_STATUS):
			effects.append(effect)
	return effects

static func _effect_can_fire(owner, effect, context_target) -> bool:
	if effect == null:
		return false
	if effect.once_per_battle and _effect_usage_count(owner, effect) > 0:
		return false
	if effect.condition == "Self HP Below Percent" or effect.trigger == TRIGGER_HP_BELOW_THRESHOLD:
		return owner.hp * 100 <= owner.max_hp * effect.threshold_percent
	if effect.condition == "Target Has Tag":
		return _target_has_any_effect_tag(context_target, effect)
	if effect.condition == "Target Missing Tag":
		return not _target_has_any_effect_tag(context_target, effect)
	return true

static func _target_has_any_effect_tag(target, effect) -> bool:
	if target == null:
		return false
	for tag in effect.tags:
		if target.tags.has(tag):
			return true
	return false

static func _effect_usage_count(owner, effect) -> int:
	return int(owner.effect_usage_counts.get(_effect_key(effect), 0))

static func _mark_effect_fired(owner, effect) -> void:
	var key := _effect_key(effect)
	owner.effect_usage_counts[key] = _effect_usage_count(owner, effect) + 1

static func _effect_key(effect) -> String:
	var name: String = effect.display_name
	if name.is_empty():
		name = effect.effect_type
	return "%s|%s|%s" % [effect.trigger, effect.effect_type, name]

static func _unsupported_effect_text(unit, item: ItemDefinition, effect) -> String:
	return "%s triggers %s on %s, but %s is not implemented for that trigger yet." % [unit.unit_name, item.display_name, effect.trigger.to_lower(), effect.effect_type]


static func _publish_trigger(context, owner, target, item: ItemDefinition, effect, parent_entry_id: int) -> void:
	if context == null:
		return
	context.publish("item_effect_triggered", owner, target, {
		"item": item.display_name,
		"trigger": effect.trigger,
		"effect": effect.effect_type,
		"effect_name": effect.display_name,
	}, -1, parent_entry_id, ["item", "trigger"])
