extends Resource

class_name JobDefinition

@export var display_name := ""
@export var max_hp_modifier := 0
@export var damage_modifier := 0
@export var armor_modifier := 0
@export var action_interval_modifier := 0
@export var can_equip_weapon := true
@export var can_equip_armor := true
@export var can_equip_trinket := true
@export_enum("None", "Guard Training", "First Aid", "Sharpened Edge") var job_effect := "None"
