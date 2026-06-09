@tool
extends Resource
class_name SkillDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export_enum("Attack", "Heal", "Guard", "Apply Status") var action := "Attack"
@export_enum("Self", "Lowest HP Ally", "Frontmost Enemy") var default_target := "Frontmost Enemy"
@export var status: Resource = null
@export_range(1, 99, 1) var status_duration_turns := 3
@export var status_is_permanent := false
@export var amount_modifier := 0


func _to_string() -> String:
	if display_name.is_empty():
		return "SkillDefinition"
	return display_name
