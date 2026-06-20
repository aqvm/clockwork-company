@tool
extends Resource
class_name StatusDefinition

const AMOUNT_STATUS_TYPES := ["Bleed", "Burning", "Regeneration", "Renewal"]
const AMOUNT_PERCENT_STATUS_TYPES := ["Reconstitution"]

## Label shown in the Inspector, combat logs, status dots, and tooltips. The resource name mirrors this value.
@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
## Whether this status is beneficial or harmful. Used by cleansing, Ward, replacement reactions, log coloring, and status-polarity formulas.
@export_enum("Boon", "Ailment") var polarity := "Boon"
## Mechanical identity read by combat rules. Pick the implemented rules hook this status should use.
@export_enum("Confusion", "Reconstitution", "Regeneration", "Bleed", "Burning", "Numb", "Frost", "Ward", "Rot", "Renewal") var status_type := "Reconstitution":
	set(value):
		status_type = value
		notify_property_list_changed()
## What happens when the same status is applied again: ignore, refresh duration, or add stacks.
@export_enum("Ignore", "Refresh", "Intensify") var stacking_rule := "Refresh":
	set(value):
		stacking_rule = value
		notify_property_list_changed()
## Default owner-turn duration used by skills and effects unless they explicitly override duration.
@export_range(1, 99, 1) var default_duration_turns := 3
## If true, skills and effects apply this status permanently unless they explicitly override duration.
@export var default_is_permanent := false:
	set(value):
		default_is_permanent = value
		notify_property_list_changed()
## If true, stack count cannot exceed `max_stacks`. Burning intentionally disables this.
@export var stack_cap_enabled := true:
	set(value):
		stack_cap_enabled = value
		notify_property_list_changed()
## Maximum stacks when `stack_cap_enabled` is true.
@export_range(1, 99, 1) var max_stacks := 1
## Shared TagDefinition resources for filtering, content organization, and future conditions.
@export var tags: Array[Resource] = []
## Flat numeric payload read by specific status rules: Bleed/Burning action damage, Regeneration healing, and Renewal healing.
@export_range(0, 99, 1) var amount := 0
## Percent payload read by Reconstitution recovery.
@export_range(1, 100, 1) var amount_percent := 50
## If true, finite statuses lose remaining turns on the owner's turn flow. Permanent applications ignore natural elapse.
@export var elapses_naturally := true
## Human-facing rules text shown in status tooltips and authoring references.
@export_multiline var description := ""


func _validate_property(property: Dictionary) -> void:
	var property_name := String(property.name)
	if property_name == "default_duration_turns" and default_is_permanent:
		_hide(property)
	elif property_name == "max_stacks" and not stack_cap_enabled:
		_hide(property)
	elif property_name == "amount" and not AMOUNT_STATUS_TYPES.has(status_type):
		_hide(property)
	elif property_name == "amount_percent" and not AMOUNT_PERCENT_STATUS_TYPES.has(status_type):
		_hide(property)


func _to_string() -> String:
	if display_name.is_empty():
		return "StatusDefinition"
	return display_name


static func _hide(property: Dictionary) -> void:
	property.usage = PROPERTY_USAGE_NO_EDITOR
