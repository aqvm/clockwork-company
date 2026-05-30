extends Resource

class_name ItemDefinition

@export var display_name := ""
@export_enum("Weapon", "Armor", "Trinket") var slot := "Weapon"
@export var max_hp_modifier := 0
@export var damage_modifier := 0
@export var armor_modifier := 0
@export var action_interval_modifier := 0
