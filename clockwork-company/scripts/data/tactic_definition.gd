extends Resource

class_name TacticDefinition

@export var display_name := ""
@export var tags: Array[String] = []
@export_enum("Always", "Self HP Below Half", "Ally HP Below Half", "Enemy Alive") var condition := "Always"
@export_enum("Attack", "Heal", "Guard", "Job Skill", "Assigned Skill") var action := "Attack"
@export_enum("Self", "Lowest HP Ally", "Frontmost Enemy") var target := "Frontmost Enemy"
