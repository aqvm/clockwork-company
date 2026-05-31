extends Resource

class_name UnitDefinition

@export var display_name := ""
@export_enum("Allies", "Enemies") var team := "Allies"
@export var max_hp := 1
@export var damage := 1
@export var armor := 0
@export var action_interval := 10
@export var loadout: UnitLoadoutDefinition = null
