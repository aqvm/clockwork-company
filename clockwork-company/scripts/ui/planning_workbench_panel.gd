extends PanelContainer
class_name PlanningWorkbenchPanel

signal scenario_selected(scenario: Resource)
signal start_scenario_requested
signal practice_scenario_requested
signal unit_selected(unit_name: String)
signal planning_item_requested(option: Dictionary)
signal equip_option_requested(index: int)
signal unlock_choice_requested(choice: String)
signal planning_job_requested(job: JobDefinition)
signal planning_feature_requested(feature_type: String, feature: Resource)
signal planning_tactic_add_requested(tactic: TacticDefinition)
signal planning_tactic_remove_requested(index: int)
signal planning_tactic_move_requested(index: int, direction: int)
signal planning_tactic_changed(index: int, field: String, value: Variant)
signal resource_tooltip_requested(source: Control, resource: Resource)
signal glossary_tooltip_requested(source: Control, term: String)
signal tooltip_cleared

@onready var scenario_list_panel: Control = %ScenarioListPanel
@onready var scenario_detail_panel: Control = %ScenarioDetailPanel
@onready var party_panel: Control = %PartyPanel
@onready var unit_detail_panel: Control = %UnitDetailPanel
@onready var unit_action_panel: Control = %UnitActionPanel


func _ready() -> void:
	scenario_list_panel.connect("scenario_selected", func(scenario): scenario_selected.emit(scenario))
	_forward_tooltip_signals(scenario_list_panel)
	_forward_tooltip_signals(scenario_detail_panel)
	party_panel.connect("unit_selected", func(unit_name): unit_selected.emit(unit_name))
	_forward_tooltip_signals(party_panel)
	_forward_tooltip_signals(unit_detail_panel)
	unit_action_panel.connect("start_scenario_requested", func(): start_scenario_requested.emit())
	unit_action_panel.connect("practice_scenario_requested", func(): practice_scenario_requested.emit())
	unit_action_panel.connect("planning_item_requested", func(option): planning_item_requested.emit(option))
	unit_action_panel.connect("equip_option_requested", func(index): equip_option_requested.emit(index))
	unit_action_panel.connect("unlock_choice_requested", func(choice): unlock_choice_requested.emit(choice))
	unit_action_panel.connect("planning_job_requested", func(job): planning_job_requested.emit(job))
	unit_action_panel.connect("planning_feature_requested", func(feature_type, feature): planning_feature_requested.emit(feature_type, feature))
	unit_action_panel.connect("planning_tactic_add_requested", func(tactic): planning_tactic_add_requested.emit(tactic))
	unit_action_panel.connect("planning_tactic_remove_requested", func(index): planning_tactic_remove_requested.emit(index))
	unit_action_panel.connect("planning_tactic_move_requested", func(index, direction): planning_tactic_move_requested.emit(index, direction))
	unit_action_panel.connect("planning_tactic_changed", func(index, field, value): planning_tactic_changed.emit(index, field, value))
	_forward_tooltip_signals(unit_action_panel)


func show_scenarios(scenarios: Array, progress, selected_scenario: Resource, active_scenario_id: String, campaign_scenario_ids: Array[String]) -> void:
	scenario_list_panel.call("show_scenarios", scenarios, progress, selected_scenario, active_scenario_id, campaign_scenario_ids)


func show_scenario(scenario: Resource, status_text: String, campaign_progress = null) -> void:
	scenario_detail_panel.call("show_scenario", scenario, status_text, campaign_progress)


func show_party(party: Array[UnitDefinition], selected_unit_name: String) -> void:
	party_panel.call("show_party", party, selected_unit_name)


func show_unit(unit: UnitDefinition, party: Array[UnitDefinition]) -> void:
	unit_detail_panel.call("show_unit", unit, party)


func show_actions(
	selected_scenario: Resource,
	selected_unit: UnitDefinition,
	selected_unit_name: String,
	selected_scenario_status: String,
	can_start_scenario: bool,
	can_practice_scenario: bool,
	has_active_campaign_scenario: bool,
	is_replay_active: bool,
	is_equipment_state: bool,
	planning_item_options: Array,
	equip_options: Array,
	unlock_options: Array,
	job_options: Array,
	learned_feature_options: Dictionary,
	tactic_options: Array
) -> void:
	unit_action_panel.call(
		"show_actions",
		selected_scenario,
		selected_unit,
		selected_unit_name,
		selected_scenario_status,
		can_start_scenario,
		can_practice_scenario,
		has_active_campaign_scenario,
		is_replay_active,
		is_equipment_state,
		planning_item_options,
		equip_options,
		unlock_options,
		job_options,
		learned_feature_options,
		tactic_options
	)


func _forward_tooltip_signals(panel: Control) -> void:
	if panel.has_signal("resource_tooltip_requested"):
		panel.connect("resource_tooltip_requested", func(source, resource): resource_tooltip_requested.emit(source, resource))
	if panel.has_signal("glossary_tooltip_requested"):
		panel.connect("glossary_tooltip_requested", func(source, term): glossary_tooltip_requested.emit(source, term))
	if panel.has_signal("tooltip_cleared"):
		panel.connect("tooltip_cleared", func(): tooltip_cleared.emit())
