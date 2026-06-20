@tool
extends Resource
class_name EncounterDefinition

## Encounter name shown in scenario setup and tooltips.
@export var display_name := ""
## Recon/planning text shown before this encounter.
@export_multiline var scout_text := ""
## Enemy units used in this fixed encounter.
@export var enemy_units: Array[UnitDefinition] = []
