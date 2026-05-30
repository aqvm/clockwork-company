extends Resource

class_name ItemDefinition

@export var display_name := ""
@export_enum("Weapon", "Armor", "Trinket") var slot := "Weapon"
@export var max_hp_modifier := 0
@export var damage_modifier := 0
@export var armor_modifier := 0
@export var action_interval_modifier := 0
@export_enum("None", "Battle Start", "Attack", "Hit", "Kill", "Death") var trigger := "None"
@export_enum("None", "Gain Armor", "Bonus Damage", "Reduce Target Armor", "Heal Self", "Damage Killer") var effect := "None"
@export var effect_amount := 0
