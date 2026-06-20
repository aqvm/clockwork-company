extends SceneTree

const BattleContributionPanelScript := preload("res://scripts/ui/battle_contribution_panel.gd")
const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var simulator: CombatSimulator = CombatSimulatorScript.new()
	var report: Dictionary = simulator.run_battle_report(JsonContentLoaderScript.load_demo_unit_definitions(), "Contribution panel check")
	var contributions: Array = report.get("contribution_summary", [])
	assert(not contributions.is_empty(), "Real battle report should include contribution rows for the panel.")

	var panel: Control = BattleContributionPanelScript.new()
	root.add_child(panel)
	await process_frame
	panel.call("show_contributions", contributions)
	await process_frame
	assert(panel.visible, "Contribution panel should be visible when rendering real report data.")
	assert(_label_with_text(panel, "Battle Contributions") != null, "Contribution panel should render its title.")
	assert(_label_with_text(panel, "Dmg") != null and _label_with_text(panel, "Heal") != null and _label_with_text(panel, "Mit/Prev") != null, "Contribution panel should render contribution columns.")
	var first_name := String((contributions[0] as Dictionary).get("name", ""))
	assert(not first_name.is_empty() and _label_with_text(panel, first_name) != null, "Contribution panel should render unit rows from a real battle report.")
	panel.call("clear_contributions")
	await process_frame
	assert(not panel.visible, "Contribution panel should hide when cleared.")

	print("Battle contribution panel validation passed: panel rendered contribution data from a real battle report.")
	quit(0)


func _label_with_text(parent: Node, text: String) -> Label:
	for child in parent.get_children():
		if child is Label and child.text == text:
			return child
		var nested := _label_with_text(child, text)
		if nested != null:
			return nested
	return null
