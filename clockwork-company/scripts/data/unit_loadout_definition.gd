extends Resource

class_name UnitLoadoutDefinition

@export var display_name := ""
@export var current_job: JobDefinition = null
@export var equipped_skill: SkillDefinition = null
@export var equipped_passive: PassiveDefinition = null
@export var equipped_reaction: ReactionDefinition = null
@export var weapon: ItemDefinition = null
@export var armor: ItemDefinition = null
@export var helmet: ItemDefinition = null
@export var trinket: ItemDefinition = null
@export var tactics: Array[TacticDefinition] = []
