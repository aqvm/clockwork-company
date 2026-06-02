extends Control

const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const CombatLogHighlightPaletteScript := preload("res://scripts/ui/combat_log_highlight_palette.gd")
const UnitStatusDotScript := preload("res://scripts/ui/unit_status_dot.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const RunStateScript := preload("res://scripts/run/run_state.gd")
const COMBAT_LOG_HEADER := "Combat log:"
const RUN_BUTTON_REPLAYING_TEXT := "Replaying..."
const MODS_BUTTON_BASE_TEXT := "Mods"
const MOD_SETTINGS_PATH := "user://mod_settings.cfg"
const MOD_SETTINGS_SECTION := "mods"
const MOD_SETTINGS_KEY_ENABLED_IDS := "enabled_pack_ids"
const DEFAULT_WINDOW_AREA_FRACTION := 0.75
const MIN_CONDITIONS_HEIGHT := 120
const SECONDS_PER_SIM_SECOND := 0.2
const MIN_SECONDS_BETWEEN_REPLAY_ACTIONS := 0.1
const MAX_EQUIPMENT_BUTTONS := 12
const DEFAULT_LOG_HIGHLIGHT_PALETTE := preload("res://resources/ui/combat_log_highlight_palette_default.tres")

@onready var run_button: Button = %RunButton
@onready var mods_menu_button: Button = %ModsMenuButton
@onready var mods_list_panel: PanelContainer = %ModsListPanel
@onready var mods_list_vbox: VBoxContainer = %ModsListVBox
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
var cached_fight_static_lines: Array[String] = []
var combat_replay_events: Array[Dictionary] = []
var cached_structured_events: Array[Dictionary] = []
var cached_roster_units: Array[Dictionary] = []
var replay_units_by_name := {}
var replay_units_by_id := {}
var replay_unit_widgets_by_name := {}
var replay_event_index := 0
var autoscroll_enabled := true
var is_programmatic_scroll := false
var replay_is_active := false
var displayed_sim_time := 0.0
var current_event_time := 0.0
var next_event_time := 0.0
var event_transition_elapsed := 0.0
var active_event_actor_name := ""
var available_mod_packs: Array[Dictionary] = []
var enabled_mod_pack_ids := {}
var run_state = null
var cached_battle_report := {}
var reward_buttons: Array[Button] = []
var equipment_buttons: Array[Button] = []
var continue_button: Button = null
var loss_test_button: Button = null


func _ready() -> void:
	_size_window_to_half_screen()
	run_button.pressed.connect(_on_run_button_pressed)
	mods_menu_button.pressed.connect(_on_mods_button_pressed)
	replay_timer.timeout.connect(_on_replay_timer_timeout)
	replay_timer.one_shot = true
	combat_log.get_v_scroll_bar().value_changed.connect(_on_combat_log_scroll_value_changed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_setup_mod_menu()
	_setup_run_controls()
	_start_new_run(false)


func _process(delta: float) -> void:
	if not replay_is_active:
		return

	event_transition_elapsed = min(replay_timer.wait_time, event_transition_elapsed + delta)
	if replay_timer.wait_time > 0.0:
		var lerp_weight: float = clamp(event_transition_elapsed / replay_timer.wait_time, 0.0, 1.0)
		displayed_sim_time = lerp(current_event_time, next_event_time, lerp_weight)
		_update_visual_replay_widgets()


func _on_run_button_pressed() -> void:
	if run_state == null:
		_start_new_run(false)
		return
	if run_state.status == RunStateScript.STATUS_WON or run_state.status == RunStateScript.STATUS_LOST:
		_start_new_run(false)
		return
	if run_state.status != RunStateScript.STATUS_ACTIVE:
		return

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
	active_event_actor_name = ""

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


func _on_mods_button_pressed() -> void:
	mods_list_panel.visible = not mods_list_panel.visible
	if mods_list_panel.visible:
		_position_mods_panel()


func _load_combat_preview() -> void:
	_clear_logs()
	if run_state == null:
		return

	var simulator: CombatSimulator = CombatSimulatorScript.new()
	var report: Dictionary = simulator.run_battle_report(run_state.build_current_fight_definitions(), run_state.current_fight_title())
	var log_lines: Array[String] = report.get("lines", [])
	var static_lines: Array[String] = []

	cached_battle_report = report.duplicate(true)
	cached_replay_lines.clear()
	cached_static_lines.clear()
	cached_structured_events = report.get("events", []).duplicate(true)
	cached_roster_units = report.get("roster_units", []).duplicate(true)
	_split_log_lines(log_lines, static_lines, cached_replay_lines)
	cached_fight_static_lines = static_lines.duplicate()
	cached_static_lines = _build_run_static_lines(static_lines)
	_append_lines(combat_summary, cached_static_lines)
	_build_visual_replay_model()
	_build_visual_replay_widgets()
	displayed_sim_time = 0.0
	active_event_actor_name = ""
	_update_run_controls()
	_update_visual_replay_widgets()
	call_deferred("_resize_conditions_pane")


func _setup_mod_menu() -> void:
	available_mod_packs = JsonContentLoaderScript.list_available_mod_packs()
	enabled_mod_pack_ids.clear()

	var saved_enabled_ids := _load_saved_enabled_mod_pack_ids()
	var has_saved_selection := not saved_enabled_ids.is_empty()
	for pack in available_mod_packs:
		var pack_id := String(pack.get("id", ""))
		if pack_id.is_empty():
			continue
		if has_saved_selection:
			if saved_enabled_ids.has(pack_id):
				enabled_mod_pack_ids[pack_id] = true
		elif bool(pack.get("default_enabled", true)):
			enabled_mod_pack_ids[pack_id] = true

	_rebuild_mod_menu()


func _setup_run_controls() -> void:
	loss_test_button = Button.new()
	loss_test_button.text = "Start Loss Test"
	loss_test_button.pressed.connect(_on_loss_test_button_pressed)
	run_button.get_parent().add_child(loss_test_button)

	for index in 3:
		var reward_button := Button.new()
		reward_button.visible = false
		reward_button.pressed.connect(_on_reward_button_pressed.bind(index))
		run_button.get_parent().add_child(reward_button)
		reward_buttons.append(reward_button)

	continue_button = Button.new()
	continue_button.text = "Continue to Next Fight"
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_button_pressed)
	run_button.get_parent().add_child(continue_button)

	for index in MAX_EQUIPMENT_BUTTONS:
		var equipment_button := Button.new()
		equipment_button.visible = false
		equipment_button.pressed.connect(_on_equipment_button_pressed.bind(index))
		run_button.get_parent().add_child(equipment_button)
		equipment_buttons.append(equipment_button)


func _start_new_run(should_force_loss: bool) -> void:
	_stop_log_replay()
	run_state = RunStateScript.new()
	run_state.start(_enabled_mod_pack_ids_array(), should_force_loss)
	_load_combat_preview()


func _on_loss_test_button_pressed() -> void:
	_start_new_run(true)


func _on_reward_button_pressed(index: int) -> void:
	if run_state == null or run_state.status != RunStateScript.STATUS_REWARD:
		return

	run_state.apply_reward(index)
	_load_combat_preview()


func _on_continue_button_pressed() -> void:
	if run_state == null or run_state.status != RunStateScript.STATUS_EQUIPMENT:
		return

	run_state.continue_to_next_fight()
	_load_combat_preview()


func _on_equipment_button_pressed(index: int) -> void:
	if run_state == null or run_state.status != RunStateScript.STATUS_EQUIPMENT:
		return

	var options: Array[Dictionary] = run_state.equip_options()
	if index < 0 or index >= options.size():
		return

	var option: Dictionary = options[index]
	run_state.equip_inventory_item(int(option["item_index"]), String(option["unit_name"]))
	_load_combat_preview()


func _build_run_static_lines(fight_static_lines: Array[String]) -> Array[String]:
	var lines: Array[String] = run_state.status_lines()
	lines.append("")
	for line in fight_static_lines:
		lines.append(line)
	return lines


func _update_run_controls() -> void:
	if run_state == null:
		run_button.disabled = false
		run_button.text = "Start Run"
		return

	loss_test_button.disabled = replay_is_active
	if replay_is_active:
		run_button.disabled = true
		run_button.text = RUN_BUTTON_REPLAYING_TEXT
	elif run_state.status == RunStateScript.STATUS_ACTIVE:
		run_button.disabled = false
		run_button.text = "Run Fight %d/%d" % [run_state.current_fight_number(), RunStateScript.FIGHT_COUNT]
	elif run_state.status == RunStateScript.STATUS_REWARD:
		run_button.disabled = true
		run_button.text = "Choose Reward"
	elif run_state.status == RunStateScript.STATUS_EQUIPMENT:
		run_button.disabled = true
		run_button.text = "Equip Or Continue"
	elif run_state.status == RunStateScript.STATUS_WON:
		run_button.disabled = false
		run_button.text = "Run Won - Start New Run"
	elif run_state.status == RunStateScript.STATUS_LOST:
		run_button.disabled = false
		run_button.text = "Run Lost - Start New Run"

	var options: Array[Dictionary] = []
	if run_state.status == RunStateScript.STATUS_REWARD:
		options = run_state.reward_options()
	for index in reward_buttons.size():
		var reward_button := reward_buttons[index]
		var has_option: bool = index < options.size()
		reward_button.visible = has_option
		reward_button.disabled = replay_is_active or not has_option
		if has_option:
			var option: Dictionary = options[index]
			reward_button.text = String(option["label"])
			reward_button.tooltip_text = String(option["description"])

	continue_button.visible = run_state.status == RunStateScript.STATUS_EQUIPMENT
	continue_button.disabled = replay_is_active

	var equip_options: Array[Dictionary] = []
	if run_state.status == RunStateScript.STATUS_EQUIPMENT:
		equip_options = run_state.equip_options()
	for index in equipment_buttons.size():
		var equipment_button := equipment_buttons[index]
		var has_equip_option: bool = index < equip_options.size()
		equipment_button.visible = has_equip_option
		equipment_button.disabled = replay_is_active or not has_equip_option
		if has_equip_option:
			var equip_option: Dictionary = equip_options[index]
			equipment_button.text = String(equip_option["label"])


func _rebuild_mod_menu() -> void:
	for child in mods_list_vbox.get_children():
		child.queue_free()

	if available_mod_packs.is_empty():
		mods_menu_button.disabled = true
		mods_menu_button.text = "%s (none)" % MODS_BUTTON_BASE_TEXT
		mods_list_panel.visible = false
		return

	mods_menu_button.disabled = false
	for pack in available_mod_packs:
		var pack_id := String(pack.get("id", ""))
		var display_name := String(pack.get("display_name", pack_id))
		if bool(pack.get("is_reference", false)):
			display_name = "%s [ref]" % display_name
		var checkbox := CheckButton.new()
		checkbox.text = display_name
		checkbox.button_pressed = enabled_mod_pack_ids.has(pack_id)
		checkbox.toggled.connect(_on_mod_checkbox_toggled.bind(pack_id))
		mods_list_vbox.add_child(checkbox)

	mods_menu_button.text = "%s (%d/%d)" % [MODS_BUTTON_BASE_TEXT, enabled_mod_pack_ids.size(), available_mod_packs.size()]
	if mods_list_panel.visible:
		call_deferred("_position_mods_panel")


func _on_mod_checkbox_toggled(pressed: bool, pack_id: String) -> void:
	if pack_id.is_empty():
		return

	if pressed:
		enabled_mod_pack_ids[pack_id] = true
	else:
		enabled_mod_pack_ids.erase(pack_id)

	_save_enabled_mod_pack_ids(_enabled_mod_pack_ids_array())
	_start_new_run(false)


func _position_mods_panel() -> void:
	var button_rect := mods_menu_button.get_global_rect()
	var viewport_rect := get_viewport_rect()
	var desired_size := Vector2(300.0, 220.0)
	var x: float = min(button_rect.position.x, viewport_rect.size.x - desired_size.x - 8.0)
	var y: float = min(button_rect.end.y + 4.0, viewport_rect.size.y - desired_size.y - 8.0)
	mods_list_panel.global_position = Vector2(max(8.0, x), max(8.0, y))
	mods_list_panel.size = desired_size


func _input(event: InputEvent) -> void:
	if not mods_list_panel.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index > MOUSE_BUTTON_MIDDLE:
			return
		var click_pos := mouse_event.global_position
		var in_panel := mods_list_panel.get_global_rect().has_point(click_pos)
		var in_button := mods_menu_button.get_global_rect().has_point(click_pos)
		if not in_panel and not in_button:
			mods_list_panel.visible = false


func _enabled_mod_pack_ids_array() -> Array[String]:
	var ids: Array[String] = []
	for pack_id in enabled_mod_pack_ids.keys():
		ids.append(String(pack_id))
	ids.sort()
	return ids


func _load_saved_enabled_mod_pack_ids() -> Dictionary:
	var out := {}
	var config := ConfigFile.new()
	if config.load(MOD_SETTINGS_PATH) != OK:
		return out
	var raw_ids: Array = config.get_value(MOD_SETTINGS_SECTION, MOD_SETTINGS_KEY_ENABLED_IDS, [])
	for id in raw_ids:
		out[String(id)] = true
	return out


func _save_enabled_mod_pack_ids(enabled_ids: Array[String]) -> void:
	var config := ConfigFile.new()
	config.set_value(MOD_SETTINGS_SECTION, MOD_SETTINGS_KEY_ENABLED_IDS, enabled_ids)
	var err := config.save(MOD_SETTINGS_PATH)
	if err != OK:
		push_warning("Failed to save mod settings to %s" % MOD_SETTINGS_PATH)


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


func _prepare_replay_events(_replay_lines: Array[String]) -> void:
	combat_replay_events.clear()
	var event_by_id := {}
	var root_ids: Array[int] = []
	for entry: Dictionary in cached_structured_events:
		var entry_id := int(entry.get("id", -1))
		event_by_id[entry_id] = entry
		if int(entry.get("parent_id", -1)) == -1:
			root_ids.append(entry_id)

	var last_timed_event := 0.0
	for root_id in root_ids:
		if not event_by_id.has(root_id):
			continue
		var entry: Dictionary = event_by_id[root_id]
		var grouped_lines: Array[String] = []
		var grouped_events: Array[Dictionary] = []
		for nested: Dictionary in cached_structured_events:
			var nested_id := int(nested.get("id", -1))
			if _event_is_descendant_of(nested_id, root_id, event_by_id):
				grouped_events.append(nested)
				grouped_lines.append(String(nested.get("rendered_line", nested.get("text", ""))))

		var timed_value := int(entry.get("time", -1))
		if timed_value >= 0:
			last_timed_event = float(timed_value)
		var replay_time := last_timed_event if timed_value < 0 else float(timed_value)
		combat_replay_events.append({
			"time": replay_time,
			"lines": grouped_lines,
			"events": grouped_events,
		})


func _show_next_replay_event() -> void:
	if replay_event_index >= combat_replay_events.size():
		_finish_log_replay()
		return

	var event := combat_replay_events[replay_event_index]
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

	if line.begins_with("Job effect ") or line.begins_with("Ancestry feature "):
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
	replay_units_by_id.clear()
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
	_update_run_controls()


func _finish_log_replay() -> void:
	replay_timer.stop()
	replay_is_active = false
	if run_state != null and run_state.status == RunStateScript.STATUS_ACTIVE:
		run_state.complete_fight(cached_battle_report)
		combat_summary.clear()
		cached_static_lines = _build_run_static_lines(cached_fight_static_lines)
		_append_lines(combat_summary, cached_static_lines)
		call_deferred("_resize_conditions_pane")
	_update_run_controls()


func _build_visual_replay_model() -> void:
	replay_units_by_name.clear()
	replay_units_by_id.clear()
	for unit: Dictionary in cached_roster_units:
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
		replay_units_by_name[name] = state
		if not unit_id.is_empty():
			replay_units_by_id[unit_id] = state


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
	var actor_name := String(actor_state.get("name", ""))
	active_event_actor_name = actor_name


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
	if not unit_id.is_empty() and replay_units_by_id.has(unit_id):
		return replay_units_by_id[unit_id]
	var unit_name := String(payload.get(name_key, ""))
	if not unit_name.is_empty() and replay_units_by_name.has(unit_name):
		return replay_units_by_name[unit_name]
	return {}


func _update_visual_replay_widgets() -> void:
	for name in replay_unit_widgets_by_name.keys():
		if not replay_units_by_name.has(name):
			continue
		var state: Dictionary = replay_units_by_name[name]
		state["display_time"] = displayed_sim_time
		state["is_acting"] = name == active_event_actor_name
		var dot: Control = replay_unit_widgets_by_name[name]
		dot.configure(state)
