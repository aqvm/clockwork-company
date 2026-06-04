extends Resource

class_name ItemDefinition

@export var display_name := ""
@export var tags: Array[String] = []
@export_enum("Weapon", "Armor", "Helmet", "Trinket") var slot := "Weapon"
@export var max_hp_modifier := 0
@export var physical_damage_modifier := 0
@export var magic_damage_modifier := 0
@export var armor_modifier := 0
@export var action_interval_modifier := 0
@export var effects: Array[EffectDefinition] = []
