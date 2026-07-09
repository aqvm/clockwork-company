extends SceneTree

const CombatPreviewTextBuilderScript := preload("res://scripts/ui/combat_preview_text_builder.gd")

var check_completed := false


class StatusLineSource:
	var lines: Array[String] = []

	func status_lines() -> Array[String]:
		return lines


class LabStateSource:
	var allied_units: Array[UnitDefinition] = []
	var enemy_units: Array[UnitDefinition] = []
	var last_message := ""


func _init() -> void:
	process_frame.connect(_quit_if_incomplete, CONNECT_ONE_SHOT)

	var raw_lines: Array[String] = [
		"Scenario: tutorial",
		"t=000 | Battle starts.",
		"Battle-start child line",
		"Roster:",
		"- Ally",
		"Combat log:",
		"t=001 | Ally acts.",
	]
	var static_lines := CombatPreviewTextBuilderScript.battle_static_lines(raw_lines)
	assert(static_lines == ["Scenario: tutorial", "Roster:", "- Ally"], "Battle static lines should keep setup text and skip timed combat lines.")

	var campaign := StatusLineSource.new()
	campaign.lines = ["Campaign: First Road"]
	var run := StatusLineSource.new()
	run.lines = ["Run: Encounter 1"]
	var run_lines := CombatPreviewTextBuilderScript.run_static_lines(campaign, run, static_lines)
	assert(run_lines == ["Campaign: First Road", "", "Run: Encounter 1", "", "Scenario: tutorial", "Roster:", "- Ally"], "Run preview text should compose campaign, run, and fight setup sections.")

	var lab_state := LabStateSource.new()
	lab_state.allied_units.append(_unit("Lab Ally"))
	lab_state.enemy_units.append(_unit("Lab Enemy"))
	lab_state.last_message = "Saved."
	var lab_lines := CombatPreviewTextBuilderScript.combat_lab_static_lines(lab_state, ["Roster:"])
	assert(lab_lines[0].begins_with("Combat Lab:"), "Combat Lab text should identify the lab mode.")
	assert(lab_lines.has("Allies: 1. Lab Ally") and lab_lines.has("Enemies: 1. Lab Enemy"), "Combat Lab text should summarize both lab parties.")
	assert(lab_lines.has("Saved.") and lab_lines.has("Roster:"), "Combat Lab text should include recent feedback and fight setup lines.")

	check_completed = true
	print("Combat preview text builder validation passed.")
	quit(0)


func _quit_if_incomplete() -> void:
	if check_completed:
		return
	push_error("Combat preview text builder validation aborted before completion.")
	quit(1)


func _unit(display_name: String) -> UnitDefinition:
	var unit := UnitDefinition.new()
	unit.display_name = display_name
	return unit
