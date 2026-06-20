@tool
extends Resource

class_name UnitDefinition

## Unit name shown in rosters, combat logs, planning panels, and tooltips.
@export var display_name := ""
## Shared TagDefinition resources for filtering, target tag conditions, and content organization.
@export var tags: Array[Resource] = []
## Side this unit fights on when loaded directly into an encounter or lab setup.
@export_enum("Allies", "Enemies") var team := "Allies"
## Ancestry source for growth, equipment restrictions, and ancestry feature.
@export var ancestry: AncestryDefinition = null
## Explicit base maximum HP before ancestry/job growth and equipment modifiers.
@export var max_hp := 1
## Explicit base physical damage before growth and equipment modifiers.
@export var physical_damage := 1
## Explicit base magic damage before growth and equipment modifiers.
@export var magic_damage := 0
## Explicit base armor before growth and equipment modifiers.
@export var armor := 0
## Explicit base action speed before growth and equipment modifiers.
@export var action_speed := 10
## Durable job progress records. Runtime unlock checks and stat growth read this list.
@export var job_progress: Array[JobProgressDefinition] = []
## Current job, assigned learned features, equipment, and tactics for this unit.
@export var loadout: UnitLoadoutDefinition = null
