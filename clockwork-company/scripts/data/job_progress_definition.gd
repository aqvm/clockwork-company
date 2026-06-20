@tool
extends Resource
class_name JobProgressDefinition

## Job this progress record belongs to. Runtime unlock checks compare feature references against this job.
@export var job: JobDefinition = null
## Durable level in this job. Current cap is 3 per job.
@export_range(0, 3, 1) var level := 0
## Whether this job's primary and secondary current-job skills are unlocked.
@export var skill_unlocked := false
## Whether this job's passive is unlocked for assignment.
@export var passive_unlocked := false
## Whether this job's reaction is unlocked for assignment.
@export var reaction_unlocked := false
## Whether campaign planning must choose this job's level-1 skill-versus-reaction unlock before starting another scenario.
@export var pending_unlock_choice := false
