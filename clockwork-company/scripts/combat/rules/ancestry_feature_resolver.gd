extends RefCounted
class_name AncestryFeatureResolver

const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")

const TRIGGER_BATTLE_START := "Battle Start"
const TRIGGER_ATTACK := "Attack"
const TRIGGER_KILL := "Kill"
const TRIGGER_DAMAGED := "Damaged"
const TRIGGER_HP_BELOW_THRESHOLD := "HP Below Threshold"
const CONDITION_SELF_HP_BELOW_PERCENT := "Self HP Below Percent"
const FEATURE_GAIN_ARMOR := "Gain Armor"
const FEATURE_BONUS_DAMAGE := "Bonus Damage"
const FEATURE_HEAL_SELF := "Heal Self"
const FEATURE_DAMAGE_ATTACKER := "Damage Attacker"
const FEATURE_HASTEN_SELF := "Hasten Self"
const FEATURE_GAIN_PHYSICAL_DAMAGE := "Gain Physical Damage"


static func apply_battle_start_features(log, units: Array) -> void:
	for unit in units:
		var feature = unit.current_ancestry_feature
		if feature == null or feature.trigger != TRIGGER_BATTLE_START:
			continue
		_apply_feature(log, -1, unit, null, feature)


static func attack_bonus(log, parent_entry_id: int, actor) -> Dictionary:
	var feature = actor.current_ancestry_feature
	var result := {"physical": 0, "magic": 0}
	if feature == null or feature.trigger != TRIGGER_ATTACK or feature.feature_type != FEATURE_BONUS_DAMAGE:
		return result
	if not _feature_can_fire(actor, feature):
		return result
	_mark_feature_fired(actor, feature)
	var damage_type := "magic" if feature.tags.has("magic") else "physical"
	result[damage_type] = feature.amount
	var event := CombatEventsScript.ancestry_feature(actor, feature.display_name, "+%d %s damage" % [feature.amount, damage_type])
	log.add_event("Ancestry feature %s: +%d %s damage." % [feature.display_name, feature.amount, damage_type], event["event_type"], -1, parent_entry_id, event["payload"], event["tags"])
	return result


static func apply_damaged_feature(log, parent_entry_id: int, damaged_unit, attacker) -> void:
	var feature = damaged_unit.current_ancestry_feature
	if feature == null or (feature.trigger != TRIGGER_DAMAGED and feature.trigger != TRIGGER_HP_BELOW_THRESHOLD):
		return
	_apply_feature(log, parent_entry_id, damaged_unit, attacker, feature)


static func apply_kill_feature(log, parent_entry_id: int, actor) -> void:
	var feature = actor.current_ancestry_feature
	if feature == null or feature.trigger != TRIGGER_KILL:
		return
	_apply_feature(log, parent_entry_id, actor, null, feature)


static func _apply_feature(log, parent_entry_id: int, owner, other, feature) -> void:
	if feature.amount == 0 or not _feature_can_fire(owner, feature):
		return
	_mark_feature_fired(owner, feature)
	if feature.feature_type == FEATURE_GAIN_ARMOR:
		owner.guard_armor += feature.amount
		var armor_event := CombatEventsScript.ancestry_feature(owner, feature.display_name, "+%d temporary armor" % feature.amount)
		log.add_event("Ancestry feature %s: %s gains %d temporary armor." % [feature.display_name, owner.unit_name, feature.amount], armor_event["event_type"], -1, parent_entry_id, armor_event["payload"], armor_event["tags"])
	elif feature.feature_type == FEATURE_HEAL_SELF:
		var previous_hp: int = owner.hp
		owner.hp = min(owner.max_hp, owner.hp + feature.amount)
		var heal_event := CombatEventsScript.ancestry_feature(owner, feature.display_name, "HP %d -> %d" % [previous_hp, owner.hp])
		log.add_event("Ancestry feature %s: %s HP %d -> %d." % [feature.display_name, owner.unit_name, previous_hp, owner.hp], heal_event["event_type"], -1, parent_entry_id, heal_event["payload"], heal_event["tags"])
	elif feature.feature_type == FEATURE_DAMAGE_ATTACKER and other != null:
		var previous_other_hp: int = other.hp
		other.hp = max(0, other.hp - feature.amount)
		var damage_event := CombatEventsScript.ancestry_feature(owner, feature.display_name, "%s HP %d -> %d" % [other.unit_name, previous_other_hp, other.hp])
		log.add_event("Ancestry feature %s: %s HP %d -> %d." % [feature.display_name, other.unit_name, previous_other_hp, other.hp], damage_event["event_type"], -1, parent_entry_id, damage_event["payload"], damage_event["tags"])
		if not other.is_alive():
			var defeat_event := CombatEventsScript.defeat(other)
			log.add_event("%s is defeated by the ancestry feature." % other.unit_name, defeat_event["event_type"], -1, parent_entry_id, defeat_event["payload"], defeat_event["tags"])
	elif feature.feature_type == FEATURE_HASTEN_SELF:
		var previous_interval: int = owner.action_interval
		owner.action_interval = max(1, owner.action_interval - feature.amount)
		var haste_event := CombatEventsScript.ancestry_feature(owner, feature.display_name, "interval %d -> %d" % [previous_interval, owner.action_interval])
		log.add_event("Ancestry feature %s: %s interval %d -> %d." % [feature.display_name, owner.unit_name, previous_interval, owner.action_interval], haste_event["event_type"], -1, parent_entry_id, haste_event["payload"], haste_event["tags"])
	elif feature.feature_type == FEATURE_GAIN_PHYSICAL_DAMAGE:
		var previous_physical: int = owner.physical_damage
		owner.physical_damage = max(1, owner.physical_damage + feature.amount)
		var gain_event := CombatEventsScript.ancestry_feature(owner, feature.display_name, "physical %d -> %d" % [previous_physical, owner.physical_damage])
		log.add_event("Ancestry feature %s: %s physical %d -> %d." % [feature.display_name, owner.unit_name, previous_physical, owner.physical_damage], gain_event["event_type"], -1, parent_entry_id, gain_event["payload"], gain_event["tags"])


static func _feature_can_fire(owner, feature) -> bool:
	if feature.condition == CONDITION_SELF_HP_BELOW_PERCENT or feature.trigger == TRIGGER_HP_BELOW_THRESHOLD:
		if owner.hp * 100 > owner.max_hp * feature.threshold_percent:
			return false
	return owner.ability_is_ready(_feature_key(feature))


static func _mark_feature_fired(owner, feature) -> void:
	owner.start_ability_cooldown(_feature_key(feature), feature.cooldown_turns)


static func _feature_key(feature) -> String:
	return "ancestry|%s|%s" % [feature.trigger, feature.display_name]
