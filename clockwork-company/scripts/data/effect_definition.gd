@tool
extends Resource
class_name EffectDefinition

const STATUS_EFFECT_TYPES := ["Apply Status", "Maintain Status Aura", "Consume Status", "Detonate Status", "Gather Status", "Restore Max HP Lost To Status"]
const DURATION_STATUS_EFFECT_TYPES := ["Apply Status", "Replace Requested Status", "Gather Status", "Transfer Statuses"]
const AMOUNT_EFFECT_TYPES := ["Apply Status", "Deal Damage", "Heal", "Grant Armor", "Grant Battle Armor", "Grant Energy Shield", "Delay Action", "Apply Haste", "Increase Action Speed For Battle", "Add Attack Damage", "Modify Stat", "Modify Counter", "Begin Enemy Action Healing"]
const MODIFIER_DURATION_EFFECT_TYPES := ["Modify Stat", "Apply Haste", "Fortify Damage", "Redirect Enemy Attacks"]
const STATUS_AMOUNT_SOURCES := ["Target Max HP Times Event Status Stacks", "Target Status Stacks", "Event Target Status Stacks", "Defeated Target Status Stacks", "Total Status Stacks On Selected Group", "Total Status Max HP Loss On Selected Group", "Target Pending Status Damage"]
const GROUP_AMOUNT_SOURCES := ["Total Status Stacks On Selected Group", "Total Status Max HP Loss On Selected Group"]
const INTERVAL_AMOUNT_SOURCES := ["Target Damage Taken Within Interval", "Total Allied Magic Damage Taken Within Interval"]
const COUNTER_AMOUNT_SOURCES := ["Overhealing Diminishing", "Owner Counter", "Target Counter"]
const COUNTER_CONDITIONS := ["Event Count At Least", "Owner Counter At Least", "Target Counter At Least"]
const TARGET_TAG_CONDITIONS := ["Target Has Tag", "Target Missing Tag"]

## Label shown in the Inspector, combat logs, and tooltips. The resource name mirrors this value.
@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
## Shared TagDefinition resources. Target tag conditions compare these IDs against runtime unit tags.
@export var tags: Array[Resource] = []
## Combat event that can wake this effect. Changing it may reveal event-only fields such as requested/applied status matching.
@export_enum("Battle Start", "Battle State Changed", "Turn Start", "Turn Complete", "Action Completed", "Skill Used", "Skill Completed", "Attack", "Consecutive Attack", "Enemy Attack Targeted", "Hit", "Kill", "Death", "Ailment Damaged", "Damaged", "Physically Damaged", "Magically Damaged", "HP Below Threshold", "Damage Requested", "Healing Requested", "Healing Received", "Ally Overhealed", "Reaction Requested", "Status Application Requested", "Status Removal Requested", "Status Applied", "Externally Sourced Status Applied", "Enemy Status Applied", "Status Removed", "Reaction Triggered") var trigger := "Battle Start":
	set(value):
		trigger = value
		notify_property_list_changed()
## Extra test that must pass after the trigger matches. Some conditions require a status, tags, threshold, or counter.
@export_enum("Always", "Event Source Is Not Owner", "Owner Is Unarmed", "Event Count At Least", "Self HP Below Percent", "Target Has Tag", "Target Missing Tag", "Target Status Stacks At Least", "Target Pending Status Damage At Least HP", "Owner Counter At Least", "Target Counter At Least", "Requested Status Matches", "Applied Status Matches") var condition := "Always":
	set(value):
		condition = value
		notify_property_list_changed()
## Unit or units affected by the effect. Event-relative targets are only valid for triggers that provide that event participant.
@export_enum("Self", "Event Source", "Event Target", "Attack Target", "Attacker", "Killer", "All Units", "Allied Units", "Enemy Units", "Lowest HP Allied Unit", "Random Allied Unit", "Random Damaged Allied Unit", "Random Enemy Unit") var target_selector := "Self"
## Result produced when the effect resolves. This selection controls most of the conditional fields below.
@export_enum("Gain Armor", "Bonus Damage", "Reduce Target Armor", "Heal Self", "Damage Killer", "Increase Max HP", "Apply Status", "Maintain Status Aura", "Replace Requested Status", "Remove Status", "Consume Status", "Detonate Status", "Gather Status", "Transfer Statuses", "Restore Max HP Lost To Status", "Deal Damage", "Heal", "Grant Armor", "Grant Battle Armor", "Grant Energy Shield", "Disable Armor", "Delay Action", "Apply Haste", "Increase Action Speed For Battle", "Fortify Damage", "Redirect Enemy Attacks", "Add Attack Damage", "Modify Stat", "Modify Counter", "Reset Counter", "Seal Next Attack", "Prevent Request", "Execute Target", "Begin Enemy Action Healing", "Prepare Base Attack") var effect_type := "Gain Armor":
	set(value):
		effect_type = value
		notify_property_list_changed()
## Primary status reference. Used by status-applying/consuming effects, requested-status conditions, and as the fallback formula status for status-based amount sources.
@export var status: StatusDefinition = null
## Status matched by `Applied Status Matches`. Separate from `status` so an effect can watch one status and apply/read another.
@export var condition_status: StatusDefinition = null
## Optional status read by status-based amount formulas. If empty, formulas fall back to `status`.
@export var amount_status: StatusDefinition = null
## Boon pool used by `Replace Requested Status`. The resolver deterministically chooses one boon and prevents the incoming request.
@export var replacement_statuses: Array[StatusDefinition] = []
## If true, this application uses the override duration fields instead of the referenced status defaults.
@export var override_status_duration := false:
	set(value):
		override_status_duration = value
		notify_property_list_changed()
## Finite owner-turn duration for statuses applied by this effect. Hidden unless `override_status_duration` is true.
@export_range(1, 99, 1) var status_duration_turns := 3
## If true, this application is permanent even if the status default is finite.
@export var status_is_permanent := false:
	set(value):
		status_is_permanent = value
		notify_property_list_changed()
## Fixed stack count for `Apply Status` when `amount_source` is `Fixed`. Formula-driven applications use the amount fields instead.
@export_range(1, 99, 1) var status_stacks := 1
## Stack threshold used by `Target Status Stacks At Least`.
@export_range(1, 99, 1) var status_stack_threshold := 1
## Polarity filter for `Remove Status` and `Transfer Statuses`. `Any` includes boons and ailments.
@export_enum("Any", "Boon", "Ailment") var status_polarity := "Any"
## Removal behavior for `Remove Status`. `Specific Status` requires `status`; `Random Matching` uses `status_polarity`.
@export_enum("Random Matching", "Specific Status") var status_removal_mode := "Random Matching":
	set(value):
		status_removal_mode = value
		notify_property_list_changed()
## Stat changed by `Modify Stat`.
@export_enum("Max HP", "Physical Damage", "Magic Damage", "Armor", "Action Speed") var modified_stat := "Physical Damage"
## `Temporary Flat` adds a fixed value for completed target actions. `Dynamic Percent` recalculates a percentage modifier on `Battle State Changed`.
@export_enum("Temporary Flat", "Dynamic Percent") var modifier_mode := "Temporary Flat":
	set(value):
		modifier_mode = value
		notify_property_list_changed()
## Whether temporary or dynamic stat modifiers add to or subtract from the selected stat.
@export_enum("Increase", "Decrease") var modifier_direction := "Increase"
## Completed target actions before temporary modifiers, Haste, Fortify, or Redirect expire.
@export_range(1, 99, 1) var modifier_duration_turns := 1
## Formula used by amount-producing effects. `Fixed` uses `amount`, except fixed `Apply Status` uses `status_stacks`.
@export_enum("Fixed", "Target Current HP", "Target Max HP", "Target Max HP Times Event Status Stacks", "Target Recent Damage", "Target Damage Taken Within Interval", "Total Allied Magic Damage Taken Within Interval", "Target Predicted Next Action Damage", "Target Ailment Stacks", "Target Unique Boons", "Target Status Stacks", "Event Target Status Stacks", "Defeated Target Status Stacks", "Applied Status Stacks", "Total Status Stacks On Selected Group", "Total Status Max HP Loss On Selected Group", "Target Pending Status Damage", "Target Action Speed", "Event Amount", "Overhealing", "Overhealing Diminishing", "Owner Counter", "Target Counter") var amount_source := "Fixed":
	set(value):
		amount_source = value
		notify_property_list_changed()
## Rounding applied after formula multiplier/divisor scaling. Non-fixed formulas clamp negative results to 0.
@export_enum("Floor", "Ceil") var amount_rounding := "Floor"
## Unit group aggregated by total-status amount formulas. Independent from `target_selector`.
@export_enum("Self", "All Units", "Allied Units", "Enemy Units") var amount_target_selector := "Self"
## Named runtime counter read or changed by counter conditions, counter amount sources, Modify Counter, Reset Counter, and Overhealing Diminishing.
@export var counter_name := ""
## Required count for counter conditions and `Event Count At Least`.
@export_range(1, 999, 1) var counter_threshold := 1
## Numerator applied to formula results after reading `amount_source`.
@export_range(1, 99, 1) var amount_multiplier := 1
## Denominator applied to formula results after reading `amount_source`; never divides by less than 1.
@export_range(1, 99, 1) var amount_divisor := 1
## Timeline window used by interval damage formulas.
@export_range(1, 999, 1) var interval_time := 10
## Fixed amount for amount-producing effects when `amount_source` is `Fixed`. For fixed `Apply Status`, use `status_stacks` instead.
@export var amount := 0
## Damage channel for `Deal Damage`. Physical damage passes through armor and physical hooks; magic damage is direct.
@export_enum("Magic", "Physical") var damage_type := "Magic"
## Percent threshold used by HP threshold conditions and `Execute Target`.
@export_range(1, 100, 1) var threshold_percent := 50
## Speed cap used by `Apply Haste`, as a percent of the target's encounter-start action speed.
@export_range(100, 999, 1) var max_action_speed_percent := 200
## If true, this exact effect can resolve only once per battle for its owner/source.
@export var once_per_battle := false
## If true, ignores events whose payload `source_name` matches this effect's source name. Useful for avoiding self-feedback loops.
@export var ignore_events_from_same_effect_source := false
## If true, permits this effect to resolve for repeated events inside one causal chain. Default false prevents accidental recursion.
@export var repeat_within_event_chain := false


func _validate_property(property: Dictionary) -> void:
	var property_name := String(property.name)
	if property_name == "tags" and not TARGET_TAG_CONDITIONS.has(condition):
		_hide(property)
	elif property_name == "status" and not _uses_status():
		_hide(property)
	elif property_name == "condition_status" and condition != "Applied Status Matches":
		_hide(property)
	elif property_name == "amount_status" and not _uses_amount_status():
		_hide(property)
	elif property_name == "replacement_statuses" and effect_type != "Replace Requested Status":
		_hide(property)
	elif property_name == "override_status_duration" and not _uses_status_duration():
		_hide(property)
	elif property_name == "status_duration_turns" and (not _uses_status_duration() or not override_status_duration or status_is_permanent):
		_hide(property)
	elif property_name == "status_is_permanent" and (not _uses_status_duration() or not override_status_duration):
		_hide(property)
	elif property_name == "status_stacks" and not (effect_type == "Apply Status" and amount_source == "Fixed"):
		_hide(property)
	elif property_name == "status_stack_threshold" and condition != "Target Status Stacks At Least":
		_hide(property)
	elif property_name in ["status_polarity", "status_removal_mode"] and not effect_type in ["Remove Status", "Transfer Statuses"]:
		_hide(property)
	elif property_name in ["modified_stat", "modifier_mode", "modifier_direction"] and effect_type != "Modify Stat":
		_hide(property)
	elif property_name == "modifier_duration_turns" and not MODIFIER_DURATION_EFFECT_TYPES.has(effect_type):
		_hide(property)
	elif property_name == "amount_source" and not _uses_amount_source():
		_hide(property)
	elif property_name == "amount_rounding" and not _uses_amount_scaling():
		_hide(property)
	elif property_name == "amount_target_selector" and not GROUP_AMOUNT_SOURCES.has(amount_source):
		_hide(property)
	elif property_name == "counter_name" and not _uses_counter_name():
		_hide(property)
	elif property_name == "counter_threshold" and not COUNTER_CONDITIONS.has(condition):
		_hide(property)
	elif property_name in ["amount_multiplier", "amount_divisor"] and not _uses_amount_scaling():
		_hide(property)
	elif property_name == "interval_time" and not INTERVAL_AMOUNT_SOURCES.has(amount_source):
		_hide(property)
	elif property_name == "amount" and not _uses_fixed_amount():
		_hide(property)
	elif property_name == "damage_type" and effect_type != "Deal Damage":
		_hide(property)
	elif property_name == "threshold_percent" and not (condition == "Self HP Below Percent" or trigger == "HP Below Threshold" or effect_type == "Execute Target"):
		_hide(property)
	elif property_name == "max_action_speed_percent" and effect_type != "Apply Haste":
		_hide(property)


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
	if effect_type == "Execute Target" and (trigger != "Hit" or target_selector != "Attack Target"):
		return "Execute Target requires Hit + Attack Target."
	if effect_type == "Begin Enemy Action Healing" and target_selector != "Self":
		return "Begin Enemy Action Healing requires Self."
	if effect_type == "Prepare Base Attack" and target_selector != "Self":
		return "Prepare Base Attack requires Self."
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


const SHARED_EFFECT_TYPES := ["Apply Status", "Maintain Status Aura", "Replace Requested Status", "Remove Status", "Consume Status", "Detonate Status", "Gather Status", "Transfer Statuses", "Restore Max HP Lost To Status", "Deal Damage", "Heal", "Grant Armor", "Grant Battle Armor", "Grant Energy Shield", "Disable Armor", "Delay Action", "Apply Haste", "Increase Action Speed For Battle", "Fortify Damage", "Redirect Enemy Attacks", "Add Attack Damage", "Modify Stat", "Modify Counter", "Reset Counter", "Seal Next Attack", "Prevent Request", "Execute Target", "Begin Enemy Action Healing", "Prepare Base Attack"]
const REQUEST_TRIGGERS := ["Damage Requested", "Healing Requested", "Reaction Requested", "Status Application Requested", "Status Removal Requested"]


static func _hide(property: Dictionary) -> void:
	property.usage = PROPERTY_USAGE_NO_EDITOR


func _uses_status() -> bool:
	return STATUS_EFFECT_TYPES.has(effect_type) \
		or condition in ["Requested Status Matches", "Target Status Stacks At Least", "Target Pending Status Damage At Least HP"] \
		or (effect_type == "Remove Status" and status_removal_mode == "Specific Status") \
		or _uses_amount_status()


func _uses_status_duration() -> bool:
	return DURATION_STATUS_EFFECT_TYPES.has(effect_type)


func _uses_amount_status() -> bool:
	return STATUS_AMOUNT_SOURCES.has(amount_source)


func _uses_amount_source() -> bool:
	return AMOUNT_EFFECT_TYPES.has(effect_type)


func _uses_amount_scaling() -> bool:
	return _uses_amount_source() and amount_source != "Fixed"


func _uses_fixed_amount() -> bool:
	return _uses_amount_source() and amount_source == "Fixed" and effect_type != "Apply Status"


func _uses_counter_name() -> bool:
	return COUNTER_CONDITIONS.has(condition) \
		or COUNTER_AMOUNT_SOURCES.has(amount_source) \
		or effect_type in ["Modify Counter", "Reset Counter"]
