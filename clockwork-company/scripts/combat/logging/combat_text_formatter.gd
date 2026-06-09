extends RefCounted
class_name CombatTextFormatter

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const TargetingRulesScript := preload("res://scripts/combat/rules/targeting_rules.gd")

static func describe_tactic(tactic: TacticDefinition) -> String:
	var rules_text := "%s -> %s -> %s" % [tactic.condition, tactic.action, tactic.target]
	if tactic.foretell_enabled:
		rules_text = "Foretell: %s" % rules_text
	if tactic.display_name.is_empty():
		return rules_text
	return "%s (%s)" % [tactic.display_name, rules_text]

static func item_name_or_none(unit) -> String:
	if unit.equipped_items.is_empty():
		return "none"
	var item_names: Array[String] = []
	for item in unit.equipped_items:
		item_names.append(item.display_name)
	return join_text_parts(item_names, ", ")

static func describe_item(item: ItemDefinition) -> String:
	return "%s [%s] (%s; %s)" % [item.display_name, item.slot, _describe_item_modifiers(item), _describe_item_effect(item)]

static func build_result_line(units: Array, actions_taken: int) -> String:
	if TargetingRulesScript.team_has_living_unit(units, CombatConstantsScript.TEAM_ALLY) and not TargetingRulesScript.team_has_living_unit(units, CombatConstantsScript.TEAM_ENEMY):
		return "Result: Allies win after %d actions." % actions_taken
	if TargetingRulesScript.team_has_living_unit(units, CombatConstantsScript.TEAM_ENEMY) and not TargetingRulesScript.team_has_living_unit(units, CombatConstantsScript.TEAM_ALLY):
		return "Result: Enemies win after %d actions." % actions_taken
	return "Result: No winner after %d actions." % actions_taken

static func _describe_item_modifiers(item: ItemDefinition) -> String:
	var parts: Array[String] = []
	_append_modifier_text(parts, "HP", item.max_hp_modifier)
	_append_modifier_text(parts, "physical", item.physical_damage_modifier)
	_append_modifier_text(parts, "magic", item.magic_damage_modifier)
	_append_modifier_text(parts, "armor", item.armor_modifier)
	_append_modifier_text(parts, "interval", item.action_interval_modifier)
	if parts.is_empty():
		return "no stat changes"
	return join_text_parts(parts, ", ")

static func _describe_item_effect(item: ItemDefinition) -> String:
	if not item.effects.is_empty():
		var parts: Array[String] = []
		for effect in item.effects:
			if effect == null:
				continue
			var limit_text := ", once" if effect.once_per_battle else ""
			parts.append("%s -> %s %d%s" % [effect.trigger, effect.effect_type, effect.amount, limit_text])
		if not parts.is_empty():
			return join_text_parts(parts, "; ")
	return "no triggered effect"

static func _append_modifier_text(parts: Array[String], label: String, amount: int) -> void:
	if amount == 0:
		return
	if amount > 0:
		parts.append("%s +%d" % [label, amount])
	else:
		parts.append("%s %d" % [label, amount])

static func join_text_parts(parts: Array[String], separator: String) -> String:
	var text := ""
	for part in parts:
		if not text.is_empty():
			text += separator
		text += part
	return text
