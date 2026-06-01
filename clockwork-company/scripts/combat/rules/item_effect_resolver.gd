extends RefCounted
class_name ItemEffectResolver

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")

static func apply_battle_start_item_effects(log, units: Array) -> void:
	var battle_start_entry_id: int = log.add("Battle start item effects:")
	var any_effects := false
	for unit in units:
		for item in unit.equipped_items:
			if not _item_has_trigger(item, CombatConstantsScript.TRIGGER_BATTLE_START):
				continue
			any_effects = true
			if item.effect == CombatConstantsScript.EFFECT_GAIN_ARMOR:
				unit.armor = max(0, unit.armor + item.effect_amount)
				log.add_child(battle_start_entry_id, "%s triggers %s: gains %d armor for this battle." % [unit.unit_name, item.display_name, item.effect_amount])
			else:
				log.add_child(battle_start_entry_id, _unsupported_effect_text(unit, item, CombatConstantsScript.TRIGGER_BATTLE_START))
	if not any_effects:
		log.add_child(battle_start_entry_id, "none")

static func apply_attack_item_effects(log, parent_entry_id: int, actor, target) -> int:
	var bonus_damage := 0
	for item in actor.equipped_items:
		if not _item_has_trigger(item, CombatConstantsScript.TRIGGER_ATTACK):
			continue
		if item.effect == CombatConstantsScript.EFFECT_BONUS_DAMAGE:
			log.add_child(parent_entry_id, "%s triggers %s on attack: +%d damage against %s." % [actor.unit_name, item.display_name, item.effect_amount, target.unit_name])
			bonus_damage += item.effect_amount
		else:
			log.add_child(parent_entry_id, _unsupported_effect_text(actor, item, CombatConstantsScript.TRIGGER_ATTACK))
	return bonus_damage

static func apply_hit_item_effects(log, parent_entry_id: int, actor, target) -> void:
	for item in actor.equipped_items:
		if not _item_has_trigger(item, CombatConstantsScript.TRIGGER_HIT):
			continue
		if item.effect == CombatConstantsScript.EFFECT_REDUCE_TARGET_ARMOR:
			_reduce_target_armor(log, parent_entry_id, actor, target, item)
		else:
			log.add_child(parent_entry_id, _unsupported_effect_text(actor, item, CombatConstantsScript.TRIGGER_HIT))

static func apply_kill_item_effects(log, parent_entry_id: int, actor) -> void:
	for item in actor.equipped_items:
		if not _item_has_trigger(item, CombatConstantsScript.TRIGGER_KILL):
			continue
		if item.effect == CombatConstantsScript.EFFECT_HEAL_SELF:
			var previous_hp: int = actor.hp
			actor.hp = min(actor.max_hp, actor.hp + item.effect_amount)
			log.add_child(parent_entry_id, "%s triggers %s on kill: heals %d -> %d HP." % [actor.unit_name, item.display_name, previous_hp, actor.hp])
		else:
			log.add_child(parent_entry_id, _unsupported_effect_text(actor, item, CombatConstantsScript.TRIGGER_KILL))

static func apply_death_item_effects(log, parent_entry_id: int, defeated_unit, killer) -> void:
	for item in defeated_unit.equipped_items:
		if not _item_has_trigger(item, CombatConstantsScript.TRIGGER_DEATH):
			continue
		if item.effect == CombatConstantsScript.EFFECT_DAMAGE_KILLER:
			var previous_hp: int = killer.hp
			killer.hp = max(0, killer.hp - item.effect_amount)
			log.add_child(parent_entry_id, "%s triggers %s on death: %s HP %d -> %d." % [defeated_unit.unit_name, item.display_name, killer.unit_name, previous_hp, killer.hp])
			if not killer.is_alive():
				log.add_child(parent_entry_id, "%s is defeated by the death effect." % killer.unit_name)
		else:
			log.add_child(parent_entry_id, _unsupported_effect_text(defeated_unit, item, CombatConstantsScript.TRIGGER_DEATH))

static func _reduce_target_armor(log, parent_entry_id: int, actor, target, item) -> void:
	var previous_base_armor: int = target.armor
	var previous_guard_armor: int = target.guard_armor
	var remaining_reduction: int = item.effect_amount
	if target.armor > 0:
		var base_reduction: int = min(target.armor, remaining_reduction)
		target.armor -= base_reduction
		remaining_reduction -= base_reduction
	if remaining_reduction > 0 and target.guard_armor > 0:
		var guard_reduction: int = min(target.guard_armor, remaining_reduction)
		target.guard_armor -= guard_reduction
	log.add_child(parent_entry_id, "%s triggers %s on hit: %s base armor %d -> %d, temporary armor %d -> %d." % [actor.unit_name, item.display_name, target.unit_name, previous_base_armor, target.armor, previous_guard_armor, target.guard_armor])

static func _item_has_trigger(item: ItemDefinition, trigger: String) -> bool:
	return item != null and item.trigger == trigger and item.effect != CombatConstantsScript.EFFECT_NONE and item.effect_amount != 0

static func _unsupported_effect_text(unit, item: ItemDefinition, trigger: String) -> String:
	return "%s triggers %s on %s, but that effect is not implemented yet." % [unit.unit_name, item.display_name, trigger.to_lower()]
