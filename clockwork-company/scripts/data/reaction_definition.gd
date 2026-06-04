@tool
extends Resource
class_name ReactionDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export_enum("Damaged", "HP Below Threshold") var trigger := "Damaged"
@export_enum("Always", "Self HP Below Percent") var condition := "Always"
@export_enum("Gain Armor", "Heal Self", "Damage Attacker") var reaction_type := "Gain Armor"
@export var amount := 0
@export_range(1, 100, 1) var threshold_percent := 50
@export var cooldown_turns := 0


func _to_string() -> String:
	if display_name.is_empty():
		return "ReactionDefinition"
	return display_name
