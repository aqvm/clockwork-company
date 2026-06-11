@tool
extends Resource
class_name EffectDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export_enum("Battle Start", "Turn Start", "Turn Complete", "Skill Used", "Attack", "Hit", "Kill", "Death", "Damaged", "HP Below Threshold", "Status Applied", "Status Removed", "Reaction Triggered") var trigger := "Battle Start"
@export_enum("Always", "Self HP Below Percent", "Target Has Tag", "Target Missing Tag") var condition := "Always"
@export_enum("Self", "Event Source", "Event Target", "Attack Target", "Attacker", "Killer", "All Units", "Allied Units", "Enemy Units", "Random Allied Unit", "Random Enemy Unit") var target_selector := "Self"
@export_enum("Gain Armor", "Bonus Damage", "Reduce Target Armor", "Heal Self", "Damage Killer", "Increase Max HP", "Apply Status", "Remove Status", "Modify Stat") var effect_type := "Gain Armor"
@export var status: StatusDefinition = null
@export_range(1, 99, 1) var status_duration_turns := 3
@export var status_is_permanent := false
@export_enum("Any", "Boon", "Ailment") var status_polarity := "Any"
@export_enum("Random Matching", "Specific Status") var status_removal_mode := "Random Matching"
@export_enum("Max HP", "Physical Damage", "Magic Damage", "Armor", "Action Interval") var modified_stat := "Physical Damage"
@export_range(1, 99, 1) var modifier_duration_turns := 1
@export var amount := 0
@export_range(1, 100, 1) var threshold_percent := 50
@export var once_per_battle := false


func _to_string() -> String:
	if display_name.is_empty():
		return "EffectDefinition"
	return display_name


func support_error() -> String:
	if ["Apply Status", "Remove Status", "Modify Stat"].has(effect_type) and trigger in ["Kill", "Death"] and target_selector in ["Self", "Event Target"]:
		return "%s is defeated during %s and cannot receive %s." % [target_selector, trigger, effect_type]
	if trigger == "Battle Start" and ["Event Source", "Event Target", "Attack Target", "Attacker", "Killer"].has(target_selector):
		return "%s has no target during Battle Start." % target_selector
	if target_selector == "Attack Target" and not ["Attack", "Hit"].has(trigger):
		return "Attack Target is only available for Attack and Hit triggers."
	if target_selector == "Attacker" and not ["Damaged", "HP Below Threshold"].has(trigger):
		return "Attacker is only available for Damaged and HP Below Threshold triggers."
	if target_selector == "Killer" and trigger != "Death":
		return "Killer is only available for the Death trigger."
	if effect_type == "Apply Status":
		return "" if status != null else "Apply Status requires a status."
	if effect_type == "Remove Status":
		if status_removal_mode == "Specific Status" and status == null:
			return "Specific Status removal requires a status."
		if status_removal_mode == "Specific Status" and status_polarity != "Any" and status != null and status.polarity != status_polarity:
			return "Specific Status removal polarity does not match the referenced status."
		return ""
	if effect_type == "Modify Stat":
		return "" if amount != 0 else "Modify Stat requires a non-zero amount."
	if trigger == "Battle Start" and effect_type == "Gain Armor" and target_selector == "Self":
		return ""
	if trigger == "Attack" and effect_type == "Bonus Damage" and target_selector == "Attack Target":
		return ""
	if trigger == "Hit" and effect_type == "Reduce Target Armor" and target_selector == "Attack Target":
		return ""
	if (trigger == "Damaged" or trigger == "HP Below Threshold") and (effect_type == "Heal Self" or effect_type == "Increase Max HP") and target_selector == "Self":
		return ""
	if trigger == "Kill" and effect_type == "Heal Self" and target_selector == "Self":
		return ""
	if trigger == "Death" and effect_type == "Damage Killer" and target_selector == "Killer":
		return ""
	return "%s + %s + %s is not a supported effect combination." % [trigger, effect_type, target_selector]
