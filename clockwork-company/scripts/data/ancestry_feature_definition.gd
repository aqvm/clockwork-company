@tool
extends Resource

class_name AncestryFeatureDefinition

## Label shown in the Inspector, combat logs, and tooltips. The resource name mirrors this value.
@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
## Player-facing summary shown at the top of resource tooltips.
@export_multiline var tooltip_text := ""
## Shared TagDefinition resources. A `magic` tag makes `Attack` + `Bonus Damage` add magic damage instead of physical damage.
@export var tags: Array[Resource] = []
## Combat event that can trigger this ancestry feature.
@export_enum("Battle Start", "Attack", "Kill", "Damaged", "HP Below Threshold") var trigger := "Battle Start":
	set(value):
		trigger = value
		notify_property_list_changed()
## Optional gate checked after the trigger. `Self HP Below Percent` reads `threshold_percent`.
@export_enum("Always", "Self HP Below Percent") var condition := "Always":
	set(value):
		condition = value
		notify_property_list_changed()
## Built-in result produced when the feature fires. Not every trigger supports every feature type; validation reports unsupported pairs.
@export_enum("Gain Armor", "Bonus Damage", "Heal Self", "Damage Attacker", "Increase Own Action Speed", "Gain Physical Damage") var feature_type := "Gain Armor":
	set(value):
		feature_type = value
		notify_property_list_changed()
## Fixed amount used by the selected feature type: armor, damage, healing, action speed, or physical damage.
@export var amount := 0
## HP percent used by `Self HP Below Percent` and the `HP Below Threshold` trigger.
@export_range(1, 100, 1) var threshold_percent := 50
## Owner-turn cooldown after the feature fires.
@export_range(0, 50, 1) var cooldown_turns := 0
## Authoring notes shown only in the editor. They do not affect combat.
@export_multiline var notes := ""


func _validate_property(property: Dictionary) -> void:
	var property_name := String(property.name)
	if property_name == "tags" and not (trigger == "Attack" and feature_type == "Bonus Damage"):
		_hide(property)
	elif property_name == "threshold_percent" and not (condition == "Self HP Below Percent" or trigger == "HP Below Threshold"):
		_hide(property)


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


static func _hide(property: Dictionary) -> void:
	property.usage = PROPERTY_USAGE_NO_EDITOR
