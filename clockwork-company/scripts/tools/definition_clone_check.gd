extends SceneTree

const CheckHarnessScript := preload("res://scripts/tools/check_harness.gd")
const DefinitionCloneHelperScript := preload("res://scripts/data/definition_clone_helper.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")
const BleedStatus := preload("res://resources/statuses/bleed.tres")

var check_completed := false


func _init() -> void:
	process_frame.connect(_quit_if_incomplete, CONNECT_ONE_SHOT)
	var checks = CheckHarnessScript.new()
	checks.run_case("definition clone preserves tactic status fields", _check_definition_clone_preserves_tactic_status_fields)
	checks.run_case("runtime clone isolates loadout resources", _check_runtime_clone_isolates_loadout_resources)
	print("Definition clone checks passed: %d cases." % checks.case_count)
	check_completed = true
	quit(0)


func _check_definition_clone_preserves_tactic_status_fields() -> bool:
	var tactic := TacticDefinition.new()
	tactic.display_name = "Bleed Focus"
	tactic.condition = "Target Status Stacks At Least"
	tactic.action = "Job Skill"
	tactic.target = "Frontmost Enemy"
	tactic.status = BleedStatus
	tactic.status_stack_threshold = 4
	tactic.foretell_enabled = true
	var clone: TacticDefinition = DefinitionCloneHelperScript.clone_tactic(tactic)
	return clone != tactic \
		and clone.status == BleedStatus \
		and clone.status_stack_threshold == 4 \
		and clone.foretell_enabled


func _check_runtime_clone_isolates_loadout_resources() -> bool:
	var job := JobDefinition.new()
	job.display_name = "Clone Job"
	var skill := SkillDefinition.new()
	skill.display_name = "Clone Skill"
	job.skill = skill
	var passive := PassiveDefinition.new()
	passive.display_name = "Clone Passive"
	job.passive = passive
	var reaction := ReactionDefinition.new()
	reaction.display_name = "Clone Reaction"
	job.reaction = reaction
	var tactic := TacticDefinition.new()
	tactic.display_name = "Clone Tactic"
	var loadout := UnitLoadoutDefinition.new()
	loadout.display_name = "Clone Loadout"
	loadout.current_job = job
	loadout.equipped_skill = skill
	loadout.equipped_passive = passive
	loadout.equipped_reaction = reaction
	loadout.tactics = [tactic]
	var unit := UnitDefinition.new()
	unit.display_name = "Clone Unit"
	unit.team = "Allies"
	unit.loadout = loadout
	var progress := JobProgressDefinition.new()
	progress.job = job
	progress.level = 3
	progress.skill_unlocked = true
	progress.passive_unlocked = true
	progress.reaction_unlocked = true
	unit.job_progress = [progress]
	var state = UnitStateScript.new(unit)
	var clone = state.clone_runtime_state()
	if clone.loadout == state.loadout:
		return false
	if clone.current_job == state.current_job or clone.current_skill == state.current_skill:
		return false
	if clone.current_passive == state.current_passive or clone.current_reaction == state.current_reaction:
		return false
	if clone.loadout.current_job != clone.current_job:
		return false
	if clone.loadout.equipped_skill != clone.assigned_skill:
		return false
	clone.current_skill.display_name = "Changed Clone Skill"
	return state.current_skill.display_name == "Clone Skill"


func _quit_if_incomplete() -> void:
	if check_completed:
		return
	push_error("Definition clone checks did not complete before the first frame.")
	quit(1)
