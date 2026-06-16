extends Resource

class_name TacticDefinition

@export var display_name := ""
@export var tags: Array[String] = []
@export_enum("Always", "Self HP Below Half", "Ally HP Below Half", "Enemy Alive", "Target Has Status", "Target Status Stacks At Least", "Target Pending Status Damage At Least HP", "Target Slower Than Self") var condition := "Always"
@export_enum("Attack", "Heal", "Guard", "Job Skill", "Assigned Skill") var action := "Attack"
@export_enum("Self", "Lowest HP Ally", "Lowest HP Ally With Status", "Frontmost Enemy") var target := "Frontmost Enemy"
@export var status: StatusDefinition = null
@export_range(1, 99, 1) var status_stack_threshold := 1
@export var foretell_enabled := false
