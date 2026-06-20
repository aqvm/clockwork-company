@tool
extends Resource
class_name SkillDefinition

## Label shown in the Inspector, combat logs, tactic summaries, and tooltips. The resource name mirrors this value.
@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
## Shared TagDefinition resources for filtering, future conditions, and damage tagging. A `magic` tag can affect some attack-damage handling.
@export var tags: Array[Resource] = []
## Main action performed when this skill resolves. This controls which action-specific fields are visible.
@export_enum("Attack", "Heal", "Guard", "Apply Status", "Effects Only") var action := "Attack":
	set(value):
		action = value
		notify_property_list_changed()
## Fallback target preference for tooling and authored skill intent. Tactics still provide the actual target during combat.
@export_enum("Self", "Lowest HP Ally", "Frontmost Enemy") var default_target := "Frontmost Enemy"
## Damage channel for `Attack` skills. Physical is reduced by armor; magic is direct; split divides the base physical attack between both channels.
@export_enum("Physical", "Magic", "Split Evenly") var attack_damage_type := "Physical"
## Number of complete attacks performed by an `Attack` skill. Each attack runs targeting, hit effects, damage, reactions, and defeat separately.
@export_range(1, 9, 1) var attack_count := 1
## Status applied by an `Apply Status` skill. Effect-based applications use each nested effect's status instead.
@export var status: StatusDefinition = null
## If true, this skill uses the override duration fields instead of the referenced status defaults.
@export var override_status_duration := false:
	set(value):
		override_status_duration = value
		notify_property_list_changed()
## Owner-turn duration for the status applied by an `Apply Status` skill. Hidden unless `override_status_duration` is true.
@export_range(1, 99, 1) var status_duration_turns := 3
## If true, this skill applies its status permanently even if the status default is finite.
@export var status_is_permanent := false:
	set(value):
		status_is_permanent = value
		notify_property_list_changed()
## Flat bonus to the built-in action amount. Used by `Attack`, `Heal`, and `Guard`; ignored by `Apply Status` and `Effects Only`.
@export var amount_modifier := 0
## Owner-turn cooldown started after using this skill. Tactics skip this skill while it is cooling down.
@export var cooldown_turns := 0
## Optional shared effects that can run on `Skill Used` or `Skill Completed`. Required when action is `Effects Only`; also valid for pre/post effects on other actions.
@export var effects: Array[EffectDefinition] = []


func _validate_property(property: Dictionary) -> void:
	var property_name := String(property.name)
	if property_name == "attack_damage_type" and action != "Attack":
		_hide(property)
	elif property_name == "attack_count" and action != "Attack":
		_hide(property)
	elif property_name == "status" and action != "Apply Status":
		_hide(property)
	elif property_name == "override_status_duration" and action != "Apply Status":
		_hide(property)
	elif property_name == "status_duration_turns" and (action != "Apply Status" or not override_status_duration or status_is_permanent):
		_hide(property)
	elif property_name == "status_is_permanent" and (action != "Apply Status" or not override_status_duration):
		_hide(property)
	elif property_name == "amount_modifier" and not action in ["Attack", "Heal", "Guard"]:
		_hide(property)


func _to_string() -> String:
	if display_name.is_empty():
		return "SkillDefinition"
	return display_name


func resolved_status_duration_turns() -> int:
	if override_status_duration or status == null:
		return status_duration_turns
	return status.default_duration_turns


func resolved_status_is_permanent() -> bool:
	if override_status_duration or status == null:
		return status_is_permanent
	return status.default_is_permanent


static func _hide(property: Dictionary) -> void:
	property.usage = PROPERTY_USAGE_NO_EDITOR
