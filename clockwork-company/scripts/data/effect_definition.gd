@tool
extends Resource
class_name EffectDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export_enum("Battle Start", "Battle State Changed", "Turn Start", "Turn Complete", "Action Completed", "Skill Used", "Skill Completed", "Attack", "Consecutive Attack", "Enemy Attack Targeted", "Hit", "Kill", "Death", "Ailment Damaged", "Damaged", "Physically Damaged", "Magically Damaged", "HP Below Threshold", "Damage Requested", "Healing Requested", "Healing Received", "Ally Overhealed", "Reaction Requested", "Status Application Requested", "Status Removal Requested", "Status Applied", "Externally Sourced Status Applied", "Enemy Status Applied", "Status Removed", "Reaction Triggered") var trigger := "Battle Start"
@export_enum("Always", "Event Source Is Not Owner", "Owner Is Unarmed", "Event Count At Least", "Self HP Below Percent", "Target Has Tag", "Target Missing Tag", "Target Status Stacks At Least", "Target Pending Status Damage At Least HP", "Owner Counter At Least", "Target Counter At Least", "Requested Status Matches", "Applied Status Matches") var condition := "Always"
@export_enum("Self", "Event Source", "Event Target", "Attack Target", "Attacker", "Killer", "All Units", "Allied Units", "Enemy Units", "Lowest HP Allied Unit", "Random Allied Unit", "Random Damaged Allied Unit", "Random Enemy Unit") var target_selector := "Self"
@export_enum("Gain Armor", "Bonus Damage", "Reduce Target Armor", "Heal Self", "Damage Killer", "Increase Max HP", "Apply Status", "Maintain Status Aura", "Replace Requested Status", "Remove Status", "Consume Status", "Detonate Status", "Gather Status", "Transfer Statuses", "Restore Max HP Lost To Status", "Deal Damage", "Heal", "Grant Armor", "Grant Battle Armor", "Grant Energy Shield", "Disable Armor", "Delay Action", "Hasten Action", "Hasten Action For Battle", "Fortify Damage", "Redirect Enemy Attacks", "Add Attack Damage", "Modify Stat", "Modify Counter", "Reset Counter", "Seal Next Attack", "Prevent Request") var effect_type := "Gain Armor"
@export var status: StatusDefinition = null
@export var condition_status: StatusDefinition = null
@export var amount_status: StatusDefinition = null
@export var replacement_statuses: Array[StatusDefinition] = []
@export_range(1, 99, 1) var status_duration_turns := 3
@export var status_is_permanent := false
@export_range(1, 99, 1) var status_stacks := 1
@export_range(1, 99, 1) var status_stack_threshold := 1
@export_enum("Any", "Boon", "Ailment") var status_polarity := "Any"
@export_enum("Random Matching", "Specific Status") var status_removal_mode := "Random Matching"
@export_enum("Max HP", "Physical Damage", "Magic Damage", "Armor", "Action Interval") var modified_stat := "Physical Damage"
@export_enum("Temporary Flat", "Dynamic Percent") var modifier_mode := "Temporary Flat"
@export_enum("Increase", "Decrease") var modifier_direction := "Increase"
@export_range(1, 99, 1) var modifier_duration_turns := 1
@export_enum("Fixed", "Target Current HP", "Target Max HP", "Target Max HP Times Event Status Stacks", "Target Recent Damage", "Target Ailment Stacks", "Target Unique Boons", "Target Status Stacks", "Event Target Status Stacks", "Defeated Target Status Stacks", "Applied Status Stacks", "Total Status Stacks On Selected Group", "Total Status Max HP Loss On Selected Group", "Target Pending Status Damage", "Target Action Interval", "Event Amount", "Overhealing", "Overhealing Diminishing", "Owner Counter", "Target Counter") var amount_source := "Fixed"
@export_enum("Floor", "Ceil") var amount_rounding := "Floor"
@export_enum("Self", "All Units", "Allied Units", "Enemy Units") var amount_target_selector := "Self"
@export var counter_name := ""
@export_range(1, 999, 1) var counter_threshold := 1
@export_range(1, 99, 1) var amount_multiplier := 1
@export_range(1, 99, 1) var amount_divisor := 1
@export var amount := 0
@export_enum("Magic", "Physical") var damage_type := "Magic"
@export_range(1, 100, 1) var threshold_percent := 50
@export var once_per_battle := false
@export var ignore_events_from_same_effect_source := false
@export var repeat_within_event_chain := false


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
	if target_selector == "Attacker" and not ["Damaged", "Physically Damaged", "Magically Damaged", "HP Below Threshold"].has(trigger):
		return "Attacker is only available for damage-received triggers."
	if target_selector == "Killer" and trigger != "Death":
		return "Killer is only available for the Death trigger."
	if effect_type == "Apply Status" and status == null:
		return "Apply Status requires a status."
	if effect_type == "Maintain Status Aura" and status == null:
		return "Maintain Status Aura requires a status."
	if effect_type == "Maintain Status Aura" and trigger != "Battle State Changed":
		return "Maintain Status Aura requires Battle State Changed."
	if effect_type == "Replace Requested Status":
		if trigger != "Status Application Requested":
			return "Replace Requested Status requires Status Application Requested."
		if replacement_statuses.is_empty():
			return "Replace Requested Status requires at least one replacement status."
		for replacement in replacement_statuses:
			if replacement == null or replacement.polarity != "Boon":
				return "Replace Requested Status replacements must be boons."
	if effect_type in ["Consume Status", "Detonate Status", "Gather Status", "Restore Max HP Lost To Status"] and status == null:
		return "%s requires a status." % effect_type
	if effect_type == "Remove Status":
		if status_removal_mode == "Specific Status" and status == null:
			return "Specific Status removal requires a status."
		if status_removal_mode == "Specific Status" and status_polarity != "Any" and status != null and status.polarity != status_polarity:
			return "Specific Status removal polarity does not match the referenced status."
	if effect_type == "Modify Stat" and amount == 0 and amount_source == "Fixed":
		return "Modify Stat requires a non-zero amount."
	if effect_type == "Modify Counter" and counter_name.is_empty():
		return "Modify Counter requires a counter name."
	if effect_type == "Reset Counter" and counter_name.is_empty():
		return "Reset Counter requires a counter name."
	if effect_type == "Prevent Request" and not REQUEST_TRIGGERS.has(trigger):
		return "Prevent Request requires a request trigger."
	if condition == "Requested Status Matches" and status == null:
		return "Requested Status Matches requires a status."
	if condition == "Requested Status Matches" and not trigger in ["Status Application Requested", "Status Removal Requested"]:
		return "Requested Status Matches requires a status request trigger."
	if condition == "Applied Status Matches" and condition_status == null:
		return "Applied Status Matches requires a condition status."
	if condition == "Applied Status Matches" and not trigger in ["Status Applied", "Externally Sourced Status Applied", "Enemy Status Applied"]:
		return "Applied Status Matches requires a status-applied trigger."
	if amount_source in ["Target Status Stacks", "Event Target Status Stacks", "Defeated Target Status Stacks", "Total Status Stacks On Selected Group", "Total Status Max HP Loss On Selected Group", "Target Pending Status Damage"] and amount_status == null and status == null:
		return "%s requires a status." % amount_source
	if modifier_mode == "Dynamic Percent" and effect_type != "Modify Stat":
		return "Dynamic Percent is only available for Modify Stat."
	if modifier_mode == "Dynamic Percent" and trigger != "Battle State Changed":
		return "Dynamic Percent modifiers require the Battle State Changed trigger."
	if amount_source in ["Overhealing Diminishing", "Owner Counter", "Target Counter"] and counter_name.is_empty():
		return "%s requires a counter name." % amount_source
	if condition in ["Owner Counter At Least", "Target Counter At Least"] and counter_name.is_empty():
		return "%s requires a counter name." % condition
	if SHARED_EFFECT_TYPES.has(effect_type):
		return ""
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


const SHARED_EFFECT_TYPES := ["Apply Status", "Maintain Status Aura", "Replace Requested Status", "Remove Status", "Consume Status", "Detonate Status", "Gather Status", "Transfer Statuses", "Restore Max HP Lost To Status", "Deal Damage", "Heal", "Grant Armor", "Grant Battle Armor", "Grant Energy Shield", "Disable Armor", "Delay Action", "Hasten Action", "Hasten Action For Battle", "Fortify Damage", "Redirect Enemy Attacks", "Add Attack Damage", "Modify Stat", "Modify Counter", "Reset Counter", "Seal Next Attack", "Prevent Request"]
const REQUEST_TRIGGERS := ["Damage Requested", "Healing Requested", "Reaction Requested", "Status Application Requested", "Status Removal Requested"]
