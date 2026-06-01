extends Resource

class_name TacticDefinition

@export var tags: Array[String] = []
@export_enum("Always", "Self HP Below Half", "Ally HP Below Half", "Enemy Alive") var condition := "Always"
@export_enum("Attack", "Heal", "Guard") var action := "Attack"
@export_enum("Self", "Lowest HP Ally", "Frontmost Enemy") var target := "Frontmost Enemy"
