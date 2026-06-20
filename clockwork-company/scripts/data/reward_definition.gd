@tool
extends Resource
class_name RewardDefinition

## Reward name shown in scenario rewards and tooltips.
@export var display_name := ""
## Reward explanation shown to the player.
@export_multiline var description := ""
## Optional unit name this reward is intended for. Empty means generally available.
@export var target_unit_name := ""
## Item granted or offered by this reward.
@export var item: ItemDefinition = null
