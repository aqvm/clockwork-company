extends SceneTree

const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")
const CombatContextScript := preload("res://scripts/combat/runtime/combat_context.gd")
const CombatHookResolverScript := preload("res://scripts/combat/rules/combat_hook_resolver.gd")
const ReactionDefinitionScript := preload("res://scripts/data/reaction_definition.gd")
const ReconstitutionStatus := preload("res://resources/statuses/reconstitution.tres")
const ConfusionStatus := preload("res://resources/statuses/confusion.tres")
const BleedStatus := preload("res://resources/statuses/bleed.tres")
const NumbStatus := preload("res://resources/statuses/numb.tres")
const FrostStatus := preload("res://resources/statuses/frost.tres")
const BurningStatus := preload("res://resources/statuses/burning.tres")
const WardStatus := preload("res://resources/statuses/ward.tres")
const RotStatus := preload("res://resources/statuses/rot.tres")
const RenewalStatus := preload("res://resources/statuses/renewal.tres")
const TEST_UNIT := preload("res://resources/units/alden_guard.tres")


func _init() -> void:
	var unit = UnitStateScript.new(TEST_UNIT, 0)
	var log = CombatLogScript.new()
	var root_entry_id: int = log.add("Status mechanics check")

	assert(StatusResolverScript.apply_status(log, root_entry_id, unit, ReconstitutionStatus, "Status mechanics check"))
	assert(StatusResolverScript.apply_status(log, root_entry_id, unit, ReconstitutionStatus, "Refresh source", 5))
	assert(int(unit.status_instance("Reconstitution").get("stack_count", 0)) == 2, "Reconstitution reapplication should intensify to two stacks.")
	assert(int(unit.status_instance("Reconstitution").get("remaining_turns", 0)) == 5, "Reapplication should refresh to the longer finite duration.")
	assert(StatusResolverScript.apply_status(log, root_entry_id, unit, ReconstitutionStatus, "Status mechanics check", 3))
	assert(int(unit.status_instance("Reconstitution").get("stack_count", 0)) == 3, "Reconstitution should intensify to its three-stack cap.")
	assert(int(unit.status_instance("Reconstitution").get("remaining_turns", 0)) == 5, "A shorter reapplication should not shorten existing duration.")
	assert(StatusResolverScript.apply_status(log, root_entry_id, unit, ReconstitutionStatus, "At-cap refresh", 2))
	assert(int(unit.status_instance("Reconstitution").get("stack_count", 0)) == 3, "Reconstitution should not exceed its authored stack cap.")
	assert(int(unit.status_instance("Reconstitution").get("remaining_turns", 0)) == 5, "At-cap reapplication should still keep the longer duration.")

	unit.hp -= 7
	StatusResolverScript.record_damage(unit, 7)
	var active_ids: Array[int] = unit.status_instance_ids()
	StatusResolverScript.apply_turn_start_statuses(log, root_entry_id, unit)
	StatusResolverScript.elapse_turn_statuses(log, root_entry_id, unit, active_ids)

	assert(unit.hp == unit.max_hp, "Three-stack Reconstitution should restore 100%% of 7 damage.")
	assert(int(unit.status_instance("Reconstitution").get("damage_since_last_turn", -1)) == 0, "Reconstitution should clear stored damage after turn-start resolution.")
	assert(int(unit.status_instance("Reconstitution").get("stack_count", 0)) == 2, "Successful Reconstitution healing should consume one stack.")
	assert(int(unit.status_instance("Reconstitution").get("remaining_turns", 0)) == 4, "A finite status should lose one turn after affecting an owner turn.")

	unit.hp -= 4
	StatusResolverScript.record_damage(unit, 4)
	active_ids = unit.status_instance_ids()
	StatusResolverScript.apply_turn_start_statuses(log, root_entry_id, unit)
	StatusResolverScript.elapse_turn_statuses(log, root_entry_id, unit, active_ids)
	assert(unit.hp == unit.max_hp - 1, "Two-stack Reconstitution should restore floor(4 * 75%%) = 3 HP.")
	assert(int(unit.status_instance("Reconstitution").get("stack_count", 0)) == 1, "A second successful heal should consume another stack.")

	StatusResolverScript.elapse_turn_statuses(log, root_entry_id, unit, unit.status_instance_ids())
	assert(int(unit.status_instance("Reconstitution").get("stack_count", 0)) == 1, "A turn with no restored HP should not consume a stack.")
	unit.hp -= 2
	StatusResolverScript.record_damage(unit, 2)
	active_ids = unit.status_instance_ids()
	StatusResolverScript.apply_turn_start_statuses(log, root_entry_id, unit)
	StatusResolverScript.elapse_turn_statuses(log, root_entry_id, unit, active_ids)
	assert(not unit.has_status("Reconstitution"), "A successful one-stack Reconstitution heal should consume the final stack.")

	assert(StatusResolverScript.apply_status(log, root_entry_id, unit, ConfusionStatus, "Permanent test", 1, true))
	for _turn in range(5):
		StatusResolverScript.elapse_turn_statuses(log, root_entry_id, unit, unit.status_instance_ids())
	assert(unit.has_status("Confusion"), "Explicitly permanent statuses should not expire.")

	var finite_unit = UnitStateScript.new(TEST_UNIT, 1)
	assert(StatusResolverScript.apply_status(log, root_entry_id, finite_unit, ConfusionStatus, "Finite duration test", 2))
	for _turn in range(2):
		StatusResolverScript.elapse_turn_statuses(log, root_entry_id, finite_unit, finite_unit.status_instance_ids())
	assert(not finite_unit.has_status("Confusion"), "Finite statuses should expire after their authored affected owner turns.")

	var mod_units: Array[UnitDefinition] = JsonContentLoaderScript.load_unit_definitions_by_ids(["borin_anchor_it"], ["integration_test_mod_pack"])
	assert(mod_units.size() == 1, "Integration test unit should load through JSON content.")
	var mod_job: JobDefinition = JsonContentLoaderScript.load_job_definition_by_id("warden_it", ["integration_test_mod_pack"])
	assert(mod_job != null and mod_job.skill != null and mod_job.skill.status != null, "JSON skills should resolve status_id references.")
	assert(mod_job.skill.status_duration_turns == 5 and not mod_job.skill.status_is_permanent, "JSON skills should preserve authored finite duration.")
	assert(mod_job.skill.status.stacking_rule == "Intensify" and mod_job.skill.status.max_stacks == 3, "JSON statuses should preserve authored stacking rules and caps.")
	var mod_unit = UnitStateScript.new(mod_units[0], 0)
	var mod_context = CombatContextScript.new([mod_unit], log)
	mod_context.add_responder(CombatHookResolverScript.respond)
	mod_context.publish("battle_started", null, null, {}, -1, root_entry_id)
	assert(mod_unit.has_status("Reconstitution IT"), "Battle-start Apply Status should resolve a JSON status_id reference.")
	assert(int(mod_unit.status_instance("Reconstitution").get("remaining_turns", 0)) == 3, "JSON status applications should default to finite three-turn duration.")

	_assert_hook_driven_statuses()
	_assert_high_value_statuses()

	print("Status mechanics validation passed: core hooks plus Burn/Scorched, Ward, Rot, and Renewal worked.")
	quit(0)


func _assert_hook_driven_statuses() -> void:
	var bleeding_unit = UnitStateScript.new(TEST_UNIT, 0)
	var log = CombatLogScript.new()
	var context = CombatContextScript.new([bleeding_unit], log)
	context.add_responder(CombatHookResolverScript.respond)
	var root_entry_id: int = log.add("Hook-driven status check")
	assert(StatusResolverScript.apply_status(log, root_entry_id, bleeding_unit, BleedStatus, "Test", 2, false, context))
	assert(StatusResolverScript.apply_status(log, root_entry_id, bleeding_unit, BleedStatus, "Test", 2, false, context))
	var hp_before_bleed: int = bleeding_unit.hp
	context.publish("action_completed", bleeding_unit, bleeding_unit, {"action": "Test"}, -1, root_entry_id, ["action"])
	assert(bleeding_unit.hp == hp_before_bleed - 2, "Two Bleed stacks should deal two damage after the afflicted unit completes an action.")
	assert(context.events_of_type("damage_dealt").size() == 1, "Bleed damage should use the shared damage event pipeline.")
	StatusResolverScript.elapse_turn_statuses(log, root_entry_id, bleeding_unit, bleeding_unit.status_instance_ids(), context)
	assert(bleeding_unit.has_status("Bleed"), "Bleed should not expire naturally.")

	var attacker = UnitStateScript.new(TEST_UNIT, 1)
	var reaction := ReactionDefinitionScript.new()
	reaction.display_name = "Test Counter"
	reaction.trigger = "Damaged"
	reaction.reaction_type = "Damage Attacker"
	reaction.amount = 1
	bleeding_unit.current_reaction = reaction
	assert(StatusResolverScript.apply_status(log, root_entry_id, bleeding_unit, NumbStatus, "Test", 2, false, context))
	context.apply_direct_damage(attacker, bleeding_unit, 1, -1, root_entry_id, ["test"])
	assert(context.events_of_type("reaction_suppressed").size() == 1, "Numb should suppress and explain an otherwise-valid reaction.")
	assert(StatusResolverScript.remove_status(log, root_entry_id, bleeding_unit, "Numb", "test removal", context, attacker))
	var attacker_hp_before: int = attacker.hp
	context.apply_direct_damage(attacker, bleeding_unit, 1, -1, root_entry_id, ["test"])
	assert(attacker.hp == attacker_hp_before - 1, "Removing Numb should allow the reaction to trigger again.")
	assert(context.events_of_type("reaction_triggered").size() == 1, "Reaction triggering should emit a shared hook event.")
	assert(context.events_of_type("status_removed").size() >= 1, "Explicit status removal should emit a shared hook event.")

	assert(StatusResolverScript.apply_status(log, root_entry_id, bleeding_unit, FrostStatus, "Test", 2, false, context))
	assert(StatusResolverScript.apply_status(log, root_entry_id, bleeding_unit, FrostStatus, "Test", 2, false, context))
	var physical_request: Dictionary = context.request("damage_requested", attacker, bleeding_unit, {
		"physical_amount": 3,
		"magic_amount": 0,
		"amount": 3,
		"prevented": false,
	}, -1, root_entry_id, ["damage", "physical"])
	assert(int(physical_request["payload"]["amount"]) == 5, "Two Frost stacks should increase three post-armor physical damage by 40%, rounded up.")
	assert(bleeding_unit.has_status("Frost"), "Frost should remain until the modified physical damage actually resolves.")
	var previous_frost_target_hp: int = bleeding_unit.hp
	bleeding_unit.hp -= int(physical_request["payload"]["amount"])
	context.record_damage(attacker, bleeding_unit, int(physical_request["payload"]["amount"]), previous_frost_target_hp, int(physical_request["payload"]["physical_amount"]), 0, int(physical_request["id"]), root_entry_id, ["damage", "physical"])
	assert(not bleeding_unit.has_status("Frost"), "Frost should be removed after modified physical damage resolves.")
	assert(StatusResolverScript.apply_status(log, root_entry_id, bleeding_unit, FrostStatus, "Test", 2, false, context))
	var magic_request: Dictionary = context.request("damage_requested", attacker, bleeding_unit, {
		"physical_amount": 0,
		"magic_amount": 3,
		"amount": 3,
		"prevented": false,
	}, -1, root_entry_id, ["damage", "magic"])
	assert(int(magic_request["payload"]["amount"]) == 3 and bleeding_unit.has_status("Frost"), "Nonphysical damage should not consume or benefit from Frost.")
	for _stack in range(4):
		assert(StatusResolverScript.apply_status(log, root_entry_id, bleeding_unit, FrostStatus, "Test", 2, false, context))
	var capped_frost_request: Dictionary = context.request("damage_requested", attacker, bleeding_unit, {
		"physical_amount": 10,
		"magic_amount": 0,
		"amount": 10,
		"prevented": false,
	}, -1, root_entry_id, ["damage", "physical"])
	assert(int(capped_frost_request["payload"]["amount"]) == 20, "Five Frost stacks should double the next post-armor physical hit.")


func _assert_high_value_statuses() -> void:
	var loaded_status_types: Array[String] = []
	for status in JsonContentLoaderScript.load_status_definitions([]):
		loaded_status_types.append(status.status_type)
	for required_type in ["Burning", "Ward", "Rot", "Renewal"]:
		assert(loaded_status_types.has(required_type), "%s should appear in the authorable status library." % required_type)
	assert(not loaded_status_types.has("Scorched"), "Scorched is an immediate consequence, not a status.")

	var supporter = UnitStateScript.new(TEST_UNIT, 0)
	supporter.unit_name = "Supporter"
	supporter.next_action_time = 10
	var burning_unit = UnitStateScript.new(TEST_UNIT, 1)
	burning_unit.unit_name = "Burning Unit"
	var log = CombatLogScript.new()
	var root_entry_id: int = log.add("High-value status check")
	var context = CombatContextScript.new([supporter, burning_unit], log)
	context.add_responder(CombatHookResolverScript.respond)

	assert(StatusResolverScript.apply_status(log, root_entry_id, burning_unit, BurningStatus, "Test", 3, false, context, supporter, -1, 2))
	var hp_before_burn: int = burning_unit.hp
	context.publish("action_completed", burning_unit, supporter, {"action": "Test"}, -1, root_entry_id, ["action"])
	assert(burning_unit.hp == hp_before_burn - 2, "Two Burn stacks should deal two action damage.")
	assert(burning_unit.status_stack_count("Burning") == 1, "Burn should decay by one stack after triggering.")

	StatusResolverScript.apply_status(log, root_entry_id, burning_unit, BurningStatus, "Test", 3, false, context)
	burning_unit.hp -= 3
	var supporter_time_before: int = supporter.next_action_time
	context.apply_healing(supporter, burning_unit, 2, -1, root_entry_id, ["test"])
	assert(supporter.next_action_time == supporter_time_before + 4, "Supporting a two-stack Burning unit should apply a four-time Scorched delay.")
	assert(context.events_of_type("scorched").size() == 1 and not supporter.has_status("Scorched"), "Scorched should be recorded as an immediate consequence, not a status.")

	assert(StatusResolverScript.apply_status(log, root_entry_id, burning_unit, WardStatus, "Test", 3, false, context))
	assert(not StatusResolverScript.apply_status(log, root_entry_id, burning_unit, RotStatus, "Test", 3, false, context, supporter), "Ward should prevent an incoming ailment.")
	assert(not burning_unit.has_status("Rot") and not burning_unit.has_status("Ward"), "One Ward charge should be consumed when it blocks an ailment.")

	assert(StatusResolverScript.apply_status(log, root_entry_id, burning_unit, RotStatus, "Test", 3, false, context, supporter, -1, 2))
	var max_hp_before_rot: int = burning_unit.max_hp
	burning_unit.hp -= 3
	context.apply_healing(supporter, burning_unit, 2, -1, root_entry_id, ["test"])
	assert(burning_unit.max_hp == max_hp_before_rot - 2, "Two Rot stacks should remove two maximum HP when healing lands.")

	assert(StatusResolverScript.apply_status(log, root_entry_id, burning_unit, RenewalStatus, "Test", 3, false, context))
	burning_unit.hp -= 8
	var hp_before_renewal: int = burning_unit.hp
	assert(StatusResolverScript.remove_status(log, root_entry_id, burning_unit, "Rot", "test cleanse", context, supporter))
	assert(burning_unit.hp == hp_before_renewal + RenewalStatus.amount, "Removing an ailment should trigger Renewal healing.")
