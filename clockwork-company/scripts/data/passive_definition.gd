@tool
extends Resource
class_name PassiveDefinition

const AMOUNT_PASSIVE_TYPES := ["Attack Damage Bonus", "Heal Bonus", "Guard Armor Bonus", "Extend Allied Buff Duration"]

## Label shown in the Inspector, combat logs, and tooltips. The resource name mirrors this value.
@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
## Player-facing summary shown at the top of resource tooltips.
@export_multiline var tooltip_text := ""
## Shared TagDefinition resources for filtering and future conditions.
@export var tags: Array[Resource] = []
## Built-in passive behavior. Use `None` when this passive is entirely authored through `effects`.
@export_enum("None", "Attack Damage Bonus", "Heal Bonus", "Guard Armor Bonus", "Forecast", "Extend Allied Buff Duration") var passive_type := "None":
	set(value):
		passive_type = value
		notify_property_list_changed()
## Numeric payload for built-in amount-based passives. `Extend Allied Buff Duration` interprets it as a percent.
@export var amount := 0
## Owner-turn cooldown for built-in passive triggers. Effect-level once-per-battle and cooldown behavior is configured on nested effects.
@export var cooldown_turns := 0
## Shared effects owned by the passive. These can define fully custom passive behavior when `passive_type` is `None`.
@export var effects: Array[EffectDefinition] = []


func _validate_property(property: Dictionary) -> void:
	if String(property.name) == "amount" and not AMOUNT_PASSIVE_TYPES.has(passive_type):
		_hide(property)


func _to_string() -> String:
	if display_name.is_empty():
		return "PassiveDefinition"
	return display_name


static func _hide(property: Dictionary) -> void:
	property.usage = PROPERTY_USAGE_NO_EDITOR
