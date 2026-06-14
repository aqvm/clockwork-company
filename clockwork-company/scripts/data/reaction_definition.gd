@tool
extends Resource
class_name ReactionDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export_enum("Damaged", "Physically Damaged", "Magically Damaged", "HP Below Threshold", "Lethal Physical Attack Requested", "Attack Targets Another Ally", "Status Application Requested", "Enemy Healing Requested", "Enemy Status Threshold Reached", "Enemy Died With Status") var trigger := "Damaged"
@export_enum("Always", "Self HP Below Percent", "Self Status Stacks At Least", "Requested Status Is Ailment", "Requested Status Matches") var condition := "Always"
@export_enum("Gain Armor", "Heal Self", "Damage Attacker", "Effects Only") var reaction_type := "Gain Armor"
@export var amount := 0
@export_range(1, 100, 1) var threshold_percent := 50
@export var status: StatusDefinition = null
@export_range(1, 99, 1) var status_stack_threshold := 1
@export var prevents_triggering_request := false
@export var replacement_statuses: Array[StatusDefinition] = []
@export var cooldown_turns := 0
@export var effects: Array[EffectDefinition] = []


func _to_string() -> String:
	if display_name.is_empty():
		return "ReactionDefinition"
	return display_name
