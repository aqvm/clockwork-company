extends RefCounted

const CombatContextScript := preload("res://scripts/combat/runtime/combat_context.gd")
const CombatHookResolverScript := preload("res://scripts/combat/rules/combat_hook_resolver.gd")
const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")

const BurningStatus := preload("res://resources/statuses/burning.tres")
const ElementalFusionStatus := preload("res://resources/statuses/elemental_fusion.tres")
const FrostStatus := preload("res://resources/statuses/frost.tres")
const ShockStatus := preload("res://resources/statuses/shock.tres")


static func effect(trigger: String, effect_type: String, target_selector: String, amount := 0, status: StatusDefinition = null) -> EffectDefinition:
	var result := EffectDefinition.new()
	result.display_name = "%s %s" % [trigger, effect_type]
	result.trigger = trigger
	result.effect_type = effect_type
	result.target_selector = target_selector
	result.amount = amount
	result.status = status
	return result


static func unit(display_name: String, team: String):
	var result = UnitStateScript.new()
	result.unit_name = display_name
	result.unit_id = display_name.to_lower()
	result.team = team
	result.max_hp = 20
	result.hp = 20
	result.physical_damage = 5
	return result


static func context(units: Array, log):
	var result = CombatContextScript.new(units, log)
	result.add_responder(CombatHookResolverScript.respond)
	return result


static func assert_elementalist_authoring(log, root_log_id: int) -> void:
	var elementalist = unit("Elementalist", "Allies")
	var target = unit("Fusion Target", "Enemies")
	var target_ally = unit("Fusion Ally", "Enemies")
	var test_context = context([elementalist, target, target_ally], log)
	var passive := PassiveDefinition.new()
	passive.display_name = "Elemental Buffer"
	var shield_effect := effect("Owner Applied Ailment", "Grant Energy Shield", "Self")
	shield_effect.amount_source = "Applied Status Stacks"
	shield_effect.amount_multiplier = 5
	shield_effect.repeat_within_event_chain = true
	passive.effects.append(shield_effect)
	elementalist.current_passive = passive
	var primary_target = unit("Primary Target", "Enemies")
	test_context.units.append(primary_target)
	var primary := SkillDefinition.new()
	primary.display_name = "Elemental Triad"
	primary.action = "Effects Only"
	primary.effects.append(effect("Skill Used", "Apply Status", "Event Target", 0, BurningStatus))
	primary.effects.append(effect("Skill Used", "Apply Status", "Event Target", 0, ShockStatus))
	primary.effects.append(effect("Skill Used", "Apply Status", "Event Target", 0, FrostStatus))
	elementalist.current_skill = primary
	CombatSimulatorScript.new()._resolve_skill(test_context, log, root_log_id, elementalist, primary_target, primary, "job skill")
	assert(elementalist.energy_shield == 15, "A repeat-enabled owner-applied-ailment effect should reward all three applications in one skill chain.")
	elementalist.energy_shield = 0
	assert(StatusResolverScript.apply_status(log, root_log_id, target, BurningStatus, "Elementalist", 3, false, test_context, elementalist, -1, 2))
	assert(elementalist.energy_shield == 10, "Owner Applied Ailment should grant ES from stacks actually added by the owner.")
	assert(StatusResolverScript.apply_status(log, root_log_id, target, ShockStatus, "Transferred", 3, false, test_context, elementalist, -1, 1, false, true))
	assert(elementalist.energy_shield == 10, "Transferred ailment stacks should not retrigger owner-applied-ailment effects.")
	assert(StatusResolverScript.apply_status(log, root_log_id, target, ShockStatus, "Elementalist", 3, false, test_context, elementalist))
	assert(StatusResolverScript.apply_status(log, root_log_id, target, FrostStatus, "Elementalist", 3, false, test_context, elementalist, -1, 2))
	var bridge := SkillDefinition.new()
	bridge.display_name = "Elemental Convergence"
	bridge.action = "Effects Only"
	var fuse := effect("Skill Used", "Fuse Elemental Ailments", "Event Target", 0, ElementalFusionStatus)
	fuse.amount_divisor = 3
	bridge.effects.append(fuse)
	elementalist.current_secondary_skill = bridge
	var shield_before_fusion: int = elementalist.energy_shield
	CombatSimulatorScript.new()._resolve_skill(test_context, log, root_log_id, elementalist, target, bridge, "secondary skill")
	assert(not target.has_status("Burning") and not target.has_status("Shock") and not target.has_status("Frost"), "Elemental fusion should remove all three source ailments.")
	assert(target.status_stack_count("Elemental Fusion") == 2, "Six elemental stacks should become two fusion stacks at a 3:1 authored divisor.")
	assert(elementalist.energy_shield == shield_before_fusion + 10, "New fusion stacks should count as owner-applied ailment stacks.")
	var target_hp_before_tick: int = target.hp
	test_context.publish("action_completed", target, target, {"action": "Test"}, -1, root_log_id, ["action"])
	assert(target.hp == target_hp_before_tick - 2 and target.status_stack_count("Elemental Fusion") == 1, "Elemental Fusion should apply Burning-style action damage and consume one stack.")
	var ally_hp_before_arc: int = target_ally.hp
	test_context.apply_direct_damage(elementalist, target, 8, -1, root_log_id, ["magic"])
	assert(target_ally.hp == ally_hp_before_arc - 2 and not target.has_status("Elemental Fusion"), "Elemental Fusion should apply Shock-style propagation and consume one stack.")
	assert(StatusResolverScript.apply_status(log, root_log_id, target, ElementalFusionStatus, "Elementalist", 3, false, test_context, elementalist, -1, 2))
	var physical_request: Dictionary = test_context.request("damage_requested", elementalist, target, {
		"amount": 3,
		"physical_amount": 3,
		"magic_amount": 0,
		"prevented": false,
	}, -1, root_log_id, ["physical"])
	assert(int(physical_request["payload"].get("amount", 0)) == 5, "Two Elemental Fusion stacks should add 40 percent Frost-style physical damage, rounded up.")
	var previous_hp: int = target.hp
	target.hp = max(0, target.hp - int(physical_request["payload"].get("amount", 0)))
	test_context.record_damage(elementalist, target, int(physical_request["payload"].get("amount", 0)), previous_hp, int(physical_request["payload"].get("physical_amount", 0)), 0, int(physical_request["id"]), root_log_id, ["physical"])
	assert(not target.has_status("Elemental Fusion"), "Physical HP damage should shatter Elemental Fusion like Frost.")

	var doomed = unit("Doomed", "Enemies")
	var ailmented = unit("Ailmented", "Enemies")
	ailmented.hp = 10
	var clean = unit("Clean", "Enemies")
	clean.hp = 5
	var reaction_context = context([elementalist, doomed, ailmented, clean], log)
	assert(StatusResolverScript.apply_status(log, root_log_id, doomed, BurningStatus, "Elementalist", 4, false, reaction_context, elementalist, -1, 2))
	assert(StatusResolverScript.apply_status(log, root_log_id, doomed, ShockStatus, "Elementalist", 2, false, reaction_context, elementalist))
	assert(StatusResolverScript.apply_status(log, root_log_id, ailmented, FrostStatus, "Setup", 3, false, reaction_context, elementalist))
	var carryover := ReactionDefinition.new()
	carryover.display_name = "Elemental Inheritance"
	carryover.trigger = "Enemy Died With Ailments"
	carryover.reaction_type = "Effects Only"
	carryover.cooldown_turns = 3
	carryover.effects.append(effect("Reaction Triggered", "Transfer Defeated Ailments", "Most Ailmented Enemy Unit"))
	elementalist.current_reaction = carryover
	var shield_before_transfer: int = elementalist.energy_shield
	reaction_context.apply_physical_damage(elementalist, doomed, doomed.hp, -1, root_log_id, ["test"])
	assert(ailmented.status_stack_count("Burning") == 2 and ailmented.status_stack_count("Shock") == 1, "Defeated ailments should transfer to the living enemy with the most ailments.")
	assert(not clean.has_status("Burning") and not clean.has_status("Shock"), "Defeated-ailment transfer should use deterministic concentration targeting.")
	assert(elementalist.energy_shield == shield_before_transfer, "Transferred defeated ailments should not generate owner-applied-ailment ES.")
