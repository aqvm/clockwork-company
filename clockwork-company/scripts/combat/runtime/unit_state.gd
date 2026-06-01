extends RefCounted
class_name UnitState

var unit_name := ""
var team := ""
var max_hp := 1
var hp := 1
var damage := 1
var armor := 0
var action_interval := 10
var next_action_time := 10
var slot_index := 0
var loadout: UnitLoadoutDefinition = null
var current_job: JobDefinition = null
var equipped_items: Array[ItemDefinition] = []
var skipped_items: Array[ItemDefinition] = []
var tactics: Array = []
var guard_armor := 0


func _init(definition: UnitDefinition, unit_slot_index: int) -> void:
	unit_name = definition.display_name
	team = definition.team
	max_hp = definition.max_hp
	damage = definition.damage
	armor = definition.armor
	action_interval = definition.action_interval
	slot_index = unit_slot_index
	loadout = definition.loadout
	equipped_items = []
	skipped_items = []

	if loadout != null:
		current_job = loadout.current_job
		tactics = loadout.tactics.duplicate()

	if current_job != null:
		max_hp = max(1, max_hp + current_job.max_hp_modifier)
		damage = max(1, damage + current_job.damage_modifier)
		armor = max(0, armor + current_job.armor_modifier)
		action_interval = max(1, action_interval + current_job.action_interval_modifier)

	for item in assigned_items():
		if _can_equip_item(item):
			equipped_items.append(item)
			_apply_item_stat_modifiers(item)
		else:
			skipped_items.append(item)

	hp = max_hp
	next_action_time = action_interval


func is_alive() -> bool:
	return hp > 0


func total_armor() -> int:
	return armor + guard_armor


func current_job_name() -> String:
	if current_job == null:
		return "No Job"
	return current_job.display_name


func loadout_name() -> String:
	if loadout == null:
		return "No Loadout"
	return loadout.display_name


func job_effect() -> String:
	if current_job == null:
		return "None"
	return current_job.job_effect


func assigned_items() -> Array[ItemDefinition]:
	var items: Array[ItemDefinition] = []
	if loadout == null:
		return items

	for item in [loadout.weapon, loadout.armor, loadout.trinket]:
		if item != null:
			items.append(item)

	return items


func _apply_item_stat_modifiers(item: ItemDefinition) -> void:
	max_hp = max(1, max_hp + item.max_hp_modifier)
	damage = max(1, damage + item.damage_modifier)
	armor = max(0, armor + item.armor_modifier)
	action_interval = max(1, action_interval + item.action_interval_modifier)


func _can_equip_item(item: ItemDefinition) -> bool:
	if item == null:
		return false

	if current_job == null:
		return true

	if item.slot == "Weapon":
		return current_job.can_equip_weapon

	if item.slot == "Armor":
		return current_job.can_equip_armor

	if item.slot == "Trinket":
		return current_job.can_equip_trinket

	return false
