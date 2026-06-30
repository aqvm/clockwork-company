@tool
extends Resource

class_name JobDefinition

## Job name shown in planning, combat setup logs, and tooltips.
@export var display_name := ""
## Player-facing summary shown at the top of resource tooltips.
@export_multiline var tooltip_text := ""
## Shared TagDefinition resources for filtering, content organization, and future conditions.
@export var tags: Array[Resource] = []
## HP gained per level in this job, applied from durable job progress when a runtime unit is built.
@export var max_hp_growth := 0
## Physical damage gained per level in this job.
@export var physical_damage_growth := 0
## Magic damage gained per level in this job.
@export var magic_damage_growth := 0
## Armor gained per level in this job.
@export var armor_growth := 0
## Action speed gained per level in this job. Positive means the unit acts more often.
@export var action_speed_growth := 0
## If true, weapons in the loadout are skipped while this is the current job.
@export var forbid_weapon := false
## If true, armor in the loadout is skipped while this is the current job.
@export var forbid_armor := false
## If true, helmets in the loadout are skipped while this is the current job.
@export var forbid_helmet := false
## If true, trinkets in the loadout are skipped while this is the current job.
@export var forbid_trinket := false
## Primary current-job active skill. `Job Skill` tactics use this after the job's skill unlock is earned.
@export var skill: SkillDefinition = null
## Optional current-job bridge action. `Secondary Skill` tactics use this after the job's normal skill unlock is earned.
@export var secondary_skill: SkillDefinition = null
## Passive available from this job. Campaign loadouts equip learned passives through their assigned passive slot.
@export var passive: PassiveDefinition = null
## Reaction available from this job. Campaign loadouts equip learned reactions through their assigned reaction slot.
@export var reaction: ReactionDefinition = null
## Tactic automatically appended while this is the current job. It should demonstrate the job's default active behavior.
@export var default_tactic: TacticDefinition = null
