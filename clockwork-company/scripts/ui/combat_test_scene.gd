extends Control

const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const CombatLogHighlightPaletteScript := preload("res://scripts/ui/combat_log_highlight_palette.gd")
const CombatLogRichTextFormatterScript := preload("res://scripts/ui/combat_log_rich_text_formatter.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const RunStateScript := preload("res://scripts/run/run_state.gd")
const CampaignManagerScript := preload("res://scripts/campaign/campaign_manager.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const TooltipPresenterScript := preload("res://scripts/ui/tooltip_presenter.gd")
const PlanningWorkbenchPanelScene := preload("res://scenes/planning_workbench_panel.tscn")
const COMBAT_LOG_HEADER := "Combat log:"
const RUN_BUTTON_REPLAYING_TEXT := "Replaying..."
const MOD_SETTINGS_PATH := "user://mod_settings.cfg"
const MOD_SETTINGS_SECTION := "mods"
const MOD_SETTINGS_KEY_ENABLED_IDS := "enabled_pack_ids"
const CAMPAIGN_SAVE_PATH := "user://first_road_campaign_save.json"
const MIN_CONDITIONS_HEIGHT := 120
const FIRST_ROAD_CAMPAIGN := preload("res://resources/campaigns/first_road_campaign.tres")
const DEFAULT_LOG_HIGHLIGHT_PALETTE := preload("res://resources/ui/combat_log_highlight_palette_default.tres")
const COLORBLIND_LOG_HIGHLIGHT_PALETTE := preload("res://resources/ui/combat_log_highlight_palette_colorblind.tres")

@onready var run_controls = %ControlsRow
@onready var mods_list_panel: PanelContainer = %ModsListPanel
@onready var mods_list_vbox: VBoxContainer = %ModsListVBox
@onready var log_split: VSplitContainer = %LogSplit
@onready var conditions_label: Label = %ConditionsLabel
@onready var combat_summary: RichTextLabel = %CombatSummary
@onready var replay_panel: Control = %ReplayColumn
@onready var replay_timer: Timer = %ReplayTimer
@export var log_highlight_palette: CombatLogHighlightPaletteScript = DEFAULT_LOG_HIGHLIGHT_PALETTE

var planning_panel: Control = null
var tooltip_presenter = null
var cached_static_lines: Array[String] = []
var cached_structured_events: Array[Dictionary] = []
var cached_roster_units: Array[Dictionary] = []
var cached_replay_snapshots: Array[Dictionary] = []
var replay_is_active := false
var available_mod_packs: Array[Dictionary] = []
var enabled_mod_pack_ids := {}
var run_state = null
var cached_battle_report := {}
var colorblind_palette_enabled := false
var campaign_manager = null
var active_campaign_scenario_id := ""
var selected_scenario: Resource = null
var selected_unit_name := ""
var planning_party: Array[UnitDefinition] = []


func _ready() -> void:
	run_controls.connect("run_requested", _on_run_button_pressed)
	run_controls.connect("mods_menu_requested", _on_mods_button_pressed)
	run_controls.connect("palette_requested", _on_palette_button_pressed)
	run_controls.connect("save_campaign_requested", _on_save_campaign_pressed)
	run_controls.connect("load_campaign_requested", _on_load_campaign_pressed)
	run_controls.connect("loss_test_requested", _on_loss_test_button_pressed)
	run_controls.connect("phase7_run_requested", _on_phase7_run_button_pressed)
	run_controls.connect("reward_requested", _on_reward_button_pressed)
	run_controls.connect("continue_requested", _on_continue_button_pressed)
	run_controls.connect("equipment_requested", _on_equipment_button_pressed)
	_connect_panel_tooltips(run_controls)
	replay_panel.call("setup", replay_timer, log_highlight_palette)
	replay_panel.connect("replay_finished", _on_replay_finished)
	replay_panel.connect("runtime_tooltip_requested", _on_panel_runtime_tooltip_requested)
	replay_panel.connect("structured_event_tooltip_requested", _on_panel_structured_event_tooltip_requested)
	replay_panel.connect("tooltip_cleared", _on_tooltip_exited)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_setup_mod_menu()
	_setup_run_controls()
	_setup_planning_panel()
	_setup_tooltip_presenter()
	_start_first_road_campaign()


func _process(delta: float) -> void:
	replay_panel.call("tick", delta)


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
	_load_combat_preview()
	_clear_replay_log()

	run_controls.show_run_button(RUN_BUTTON_REPLAYING_TEXT, true)
	replay_is_active = true
	replay_panel.call("start_replay", cached_roster_units, cached_structured_events, cached_replay_snapshots)


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
	var scenario_rules: Array = run_state.active_scenario.scenario_rules if run_state.active_scenario != null else []
	var report: Dictionary = simulator.run_battle_report(run_state.build_current_fight_definitions(), run_state.current_fight_title(), scenario_rules)
	var log_lines: Array[String] = report.get("lines", [])
	var static_lines: Array[String] = []

	cached_battle_report = report.duplicate(true)
	cached_static_lines.clear()
	cached_structured_events = report.get("events", []).duplicate(true)
	cached_roster_units = report.get("roster_units", []).duplicate(true)
	cached_replay_snapshots = report.get("replay_snapshots", []).duplicate(true)
	_collect_static_log_lines(log_lines, static_lines)
	cached_static_lines = _build_run_static_lines(static_lines)
	_append_lines(combat_summary, cached_static_lines)
	replay_panel.call("load_preview", cached_roster_units, cached_structured_events, cached_replay_snapshots)
	_update_run_controls()
	call_deferred("_resize_conditions_pane")


func _show_run_state_without_combat_preview() -> void:
	_clear_logs()
	cached_battle_report.clear()
	cached_static_lines.clear()
	cached_structured_events.clear()
	cached_roster_units.clear()
	cached_replay_snapshots.clear()
	_clear_replay_log()
	if run_state == null:
		return
	var lines: Array[String] = _build_run_static_lines([])
	_append_lines(combat_summary, lines)
	_update_run_controls()
	_refresh_planning_panel()
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
	run_controls.show_palette_button(colorblind_palette_enabled)


func _on_palette_button_pressed() -> void:
	colorblind_palette_enabled = not colorblind_palette_enabled
	log_highlight_palette = COLORBLIND_LOG_HIGHLIGHT_PALETTE if colorblind_palette_enabled else DEFAULT_LOG_HIGHLIGHT_PALETTE
	run_controls.show_palette_button(colorblind_palette_enabled)
	replay_panel.call("set_highlight_palette", log_highlight_palette)
	if not cached_static_lines.is_empty():
		combat_summary.clear()
		_append_lines(combat_summary, cached_static_lines)
		call_deferred("_resize_conditions_pane")


func _on_save_campaign_pressed() -> void:
	if campaign_manager == null:
		return
	var err: int = campaign_manager.save_to_path(CAMPAIGN_SAVE_PATH)
	if err == OK:
		_show_campaign_message("Campaign saved to %s." % CAMPAIGN_SAVE_PATH)
	else:
		_show_campaign_message("Campaign save failed with error %d." % err)


func _on_load_campaign_pressed() -> void:
	if campaign_manager == null:
		return
	if campaign_manager.load_from_path(CAMPAIGN_SAVE_PATH):
		run_state = null
		active_campaign_scenario_id = ""
		selected_scenario = null
		selected_unit_name = ""
		_load_planning_party()
		_show_campaign_message("Campaign loaded from %s." % CAMPAIGN_SAVE_PATH)
	else:
		_show_campaign_message("No compatible campaign save found at %s." % CAMPAIGN_SAVE_PATH)


func _setup_planning_panel() -> void:
	var parent_vbox := log_split.get_parent()
	planning_panel = PlanningWorkbenchPanelScene.instantiate()
	planning_panel.connect("scenario_selected", _on_scenario_selected)
	planning_panel.connect("start_scenario_requested", _on_start_selected_scenario_pressed)
	planning_panel.connect("practice_scenario_requested", _on_practice_selected_scenario_pressed)
	planning_panel.connect("unit_selected", _on_party_unit_pressed)
	planning_panel.connect("planning_item_requested", _on_planning_item_requested)
	planning_panel.connect("equip_option_requested", _on_planning_equip_pressed)
	planning_panel.connect("unlock_choice_requested", _on_unlock_choice_requested)
	planning_panel.connect("planning_job_requested", _on_planning_job_requested)
	planning_panel.connect("planning_feature_requested", _on_planning_feature_requested)
	planning_panel.connect("planning_tactic_add_requested", _on_planning_tactic_add_requested)
	planning_panel.connect("planning_tactic_remove_requested", _on_planning_tactic_remove_requested)
	planning_panel.connect("planning_tactic_move_requested", _on_planning_tactic_move_requested)
	_connect_panel_tooltips(planning_panel)
	parent_vbox.add_child(planning_panel)
	parent_vbox.move_child(planning_panel, log_split.get_index())
	conditions_label.text = "Fight Preview"
	conditions_label.get_parent().visible = true


func _setup_tooltip_presenter() -> void:
	tooltip_presenter = TooltipPresenterScript.new()
	add_child(tooltip_presenter)


func _start_new_run(should_force_loss: bool) -> void:
	_stop_log_replay()
	active_campaign_scenario_id = ""
	selected_scenario = null
	run_state = RunStateScript.new()
	run_state.start(_enabled_mod_pack_ids_array(), should_force_loss)
	_refresh_planning_panel()
	_show_run_state_without_combat_preview()


func _start_first_road_campaign() -> void:
	_stop_log_replay()
	campaign_manager = CampaignManagerScript.new()
	campaign_manager.start(FIRST_ROAD_CAMPAIGN, _enabled_mod_pack_ids_array())
	active_campaign_scenario_id = ""
	run_state = null
	selected_scenario = null
	selected_unit_name = ""
	_load_planning_party()
	_show_campaign_landing()


func _start_scenario_run(scenario: Resource, should_mutate_campaign := true) -> void:
	_stop_log_replay()
	run_state = RunStateScript.new()
	active_campaign_scenario_id = scenario.scenario_id if should_mutate_campaign else ""
	var starting_party: Array = campaign_manager.campaign_party_snapshot() if should_mutate_campaign and campaign_manager != null else planning_party
	var starting_inventory: Array = campaign_manager.campaign_inventory_snapshot() if should_mutate_campaign and campaign_manager != null else []
	run_state.start_scenario(_enabled_mod_pack_ids_array(), scenario, false, starting_party, starting_inventory)
	_load_planning_party_from_run()
	_refresh_planning_panel()
	_show_run_state_without_combat_preview()


func _on_loss_test_button_pressed() -> void:
	_start_new_run(true)


func _on_phase7_run_button_pressed() -> void:
	_start_new_run(false)


func _on_start_selected_scenario_pressed() -> void:
	if campaign_manager == null or selected_scenario == null:
		return
	if not campaign_manager.progress.is_scenario_unlocked(selected_scenario.scenario_id):
		return
	if campaign_manager.progress.completed_scenario_ids.has(selected_scenario.scenario_id):
		return
	var scenario = campaign_manager.start_scenario(selected_scenario.scenario_id)
	if scenario == null:
		return
	selected_scenario = scenario
	_start_scenario_run(scenario, true)


func _on_practice_selected_scenario_pressed() -> void:
	if selected_scenario == null or not _selected_scenario_can_practice():
		return
	_start_scenario_run(selected_scenario, false)


func _on_reward_button_pressed(index: int) -> void:
	if run_state == null or run_state.status != RunStateScript.STATUS_REWARD:
		return

	run_state.apply_reward(index)
	_load_planning_party_from_run()
	_show_run_state_without_combat_preview()


func _on_continue_button_pressed() -> void:
	if run_state == null or run_state.status != RunStateScript.STATUS_EQUIPMENT:
		return

	run_state.continue_to_next_fight()
	_load_planning_party_from_run()
	_show_run_state_without_combat_preview()


func _on_equipment_button_pressed(index: int) -> void:
	if run_state == null or run_state.status != RunStateScript.STATUS_EQUIPMENT:
		return

	var options: Array[Dictionary] = run_state.equip_options()
	if index < 0 or index >= options.size():
		return

	var option: Dictionary = options[index]
	run_state.equip_inventory_item(int(option["item_index"]), String(option["unit_name"]))
	_load_planning_party_from_run()
	_show_run_state_without_combat_preview()


func _build_run_static_lines(fight_static_lines: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	if campaign_manager != null:
		for campaign_line in campaign_manager.status_lines():
			lines.append(campaign_line)
		lines.append("")
	if run_state != null:
		for run_line in run_state.status_lines():
			lines.append(run_line)
	lines.append("")
	for line in fight_static_lines:
		lines.append(line)
	return lines


func _update_run_controls() -> void:
	if run_state == null:
		run_controls.show_run_button("Choose Scenario", true)
		run_controls.set_campaign_buttons_disabled(campaign_manager == null)
		run_controls.set_debug_buttons_disabled(replay_is_active)
		run_controls.show_reward_options([], replay_is_active)
		run_controls.show_continue_button(false, "", replay_is_active)
		run_controls.show_equipment_options([], replay_is_active)
		_update_campaign_controls()
		return

	run_controls.set_campaign_buttons_disabled(campaign_manager == null or replay_is_active)
	run_controls.set_debug_buttons_disabled(replay_is_active)
	if replay_is_active:
		run_controls.show_run_button(RUN_BUTTON_REPLAYING_TEXT, true)
	elif run_state.status == RunStateScript.STATUS_ACTIVE:
		run_controls.show_run_button("Run Encounter %d/%d: %s" % [run_state.current_fight_number(), run_state.current_fight_count(), run_state.current_encounter_name()], false)
	elif run_state.status == RunStateScript.STATUS_REWARD:
		run_controls.show_run_button("Choose Reward", true)
	elif run_state.status == RunStateScript.STATUS_EQUIPMENT:
		run_controls.show_run_button("Equip Or Continue", true)
	elif run_state.status == RunStateScript.STATUS_WON:
		run_controls.show_run_button("Run Won - Start New Run", false)
	elif run_state.status == RunStateScript.STATUS_LOST:
		run_controls.show_run_button("Run Lost - Start New Run", false)

	_update_campaign_controls()

	var options: Array[Dictionary] = []
	if run_state.status == RunStateScript.STATUS_REWARD:
		options = run_state.reward_options()
	run_controls.show_reward_options(options, replay_is_active)

	var continue_text := "Continue to Encounter %d: %s" % [run_state.current_fight_number(), run_state.current_encounter_name()]
	run_controls.show_continue_button(run_state.status == RunStateScript.STATUS_EQUIPMENT, continue_text, replay_is_active)

	var equip_options: Array[Dictionary] = []
	if run_state.status == RunStateScript.STATUS_EQUIPMENT:
		equip_options = run_state.equip_options()
	run_controls.show_equipment_options(equip_options, replay_is_active)


func _update_campaign_controls() -> void:
	var scenarios: Array = []
	if campaign_manager != null and not replay_is_active:
		scenarios = campaign_manager.all_scenarios()
	if planning_panel != null:
		var progress = campaign_manager.progress if campaign_manager != null else null
		planning_panel.call("show_scenarios", scenarios, progress, selected_scenario, _active_scenario_id())


func _select_scenario(scenario: Resource) -> void:
	selected_scenario = scenario
	_refresh_planning_panel()


func _on_scenario_selected(scenario: Resource) -> void:
	_select_scenario(scenario)


func _load_planning_party() -> void:
	planning_party.clear()
	if campaign_manager != null:
		planning_party = campaign_manager.campaign_party_snapshot()
		if selected_unit_name.is_empty() and not planning_party.is_empty():
			selected_unit_name = planning_party[0].display_name
		return
	for definition: UnitDefinition in JsonContentLoaderScript.load_demo_unit_definitions(_enabled_mod_pack_ids_array()):
		if definition.team == "Allies":
			planning_party.append(definition)
	if selected_unit_name.is_empty() and not planning_party.is_empty():
		selected_unit_name = planning_party[0].display_name


func _load_planning_party_from_run() -> void:
	planning_party.clear()
	if run_state == null:
		_load_planning_party()
		return
	for ally: UnitDefinition in run_state.ally_definitions:
		planning_party.append(ally)
	if selected_unit_name.is_empty() and not planning_party.is_empty():
		selected_unit_name = planning_party[0].display_name


func _refresh_planning_panel() -> void:
	if planning_panel == null:
		return
	_update_campaign_controls()
	var progress = campaign_manager.progress if campaign_manager != null else null
	planning_panel.call("show_scenario", selected_scenario, _scenario_campaign_status(selected_scenario), progress)
	planning_panel.call("show_party", planning_party, selected_unit_name)
	planning_panel.call("show_unit", _find_planning_unit(selected_unit_name), planning_party)
	_render_unit_actions()


func _render_unit_actions() -> void:
	var selected_unit := _find_planning_unit(selected_unit_name)
	var is_equipment_state: bool = run_state != null and run_state.status == RunStateScript.STATUS_EQUIPMENT
	var equip_options: Array = run_state.equip_options() if is_equipment_state else []
	var planning_item_options := _planning_item_options(selected_unit)
	var unlock_options: Array = []
	var job_options: Array = []
	var learned_feature_options := {}
	var tactic_options: Array = []
	if campaign_manager != null and selected_unit != null:
		var unit_id := _campaign_unit_id(selected_unit)
		unlock_options = campaign_manager.pending_unlock_options_for_unit(unit_id)
		job_options = _planning_job_options(selected_unit)
		for feature_type in ["skill", "passive", "reaction"]:
			learned_feature_options[feature_type] = campaign_manager.learned_feature_options(unit_id, feature_type)
		tactic_options = _planning_tactic_options(selected_unit)
	planning_panel.call(
		"show_actions",
		selected_scenario,
		selected_unit,
		selected_unit_name,
		_scenario_campaign_status(selected_scenario),
		_selected_scenario_can_start(),
		_selected_scenario_can_practice(),
		_has_active_scenario_run(),
		replay_is_active,
		is_equipment_state,
		planning_item_options,
		equip_options,
		unlock_options,
		job_options,
		learned_feature_options,
		tactic_options
	)


func _selected_scenario_can_start() -> bool:
	if selected_scenario == null or campaign_manager == null:
		return false
	if _has_active_scenario_run():
		return false
	if campaign_manager.has_pending_unlock_choices():
		return false
	if campaign_manager.progress.completed_scenario_ids.has(selected_scenario.scenario_id):
		return false
	return campaign_manager.progress.is_scenario_unlocked(selected_scenario.scenario_id)


func _selected_scenario_can_practice() -> bool:
	if selected_scenario == null or campaign_manager == null:
		return false
	if _has_active_scenario_run():
		return false
	return campaign_manager.progress.is_scenario_unlocked(selected_scenario.scenario_id)


func _has_active_scenario_run() -> bool:
	if run_state == null or run_state.active_scenario == null:
		return false
	return run_state.status != RunStateScript.STATUS_WON and run_state.status != RunStateScript.STATUS_LOST


func _active_scenario_id() -> String:
	if _has_active_scenario_run() and run_state.active_scenario != null:
		return String(run_state.active_scenario.scenario_id)
	return ""


func _scenario_campaign_status(scenario: Resource) -> String:
	if scenario == null or campaign_manager == null:
		return "unknown"
	if active_campaign_scenario_id == scenario.scenario_id:
		return "active"
	if _has_active_scenario_run() and run_state.active_scenario != null and run_state.active_scenario.scenario_id == scenario.scenario_id:
		return "practice"
	if campaign_manager.progress.completed_scenario_ids.has(scenario.scenario_id):
		return "complete"
	if campaign_manager.progress.attempted_scenario_ids.has(scenario.scenario_id):
		return "attempted"
	if campaign_manager.progress.is_scenario_unlocked(scenario.scenario_id):
		return "available"
	return "locked"


func _on_party_unit_pressed(unit_name: String) -> void:
	selected_unit_name = unit_name
	_refresh_planning_panel()


func _on_unlock_choice_requested(choice: String) -> void:
	if campaign_manager == null:
		return
	var unit := _find_planning_unit(selected_unit_name)
	if unit == null:
		return
	if campaign_manager.resolve_pending_unlock(_campaign_unit_id(unit), choice):
		_load_planning_party()
		_show_campaign_landing()


func _on_planning_job_requested(job: JobDefinition) -> void:
	if campaign_manager == null or _has_active_scenario_run():
		return
	var unit := _find_planning_unit(selected_unit_name)
	if unit != null and campaign_manager.set_current_job(_campaign_unit_id(unit), job):
		_load_planning_party()
		_refresh_planning_panel()


func _on_planning_feature_requested(feature_type: String, feature: Resource) -> void:
	if campaign_manager == null or _has_active_scenario_run():
		return
	var unit := _find_planning_unit(selected_unit_name)
	if unit != null and campaign_manager.assign_learned_feature(_campaign_unit_id(unit), feature_type, feature):
		_load_planning_party()
		_refresh_planning_panel()


func _planning_job_options(unit: UnitDefinition) -> Array:
	var options: Array = []
	if campaign_manager == null or unit == null:
		return options
	var current_job = unit.loadout.current_job if unit.loadout != null else null
	for job in campaign_manager.available_jobs():
		options.append({"job": job, "label": job.display_name, "equipped": _content_id(job) == _content_id(current_job)})
	return options


func _planning_tactic_options(unit: UnitDefinition) -> Array:
	var options: Array = []
	if campaign_manager == null or unit == null:
		return options
	var loadout = _ensure_planning_loadout(unit)
	for tactic in loadout.tactics:
		options.append({"tactic": tactic, "label": tactic.display_name, "equipped": true})
	for tactic in campaign_manager.available_tactics():
		if not _resources_include_id(loadout.tactics, tactic):
			options.append({"tactic": tactic, "label": tactic.display_name, "equipped": false})
	return options


func _on_planning_tactic_add_requested(tactic: TacticDefinition) -> void:
	var unit := _editable_planning_unit()
	if unit == null or tactic == null:
		return
	var loadout = _ensure_planning_loadout(unit)
	if not _resources_include_id(loadout.tactics, tactic):
		loadout.tactics.append(tactic)
		_commit_planning_tactics(unit)


func _on_planning_tactic_remove_requested(index: int) -> void:
	var unit := _editable_planning_unit()
	if unit == null or unit.loadout == null or index < 0 or index >= unit.loadout.tactics.size():
		return
	unit.loadout.tactics.remove_at(index)
	_commit_planning_tactics(unit)


func _on_planning_tactic_move_requested(index: int, direction: int) -> void:
	var unit := _editable_planning_unit()
	if unit == null or unit.loadout == null:
		return
	var destination := index + direction
	if index < 0 or index >= unit.loadout.tactics.size() or destination < 0 or destination >= unit.loadout.tactics.size():
		return
	var tactic := unit.loadout.tactics[index]
	unit.loadout.tactics.remove_at(index)
	unit.loadout.tactics.insert(destination, tactic)
	_commit_planning_tactics(unit)


func _editable_planning_unit() -> UnitDefinition:
	if campaign_manager == null or _has_active_scenario_run():
		return null
	return _find_planning_unit(selected_unit_name)


func _commit_planning_tactics(unit: UnitDefinition) -> void:
	if campaign_manager.set_tactics(_campaign_unit_id(unit), unit.loadout.tactics):
		_load_planning_party()
		_refresh_planning_panel()


func _on_planning_equip_pressed(index: int) -> void:
	if run_state == null or run_state.status != RunStateScript.STATUS_EQUIPMENT:
		return
	var options: Array[Dictionary] = run_state.equip_options()
	if index < 0 or index >= options.size():
		return
	var option: Dictionary = options[index]
	run_state.equip_inventory_item(int(option["item_index"]), String(option["unit_name"]))
	_load_planning_party_from_run()
	_show_run_state_without_combat_preview()


func _connect_panel_tooltips(panel: Control) -> void:
	if panel.has_signal("resource_tooltip_requested"):
		panel.connect("resource_tooltip_requested", _on_panel_resource_tooltip_requested)
	if panel.has_signal("glossary_tooltip_requested"):
		panel.connect("glossary_tooltip_requested", _on_panel_glossary_tooltip_requested)
	if panel.has_signal("tooltip_cleared"):
		panel.connect("tooltip_cleared", _on_tooltip_exited)


func _on_panel_resource_tooltip_requested(_source: Control, resource: Resource) -> void:
	if tooltip_presenter != null:
		tooltip_presenter.show_resource(resource)


func _on_panel_runtime_tooltip_requested(_source: Control, snapshot: Dictionary) -> void:
	if tooltip_presenter != null:
		tooltip_presenter.show_runtime_unit(snapshot)


func _on_panel_glossary_tooltip_requested(_source: Control, term: String) -> void:
	if tooltip_presenter != null:
		tooltip_presenter.show_glossary_term(term)


func _on_panel_structured_event_tooltip_requested(_source: Control, events: Array[Dictionary]) -> void:
	if tooltip_presenter != null:
		tooltip_presenter.show_structured_events(events)


func _on_tooltip_exited() -> void:
	if tooltip_presenter != null:
		tooltip_presenter.hide_tooltip()


func _planning_item_options(unit: UnitDefinition) -> Array:
	if campaign_manager == null or unit == null or _has_active_scenario_run():
		return []
	return campaign_manager.planning_item_options(_campaign_unit_id(unit))


func _on_planning_item_requested(option: Dictionary) -> void:
	if campaign_manager == null or _has_active_scenario_run():
		return
	var unit := _find_planning_unit(selected_unit_name)
	if unit == null:
		return
	if campaign_manager.equip_planning_item(_campaign_unit_id(unit), String(option.get("slot", "")), int(option.get("inventory_index", -1))):
		_load_planning_party()
		_refresh_planning_panel()


func _ensure_planning_loadout(unit: UnitDefinition):
	if unit.loadout == null:
		unit.loadout = UnitLoadoutDefinitionScript.new()
		unit.loadout.display_name = "%s Planning Loadout" % unit.display_name
	return unit.loadout


func _find_planning_unit(unit_name: String) -> UnitDefinition:
	for unit: UnitDefinition in planning_party:
		if unit.display_name == unit_name:
			return unit
	return null


func _campaign_unit_id(unit: UnitDefinition) -> String:
	if unit == null:
		return ""
	return String(unit.get_meta("campaign_unit_id", unit.display_name))


func _content_id(resource: Resource) -> String:
	if resource == null:
		return ""
	if resource.has_meta("content_id"):
		return String(resource.get_meta("content_id"))
	if not resource.resource_path.is_empty():
		return resource.resource_path.get_file().get_basename()
	return ""


func _resources_include_id(resources: Array, candidate: Resource) -> bool:
	var candidate_id := _content_id(candidate)
	for resource in resources:
		if _content_id(resource) == candidate_id:
			return true
	return false


func _show_campaign_landing() -> void:
	_clear_logs()
	var lines: Array[String] = []
	if campaign_manager != null:
		lines = campaign_manager.status_lines()
		lines.append("")
		lines.append("Available scenarios:")
		var scenarios: Array = campaign_manager.available_scenarios()
		if scenarios.is_empty():
			lines.append("- none")
		else:
			for scenario in scenarios:
				lines.append("- %s: %s" % [scenario.display_name, scenario.story_intro])
	_append_lines(combat_summary, lines)
	if selected_scenario == null and campaign_manager != null:
		var scenarios: Array = campaign_manager.all_scenarios()
		if not scenarios.is_empty():
			selected_scenario = scenarios[0]
	_refresh_planning_panel()
	_update_run_controls()
	call_deferred("_resize_conditions_pane")


func _show_campaign_message(message: String) -> void:
	_show_campaign_landing()
	if not message.is_empty():
		CombatLogRichTextFormatterScript.append_line(combat_summary, "", log_highlight_palette)
		CombatLogRichTextFormatterScript.append_line(combat_summary, message, log_highlight_palette)
		call_deferred("_resize_conditions_pane")


func _rebuild_mod_menu() -> void:
	for child in mods_list_vbox.get_children():
		child.queue_free()

	if available_mod_packs.is_empty():
		run_controls.show_mod_pack_count(0, 0)
		mods_list_panel.visible = false
		return

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

	run_controls.show_mod_pack_count(enabled_mod_pack_ids.size(), available_mod_packs.size())
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
	if _has_active_scenario_run() and run_state.active_scenario != null:
		_start_scenario_run(run_state.active_scenario, not active_campaign_scenario_id.is_empty())
	elif campaign_manager != null:
		_show_campaign_landing()
	else:
		_start_new_run(false)


func _position_mods_panel() -> void:
	var button_rect: Rect2 = run_controls.mods_button_rect()
	var viewport_rect := get_viewport_rect()
	var desired_size := Vector2(300.0, 220.0)
	var x: float = min(button_rect.position.x, viewport_rect.size.x - desired_size.x - 8.0)
	var y: float = min(button_rect.end.y + 4.0, viewport_rect.size.y - desired_size.y - 8.0)
	mods_list_panel.global_position = Vector2(max(8.0, x), max(8.0, y))
	mods_list_panel.size = desired_size


func _input(event: InputEvent) -> void:
	if tooltip_presenter != null and tooltip_presenter.handle_input(event):
		return
	if not mods_list_panel.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index > MOUSE_BUTTON_MIDDLE:
			return
		var click_pos := mouse_event.global_position
		var in_panel := mods_list_panel.get_global_rect().has_point(click_pos)
		var mods_button_rect: Rect2 = run_controls.mods_button_rect()
		var in_button := mods_button_rect.has_point(click_pos)
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


func _collect_static_log_lines(log_lines: Array[String], static_lines: Array[String]) -> void:
	var found_combat_log := false
	var skipping_battle_start_event := false
	for line in log_lines:
		if line == COMBAT_LOG_HEADER:
			found_combat_log = true
			continue
		if line.begins_with("t=000 | Battle starts."):
			skipping_battle_start_event = true
			continue
		if skipping_battle_start_event and line == "Roster:":
			skipping_battle_start_event = false
		elif skipping_battle_start_event:
			continue

		if not found_combat_log:
			static_lines.append(line)


func _append_lines(target_log: RichTextLabel, lines: Array[String]) -> void:
	for line in lines:
		CombatLogRichTextFormatterScript.append_line(target_log, line, log_highlight_palette)


func _resize_conditions_pane() -> void:
	if combat_summary.get_line_count() == 0 or log_split.size.y <= 0:
		return

	var max_conditions_height := int(log_split.size.y * 0.5)
	var desired_conditions_height := combat_summary.get_content_height() + int(conditions_label.size.y) + 12
	log_split.split_offset = clamp(desired_conditions_height, MIN_CONDITIONS_HEIGHT, max_conditions_height)


func _clear_logs() -> void:
	combat_summary.clear()
	_clear_replay_log()


func _clear_replay_log() -> void:
	replay_panel.call("clear_replay")


func _stop_log_replay() -> void:
	replay_panel.call("stop_replay")
	replay_is_active = false
	_update_run_controls()


func _on_replay_finished() -> void:
	replay_is_active = false
	if run_state != null and run_state.status == RunStateScript.STATUS_ACTIVE:
		run_state.complete_fight(cached_battle_report)
		var should_reload_campaign_party := false
		if run_state.status == RunStateScript.STATUS_WON and campaign_manager != null and not active_campaign_scenario_id.is_empty():
			campaign_manager.commit_completed_run(run_state)
			campaign_manager.complete_scenario(active_campaign_scenario_id)
			active_campaign_scenario_id = ""
			selected_scenario = null
			should_reload_campaign_party = true
		elif run_state.status == RunStateScript.STATUS_LOST and campaign_manager != null and not active_campaign_scenario_id.is_empty():
			campaign_manager.fail_scenario(active_campaign_scenario_id)
			active_campaign_scenario_id = ""
			should_reload_campaign_party = true
		if should_reload_campaign_party:
			_load_planning_party()
		else:
			_load_planning_party_from_run()
		combat_summary.clear()
		cached_static_lines = _build_run_static_lines([])
		_append_lines(combat_summary, cached_static_lines)
		call_deferred("_resize_conditions_pane")
	_update_run_controls()
	_refresh_planning_panel()
