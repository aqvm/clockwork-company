@tool
extends Resource
class_name StatusDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export_enum("Boon", "Ailment") var polarity := "Boon"
@export_enum("Confusion", "Reconstitution", "Bleed", "Numb", "Frost") var status_type := "Reconstitution"
@export_enum("Ignore", "Refresh", "Intensify") var stacking_rule := "Refresh"
@export_range(1, 99, 1) var max_stacks := 1
@export var tags: Array[String] = []
@export_range(0, 99, 1) var amount := 0
@export_range(1, 100, 1) var amount_percent := 50
@export var elapses_naturally := true
@export_multiline var description := ""


func _to_string() -> String:
	if display_name.is_empty():
		return "StatusDefinition"
	return display_name
