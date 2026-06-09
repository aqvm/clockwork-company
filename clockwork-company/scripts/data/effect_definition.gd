@tool
extends Resource
class_name EffectDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export_enum("Battle Start", "Attack", "Hit", "Kill", "Death", "Damaged", "HP Below Threshold", "Every N Ticks") var trigger := "Battle Start"
@export_enum("Always", "Self HP Below Percent", "Target Has Tag", "Target Missing Tag") var condition := "Always"
@export_enum("Self", "Attack Target", "Attacker", "Killer", "All Allies", "All Enemies", "Adjacent Allies") var target_selector := "Self"
@export_enum("Gain Armor", "Bonus Damage", "Reduce Target Armor", "Heal", "Heal Self", "Damage", "Damage Killer", "Increase Max HP", "Apply Status") var effect_type := "Gain Armor"
@export var status: Resource = null
@export_range(1, 99, 1) var status_duration_turns := 3
@export var status_is_permanent := false
@export var amount := 0
@export_range(1, 100, 1) var threshold_percent := 50
@export var interval_ticks := 0
@export var once_per_battle := false


func _to_string() -> String:
	if display_name.is_empty():
		return "EffectDefinition"
	return display_name
