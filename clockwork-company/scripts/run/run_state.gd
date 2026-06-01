extends RefCounted
class_name RunState

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const UnitDefinitionScript := preload("res://scripts/data/unit_definition.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const ItemDefinitionScript := preload("res://scripts/data/item_definition.gd")

const STATUS_ACTIVE := "active"
const STATUS_REWARD := "reward"
const STATUS_WON := "won"
const STATUS_LOST := "lost"
const FIGHT_COUNT := 5

var fight_index := 0
var status := STATUS_ACTIVE
var ally_definitions: Array[UnitDefinition] = []
var enemy_definitions: Array[UnitDefinition] = []
var inventory_names: Array[String] = []
var last_result_summary := ""
var loss_test_mode := false


func start(enabled_mod_pack_ids: Array[String], should_force_loss := false) -> void:
	fight_index = 0
	status = STATUS_ACTIVE
	inventory_names.clear()
	last_result_summary = ""
	loss_test_mode = should_force_loss

	ally_definitions.clear()
	enemy_definitions.clear()
	for definition: UnitDefinition in JsonContentLoaderScript.load_demo_unit_definitions(enabled_mod_pack_ids):
		var copy := _clone_unit_definition(definition)
		if copy.team == CombatConstantsScript.TEAM_ALLY:
			ally_definitions.append(copy)
		else:
			enemy_definitions.append(copy)

	if loss_test_mode:
		for ally in ally_definitions:
			ally.max_hp = 1
			ally.damage = 1
			ally.armor = 0


func current_fight_number() -> int:
	return fight_index + 1


func current_fight_title() -> String:
	var suffix := " (loss test)" if loss_test_mode else ""
	return "Phase 7 run fight %d of %d%s" % [current_fight_number(), FIGHT_COUNT, suffix]


func build_current_fight_definitions() -> Array[UnitDefinition]:
	var definitions: Array[UnitDefinition] = []
	for ally in ally_definitions:
		definitions.append(_clone_unit_definition(ally))
	for enemy in enemy_definitions:
		var scaled_enemy := _clone_unit_definition(enemy)
		_apply_enemy_scaling(scaled_enemy)
		definitions.append(scaled_enemy)
	return definitions


func complete_fight(report: Dictionary) -> void:
	var winner := String(report.get("winner", "None"))
	if winner != CombatConstantsScript.TEAM_ALLY:
		status = STATUS_LOST
		last_result_summary = "Run lost on fight %d. The enemy team survived the battle." % current_fight_number()
		return

	if fight_index >= FIGHT_COUNT - 1:
		status = STATUS_WON
		last_result_summary = "Run won after fight %d. The party cleared the five-fight slice." % current_fight_number()
		return

	status = STATUS_REWARD
	last_result_summary = "Fight %d won. Choose one reward before fight %d." % [current_fight_number(), current_fight_number() + 1]


func reward_options() -> Array[Dictionary]:
	var fight_number := current_fight_number()
	return [
		_build_reward(
			"Guardplate for Alden",
			"Equip Alden with sturdier armor: +5 HP, +1 armor, +1 interval.",
			"Alden Guard",
			"Armor",
			"Run Guardplate %d" % fight_number,
			5,
			0,
			1,
			1
		),
		_build_reward(
			"Honed Blade for Mira",
			"Equip Mira with a sharper weapon: +2 damage.",
			"Mira Scout",
			"Weapon",
			"Run Honed Blade %d" % fight_number,
			0,
			2,
			0,
			0
		),
		_build_reward(
			"Focus Lens for Sol",
			"Equip Sol with a stronger trinket: -1 HP, +2 damage.",
			"Sol Apprentice",
			"Trinket",
			"Run Focus Lens %d" % fight_number,
			-1,
			2,
			0,
			0
		),
	]


func apply_reward(reward_index: int) -> void:
	var options := reward_options()
	if reward_index < 0 or reward_index >= options.size():
		return

	var reward: Dictionary = options[reward_index]
	var target := _find_ally(String(reward["unit_name"]))
	if target == null:
		return

	var item := _item_from_reward(reward)
	var loadout := _ensure_loadout_clone(target)
	if item.slot == "Weapon":
		loadout.weapon = item
	elif item.slot == "Armor":
		loadout.armor = item
	elif item.slot == "Trinket":
		loadout.trinket = item

	inventory_names.append("%s -> %s" % [String(reward["item_name"]), target.display_name])
	fight_index += 1
	status = STATUS_ACTIVE
	last_result_summary = "Reward equipped: %s. Fight %d is ready." % [String(reward["label"]), current_fight_number()]


func status_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("Run status: %s" % status.capitalize())
	lines.append("Current fight: %d/%d" % [current_fight_number(), FIGHT_COUNT])
	if not last_result_summary.is_empty():
		lines.append(last_result_summary)
	if inventory_names.is_empty():
		lines.append("Inventory/equipment rewards: none yet")
	else:
		lines.append("Inventory/equipment rewards:")
		for entry in inventory_names:
			lines.append("- %s" % entry)
	return lines


func _apply_enemy_scaling(enemy: UnitDefinition) -> void:
	var step := fight_index
	enemy.max_hp += step * 2
	enemy.damage += int(step / 3)
	if step >= 2:
		enemy.armor += 1

	if loss_test_mode:
		enemy.max_hp += 30
		enemy.damage += 10
		enemy.armor += 3
		enemy.action_interval = max(1, enemy.action_interval - 3)


func _build_reward(label: String, description: String, unit_name: String, slot: String, item_name: String, max_hp_modifier: int, damage_modifier: int, armor_modifier: int, action_interval_modifier: int) -> Dictionary:
	return {
		"label": label,
		"description": description,
		"unit_name": unit_name,
		"slot": slot,
		"item_name": item_name,
		"max_hp_modifier": max_hp_modifier,
		"damage_modifier": damage_modifier,
		"armor_modifier": armor_modifier,
		"action_interval_modifier": action_interval_modifier,
	}


func _item_from_reward(reward: Dictionary) -> ItemDefinition:
	var item: ItemDefinition = ItemDefinitionScript.new()
	item.display_name = String(reward["item_name"])
	item.slot = String(reward["slot"])
	item.max_hp_modifier = int(reward["max_hp_modifier"])
	item.damage_modifier = int(reward["damage_modifier"])
	item.armor_modifier = int(reward["armor_modifier"])
	item.action_interval_modifier = int(reward["action_interval_modifier"])
	return item


func _find_ally(unit_name: String) -> UnitDefinition:
	for ally in ally_definitions:
		if ally.display_name == unit_name:
			return ally
	return null


func _ensure_loadout_clone(unit: UnitDefinition) -> UnitLoadoutDefinition:
	if unit.loadout == null:
		unit.loadout = UnitLoadoutDefinitionScript.new()
		unit.loadout.display_name = "%s Run Loadout" % unit.display_name
	else:
		unit.loadout = _clone_loadout_definition(unit.loadout)
	return unit.loadout


func _clone_unit_definition(source: UnitDefinition) -> UnitDefinition:
	var copy: UnitDefinition = UnitDefinitionScript.new()
	copy.display_name = source.display_name
	copy.team = source.team
	copy.max_hp = source.max_hp
	copy.damage = source.damage
	copy.armor = source.armor
	copy.action_interval = source.action_interval
	copy.loadout = _clone_loadout_definition(source.loadout) if source.loadout != null else null
	return copy


func _clone_loadout_definition(source: UnitLoadoutDefinition) -> UnitLoadoutDefinition:
	var copy: UnitLoadoutDefinition = UnitLoadoutDefinitionScript.new()
	copy.display_name = source.display_name
	copy.current_job = source.current_job
	copy.weapon = _clone_item_definition(source.weapon) if source.weapon != null else null
	copy.armor = _clone_item_definition(source.armor) if source.armor != null else null
	copy.trinket = _clone_item_definition(source.trinket) if source.trinket != null else null
	copy.tactics = source.tactics.duplicate()
	return copy


func _clone_item_definition(source: ItemDefinition) -> ItemDefinition:
	var copy: ItemDefinition = ItemDefinitionScript.new()
	copy.display_name = source.display_name
	copy.slot = source.slot
	copy.max_hp_modifier = source.max_hp_modifier
	copy.damage_modifier = source.damage_modifier
	copy.armor_modifier = source.armor_modifier
	copy.action_interval_modifier = source.action_interval_modifier
	copy.trigger = source.trigger
	copy.effect = source.effect
	copy.effect_amount = source.effect_amount
	return copy
