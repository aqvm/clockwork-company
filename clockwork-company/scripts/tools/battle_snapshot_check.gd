extends SceneTree

const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")

const EXPECTED_WINNER := "Allies"
const EXPECTED_ACTIONS_TAKEN := 80
const EXPECTED_LINE_COUNT := 763
const EXPECTED_EVENT_COUNT := 763
const EXPECTED_COMBAT_EVENT_COUNT := 1178
const EXPECTED_SNAPSHOT_COUNT := 82

var check_completed := false


func _init() -> void:
	process_frame.connect(_quit_if_incomplete, CONNECT_ONE_SHOT)
	var simulator: CombatSimulator = CombatSimulatorScript.new()
	var report: Dictionary = simulator.run_demo_battle_report()
	var metrics := {
		"winner": String(report.get("winner", "")),
		"actions_taken": int(report.get("actions_taken", -1)),
		"line_count": report.get("lines", []).size(),
		"event_count": report.get("events", []).size(),
		"combat_event_count": report.get("combat_events", []).size(),
		"snapshot_count": report.get("replay_snapshots", []).size(),
	}
	assert(String(metrics["winner"]) == EXPECTED_WINNER, "Demo battle winner changed: %s" % JSON.stringify(metrics))
	assert(int(metrics["actions_taken"]) == EXPECTED_ACTIONS_TAKEN, "Demo battle action count changed: %s" % JSON.stringify(metrics))
	assert(int(metrics["line_count"]) == EXPECTED_LINE_COUNT, "Demo battle rendered line count changed: %s" % JSON.stringify(metrics))
	assert(int(metrics["event_count"]) == EXPECTED_EVENT_COUNT, "Demo battle presentation event count changed: %s" % JSON.stringify(metrics))
	assert(int(metrics["combat_event_count"]) == EXPECTED_COMBAT_EVENT_COUNT, "Demo battle combat event count changed: %s" % JSON.stringify(metrics))
	assert(int(metrics["snapshot_count"]) == EXPECTED_SNAPSHOT_COUNT, "Demo battle replay snapshot count changed: %s" % JSON.stringify(metrics))
	print("Battle snapshot validation passed: %s" % JSON.stringify(metrics))
	check_completed = true
	quit(0)


func _quit_if_incomplete() -> void:
	if check_completed:
		return
	push_error("Battle snapshot check did not complete before the first frame.")
	quit(1)
