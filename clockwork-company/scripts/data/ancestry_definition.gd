@tool
extends Resource

class_name AncestryDefinition

## Ancestry name shown in planning, combat setup logs, and tooltips. The resource name mirrors this value.
@export var display_name := "":
	set(value):
		display_name = value
		resource_name = value
## Shared TagDefinition resources for filtering, content organization, and future conditions.
@export var tags: Array[Resource] = []
## Minimum suggested HP when authoring a unit of this ancestry. Existing units keep their explicit stats.
@export var min_max_hp := 1
## Maximum suggested HP when authoring a unit of this ancestry. Not used as combat randomization.
@export var max_max_hp := 1
## Minimum suggested physical damage when authoring a unit of this ancestry.
@export var min_physical_damage := 1
## Maximum suggested physical damage when authoring a unit of this ancestry.
@export var max_physical_damage := 1
## Minimum suggested magic damage when authoring a unit of this ancestry.
@export var min_magic_damage := 0
## Maximum suggested magic damage when authoring a unit of this ancestry.
@export var max_magic_damage := 0
## Minimum suggested armor when authoring a unit of this ancestry.
@export var min_armor := 0
## Maximum suggested armor when authoring a unit of this ancestry.
@export var max_armor := 0
## Minimum suggested action speed when authoring a unit of this ancestry.
@export var min_action_speed := 10
## Maximum suggested action speed when authoring a unit of this ancestry.
@export var max_action_speed := 10
## HP gained per total unit job level from this ancestry.
@export var max_hp_growth := 0
## Physical damage gained per total unit job level from this ancestry.
@export var physical_damage_growth := 0
## Magic damage gained per total unit job level from this ancestry.
@export var magic_damage_growth := 0
## Armor gained per total unit job level from this ancestry.
@export var armor_growth := 0
## Action speed gained per total unit job level from this ancestry.
@export var action_speed_growth := 0
## If true, weapons in the loadout are skipped for units of this ancestry.
@export var forbid_weapon := false
## If true, armor in the loadout is skipped for units of this ancestry.
@export var forbid_armor := false
## If true, helmets in the loadout are skipped for units of this ancestry.
@export var forbid_helmet := false
## If true, trinkets in the loadout are skipped for units of this ancestry.
@export var forbid_trinket := false
## Always-on ancestry feature active regardless of current job or learned assignments.
@export var feature: AncestryFeatureDefinition = null
## Authoring notes only. These do not affect combat.
@export_multiline var notes := ""
