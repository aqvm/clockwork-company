extends VBoxContainer
class_name CombatReplayPanel

signal replay_finished
signal runtime_tooltip_requested(source: Control, snapshot: Dictionary)
signal tooltip_cleared

const UnitStatusDotScript := preload("res://scripts/ui/unit_status_dot.gd")
const CombatLogRichTextFormatterScript := preload("res://scripts/ui/combat_log_rich_text_formatter.gd")
const COMBAT_LOG_HEADER := "Combat log:"
const SECONDS_PER_SIM_SECOND := 0.2
const MIN_SECONDS_BETWEEN_REPLAY_ACTIONS := 0.1
const REPLAY_SPEEDS: Array[float] = [0.5, 1.0, 2.0, 4.0]

@onready var combat_log: RichTextLabel = %CombatLog
@onready var allies_row: HBoxContainer = %AlliesRow
@onready var enemies_row: HBoxContainer = %EnemiesRow

var timer: Timer = null
var log_highlight_palette = null
var speed_label: Label = null
var speed_buttons: Array[Button] = []
var replay_events: Array[Dictionary] = []
var structured_events: Array[Dictionary] = []
var roster_units: Array[Dictionary] = []
var units_by_name := {}
var units_by_id := {}
var unit_widgets_by_name := {}
var replay_event_index := 0
var autoscroll_enabled := true
var is_programmatic_scroll := false
var replay_is_active := false
var displayed_sim_time := 0.0
var current_event_time := 0.0
var next_event_time := 0.0
var event_transition_elapsed := 0.0
var active_event_actor_name := ""
var replay_speed := 1.0


func setup(replay_timer: Timer, highlight_palette) -> void:
	timer = replay_timer
	log_highlight_palette = highlight_palette
	timer.timeout.connect(_on_replay_timer_timeout)
	timer.one_shot = true
	combat_log.get_v_scroll_bar().value_changed.connect(_on_combat_log_scroll_value_changed)
	_setup_speed_controls()


func tick(delta: float) -> void:
	if not replay_is_active:
		return

	event_transition_elapsed = min(timer.wait_time, event_transition_elapsed + delta)
	if timer.wait_time > 0.0:
		var lerp_weight: float = clamp(event_transition_elapsed / timer.wait_time, 0.0, 1.0)
		displayed_sim_time = lerp(current_event_time, next_event_time, lerp_weight)
		_update_visual_replay_widgets()


func load_preview(new_roster_units: Array, new_structured_events: Array) -> void:
	roster_units = _typed_dictionary_array(new_roster_units)
	structured_events = _typed_dictionary_array(new_structured_events)
	_build_visual_replay_model()
	_build_visual_replay_widgets()
	displayed_sim_time = 0.0
	active_event_actor_name = ""
	_update_visual_replay_widgets()


func start_replay(new_roster_units: Array, new_structured_events: Array) -> void:
	clear_replay()
	load_preview(new_roster_units, new_structured_events)
	_prepare_replay_events()

	replay_is_active = true
	autoscroll_enabled = true
	replay_event_index = 0
	displayed_sim_time = 0.0
	current_event_time = 0.0
	next_event_time = 0.0
	event_transition_elapsed = 0.0
	active_event_actor_name = ""

	_append_log_line(COMBAT_LOG_HEADER)
	_show_next_replay_event()


func stop_replay() -> void:
	if timer != null:
		timer.stop()
	replay_events.clear()
	replay_event_index = 0
	replay_is_active = false
	autoscroll_enabled = true
	is_programmatic_scroll = false


func clear_replay() -> void:
	combat_log.clear()
	units_by_name.clear()
	units_by_id.clear()
	unit_widgets_by_name.clear()
	for child in allies_row.get_children():
		child.queue_free()
	for child in enemies_row.get_children():
		child.queue_free()


func is_replaying() -> bool:
	return replay_is_active


func _typed_dictionary_array(values: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for value in values:
		if value is Dictionary:
			out.append((value as Dictionary).duplicate(true))
	return out


func _prepare_replay_events() -> void:
	replay_events.clear()
	var event_by_id := {}
	var root_ids: Array[int] = []
	for entry: Dictionary in structured_events:
		var entry_id := int(entry.get("id", -1))
		event_by_id[entry_id] = entry
		if int(entry.get("parent_id", -1)) == -1:
			root_ids.append(entry_id)

	var last_timed_event := 0.0
	for root_id in root_ids:
		if not event_by_id.has(root_id):
			continue
		var entry: Dictionary = event_by_id[root_id]
		var event_type := String(entry.get("event_type", "text"))
		var timed_value := int(entry.get("time", -1))
		if timed_value < 0 and event_type != "result":
			continue
		var grouped_lines: Array[String] = []
		var grouped_events: Array[Dictionary] = []
		for nested: Dictionary in structured_events:
			var nested_id := int(nested.get("id", -1))
			if _event_is_descendant_of(nested_id, root_id, event_by_id):
				grouped_events.append(nested)
				grouped_lines.append(String(nested.get("rendered_line", nested.get("text", ""))))

		if timed_value >= 0:
			last_timed_event = float(timed_value)
		var replay_time := last_timed_event if timed_value < 0 else float(timed_value)
		replay_events.append({
			"time": replay_time,
			"lines": grouped_lines,
			"events": grouped_events,
		})


func _show_next_replay_event() -> void:
	if replay_event_index >= replay_events.size():
		_finish_replay()
		return

	var event := replay_events[replay_event_index]
	current_event_time = float(event.get("time", current_event_time))
	displayed_sim_time = current_event_time
	_apply_structured_events_to_visual_model(event.get("events", []))
	_update_visual_replay_widgets()

	var event_lines: Array = event["lines"]
	for line: String in event_lines:
		_append_log_line(line)

	replay_event_index += 1
	_schedule_next_replay_event()


func _schedule_next_replay_event() -> void:
	if replay_event_index >= replay_events.size():
		_finish_replay()
		return

	next_event_time = float(replay_events[replay_event_index].get("time", current_event_time))
	event_transition_elapsed = 0.0
	var sim_delta: float = max(0.0, next_event_time - current_event_time)
	timer.wait_time = max(MIN_SECONDS_BETWEEN_REPLAY_ACTIONS, sim_delta * SECONDS_PER_SIM_SECOND / replay_speed)
	timer.start()


func _finish_replay() -> void:
	if timer != null:
		timer.stop()
	replay_is_active = false
	replay_finished.emit()


func _on_replay_timer_timeout() -> void:
	_show_next_replay_event()


func _setup_speed_controls() -> void:
	if speed_label != null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	speed_label = Label.new()
	speed_label.text = "Speed"
	row.add_child(speed_label)
	for speed in REPLAY_SPEEDS:
		var button := Button.new()
		button.text = _speed_text(speed)
		button.toggle_mode = true
		button.button_pressed = is_equal_approx(speed, replay_speed)
		button.pressed.connect(_on_speed_button_pressed.bind(speed))
		row.add_child(button)
		speed_buttons.append(button)
	add_child(row)
	move_child(row, min(2, get_child_count() - 1))


func _on_speed_button_pressed(speed: float) -> void:
	replay_speed = speed
	for button in speed_buttons:
		button.button_pressed = button.text == _speed_text(speed)


func _speed_text(speed: float) -> String:
	if is_equal_approx(speed, round(speed)):
		return "%dx" % int(round(speed))
	return "%.1fx" % speed


func _on_combat_log_scroll_value_changed(_value: float) -> void:
	if not replay_is_active or is_programmatic_scroll:
		return
	autoscroll_enabled = false


func _append_log_line(line: String) -> void:
	CombatLogRichTextFormatterScript.append_line(combat_log, line, log_highlight_palette)
	_scroll_combat_log_to_bottom()


func _scroll_combat_log_to_bottom() -> void:
	if not autoscroll_enabled:
		return
	is_programmatic_scroll = true
	combat_log.scroll_to_line(max(0, combat_log.get_line_count() - 1))
	call_deferred("_finish_programmatic_scroll")


func _finish_programmatic_scroll() -> void:
	is_programmatic_scroll = false


func _build_visual_replay_model() -> void:
	units_by_name.clear()
	units_by_id.clear()
	for unit: Dictionary in roster_units:
		var unit_id := String(unit.get("id", ""))
		var name := String(unit.get("name", ""))
		if name.is_empty():
			continue
		var max_hp: int = max(1, int(unit.get("max_hp", 1)))
		var action_interval: int = max(1, int(unit.get("action_interval", 1)))
		var state := {
			"id": unit_id,
			"name": name,
			"team": String(unit.get("team", "Enemies")),
			"max_hp": max_hp,
			"hp": max_hp,
			"previous_hp": max_hp,
			"action_interval": action_interval,
			"next_action_time": float(action_interval),
			"display_time": 0.0,
			"is_alive": true,
			"turn_pulse_started_at": -9999.0,
			"floating_text": "",
			"floating_text_started_at": -9999.0,
			"floating_text_pulse_started_at": -9999.0,
			"defeat_time": -9999.0,
			"is_defeated": false,
		}
		units_by_name[name] = state
		if not unit_id.is_empty():
			units_by_id[unit_id] = state


func _build_visual_replay_widgets() -> void:
	for child in allies_row.get_children():
		child.queue_free()
	for child in enemies_row.get_children():
		child.queue_free()
	unit_widgets_by_name.clear()

	var names := units_by_name.keys()
	names.sort()
	for name in names:
		var unit_data: Dictionary = units_by_name[name]
		var dot: Control = UnitStatusDotScript.new()
		if unit_data["team"] == "Allies":
			allies_row.add_child(dot)
		else:
			enemies_row.add_child(dot)
		_bind_runtime_tooltip(dot, unit_data)
		unit_widgets_by_name[name] = dot

	_update_visual_replay_widgets()


func _apply_structured_events_to_visual_model(events: Array) -> void:
	for raw_event in events:
		var event: Dictionary = raw_event
		var event_type := String(event.get("event_type", "text"))
		var payload: Dictionary = event.get("payload", {})
		if event_type == "turn_start":
			_apply_turn_start_event(payload)
			continue
		if event_type == "damage" or event_type == "heal":
			_apply_hp_change_event(payload)
			continue
		if event_type == "defeat":
			_apply_defeat_event(payload)


func _apply_turn_start_event(payload: Dictionary) -> void:
	var actor_state: Dictionary = _find_unit_state_from_payload(payload, "actor_id", "actor")
	if actor_state.is_empty():
		return
	actor_state["next_action_time"] = current_event_time + float(actor_state["action_interval"])
	actor_state["turn_pulse_started_at"] = displayed_sim_time
	active_event_actor_name = String(actor_state.get("name", ""))


func _apply_hp_change_event(payload: Dictionary) -> void:
	var target_state: Dictionary = _find_unit_state_from_payload(payload, "target_id", "target")
	if target_state.is_empty():
		return
	var previous_hp := int(payload.get("previous_hp", 0))
	var new_hp := int(payload.get("new_hp", previous_hp))
	target_state["previous_hp"] = previous_hp
	target_state["hp"] = new_hp
	target_state["is_alive"] = new_hp > 0
	var delta := new_hp - previous_hp
	if delta != 0:
		var delta_prefix := "+" if delta > 0 else ""
		target_state["floating_text"] = "%s%d" % [delta_prefix, delta]
		target_state["floating_text_started_at"] = displayed_sim_time
		target_state["floating_text_pulse_started_at"] = displayed_sim_time


func _apply_defeat_event(payload: Dictionary) -> void:
	var defeated_state: Dictionary = _find_unit_state_from_payload(payload, "target_id", "target")
	if defeated_state.is_empty():
		return
	defeated_state["hp"] = 0
	defeated_state["is_alive"] = false
	defeated_state["is_defeated"] = true
	defeated_state["defeat_time"] = displayed_sim_time


func _event_is_descendant_of(entry_id: int, root_id: int, event_by_id: Dictionary) -> bool:
	var current_id := entry_id
	while event_by_id.has(current_id):
		if current_id == root_id:
			return true
		current_id = int(event_by_id[current_id].get("parent_id", -1))
		if current_id == -1:
			return false
	return false


func _find_unit_state_from_payload(payload: Dictionary, id_key: String, name_key: String) -> Dictionary:
	var unit_id := String(payload.get(id_key, ""))
	if not unit_id.is_empty() and units_by_id.has(unit_id):
		return units_by_id[unit_id]
	var unit_name := String(payload.get(name_key, ""))
	if not unit_name.is_empty() and units_by_name.has(unit_name):
		return units_by_name[unit_name]
	return {}


func _update_visual_replay_widgets() -> void:
	for name in unit_widgets_by_name.keys():
		if not units_by_name.has(name):
			continue
		var state: Dictionary = units_by_name[name]
		state["display_time"] = displayed_sim_time
		state["is_acting"] = name == active_event_actor_name
		var dot: Control = unit_widgets_by_name[name]
		dot.configure(state)


func _bind_runtime_tooltip(control: Control, snapshot: Dictionary) -> void:
	control.set_meta("tooltip_snapshot", snapshot)
	control.mouse_entered.connect(_on_runtime_tooltip_entered.bind(control))
	control.mouse_exited.connect(_on_tooltip_exited)


func _on_runtime_tooltip_entered(source: Control) -> void:
	var snapshot: Dictionary = source.get_meta("tooltip_snapshot", {})
	runtime_tooltip_requested.emit(source, snapshot)


func _on_tooltip_exited() -> void:
	tooltip_cleared.emit()
