extends Resource

class_name JobDefinition

@export var display_name := ""
@export var tags: Array[String] = []
@export var max_hp_growth := 0
@export var physical_damage_growth := 0
@export var magic_damage_growth := 0
@export var armor_growth := 0
@export var action_interval_growth := 0
@export var forbid_weapon := false
@export var forbid_armor := false
@export var forbid_helmet := false
@export var forbid_trinket := false
@export var skill: SkillDefinition = null
@export var passive: PassiveDefinition = null
@export var reaction: ReactionDefinition = null
@export var default_tactic: TacticDefinition = null
