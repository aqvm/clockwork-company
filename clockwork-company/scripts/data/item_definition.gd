@tool
extends Resource

class_name ItemDefinition

## Item name shown in planning, equipment lists, combat setup logs, and tooltips.
@export var display_name := ""
## Shared TagDefinition resources for filtering, content organization, and future conditions.
@export var tags: Array[Resource] = []
## Equipment slot this item occupies. Content validation rejects items equipped in the wrong slot.
@export_enum("Weapon", "Armor", "Helmet", "Trinket") var slot := "Weapon"
## Flat maximum HP modifier applied while the item is equipped and legal for the unit.
@export var max_hp_modifier := 0
## Flat physical damage modifier applied while the item is equipped and legal for the unit.
@export var physical_damage_modifier := 0
## Flat magic damage modifier applied while the item is equipped and legal for the unit.
@export var magic_damage_modifier := 0
## Flat armor modifier applied while the item is equipped and legal for the unit.
@export var armor_modifier := 0
## Flat action speed modifier applied while the item is equipped and legal for the unit.
@export var action_speed_modifier := 0
## Triggered effects owned by this item. Item effects resolve relative to the equipped unit.
@export var effects: Array[EffectDefinition] = []
