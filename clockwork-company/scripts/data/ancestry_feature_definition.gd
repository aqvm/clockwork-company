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


func support_error() -> String:
	if trigger == "Attack":
		return "" if feature_type == "Bonus Damage" else "Attack only supports Bonus Damage."
	if trigger == "Battle Start":
		if feature_type == "Bonus Damage" or feature_type == "Damage Attacker":
			return "Battle Start cannot use %s." % feature_type
		return ""
	if trigger == "Kill":
		if feature_type == "Bonus Damage" or feature_type == "Damage Attacker":
			return "Kill cannot use %s." % feature_type
		return ""
	return ""
