extends Resource

class_name UnitDefinition

@export var display_name := ""
@export var tags: Array[String] = []
@export_enum("Allies", "Enemies") var team := "Allies"
@export var ancestry: AncestryDefinition = null
@export var max_hp := 1
@export var physical_damage := 1
@export var magic_damage := 0
@export var armor := 0
@export var action_interval := 10
@export var job_progress: Array[JobProgressDefinition] = []
@export var loadout: UnitLoadoutDefinition = null
