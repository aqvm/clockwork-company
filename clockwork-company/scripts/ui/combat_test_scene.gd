extends Control

const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const CombatLogHighlightPaletteScript := preload("res://scripts/ui/combat_log_highlight_palette.gd")
const UnitStatusDotScript := preload("res://scripts/ui/unit_status_dot.gd")
const COMBAT_LOG_HEADER := "Combat log:"
const RUN_BUTTON_READY_TEXT := "Run Jobs 3v3 Fight"
const RUN_BUTTON_REPLAYING_TEXT := "Replaying..."
const DEFAULT_WINDOW_AREA_FRACTION := 0.75
const MIN_CONDITIONS_HEIGHT := 120
const SECONDS_PER_SIM_SECOND := 0.2
const MIN_SECONDS_BETWEEN_REPLAY_ACTIONS := 0.1
const DEFAULT_LOG_HIGHLIGHT_PALETTE := preload("res://resources/ui/combat_log_highlight_palette_default.tres")

@onready var run_button: Button = %RunButton
@onready var log_split: VSplitContainer = %LogSplit
@onready var conditions_label: Label = %ConditionsLabel
@onready var combat_summary: RichTextLabel = %CombatSummary
@onready var combat_log: RichTextLabel = %CombatLog
@onready var allies_row: HBoxContainer = %AlliesRow
@onready var enemies_row: HBoxContainer = %EnemiesRow
@onready var replay_timer: Timer = %ReplayTimer
@export var log_highlight_palette: CombatLogHighlightPaletteScript = DEFAULT_LOG_HIGHLIGHT_PALETTE

var cached_replay_lines: Array[String] = []
var cached_static_lines: Array[String] = []
var combat_replay_events: Array[Dictionary] = []
var replay_units_by_name := {}
var replay_unit_widgets_by_name := {}
var replay_event_index := 0
var autoscroll_enabled := true
var is_programmatic_scroll := false
var replay_is_active := false
var displayed_sim_time := 0.0
var current_event_time := 0.0
var next_event_time := 0.0
var event_transition_elapsed := 0.0


func _ready() -> void:
	_size_window_to_half_screen()
	run_button.pressed.connect(_on_run_button_pressed)
	replay_timer.timeout.connect(_on_replay_timer_timeout)
	replay_timer.one_shot = true
	combat_log.get_v_scroll_bar().value_changed.connect(_on_combat_log_scroll_value_changed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_load_combat_preview()


func _process(delta: float) -> void:
	if not replay_is_active:
		return

	event_transition_elapsed = min(replay_timer.wait_time, event_transition_elapsed + delta)
	if replay_timer.wait_time > 0.0:
		var lerp_weight: float = clamp(event_transition_elapsed / replay_timer.wait_time, 0.0, 1.0)
		displayed_sim_time = lerp(current_event_time, next_event_time, lerp_weight)
		_update_visual_replay_widgets()


func _on_run_button_pressed() -> void:
	_stop_log_replay()
	_clear_replay_log()

	_build_visual_replay_model()
	_prepare_replay_events(cached_replay_lines)
	_build_visual_replay_widgets()

	run_button.disabled = true
	run_button.text = RUN_BUTTON_REPLAYING_TEXT
	replay_is_active = true
	autoscroll_enabled = true
	replay_event_index = 0
	displayed_sim_time = 0.0
	current_event_time = 0.0
	next_event_time = 0.0
	event_transition_elapsed = 0.0

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
	cached_static_lines.clear()
	_split_log_lines(log_lines, static_lines, cached_replay_lines)
	cached_static_lines = static_lines.duplicate()
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
			var event_time := _parse_event_time(line)
			current_event = {
				"time": event_time,
				"lines": [line],
			}
			combat_replay_events.append(current_event)
			continue

		if current_event.is_empty():
			current_event = {
				"time": 0.0,
				"lines": [line],
			}
			combat_replay_events.append(current_event)
		else:
			var current_event_lines: Array = current_event["lines"]
			current_event_lines.append(line)


func _line_is_timestamped_action(line: String) -> bool:
	return line.begins_with("t=")


func _parse_event_time(line: String) -> float:
	var time_text := line.substr(2, 3)
	return float(time_text.to_int())


func _show_next_replay_event() -> void:
	if replay_event_index >= combat_replay_events.size():
		_finish_log_replay()
		return

	var event := combat_replay_events[replay_event_index]
	current_event_time = float(event.get("time", current_event_time))
	displayed_sim_time = current_event_time
	_apply_event_lines_to_visual_model(event["lines"])
	_update_visual_replay_widgets()

	var event_lines: Array = event["lines"]
	for line: String in event_lines:
		_append_log_line(line)

	replay_event_index += 1
	_schedule_next_replay_event()


func _schedule_next_replay_event() -> void:
	if replay_event_index >= combat_replay_events.size():
		_finish_log_replay()
		return

	next_event_time = float(combat_replay_events[replay_event_index].get("time", current_event_time))
	event_transition_elapsed = 0.0
	var sim_delta: float = max(0.0, next_event_time - current_event_time)
	replay_timer.wait_time = max(MIN_SECONDS_BETWEEN_REPLAY_ACTIONS, sim_delta * SECONDS_PER_SIM_SECOND)
	replay_timer.start()


func _append_lines(target_log: RichTextLabel, lines: Array[String]) -> void:
	for line in lines:
		_append_rich_text_line(target_log, line)


func _append_log_line(line: String) -> void:
	_append_rich_text_line(combat_log, line)
	_scroll_combat_log_to_bottom()


func _append_rich_text_line(target_log: RichTextLabel, line: String) -> void:
	target_log.append_text("%s\n" % _format_log_line_with_highlighting(line))


func _escape_bbcode_text(text: String) -> String:
	return text.replace("[", "[lb]")


func _format_log_line_with_highlighting(line: String) -> String:
	var safe_text := _escape_bbcode_text(line)
	var color_text := _log_highlight_color_for_line(line)

	if color_text.is_empty():
		return safe_text

	return "[color=%s]%s[/color]" % [color_text, safe_text]


func _log_highlight_color_for_line(line: String) -> String:
	if log_highlight_palette == null:
		return ""

	if line.begins_with("Result:"):
		return _bbcode_color_text(log_highlight_palette.result_color)

	if line.begins_with("t="):
		return _bbcode_color_text(log_highlight_palette.timestamp_color)

	if "Damage dealt:" in line:
		return _bbcode_color_text(log_highlight_palette.damage_color)

	if " attacks " in line:
		return _bbcode_color_text(log_highlight_palette.attack_color)

	if " heals " in line:
		return _bbcode_color_text(log_highlight_palette.heal_color)

	if " guards:" in line or "guard expires:" in line:
		return _bbcode_color_text(log_highlight_palette.guard_color)

	if line.begins_with("Tactic selected:") or line.begins_with("No tactic matched;") or line.begins_with("Tactic skipped:"):
		return _bbcode_color_text(log_highlight_palette.tactic_color)

	if line.begins_with("Job effect "):
		return _bbcode_color_text(log_highlight_palette.job_effect_color)

	if " triggers " in line:
		return _bbcode_color_text(log_highlight_palette.item_trigger_color)

	if " is defeated" in line:
		return _bbcode_color_text(log_highlight_palette.defeat_color)

	return ""


func _bbcode_color_text(color: Color) -> String:
	return "#" + color.to_html(false)


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
	replay_units_by_name.clear()
	replay_unit_widgets_by_name.clear()
	for child in allies_row.get_children():
		child.queue_free()
	for child in enemies_row.get_children():
		child.queue_free()


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


func _build_visual_replay_model() -> void:
	replay_units_by_name.clear()
	var in_roster := false
	var roster_team := ""
	# Visual replay intentionally rebuilds unit state from static setup text, so
	# this parser must stay aligned with the roster line format in CombatSimulator.
	for line in cached_static_lines:
		if line.strip_edges() == "Roster:":
			in_roster = true
			continue
		if not in_roster:
			continue
		if line.strip_edges() == "Allies":
			roster_team = "Allies"
			continue
		if line.strip_edges() == "Enemies":
			roster_team = "Enemies"
			continue
		if not line.contains("| HP "):
			continue

		var parsed := _parse_roster_line(line.strip_edges(), roster_team)
		if not parsed.is_empty():
			replay_units_by_name[parsed["name"]] = parsed


func _parse_roster_line(line: String, team: String) -> Dictionary:
	var parts := line.split("|")
	if parts.size() < 5:
		return {}

	var name := parts[0].strip_edges()
	var max_hp := _parse_stat_segment(parts[1], "HP")
	var action_interval := _parse_stat_segment(parts[4], "interval")
	if team.is_empty():
		team = "Enemies"

	return {
		"name": name,
		"team": team,
		"max_hp": max_hp,
		"hp": max_hp,
		"action_interval": action_interval,
		"next_action_time": float(action_interval),
		"display_time": 0.0,
		"is_alive": true,
	}


func _parse_stat_segment(segment: String, label: String) -> int:
	var prefix := "%s " % label
	var text := segment.strip_edges()
	if not text.begins_with(prefix):
		return 0
	return text.trim_prefix(prefix).to_int()


func _build_visual_replay_widgets() -> void:
	for child in allies_row.get_children():
		child.queue_free()
	for child in enemies_row.get_children():
		child.queue_free()
	replay_unit_widgets_by_name.clear()

	var names := replay_units_by_name.keys()
	names.sort()
	for name in names:
		var unit_data: Dictionary = replay_units_by_name[name]
		var dot: Control = UnitStatusDotScript.new()
		if unit_data["team"] == "Allies":
			allies_row.add_child(dot)
		else:
			enemies_row.add_child(dot)
		replay_unit_widgets_by_name[name] = dot

	_update_visual_replay_widgets()


func _apply_event_lines_to_visual_model(event_lines: Array) -> void:
	for line: String in event_lines:
		_apply_event_line(line)


func _apply_event_line(line: String) -> void:
	# These string checks are deliberately narrow and presentation-only.
	# If combat log phrasing changes, update this parser alongside that change.
	if line.ends_with(" takes a turn."):
		var actor_name := line.get_slice("|", 1).replace("takes a turn.", "").strip_edges()
		if replay_units_by_name.has(actor_name):
			var actor_state: Dictionary = replay_units_by_name[actor_name]
			actor_state["next_action_time"] = current_event_time + float(actor_state["action_interval"])
		return

	if line.contains(" HP: ") and line.contains(" -> "):
		var target_name := _target_name_from_hp_line(line)
		if replay_units_by_name.has(target_name):
			var hp_section := line.get_slice("HP: ", 1)
			var new_hp := hp_section.get_slice(" -> ", 1).trim_suffix(".").to_int()
			var target_state: Dictionary = replay_units_by_name[target_name]
			target_state["hp"] = new_hp
			target_state["is_alive"] = new_hp > 0
		return

	if line.ends_with(" is defeated."):
		var defeated_name := line.replace("is defeated.", "").strip_edges()
		if replay_units_by_name.has(defeated_name):
			var defeated_state: Dictionary = replay_units_by_name[defeated_name]
			defeated_state["hp"] = 0
			defeated_state["is_alive"] = false


func _target_name_from_hp_line(line: String) -> String:
	if line.contains(" heals "):
		return line.get_slice(" heals ", 1).get_slice(" for ", 0).strip_edges()

	var before_hp := line.get_slice(" HP:", 0)
	return before_hp.get_slice(". ", 1).get_slice(" armor:", 0).strip_edges()


func _update_visual_replay_widgets() -> void:
	for name in replay_unit_widgets_by_name.keys():
		if not replay_units_by_name.has(name):
			continue
		var state: Dictionary = replay_units_by_name[name]
		state["display_time"] = displayed_sim_time
		var dot: Control = replay_unit_widgets_by_name[name]
		dot.configure(state)
