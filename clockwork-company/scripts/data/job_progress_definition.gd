extends Resource
class_name JobProgressDefinition

@export var job: JobDefinition = null
@export_range(0, 5, 1) var level := 0
@export var xp := 0
@export var skill_unlocked := false
@export var passive_unlocked := false
@export var reaction_unlocked := false
@export var pending_unlock_choice := false
