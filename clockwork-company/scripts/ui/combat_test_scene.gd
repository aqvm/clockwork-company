extends Control

const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const COMBAT_LOG_HEADER := "Combat log:"
const RUN_BUTTON_READY_TEXT := "Run Jobs 3v3 Fight"
const RUN_BUTTON_REPLAYING_TEXT := "Replaying..."
const DEFAULT_WINDOW_AREA_FRACTION := 0.75
const MIN_CONDITIONS_HEIGHT := 120
const SECONDS_BETWEEN_REPLAY_ACTIONS := 1.0

@onready var run_button: Button = %RunButton
@onready var log_split: VSplitContainer = %LogSplit
@onready var conditions_label: Label = %ConditionsLabel
@onready var combat_summary: RichTextLabel = %CombatSummary
@onready var combat_log: RichTextLabel = %CombatLog
@onready var replay_timer: Timer = %ReplayTimer

var cached_replay_lines: Array[String] = []
var combat_replay_events: Array[Dictionary] = []
var replay_event_index := 0
var autoscroll_enabled := true
var is_programmatic_scroll := false
var replay_is_active := false


func _ready() -> void:
	_size_window_to_half_screen()
	run_button.pressed.connect(_on_run_button_pressed)
	replay_timer.timeout.connect(_on_replay_timer_timeout)
	replay_timer.one_shot = true
	combat_log.get_v_scroll_bar().value_changed.connect(_on_combat_log_scroll_value_changed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_load_combat_preview()


func _on_run_button_pressed() -> void:
	_stop_log_replay()
	_clear_replay_log()

	_prepare_replay_events(cached_replay_lines)

	run_button.disabled = true
	run_button.text = RUN_BUTTON_REPLAYING_TEXT
	replay_is_active = true
	autoscroll_enabled = true
	replay_event_index = 0

	_append_log_line(COMBAT_LOG_HEADER)
	_show_next_replay_event()


func _on_replay_timer_timeout() -> void:
	_show_next_replay_event()


func _on_combat_log_scroll_value_changed(_value: float) -> void:
	if not replay_is_active or is_programmatic_scroll:
		return

	autoscroll_enabled = false


func _on_viewport_size_changed() -> void:
	call_deferred("_resize_conditions_pane")


func _load_combat_preview() -> void:
	_clear_logs()

	var simulator: CombatSimulator = CombatSimulatorScript.new()
	var log_lines := simulator.run_demo_battle()
	var static_lines: Array[String] = []

	cached_replay_lines.clear()
	_split_log_lines(log_lines, static_lines, cached_replay_lines)
	_append_lines(combat_summary, static_lines)
	call_deferred("_resize_conditions_pane")


func _split_log_lines(log_lines: Array[String], static_lines: Array[String], replay_lines: Array[String]) -> void:
	var found_combat_log := false
	for line in log_lines:
		if line == COMBAT_LOG_HEADER:
			found_combat_log = true
			continue

		if found_combat_log:
			replay_lines.append(line)
		else:
			static_lines.append(line)


func _prepare_replay_events(replay_lines: Array[String]) -> void:
	combat_replay_events.clear()
	var current_event: Dictionary = {}
	for line in replay_lines:
		if _line_is_timestamped_action(line):
			current_event = {
				"lines": [line],
			}
			combat_replay_events.append(current_event)
			continue

		if current_event.is_empty():
			current_event = {
				"time": 0,
				"lines": [line],
			}
			combat_replay_events.append(current_event)
		else:
			var current_event_lines: Array = current_event["lines"]
			current_event_lines.append(line)


func _line_is_timestamped_action(line: String) -> bool:
	return line.begins_with("t=")


func _show_next_replay_event() -> void:
	if replay_event_index >= combat_replay_events.size():
		_finish_log_replay()
		return

	var event := combat_replay_events[replay_event_index]
	var event_lines: Array = event["lines"]
	for line: String in event_lines:
		_append_log_line(line)

	replay_event_index += 1
	_schedule_next_replay_event()


func _schedule_next_replay_event() -> void:
	if replay_event_index >= combat_replay_events.size():
		_finish_log_replay()
		return

	replay_timer.wait_time = SECONDS_BETWEEN_REPLAY_ACTIONS
	replay_timer.start()


func _append_lines(target_log: RichTextLabel, lines: Array[String]) -> void:
	for line in lines:
		_append_rich_text_line(target_log, line)


func _append_log_line(line: String) -> void:
	_append_rich_text_line(combat_log, line)
	_scroll_combat_log_to_bottom()


func _append_rich_text_line(target_log: RichTextLabel, line: String) -> void:
	target_log.append_text("%s\n" % _escape_bbcode_text(line))


func _escape_bbcode_text(text: String) -> String:
	return text.replace("[", "[lb]")


func _scroll_combat_log_to_bottom() -> void:
	if not autoscroll_enabled:
		return

	is_programmatic_scroll = true
	combat_log.scroll_to_line(max(0, combat_log.get_line_count() - 1))
	call_deferred("_finish_programmatic_scroll")


func _finish_programmatic_scroll() -> void:
	is_programmatic_scroll = false


func _resize_conditions_pane() -> void:
	if combat_summary.get_line_count() == 0 or log_split.size.y <= 0:
		return

	var max_conditions_height := int(log_split.size.y * 0.5)
	var desired_conditions_height := combat_summary.get_content_height() + int(conditions_label.size.y) + 12
	log_split.split_offset = clamp(desired_conditions_height, MIN_CONDITIONS_HEIGHT, max_conditions_height)


func _size_window_to_half_screen() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var side_scale := sqrt(DEFAULT_WINDOW_AREA_FRACTION)
	var target_size := Vector2i(
		int(usable_rect.size.x * side_scale),
		int(usable_rect.size.y * side_scale)
	)
	var target_position := Vector2i(
		usable_rect.position.x + int((usable_rect.size.x - target_size.x) * 0.5),
		usable_rect.position.y + int((usable_rect.size.y - target_size.y) * 0.5)
	)

	DisplayServer.window_set_size(target_size)
	DisplayServer.window_set_position(target_position)


func _clear_logs() -> void:
	combat_summary.clear()
	_clear_replay_log()


func _clear_replay_log() -> void:
	combat_log.clear()


func _stop_log_replay() -> void:
	replay_timer.stop()
	combat_replay_events.clear()
	replay_event_index = 0
	replay_is_active = false
	autoscroll_enabled = true
	is_programmatic_scroll = false
	run_button.disabled = false
	run_button.text = RUN_BUTTON_READY_TEXT


func _finish_log_replay() -> void:
	replay_timer.stop()
	replay_is_active = false
	run_button.disabled = false
	run_button.text = RUN_BUTTON_READY_TEXT
