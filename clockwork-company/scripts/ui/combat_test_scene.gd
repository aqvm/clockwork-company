extends Control

const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")

@onready var run_button: Button = %RunButton
@onready var combat_log: TextEdit = %CombatLog


func _ready() -> void:
	run_button.pressed.connect(_on_run_button_pressed)
	_on_run_button_pressed()


func _on_run_button_pressed() -> void:
	var simulator: CombatSimulator = CombatSimulatorScript.new()
	var log_lines := simulator.run_demo_battle()
	combat_log.text = _join_lines(log_lines)


func _join_lines(lines: Array[String]) -> String:
	var text := ""
	for line in lines:
		if not text.is_empty():
			text += "\n"
		text += line

	return text
