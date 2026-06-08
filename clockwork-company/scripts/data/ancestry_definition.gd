@tool
extends Resource

class_name AncestryDefinition

@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
@export var tags: Array[String] = []
@export var min_max_hp := 1
@export var max_max_hp := 1
@export var min_physical_damage := 1
@export var max_physical_damage := 1
@export var min_magic_damage := 0
@export var max_magic_damage := 0
@export var min_armor := 0
@export var max_armor := 0
@export var min_action_interval := 10
@export var max_action_interval := 10
@export var max_hp_growth := 0
@export var physical_damage_growth := 0
@export var magic_damage_growth := 0
@export var armor_growth := 0
@export var action_interval_growth := 0
@export var forbid_weapon := false
@export var forbid_armor := false
@export var forbid_helmet := false
@export var forbid_trinket := false
@export var feature: Resource = null
@export_multiline var notes := ""
