@tool
extends Resource
class_name PassiveDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export_enum("None", "Attack Damage Bonus", "Heal Bonus", "Guard Armor Bonus", "Forecast") var passive_type := "None"
@export var amount := 0
@export var cooldown_turns := 0


func _to_string() -> String:
	if display_name.is_empty():
		return "PassiveDefinition"
	return display_name
