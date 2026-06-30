@tool
extends Resource
class_name ReactionDefinition

const REQUEST_TRIGGERS := ["Status Application Requested", "Enemy Healing Requested", "Lethal Physical Attack Requested"]

## Label shown in the Inspector, combat logs, and tooltips. The resource name mirrors this value.
@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
## Player-facing summary shown at the top of resource tooltips.
@export_multiline var tooltip_text := ""
## Shared TagDefinition resources for filtering and future conditions.
@export var tags: Array[Resource] = []
## Combat event that can trigger the reaction. This controls request-prevention and status-threshold fields.
@export_enum("Damaged", "Physically Damaged", "Magically Damaged", "Ally Magically Damaged", "HP Below Threshold", "Lethal Physical Attack Requested", "Attack Targets Another Ally", "Status Application Requested", "Ally Ailment Applied", "Enemy Healing Requested", "Enemy Status Threshold Reached", "Enemy Died With Status", "Enemy Died With Ailments") var trigger := "Damaged":
	set(value):
		trigger = value
		notify_property_list_changed()
## Additional trigger gate. Requested-status conditions only make sense for status-application request reactions.
@export_enum("Always", "Self HP Below Percent", "Self Status Stacks At Least", "Requested Status Is Ailment", "Requested Status Matches") var condition := "Always":
	set(value):
		condition = value
		notify_property_list_changed()
## Built-in reaction result. `Effects Only` relies on the nested effects array, usually with `Reaction Triggered`.
@export_enum("Gain Armor", "Heal Self", "Damage Attacker", "Effects Only") var reaction_type := "Gain Armor":
	set(value):
		reaction_type = value
		notify_property_list_changed()
## Fixed amount for built-in `Gain Armor`, `Heal Self`, and `Damage Attacker` reactions.
@export var amount := 0
## HP percentage used by `HP Below Threshold` and `Self HP Below Percent`.
@export_range(1, 100, 1) var threshold_percent := 50
## Status reference used by status-stack conditions, requested-status matching, enemy threshold triggers, and enemy death status triggers.
@export var status: StatusDefinition = null
## Stack threshold used by `Self Status Stacks At Least` and `Enemy Status Threshold Reached`.
@export_range(1, 99, 1) var status_stack_threshold := 1
## If true, supported request triggers prevent the incoming request after this reaction fires.
@export var prevents_triggering_request := false:
	set(value):
		prevents_triggering_request = value
		notify_property_list_changed()
## Boon pool granted by a request-preventing `Status Application Requested` reaction. Ignored by non-status request reactions.
@export var replacement_statuses: Array[StatusDefinition] = []
## Owner-turn cooldown after this reaction fires.
@export var cooldown_turns := 0
## Shared effects, normally authored with `Reaction Triggered`. These can add the real payload for `Effects Only` reactions or supplement built-in reactions.
@export var effects: Array[EffectDefinition] = []


func _validate_property(property: Dictionary) -> void:
	var property_name := String(property.name)
	if property_name == "amount" and reaction_type == "Effects Only":
		_hide(property)
	elif property_name == "threshold_percent" and not (trigger == "HP Below Threshold" or condition == "Self HP Below Percent"):
		_hide(property)
	elif property_name == "status" and not _uses_status():
		_hide(property)
	elif property_name == "status_stack_threshold" and condition != "Self Status Stacks At Least" and trigger != "Enemy Status Threshold Reached":
		_hide(property)
	elif property_name == "prevents_triggering_request" and not REQUEST_TRIGGERS.has(trigger):
		_hide(property)
	elif property_name == "replacement_statuses" and not (trigger == "Status Application Requested" and prevents_triggering_request):
		_hide(property)


func _to_string() -> String:
	if display_name.is_empty():
		return "ReactionDefinition"
	return display_name


static func _hide(property: Dictionary) -> void:
	property.usage = PROPERTY_USAGE_NO_EDITOR


func _uses_status() -> bool:
	return condition in ["Self Status Stacks At Least", "Requested Status Matches"] \
		or trigger in ["Enemy Status Threshold Reached", "Enemy Died With Status"]
