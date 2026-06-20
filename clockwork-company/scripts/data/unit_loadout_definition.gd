@tool
extends Resource

class_name UnitLoadoutDefinition

## Loadout name shown in planning panels and tooltips.
@export var display_name := ""
## Job currently active for this loadout. Supplies current-job skills, restrictions, growth, and default tactic.
@export var current_job: JobDefinition = null
## Learned cross-job skill assigned separately from current-job `Job Skill` and `Secondary Skill`.
@export var equipped_skill: SkillDefinition = null
## Learned passive assigned from job progress. Null means no learned passive is equipped.
@export var equipped_passive: PassiveDefinition = null
## Learned reaction assigned from job progress. Null means no learned reaction is equipped.
@export var equipped_reaction: ReactionDefinition = null
## Weapon item. Skipped at runtime if current job or ancestry forbids weapons.
@export var weapon: ItemDefinition = null
## Armor item. Skipped at runtime if current job or ancestry forbids armor.
@export var armor: ItemDefinition = null
## Helmet item. Skipped at runtime if current job or ancestry forbids helmets.
@export var helmet: ItemDefinition = null
## Trinket item. Skipped at runtime if current job or ancestry forbids trinkets.
@export var trinket: ItemDefinition = null
## Ordered tactics evaluated before the current job's default tactic. If none match, the unit attacks the frontmost enemy.
@export var tactics: Array[TacticDefinition] = []
