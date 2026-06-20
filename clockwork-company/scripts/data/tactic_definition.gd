@tool
extends Resource

class_name TacticDefinition

const STATUS_AWARE_CONDITIONS := ["Target Has Status", "Target Status Stacks At Least", "Target Pending Status Damage At Least HP"]

## Label shown in planning UI, logs, and tooltips.
@export var display_name := ""
## Shared TagDefinition resources for filtering and future tactic authoring tools.
@export var tags: Array[Resource] = []
## Test that must pass before this tactic can select its action. Some conditions depend on `target`, `status`, or `status_stack_threshold`.
@export_enum("Always", "Self HP Below Half", "Ally HP Below Half", "Enemy Alive", "Target Has Status", "Target Status Stacks At Least", "Target Pending Status Damage At Least HP", "Target Slower Than Self") var condition := "Always":
	set(value):
		condition = value
		notify_property_list_changed()
## Action performed when this tactic is the first valid tactic. Skill actions require the matching skill slot to be unlocked and off cooldown.
@export_enum("Attack", "Heal", "Guard", "Job Skill", "Secondary Skill", "Assigned Skill") var action := "Attack"
## Target rule evaluated before the condition. Status-aware ally targeting requires `status`.
@export_enum("Self", "Lowest HP Ally", "Lowest HP Ally With Status", "Frontmost Enemy") var target := "Frontmost Enemy":
	set(value):
		target = value
		notify_property_list_changed()
## Status read by status-aware conditions and `Lowest HP Ally With Status`.
@export var status: StatusDefinition = null
## Required stack count for `Target Status Stacks At Least`.
@export_range(1, 99, 1) var status_stack_threshold := 1
## If true, this tactic evaluates against an isolated forecast before the actor's next turn. Requires an equipped Forecast passive at runtime.
@export var foretell_enabled := false


func _validate_property(property: Dictionary) -> void:
	var property_name := String(property.name)
	if property_name == "status" and not _uses_status():
		_hide(property)
	elif property_name == "status_stack_threshold" and condition != "Target Status Stacks At Least":
		_hide(property)


static func _hide(property: Dictionary) -> void:
	property.usage = PROPERTY_USAGE_NO_EDITOR


func _uses_status() -> bool:
	return STATUS_AWARE_CONDITIONS.has(condition) or target == "Lowest HP Ally With Status"
