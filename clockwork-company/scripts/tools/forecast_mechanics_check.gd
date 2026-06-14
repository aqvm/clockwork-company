extends SceneTree

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const CampaignRosterStateScript := preload("res://scripts/campaign/campaign_roster_state.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const PassiveDefinitionScript := preload("res://scripts/data/passive_definition.gd")
const StatusDefinitionScript := preload("res://scripts/data/status_definition.gd")
const TacticDefinitionScript := preload("res://scripts/data/tactic_definition.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")


func _init() -> void:
	var simulator = CombatSimulatorScript.new()
	var forecaster = _unit("Forecaster", "Allies", 1, 20, 1, 10)
	var endangered = _unit("Endangered", "Allies", 0, 10, 1, 30)
	endangered.hp = 6
	var enemy = _unit("Enemy", "Enemies", 2, 20, 5, 11)
	forecaster.current_passive = _forecast_passive()
	var foretell_tactic := _foretell_tactic()
	forecaster.tactics.append(foretell_tactic)
	forecaster.tactics.append(_attack_tactic())
	enemy.tactics.append(_attack_tactic())
	var units := [endangered, forecaster, enemy]

	var target = simulator.foretell_target_for_tactic(forecaster, units, foretell_tactic)
	assert(target == endangered, "Foretell should map the first matching speculative target back to real runtime state.")
	assert(endangered.hp == 6 and enemy.hp == 20, "Speculative combat must not mutate real runtime state.")
	var decision: Dictionary = TacticResolver.choose_action(forecaster, units, func(tactic): return simulator.foretell_target_for_tactic(forecaster, units, tactic))
	assert(decision["action"] == CombatConstantsScript.ACTION_HEAL and decision["target"] == endangered, "A Foretell tactic should execute now against its first future-match target.")
	endangered.hp = 4
	var speculative_decision: Dictionary = TacticResolver.choose_action(forecaster, units, Callable(), false)
	assert(speculative_decision["action"] == CombatConstantsScript.ACTION_HEAL and speculative_decision["target"] == endangered, "Speculation should evaluate Foretell tactics as normal tactics instead of skipping them.")
	endangered.hp = 6

	forecaster.current_passive = null
	decision = TacticResolver.choose_action(forecaster, units, func(tactic): return simulator.foretell_target_for_tactic(forecaster, units, tactic))
	assert(decision["action"] == CombatConstantsScript.ACTION_ATTACK, "Foretell tactics must be unavailable without an equipped Forecast passive.")
	assert(foretell_tactic.foretell_enabled, "Unequipping Forecast must preserve configured Foretell tactics.")
	forecaster.current_passive = _forecast_passive()

	var late_enemy = _unit("Late Enemy", "Enemies", 4, 20, 5, 21)
	assert(simulator.foretell_target_for_tactic(forecaster, [endangered, forecaster, late_enemy], foretell_tactic) == null, "Foretell horizon should end before the forecaster's next turn.")

	var mod_tactic: TacticDefinition = JsonContentLoaderScript.load_tactic_definition_by_id("foretell_heal_it", ["integration_test_mod_pack"])
	assert(mod_tactic != null and mod_tactic.foretell_enabled and mod_tactic.condition == CombatConstantsScript.CONDITION_ALLY_HP_BELOW_HALF, "JSON tactics should preserve the Foretell toggle and normal state condition.")
	var marra_definitions: Array[UnitDefinition] = JsonContentLoaderScript.load_unit_definitions_by_ids(["marra_archivist"], [])
	var marra = UnitStateScript.new(marra_definitions[0], 0)
	assert(marra.forecast_capable(), "Marra should retain the equipped Forecast passive.")
	for tactic in marra.tactics:
		assert(not tactic.foretell_enabled, "Marra should not receive an automatically configured Foretell tactic.")
	_assert_loaded_unit_resource_isolation(marra)

	var restored_tactic: TacticDefinition = _round_tripped_tactic(foretell_tactic)
	assert(restored_tactic != null and restored_tactic.condition == foretell_tactic.condition and restored_tactic.action == foretell_tactic.action and restored_tactic.target == foretell_tactic.target and restored_tactic.foretell_enabled, "Campaign saves should round-trip player-authored tactic fields.")
	var burning: StatusDefinition = JsonContentLoaderScript.load_status_definition_by_id("burning", [])
	var status_tactic := _attack_tactic()
	status_tactic.display_name = "Detonate at Four"
	status_tactic.condition = "Target Status Stacks At Least"
	status_tactic.status = burning
	status_tactic.status_stack_threshold = 4
	var restored_status_tactic: TacticDefinition = _round_tripped_tactic(status_tactic)
	assert(restored_status_tactic != null and restored_status_tactic.display_name == "Detonate at Four", "Campaign saves should preserve player-authored tactic names.")
	assert(restored_status_tactic.status != null and restored_status_tactic.status.status_type == "Burning" and restored_status_tactic.status_stack_threshold == 4, "Campaign saves should round-trip status-aware tactic parameters.")
	_assert_speculative_clone_isolation(forecaster)

	print("Foretell validation passed: normal speculative tactics, gating, first future match, target mapping, horizon, clone isolation, JSON authoring, campaign save data, and Marra cleanup worked.")
	quit(0)


func _unit(name: String, team: String, slot: int, hp: int, damage: int, next_time: int):
	var unit = UnitStateScript.new()
	unit.unit_name = name
	unit.unit_id = name.to_lower().replace(" ", "_")
	unit.team = team
	unit.slot_index = slot
	unit.max_hp = hp
	unit.hp = hp
	unit.physical_damage = damage
	unit.action_interval = 10
	unit.next_action_time = next_time
	return unit


func _forecast_passive() -> PassiveDefinition:
	var passive: PassiveDefinition = PassiveDefinitionScript.new()
	passive.display_name = "Read Ahead"
	passive.passive_type = "Forecast"
	return passive


func _foretell_tactic() -> TacticDefinition:
	var tactic: TacticDefinition = TacticDefinitionScript.new()
	tactic.display_name = "Foretell Healing"
	tactic.condition = CombatConstantsScript.CONDITION_ALLY_HP_BELOW_HALF
	tactic.action = CombatConstantsScript.ACTION_HEAL
	tactic.target = CombatConstantsScript.TARGET_LOWEST_HP_ALLY
	tactic.foretell_enabled = true
	return tactic


func _attack_tactic() -> TacticDefinition:
	var tactic: TacticDefinition = TacticDefinitionScript.new()
	tactic.display_name = "Attack"
	tactic.condition = CombatConstantsScript.CONDITION_ALWAYS
	tactic.action = CombatConstantsScript.ACTION_ATTACK
	tactic.target = CombatConstantsScript.TARGET_FRONTMOST_ENEMY
	return tactic


func _round_tripped_tactic(tactic: TacticDefinition) -> TacticDefinition:
	var roster = CampaignRosterStateScript.new()
	roster.reset(["marra_archivist"], [])
	assert(roster.set_tactics("marra_archivist", [tactic]), "Save test should configure Marra's campaign tactics.")
	var restored = CampaignRosterStateScript.new()
	restored.apply_save_data(roster.to_save_data(), ["marra_archivist"], [])
	var party: Array[UnitDefinition] = restored.active_party_snapshot()
	if party.is_empty() or party[0].loadout == null or party[0].loadout.tactics.is_empty():
		return null
	return party[0].loadout.tactics[0]


func _assert_speculative_clone_isolation(unit) -> void:
	var status: StatusDefinition = StatusDefinitionScript.new()
	status.display_name = "Clone Test Ailment"
	status.polarity = "Ailment"
	status.amount_percent = 25
	unit.add_status(status, "Test", 3, false)
	var clone = unit.clone_runtime_state()
	assert(clone.tactics[0] != unit.tactics[0] and clone.current_passive != unit.current_passive, "Speculative clones should not share tactic or passive Resources with real runtime state.")
	clone.tactics[0].foretell_enabled = false
	clone.current_passive.display_name = "Changed Clone Passive"
	var clone_status: Resource = clone.statuses[0]["definition"]
	clone_status.amount_percent = 99
	var second_status: StatusDefinition = StatusDefinitionScript.new()
	second_status.display_name = "Speculative Only"
	second_status.polarity = "Ailment"
	clone.add_status(second_status, "Test", 3, false)
	assert(unit.tactics[0].foretell_enabled and unit.current_passive.display_name == "Read Ahead", "Mutating speculative tactic and passive Resources must not affect real runtime state.")
	assert(unit.statuses[0]["definition"].amount_percent == 25 and not unit.has_status("Speculative Only"), "Mutating or applying speculative statuses must not affect real runtime state.")


func _assert_loaded_unit_resource_isolation(unit) -> void:
	var clone = unit.clone_runtime_state()
	assert(clone.ancestry != unit.ancestry and clone.current_ancestry_feature != unit.current_ancestry_feature, "Speculative clones should duplicate ancestry Resources.")
	assert(clone.loadout != unit.loadout and clone.current_job != unit.current_job and clone.current_passive != unit.current_passive, "Speculative clones should duplicate loadout and job Resources.")
	assert(clone.loadout.current_job != unit.loadout.current_job and clone.loadout.equipped_passive != unit.loadout.equipped_passive, "Speculative loadout Resources should not retain shared nested job features.")
	assert(clone.equipped_items[0] != unit.equipped_items[0] and clone.tactics[0] != unit.tactics[0], "Speculative clones should duplicate item and tactic Resources.")
