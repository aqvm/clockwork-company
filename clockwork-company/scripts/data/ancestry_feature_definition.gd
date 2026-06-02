@tool
extends Resource

class_name AncestryFeatureDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export_enum("Battle Start", "Attack", "Kill", "Damaged", "HP Below Threshold") var trigger := "Battle Start"
@export_enum("Always", "Self HP Below Percent") var condition := "Always"
@export_enum("Gain Armor", "Bonus Damage", "Heal Self", "Damage Attacker", "Hasten Self", "Gain Physical Damage") var feature_type := "Gain Armor"
@export var amount := 0
@export_range(1, 100, 1) var threshold_percent := 50
@export_range(0, 50, 1) var cooldown_turns := 0
@export_multiline var notes := ""
