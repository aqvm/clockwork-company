@tool
extends Resource
class_name ScenarioRuleDefinition

## Stable id for this scenario rule.
@export var rule_id := ""
## Player-facing rule name.
@export var display_name := ""
## Rule explanation shown in setup and tooltips.
@export_multiline var description := ""
## Shared TagDefinition resources for filtering and content organization.
@export var tags: Array[Resource] = []
## Triggered effects owned by this scenario rule. Rules have no owner, so avoid owner-only targets like `Self`.
@export var effects: Array[EffectDefinition] = []
