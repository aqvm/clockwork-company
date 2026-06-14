extends SceneTree

const CombatContextScript := preload("res://scripts/combat/runtime/combat_context.gd")
const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const CombatHookResolverScript := preload("res://scripts/combat/rules/combat_hook_resolver.gd")
const TacticResolverScript := preload("res://scripts/combat/rules/tactic_resolver.gd")
const TriggeredEffectResolverScript := preload("res://scripts/combat/rules/triggered_effect_resolver.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const BleedStatus := preload("res://resources/statuses/bleed.tres")
const FrostStatus := preload("res://resources/statuses/frost.tres")
const NumbStatus := preload("res://resources/statuses/numb.tres")
const BurningStatus := preload("res://resources/statuses/burning.tres")
const RotStatus := preload("res://resources/statuses/rot.tres")
const WardStatus := preload("res://resources/statuses/ward.tres")
const RenewalStatus := preload("res://resources/statuses/renewal.tres")
const RegenerationStatus := preload("res://resources/statuses/regeneration.tres")
const ReconstitutionStatus := preload("res://resources/statuses/reconstitution.tres")
const AshChokedRule := preload("res://resources/scenario_rules/ash_chapel_confusion.tres")
const AldenGuard := preload("res://resources/units/alden_guard.tres")
const IronBrute := preload("res://resources/units/iron_brute.tres")


func _init() -> void:
	var invalid_requested_condition := _effect("Battle Start", "Apply Status", "Self", 0, BleedStatus)
	invalid_requested_condition.condition = "Requested Status Matches"
	assert(not invalid_requested_condition.support_error().is_empty(), "Resource validation should reject request-only conditions on ordinary triggers.")
	var invalid_counter_formula := _effect("Battle Start", "Apply Status", "Self", 0, BleedStatus)
	invalid_counter_formula.amount_source = "Target Counter"
	assert(not invalid_counter_formula.support_error().is_empty(), "Resource validation should reject counter formulas without a counter name.")

	var ally = _unit("Ally", "Allies")
	var enemy = _unit("Enemy", "Enemies")
	var rule := ScenarioRuleDefinition.new()
	rule.display_name = "Authored Weather"
	rule.effects.append(_effect("Battle Start", "Apply Status", "All Units", 0, BleedStatus))
	var modifier := _effect("Battle Start", "Modify Stat", "Allied Units", 3)
	modifier.modified_stat = "Physical Damage"
	modifier.modifier_duration_turns = 1
	rule.effects.append(modifier)

	var log = CombatLogScript.new()
	var root_log_id: int = log.add("Triggered effect check")
	var context = CombatContextScript.new([ally, enemy], log, [rule])
	context.add_responder(TriggeredEffectResolverScript.respond)
	context.publish("battle_started", null, null, {}, -1, root_log_id)
	assert(ally.has_status("Bleed") and enemy.has_status("Bleed"), "Scenario hooks should broadly apply statuses.")
	assert(ally.physical_damage == 8, "Scenario hooks should apply temporary stat modifiers.")
	context.publish("turn_completed", ally, ally, {}, -1, root_log_id)
	assert(ally.physical_damage == 5 and ally.temporary_modifiers.is_empty(), "Temporary modifiers should expire after the configured owner turns.")

	var item := ItemDefinition.new()
	item.display_name = "Resolver Test Item"
	var apply_frost := _effect("Hit", "Apply Status", "Event Target", 0, FrostStatus)
	item.effects.append(apply_frost)
	var random_cleanse := _effect("Damaged", "Remove Status", "Self")
	random_cleanse.status_polarity = "Ailment"
	random_cleanse.status_removal_mode = "Random Matching"
	item.effects.append(random_cleanse)
	var specific_cleanse := _effect("Reaction Triggered", "Remove Status", "Self")
	specific_cleanse.status_removal_mode = "Specific Status"
	specific_cleanse.status = NumbStatus
	item.effects.append(specific_cleanse)
	ally.equipped_items.append(item)

	context.publish("damage_dealt", ally, enemy, {"amount": 2, "physical_amount": 2}, -1, root_log_id, ["attack"])
	assert(enemy.has_status("Frost"), "Hit effects should apply a status to the event target.")
	var before_random_cleanse: int = ally.statuses.size()
	context.publish("damage_dealt", enemy, ally, {"amount": 2, "physical_amount": 2}, -1, root_log_id)
	assert(ally.statuses.size() == before_random_cleanse - 1, "Random Matching removal should remove one eligible status deterministically.")
	ally.add_status(NumbStatus, "test", 3, false)
	context.publish("reaction_triggered", ally, enemy, {}, -1, root_log_id)
	assert(not ally.has_status("Numb"), "Specific Status removal should remove the referenced status type.")
	var json_item: ItemDefinition = JsonContentLoaderScript.load_item_definition_by_id("resolver_vocabulary_it", ["integration_test_mod_pack"])
	assert(json_item != null and json_item.effects.size() == 2, "JSON should load shared triggered effects.")
	assert(json_item.effects[0].modified_stat == "Action Interval" and json_item.effects[0].modifier_duration_turns == 2, "JSON should preserve temporary modifier fields.")
	assert(json_item.effects[1].status_removal_mode == "Specific Status" and json_item.effects[1].status != null, "JSON should preserve status-removal fields and references.")
	var json_job: JobDefinition = JsonContentLoaderScript.load_job_definition_by_id("cleanser_it", ["integration_test_mod_pack"])
	assert(json_job != null and json_job.skill.action == "Effects Only" and json_job.skill.attack_count == 2 and json_job.skill.effects.size() == 1, "JSON should load effect-only job skills and attack counts.")
	assert(json_job.passive.effects.size() == 2 and json_job.passive.effects[0].status.status_type == "Bleed" and json_job.passive.effects[1].trigger == "Damage Requested", "JSON should load specific and generic request-interception effects.")
	assert(json_job.reaction.effects.size() == 2 and json_job.reaction.status.status_type == "Burning", "JSON should load effect-only reactions, stack conditions, and formula effects.")
	assert(json_job.default_tactic.status.status_type == "Burning", "JSON should load status-aware default tactics.")
	var formula_probe: ItemDefinition = JsonContentLoaderScript.load_item_definition_by_id("formula_counter_probe_it", ["integration_test_mod_pack"])
	assert(formula_probe != null and formula_probe.effects.size() == 2, "JSON should reconstruct formula/counter probe effects.")
	assert(formula_probe.effects[0].repeat_within_event_chain, "JSON should preserve opt-in repeated resolution within one event chain.")
	assert(formula_probe.effects[1].counter_threshold == 2 and formula_probe.effects[1].amount_source == "Target Counter" and formula_probe.effects[1].amount_multiplier == 2, "JSON should preserve counter thresholds and formula scaling fields.")
	var skill := SkillDefinition.new()
	skill.display_name = "Cleanse Lesson"
	skill.action = "Effects Only"
	var skill_cleanse := _effect("Skill Used", "Remove Status", "Self")
	skill_cleanse.status_polarity = "Ailment"
	skill.effects.append(skill_cleanse)
	ally.current_skill = skill
	ally.add_status(FrostStatus, "test", 3, false)
	context.publish("skill_used", ally, ally, {"skill": skill.display_name, "action": skill.action}, -1, root_log_id)
	assert(not ally.has_status("Frost"), "Effect-only job skills should resolve the shared effect vocabulary.")
	var ash_target = _unit("Ash Target", "Allies")
	var ash_context = CombatContextScript.new([ash_target], log, [AshChokedRule])
	ash_context.add_responder(TriggeredEffectResolverScript.respond)
	ash_context.publish("battle_started", null, null, {}, -1, root_log_id)
	assert(ash_target.has_status("Confusion"), "Ash-Choked Rites should resolve through its authored scenario-rule effect.")
	var loop_rule := ScenarioRuleDefinition.new()
	loop_rule.display_name = "Root Loop Guard"
	loop_rule.effects.append(_effect("Status Applied", "Apply Status", "Event Target", 0, FrostStatus))
	var loop_target = _unit("Loop Target", "Allies")
	var loop_context = CombatContextScript.new([loop_target], log, [loop_rule])
	loop_context.add_responder(TriggeredEffectResolverScript.respond)
	StatusResolverScript.apply_status(log, root_log_id, loop_target, BleedStatus, "Loop test", 3, false, loop_context)
	assert(loop_target.has_status("Bleed") and loop_target.has_status("Frost"), "A status-applied hook should resolve its intended consequence.")
	assert(loop_context.events_of_type("triggered_effect_resolved").size() == 1, "A shared effect should fire at most once in one causal root.")

	var immune = _unit("Bleed Immune", "Allies")
	var immunity := PassiveDefinition.new()
	immunity.display_name = "Bloodless"
	var prevent_bleed := _effect("Status Application Requested", "Prevent Request", "Self")
	prevent_bleed.condition = "Requested Status Matches"
	prevent_bleed.status = BleedStatus
	immunity.effects.append(prevent_bleed)
	immune.current_passive = immunity
	var immunity_context = _context([immune], log)
	assert(not StatusResolverScript.apply_status(log, root_log_id, immune, BleedStatus, "test", 3, false, immunity_context), "A passive should be able to prevent a requested status application.")
	immune.add_status(BurningStatus, "test", 3, false)
	var preserve_burning := _effect("Status Removal Requested", "Prevent Request", "Self")
	preserve_burning.condition = "Requested Status Matches"
	preserve_burning.status = BurningStatus
	immunity.effects.append(preserve_burning)
	assert(not StatusResolverScript.remove_status(log, root_log_id, immune, BurningStatus.display_name, "test dispel", immunity_context), "A passive should be able to prevent removal of one requested status type.")
	assert(immune.has_status("Burning"), "Specific status-removal immunity should preserve the matched status.")
	var invulnerable = _unit("Invulnerable", "Allies")
	var invulnerability := PassiveDefinition.new()
	invulnerability.display_name = "Untouchable"
	invulnerability.effects.append(_effect("Damage Requested", "Prevent Request", "Self"))
	invulnerability.effects.append(_effect("Healing Requested", "Prevent Request", "Self"))
	invulnerable.current_passive = invulnerability
	var invulnerability_context = _context([invulnerable, enemy], log)
	invulnerability_context.apply_direct_damage(enemy, invulnerable, 5, -1, root_log_id)
	assert(invulnerable.hp == invulnerable.max_hp, "Request interception should support damage requests as well as status immunity.")
	invulnerable.hp = 10
	invulnerability_context.apply_healing(invulnerable, invulnerable, 5, -1, root_log_id)
	assert(invulnerable.hp == 10, "Request interception should support healing requests.")
	var reaction_blocked = _unit("Reaction Blocked", "Allies")
	var block_reactions := PassiveDefinition.new()
	block_reactions.display_name = "Unresponsive"
	block_reactions.effects.append(_effect("Reaction Requested", "Prevent Request", "Self"))
	reaction_blocked.current_passive = block_reactions
	var blocked_reaction := ReactionDefinition.new()
	blocked_reaction.display_name = "Blocked Guard"
	blocked_reaction.reaction_type = "Gain Armor"
	blocked_reaction.amount = 3
	reaction_blocked.current_reaction = blocked_reaction
	var reaction_block_context = _context([reaction_blocked, enemy], log)
	reaction_block_context.apply_direct_damage(enemy, reaction_blocked, 1, -1, root_log_id)
	assert(reaction_blocked.guard_armor == 0, "Request interception should support reaction requests.")

	var zero_formula = _unit("Zero Formula", "Allies")
	var zero_item := ItemDefinition.new()
	zero_item.display_name = "Empty Cinder"
	var zero_burn := _effect("Battle Start", "Apply Status", "Self", 0, BurningStatus)
	zero_burn.amount_source = "Target Counter"
	zero_burn.counter_name = "missing_counter"
	zero_item.effects.append(zero_burn)
	zero_formula.equipped_items.append(zero_item)
	var zero_context = _context([zero_formula], log)
	zero_context.publish("battle_started", null, null, {}, -1, root_log_id)
	assert(not zero_formula.has_status("Burning"), "A derived zero-stack application should be a true no-op.")

	var escalating = _unit("Escalating", "Allies")
	var escalation_item := ItemDefinition.new()
	escalation_item.display_name = "Cinder Plate"
	var count_hits := _effect("Damaged", "Modify Counter", "Self", 1)
	count_hits.counter_name = "cinder_hits"
	escalation_item.effects.append(count_hits)
	var escalating_burn := _effect("Damaged", "Apply Status", "Self", 0, BurningStatus)
	escalating_burn.amount_source = "Target Counter"
	escalating_burn.counter_name = "cinder_hits"
	escalation_item.effects.append(escalating_burn)
	var stacking_armor := _effect("Damaged", "Modify Stat", "Self", 1)
	stacking_armor.modified_stat = "Armor"
	stacking_armor.modifier_duration_turns = 99
	escalation_item.effects.append(stacking_armor)
	escalating.equipped_items.append(escalation_item)
	var escalation_context = _context([escalating], log)
	escalation_context.publish("damage_dealt", enemy, escalating, {"amount": 1}, -1, root_log_id)
	escalation_context.publish("damage_dealt", enemy, escalating, {"amount": 1}, -1, root_log_id)
	assert(escalating.status_stack_count("Burning") == 3 and escalating.armor == 2, "Counters should author escalating status stacks alongside stacking temporary stats.")
	var threshold_unit = _unit("Threshold Unit", "Allies")
	threshold_unit.hp = 10
	var threshold_item := ItemDefinition.new()
	threshold_item.display_name = "Second Wind Counter"
	var count_damage := _effect("Damaged", "Modify Counter", "Self", 1)
	count_damage.counter_name = "hits_taken"
	threshold_item.effects.append(count_damage)
	var threshold_heal := _effect("Damaged", "Heal", "Self", 2)
	threshold_heal.condition = "Owner Counter At Least"
	threshold_heal.counter_name = "hits_taken"
	threshold_heal.counter_threshold = 2
	threshold_item.effects.append(threshold_heal)
	threshold_unit.equipped_items.append(threshold_item)
	var threshold_context = _context([threshold_unit, enemy], log)
	threshold_context.apply_direct_damage(enemy, threshold_unit, 1, -1, root_log_id)
	assert(threshold_unit.hp == 9, "Counter-threshold effects should remain gated below their threshold.")
	threshold_context.apply_direct_damage(enemy, threshold_unit, 1, -1, root_log_id)
	assert(threshold_unit.hp == 10, "Counter-threshold conditions should unlock effects at the authored threshold.")

	var reactor = _unit("Reactor", "Allies")
	reactor.hp = 10
	for _stack in range(4):
		reactor.add_status(BurningStatus, "test", 3, false)
	var conversion := ReactionDefinition.new()
	conversion.display_name = "Cauterize"
	conversion.reaction_type = "Effects Only"
	conversion.condition = "Self Status Stacks At Least"
	conversion.status = BurningStatus
	conversion.status_stack_threshold = 4
	var convert_heal := _effect("Reaction Triggered", "Heal", "Self")
	convert_heal.amount_source = "Target Pending Status Damage"
	convert_heal.status = BurningStatus
	conversion.effects.append(convert_heal)
	var consume_burn := _effect("Reaction Triggered", "Consume Status", "Self")
	consume_burn.amount_source = "Target Status Stacks"
	consume_burn.status = BurningStatus
	conversion.effects.append(consume_burn)
	reactor.current_reaction = conversion
	var reaction_context = _context([reactor, enemy], log)
	reaction_context.apply_direct_damage(enemy, reactor, 1, -1, root_log_id)
	assert(reactor.hp == 13 and not reactor.has_status("Burning"), "A reaction should convert qualifying burning into proportional healing and consume it.")
	assert(reaction_context.events_of_type("status_removed").size() == 1, "Consuming a final status stack should emit the general status-removed hook.")

	var uncapped_burn = _unit("Uncapped Burn", "Enemies")
	var uncapped_context = _context([uncapped_burn], log)
	assert(StatusResolverScript.apply_status(log, root_log_id, uncapped_burn, BurningStatus, "bulk test", 3, false, uncapped_context, null, -1, 120), "Bulk status application should support large uncapped applications.")
	assert(uncapped_burn.status_stack_count("Burning") == 120, "Burning should not have a runtime stack cap.")

	var pyromancer = _unit("Pyromancer", "Allies")
	var pyromancer_passive := PassiveDefinition.new()
	pyromancer_passive.display_name = "Living Flame"
	var burn_immunity := _effect("Status Application Requested", "Prevent Request", "Self")
	burn_immunity.condition = "Requested Status Matches"
	burn_immunity.status = BurningStatus
	pyromancer_passive.effects.append(burn_immunity)
	pyromancer_passive.effects.append(_effect("Battle Start", "Apply Status", "All Units", 0, BurningStatus))
	pyromancer_passive.effects.append(_effect("Action Completed", "Apply Status", "All Units", 0, BurningStatus))
	pyromancer.current_passive = pyromancer_passive
	var pyromancer_reaction := ReactionDefinition.new()
	pyromancer_reaction.display_name = "Feed the Flame"
	pyromancer_reaction.trigger = "Status Application Requested"
	pyromancer_reaction.condition = "Requested Status Is Ailment"
	pyromancer_reaction.reaction_type = "Effects Only"
	pyromancer_reaction.prevents_triggering_request = true
	pyromancer_reaction.cooldown_turns = 5
	var double_burn := _effect("Reaction Triggered", "Apply Status", "Event Target", 0, BurningStatus)
	double_burn.amount_source = "Target Status Stacks"
	pyromancer_reaction.effects.append(double_burn)
	pyromancer.current_reaction = pyromancer_reaction
	var unburned_applier = _unit("Unburned Applier", "Enemies")
	var pyromancer_context = _context([pyromancer, unburned_applier], log)
	assert(not StatusResolverScript.apply_status(log, root_log_id, pyromancer, RotStatus, "test", 3, false, pyromancer_context, unburned_applier), "An incoming-ailment reaction should replace and prevent the requested ailment.")
	assert(not unburned_applier.has_status("Burning"), "Doubling zero Burn should remain a legible no-op while still preventing the ailment.")
	for _turn in range(5):
		pyromancer.tick_ability_cooldowns()
	StatusResolverScript.apply_status(log, root_log_id, unburned_applier, BurningStatus, "test", 3, false, pyromancer_context, pyromancer)
	StatusResolverScript.apply_status(log, root_log_id, unburned_applier, BurningStatus, "test", 3, false, pyromancer_context, pyromancer)
	assert(not StatusResolverScript.apply_status(log, root_log_id, pyromancer, RotStatus, "test", 3, false, pyromancer_context, unburned_applier), "A ready incoming-ailment reaction should prevent another ailment.")
	assert(unburned_applier.status_stack_count("Burning") == 4, "A reaction effect should be able to double the attempted applier's existing Burn.")
	assert(StatusResolverScript.apply_status(log, root_log_id, pyromancer, BleedStatus, "test", 3, false, pyromancer_context, unburned_applier), "The reaction cooldown should allow a later ailment through.")
	assert(not StatusResolverScript.apply_status(log, root_log_id, pyromancer, BurningStatus, "test", 3, false, pyromancer_context, unburned_applier), "Burn immunity should remain authorable independently of the reaction.")
	var passive_target = _unit("Passive Target", "Enemies")
	var passive_context = _context([pyromancer, passive_target], log)
	passive_context.publish("battle_started", null, null, {}, -1, root_log_id)
	assert(not pyromancer.has_status("Burning") and passive_target.status_stack_count("Burning") == 1, "A passive should author Burn immunity plus battle-start Burn for all units.")
	passive_context.publish("action_completed", pyromancer, passive_target, {}, -1, root_log_id)
	assert(not pyromancer.has_status("Burning") and passive_target.status_stack_count("Burning") == 2, "Action Completed should be available as an authored shared-effect trigger.")
	var observer = _unit("Ailment Observer", "Allies")
	var observing_reaction := ReactionDefinition.new()
	observing_reaction.display_name = "Learn From Pain"
	observing_reaction.trigger = "Status Application Requested"
	observing_reaction.condition = "Requested Status Is Ailment"
	observing_reaction.reaction_type = "Gain Armor"
	observing_reaction.amount = 1
	observer.current_reaction = observing_reaction
	var observing_context = _context([observer, unburned_applier], log)
	assert(StatusResolverScript.apply_status(log, root_log_id, observer, RotStatus, "test", 3, false, observing_context, unburned_applier), "A status-application reaction should observe without preventing by default.")
	assert(observer.has_status("Rot") and observer.guard_armor == 1, "An observational reaction should respond while allowing the incoming ailment.")

	var cryomancer = _unit("Cryomancer", "Allies")
	var frostbite := SkillDefinition.new()
	frostbite.display_name = "Frostbite"
	frostbite.action = "Effects Only"
	frostbite.effects.append(_effect("Skill Used", "Apply Status", "Event Target", 0, FrostStatus))
	frostbite.effects.append(_effect("Skill Used", "Apply Status", "Event Target", 0, NumbStatus))
	cryomancer.current_skill = frostbite
	var cold_snap := ReactionDefinition.new()
	cold_snap.display_name = "Cold Snap"
	cold_snap.trigger = "Physically Damaged"
	cold_snap.reaction_type = "Effects Only"
	cold_snap.cooldown_turns = 2
	var retaliatory_frost := _effect("Reaction Triggered", "Apply Status", "Event Target", 0, FrostStatus)
	retaliatory_frost.status_stacks = 2
	cold_snap.effects.append(retaliatory_frost)
	cryomancer.current_reaction = cold_snap
	var gathering_cold := PassiveDefinition.new()
	gathering_cold.display_name = "Gathering Cold"
	var frost_slow := _effect("Battle State Changed", "Modify Stat", "Enemy Units", 0, FrostStatus)
	frost_slow.modified_stat = "Action Interval"
	frost_slow.modifier_mode = "Dynamic Percent"
	frost_slow.amount_source = "Total Status Stacks On Selected Group"
	frost_slow.amount_target_selector = "Enemy Units"
	frost_slow.amount_multiplier = 10
	gathering_cold.effects.append(frost_slow)
	cryomancer.current_passive = gathering_cold
	var cold_enemy = _unit("Cold Enemy", "Enemies")
	var colder_enemy = _unit("Colder Enemy", "Enemies")
	colder_enemy.action_interval = 20
	var cryomancer_context = _context([cryomancer, cold_enemy, colder_enemy], log)
	cryomancer_context.publish("skill_used", cryomancer, cold_enemy, {"skill": frostbite.display_name}, -1, root_log_id)
	assert(cold_enemy.has_status("Frost") and cold_enemy.has_status("Numb"), "An effect-only skill should author Frost and Numb together.")
	assert(cold_enemy.action_interval == 11 and colder_enemy.action_interval == 22, "A dynamic percentage modifier should slow all enemies from aggregate enemy Frost.")
	cryomancer_context.publish("damage_dealt", colder_enemy, cryomancer, {"amount": 1, "physical_amount": 1, "magic_amount": 0}, -1, root_log_id)
	assert(colder_enemy.status_stack_count("Frost") == 2, "A Physically Damaged reaction should apply its authored effects to the damage source.")
	assert(cold_enemy.action_interval == 13 and colder_enemy.action_interval == 26, "Dynamic modifiers should replace their prior contribution when aggregate Frost changes.")
	cryomancer_context.publish("damage_dealt", cold_enemy, cryomancer, {"amount": 1, "physical_amount": 0, "magic_amount": 1}, -1, root_log_id)
	assert(cold_enemy.status_stack_count("Frost") == 1, "A Physically Damaged reaction should ignore magical damage.")

	var enthalpyst = _unit("Enthalpyst", "Allies")
	var thermal_shock := SkillDefinition.new()
	thermal_shock.display_name = "Thermal Shock"
	thermal_shock.action = "Effects Only"
	thermal_shock.effects.append(_effect("Skill Used", "Apply Status", "Event Target", 0, FrostStatus))
	thermal_shock.effects.append(_effect("Skill Used", "Apply Status", "Event Target", 0, BurningStatus))
	enthalpyst.current_skill = thermal_shock
	var thermal_exchange := PassiveDefinition.new()
	thermal_exchange.display_name = "Thermal Exchange"
	var burn_to_frost := _effect("Enemy Status Applied", "Apply Status", "Event Target", 0, FrostStatus)
	burn_to_frost.condition = "Applied Status Matches"
	burn_to_frost.condition_status = BurningStatus
	burn_to_frost.amount_source = "Applied Status Stacks"
	burn_to_frost.ignore_events_from_same_effect_source = true
	thermal_exchange.effects.append(burn_to_frost)
	var frost_to_burn := _effect("Enemy Status Applied", "Apply Status", "Event Target", 0, BurningStatus)
	frost_to_burn.condition = "Applied Status Matches"
	frost_to_burn.condition_status = FrostStatus
	frost_to_burn.amount_source = "Applied Status Stacks"
	frost_to_burn.ignore_events_from_same_effect_source = true
	thermal_exchange.effects.append(frost_to_burn)
	enthalpyst.current_passive = thermal_exchange
	var critical_enthalpy := ReactionDefinition.new()
	critical_enthalpy.display_name = "Critical Enthalpy"
	critical_enthalpy.trigger = "Enemy Status Threshold Reached"
	critical_enthalpy.reaction_type = "Effects Only"
	critical_enthalpy.status = FrostStatus
	critical_enthalpy.status_stack_threshold = 10
	critical_enthalpy.cooldown_turns = 5
	var absorb_frost := _effect("Reaction Triggered", "Apply Status", "Self", 0, BurningStatus)
	absorb_frost.amount_source = "Event Target Status Stacks"
	absorb_frost.amount_status = FrostStatus
	critical_enthalpy.effects.append(absorb_frost)
	var thermal_strike := _effect("Reaction Triggered", "Deal Damage", "Event Target", 4)
	thermal_strike.damage_type = "Physical"
	critical_enthalpy.effects.append(thermal_strike)
	enthalpyst.current_reaction = critical_enthalpy
	var thermal_target = _unit("Thermal Target", "Enemies")
	thermal_target.armor = 2
	var enthalpyst_context = _context([enthalpyst, thermal_target], log)
	StatusResolverScript.apply_status(log, root_log_id, thermal_target, FrostStatus, "external frost", 3, false, enthalpyst_context, null, -1, 3)
	assert(thermal_target.status_stack_count("Frost") == 3 and thermal_target.status_stack_count("Burning") == 3, "Thermal Exchange should mirror newly gained Frost into equal Burn without triggering itself.")
	StatusResolverScript.apply_status(log, root_log_id, thermal_target, FrostStatus, "setup", 3, false, null, null, -1, 5)
	enthalpyst_context.publish("skill_used", enthalpyst, thermal_target, {"skill": thermal_shock.display_name}, -1, root_log_id)
	assert(enthalpyst.status_stack_count("Burning") == 10, "An enemy threshold reaction should gain Burn equal to the Frost consumed by its physical attack.")
	assert(not thermal_target.has_status("Frost"), "The reaction's physical damage should consume the enemy's Frost through the existing Frost rule.")
	assert(thermal_target.status_stack_count("Burning") == 5, "Thermal Shock and Thermal Exchange should add matching Burn and Frost without recursive exchange.")
	assert(thermal_target.hp == 14, "Authored physical damage should pass through armor, then Frost amplification, before consuming Frost.")

	var mirror_owner = _unit("Mirror Owner", "Allies")
	var mirror_source = _unit("Mirror Source", "Enemies")
	var mirror_passive := PassiveDefinition.new()
	mirror_passive.display_name = "External Mirror"
	var mirror_burning := _effect("Externally Sourced Status Applied", "Apply Status", "Event Source", 0, BurningStatus)
	mirror_burning.condition = "Applied Status Matches"
	mirror_burning.condition_status = BurningStatus
	mirror_burning.amount_source = "Applied Status Stacks"
	mirror_passive.effects.append(mirror_burning)
	mirror_owner.current_passive = mirror_passive
	var mirror_context = _context([mirror_owner, mirror_source], log)
	StatusResolverScript.apply_status(log, root_log_id, mirror_owner, BurningStatus, "external", 3, false, mirror_context, mirror_source, -1, 2)
	assert(mirror_source.status_stack_count("Burning") == 2, "Externally sourced status triggers should combine with status matching and mirror added stacks.")
	StatusResolverScript.apply_status(log, root_log_id, mirror_owner, BurningStatus, "self", 3, false, mirror_context, mirror_owner)
	assert(mirror_source.status_stack_count("Burning") == 2, "Externally sourced status triggers should ignore statuses applied by the owner.")

	var paladin = _unit("Paladin", "Allies")
	paladin.physical_damage = 9
	var smite := SkillDefinition.new()
	smite.display_name = "Smite"
	smite.action = "Attack"
	smite.attack_damage_type = "Split Evenly"
	paladin.current_skill = smite
	var smite_target = _unit("Smite Target", "Enemies")
	smite_target.armor = 2
	var paladin_log = CombatLogScript.new()
	var paladin_root: int = paladin_log.add("Paladin authorability")
	var smite_context = _context([paladin, smite_target], paladin_log)
	CombatSimulatorScript.new()._resolve_skill(smite_context, paladin_log, paladin_root, paladin, smite_target, smite, "job skill")
	assert(smite_target.hp == 13, "A split attack should divide physical base damage evenly, apply armor only to its physical component, and remain one attack.")
	var purification := ReactionDefinition.new()
	purification.display_name = "Purifying Light"
	purification.trigger = "Status Application Requested"
	purification.condition = "Requested Status Matches"
	purification.status = BurningStatus
	purification.reaction_type = "Effects Only"
	purification.prevents_triggering_request = true
	purification.replacement_statuses.append(WardStatus)
	purification.replacement_statuses.append(RenewalStatus)
	paladin.current_reaction = purification
	assert(not StatusResolverScript.apply_status(paladin_log, paladin_root, paladin, BurningStatus, "test", 3, false, smite_context, smite_target), "A replacement reaction should prevent its selected incoming ailment.")
	assert(not paladin.has_status("Burning") and (paladin.has_status("Ward") or paladin.has_status("Renewal")), "A replacement reaction should atomically grant one deterministic random boon.")
	var ally_aura = _unit("Aura Ally", "Allies")
	var independently_mended = _unit("Independently Mended", "Allies")
	var aura := PassiveDefinition.new()
	aura.display_name = "Aura of Mending"
	var maintain_reconstitution := _effect("Battle State Changed", "Maintain Status Aura", "Allied Units", 0, ReconstitutionStatus)
	aura.effects.append(maintain_reconstitution)
	paladin.current_passive = aura
	var aura_context = _context([paladin, ally_aura, independently_mended, smite_target], paladin_log)
	aura_context.publish("battle_started", null, null, {}, -1, paladin_root)
	assert(paladin.has_status("Reconstitution") and ally_aura.has_status("Reconstitution") and not smite_target.has_status("Reconstitution"), "A maintained aura should grant its status to all living allies.")
	StatusResolverScript.remove_status(paladin_log, paladin_root, ally_aura, ReconstitutionStatus.display_name, "test dispel", aura_context, smite_target)
	assert(ally_aura.has_status("Reconstitution"), "A maintained aura should restore its status after removal while its source remains alive.")
	independently_mended.add_status(ReconstitutionStatus, "independent source", 3, false)
	aura_context.apply_direct_damage(smite_target, paladin, paladin.hp, -1, paladin_root)
	assert(not ally_aura.has_status("Reconstitution"), "A maintained aura should remove its contribution when its source dies.")
	assert(independently_mended.has_status("Reconstitution"), "Removing an aura contribution should preserve an independently gained copy of the same status.")

	var detonator = _unit("Detonator", "Allies")
	var burn_target = _unit("Burn Target", "Enemies")
	burn_target.hp = 3
	for _stack in range(3):
		burn_target.add_status(BurningStatus, "test", 3, false)
	var detonate_skill := SkillDefinition.new()
	detonate_skill.display_name = "Flashpoint"
	detonate_skill.action = "Effects Only"
	detonate_skill.effects.append(_effect("Skill Used", "Detonate Status", "Event Target", 0, BurningStatus))
	detonator.current_skill = detonate_skill
	var detonate_tactic := TacticDefinition.new()
	detonate_tactic.condition = "Target Pending Status Damage At Least HP"
	detonate_tactic.action = "Job Skill"
	detonate_tactic.target = "Frontmost Enemy"
	detonate_tactic.status = BurningStatus
	assert(TacticResolverScript.condition_matches(detonate_tactic.condition, detonator, [detonator, burn_target], burn_target, detonate_tactic), "Tactics should compare pending status damage with target HP.")
	var detonation_context = _context([detonator, burn_target], log)
	detonation_context.publish("skill_used", detonator, burn_target, {"skill": detonate_skill.display_name}, -1, root_log_id)
	assert(burn_target.hp == 0 and not burn_target.has_status("Burning"), "Detonation should deal all pending status damage and consume the status.")

	var overhealer = _unit("Overhealer", "Allies")
	var growth := PassiveDefinition.new()
	growth.display_name = "Overflowing Vitality"
	var grow_max_hp := _effect("Healing Received", "Modify Stat", "Self")
	grow_max_hp.modified_stat = "Max HP"
	grow_max_hp.modifier_duration_turns = 99
	grow_max_hp.amount_source = "Overhealing Diminishing"
	grow_max_hp.counter_name = "overflow_growth"
	growth.effects.append(grow_max_hp)
	var count_growth := _effect("Healing Received", "Modify Counter", "Self", 1)
	count_growth.counter_name = "overflow_growth"
	growth.effects.append(count_growth)
	overhealer.current_passive = growth
	var growth_context = _context([overhealer], log)
	growth_context.apply_healing(overhealer, overhealer, 6, -1, root_log_id)
	overhealer.hp = overhealer.max_hp
	growth_context.apply_healing(overhealer, overhealer, 6, -1, root_log_id)
	assert(overhealer.max_hp == 29, "Overhealing should be able to grant diminishing temporary max HP through a named counter.")

	var bog_priest = _unit("Bog Priest", "Allies")
	var bog_ally = _unit("Bog Ally", "Allies")
	bog_ally.max_hp = 40
	bog_ally.hp = 10
	var bog_skill := SkillDefinition.new()
	bog_skill.display_name = "Mire Mending"
	bog_skill.action = "Effects Only"
	var proportional_heal := _effect("Skill Used", "Heal", "Event Target")
	proportional_heal.amount_source = "Target Max HP"
	proportional_heal.amount_divisor = 4
	bog_skill.effects.append(proportional_heal)
	bog_priest.current_skill = bog_skill
	var bog_skill_context = _context([bog_priest, bog_ally], log)
	bog_skill_context.publish("skill_used", bog_priest, bog_ally, {"skill": bog_skill.display_name}, -1, root_log_id)
	assert(bog_ally.hp == 20, "Target Max HP should support proportional authored healing.")

	var enemy_healer = _unit("Enemy Healer", "Enemies")
	var rotted_enemy = _unit("Rotted Enemy", "Enemies")
	rotted_enemy.hp = 10
	var corrupt_healing := ReactionDefinition.new()
	corrupt_healing.display_name = "Bog Intercession"
	corrupt_healing.trigger = "Enemy Healing Requested"
	corrupt_healing.reaction_type = "Effects Only"
	corrupt_healing.prevents_triggering_request = true
	corrupt_healing.cooldown_turns = 3
	corrupt_healing.effects.append(_effect("Reaction Triggered", "Apply Status", "Event Target", 0, RotStatus))
	corrupt_healing.effects.append(_effect("Reaction Triggered", "Heal", "Event Target", 1))
	bog_priest.current_reaction = corrupt_healing
	var corrupt_context = _context([bog_priest, enemy_healer, rotted_enemy], log)
	corrupt_context.apply_healing(enemy_healer, rotted_enemy, 8, -1, root_log_id)
	assert(rotted_enemy.hp == 11 and rotted_enemy.has_status("Rot"), "Enemy healing reactions should replace the original heal with authored effects.")
	corrupt_context.apply_healing(enemy_healer, rotted_enemy, 8, -1, root_log_id)
	assert(rotted_enemy.hp == 18, "Enemy healing reactions should respect their authored cooldown and allow normal healing while cooling down.")

	bog_priest.current_reaction = null
	bog_priest.hp = bog_priest.max_hp - 4
	bog_ally.hp = bog_ally.max_hp - 1
	var overflow := PassiveDefinition.new()
	overflow.display_name = "Overflowing Mire"
	var redistribute := _effect("Ally Overhealed", "Heal", "Random Damaged Allied Unit")
	redistribute.amount_source = "Overhealing"
	overflow.effects.append(redistribute)
	overflow.effects.append(_effect("Ally Overhealed", "Apply Status", "Event Target", 0, RotStatus))
	bog_priest.current_passive = overflow
	var overflow_context = _context([bog_priest, bog_ally], log)
	overflow_context.apply_healing(bog_priest, bog_ally, 6, -1, root_log_id)
	assert(bog_priest.hp == bog_priest.max_hp and bog_ally.has_status("Rot"), "Ally overhealing should redistribute to a damaged allied unit, including the owner, and apply Rot to the original target.")
	assert(overflow_context.events_of_type("healing_received").size() == 2, "Redistributed overhealing should not recursively trigger itself.")

	var bridge_actor = _unit("Bridge Actor", "Allies")
	var bridge_ally = _unit("Bridge Ally", "Allies")
	bridge_ally.action_interval = 20
	StatusResolverScript.apply_status(log, root_log_id, bridge_ally, RotStatus, "test", 3, false)
	StatusResolverScript.apply_status(log, root_log_id, bridge_ally, BurningStatus, "test", 3, false, null, null, -1, 3)
	var haste_skill := SkillDefinition.new()
	haste_skill.display_name = "Hot on Their Heels"
	haste_skill.action = "Effects Only"
	var ailment_haste := _effect("Skill Used", "Modify Stat", "Event Target")
	ailment_haste.modified_stat = "Action Interval"
	ailment_haste.modifier_direction = "Decrease"
	ailment_haste.modifier_duration_turns = 2
	ailment_haste.amount_source = "Target Ailment Stacks"
	haste_skill.effects.append(ailment_haste)
	bridge_actor.current_skill = haste_skill
	var haste_context = _context([bridge_actor, bridge_ally], log)
	haste_context.publish("skill_used", bridge_actor, bridge_ally, {"skill": haste_skill.display_name}, -1, root_log_id)
	assert(bridge_ally.action_interval == 16, "Ailment-stack formulas should count one Rot and three Burning stacks, and temporary modifiers should support authored decreases.")

	var barrier_target = _unit("Barrier Target", "Allies")
	barrier_target.add_status(ReconstitutionStatus, "test", 3, false)
	barrier_target.add_status(RenewalStatus, "test", 3, false)
	barrier_target.add_status(RenewalStatus, "test", 3, false)
	var barrier_skill := SkillDefinition.new()
	barrier_skill.display_name = "Spiritual Barrier"
	barrier_skill.action = "Effects Only"
	var boon_armor := _effect("Skill Used", "Grant Armor", "Event Target")
	boon_armor.amount_source = "Target Unique Boons"
	boon_armor.once_per_battle = true
	barrier_skill.effects.append(boon_armor)
	bridge_actor.current_skill = barrier_skill
	var barrier_context = _context([bridge_actor, barrier_target], log)
	barrier_context.publish("skill_used", bridge_actor, barrier_target, {"skill": barrier_skill.display_name}, -1, root_log_id)
	barrier_context.publish("skill_used", bridge_actor, barrier_target, {"skill": barrier_skill.display_name}, -1, root_log_id)
	assert(barrier_target.guard_armor == 2, "Unique-boon formulas should ignore repeated stacks and once-per-battle armor effects should not fire twice.")

	var chimney_target = _unit("Chimney Target", "Enemies")
	var chimney_other = _unit("Chimney Other", "Enemies")
	chimney_target.add_status(BurningStatus, "test", 3, false)
	chimney_other.add_status(BurningStatus, "test", 3, false)
	chimney_other.add_status(BurningStatus, "test", 3, false)
	var chimney_skill := SkillDefinition.new()
	chimney_skill.display_name = "Chimney Effect"
	chimney_skill.action = "Effects Only"
	var gather_burning := _effect("Skill Used", "Gather Status", "Event Target", 0, BurningStatus)
	gather_burning.amount_target_selector = "Enemy Units"
	chimney_skill.effects.append(gather_burning)
	bridge_actor.current_skill = chimney_skill
	var chimney_context = _context([bridge_actor, chimney_target, chimney_other], log)
	chimney_context.publish("skill_used", bridge_actor, chimney_target, {"skill": chimney_skill.display_name}, -1, root_log_id)
	assert(chimney_target.status_stack_count("Burning") == 3 and not chimney_other.has_status("Burning"), "Gather Status should preserve total stacks while concentrating a status onto the selected target.")

	var harvest_ally = _unit("Harvest Ally", "Allies")
	harvest_ally.hp = 10
	var rotted_one = _unit("Rotted One", "Enemies")
	var rotted_two = _unit("Rotted Two", "Enemies")
	rotted_one.hp = 10
	rotted_two.hp = 10
	rotted_one.add_status(RotStatus, "test", 3, false)
	rotted_two.add_status(RotStatus, "test", 3, false)
	rotted_two.add_status(RotStatus, "test", 3, false)
	var harvest_context = _context([bridge_actor, harvest_ally, rotted_one, rotted_two], log)
	harvest_context.apply_healing(rotted_one, rotted_one, 1, -1, root_log_id)
	harvest_context.apply_healing(rotted_two, rotted_two, 1, -1, root_log_id)
	var harvest_skill := SkillDefinition.new()
	harvest_skill.display_name = "Bog Harvest"
	harvest_skill.action = "Effects Only"
	var harvest_heal := _effect("Skill Used", "Heal", "Allied Units", 0, RotStatus)
	harvest_heal.amount_source = "Total Status Max HP Loss On Selected Group"
	harvest_heal.amount_target_selector = "Enemy Units"
	harvest_skill.effects.append(harvest_heal)
	var restore_rot := _effect("Skill Used", "Restore Max HP Lost To Status", "Enemy Units", 0, RotStatus)
	harvest_skill.effects.append(restore_rot)
	bridge_actor.current_skill = harvest_skill
	var rotted_one_reduced_max: int = rotted_one.max_hp
	var rotted_two_reduced_max: int = rotted_two.max_hp
	harvest_context.publish("skill_used", bridge_actor, harvest_ally, {"skill": harvest_skill.display_name}, -1, root_log_id)
	assert(harvest_ally.hp == 13, "Bog Harvest should heal each ally by the total maximum HP previously lost to enemy Rot.")
	assert(rotted_one.max_hp == rotted_one_reduced_max + 1 and rotted_two.max_hp == rotted_two_reduced_max + 2, "Removing Rot through restoration should return all maximum HP recorded by Rot.")
	assert(rotted_one.hp == 11 and rotted_two.hp == 11 and not rotted_one.has_status("Rot") and not rotted_two.has_status("Rot"), "Restored maximum HP should remain empty and Rot should be removed.")

	var barrier_owner = _unit("Barrier Owner", "Allies")
	var barrier_ally = _unit("Barrier Ally", "Allies")
	var battle_barrier := PassiveDefinition.new()
	battle_barrier.display_name = "Battle Barrier"
	battle_barrier.effects.append(_effect("Battle Start", "Grant Battle Armor", "Allied Units", 4))
	barrier_owner.current_passive = battle_barrier
	var battle_barrier_context = _context([barrier_owner, barrier_ally], log)
	battle_barrier_context.publish("battle_started", null, null, {}, -1, root_log_id)
	assert(barrier_owner.battle_armor == 4 and barrier_ally.battle_armor == 4 and barrier_ally.total_armor() == 4, "Battle armor should be a battle-local armor contribution granted to selected targets.")
	battle_barrier_context.publish("turn_started", barrier_ally, barrier_ally, {}, -1, root_log_id)
	assert(barrier_ally.battle_armor == 4, "Battle armor should not expire at the target's next turn.")

	var bruiser = _unit("Bruiser", "Allies")
	bruiser.action_interval = 10
	bruiser.base_action_interval = 10
	bruiser.next_action_time = 20
	var rapid_attacker = _unit("Rapid Attacker", "Enemies")
	rapid_attacker.next_action_time = 5
	var momentum := PassiveDefinition.new()
	momentum.display_name = "Punishing Momentum"
	var physical_haste := _effect("Physically Damaged", "Hasten Action", "Self", 2)
	physical_haste.modifier_duration_turns = 3
	physical_haste.threshold_percent = 50
	physical_haste.repeat_within_event_chain = true
	momentum.effects.append(physical_haste)
	bruiser.current_passive = momentum
	var momentum_context = _context([bruiser, rapid_attacker], log)
	var rapid_root: int = momentum_context.publish("attack_performed", rapid_attacker, bruiser, {}, -1, root_log_id)
	for _hit in range(4):
		momentum_context.publish("damage_dealt", rapid_attacker, bruiser, {"amount": 1, "physical_amount": 1, "magic_amount": 0}, rapid_root, root_log_id)
	assert(bruiser.action_interval == 5 and bruiser.next_action_time == 15, "Repeated physical hits should immediately hasten the next action and stack only to half the finalized baseline interval.")
	for _action in range(3):
		momentum_context.publish("turn_completed", bruiser, bruiser, {}, -1, root_log_id)
	assert(bruiser.action_interval == 10, "Capped action haste should expire after the authored number of completed actions.")

	var protected_ally = _unit("Protected Ally", "Allies")
	var interceptor = _unit("Interceptor", "Allies")
	var enemy_attacker = _unit("Enemy Attacker", "Enemies")
	var intercept := ReactionDefinition.new()
	intercept.display_name = "Take the Hit"
	intercept.trigger = "Attack Targets Another Ally"
	intercept.reaction_type = "Effects Only"
	intercept.cooldown_turns = 4
	interceptor.current_reaction = intercept
	var intercept_context = _context([protected_ally, interceptor, enemy_attacker], log)
	var target_request: Dictionary = intercept_context.request("attack_target_requested", enemy_attacker, protected_ally, {"target_unit_id": protected_ally.unit_id}, -1, root_log_id, ["attack", "target", "request"])
	assert(target_request["payload"].get("target_unit_id", "") == interceptor.unit_id, "Attack-target reactions should redirect attacks aimed at another allied unit before resolution.")
	var self_target_request: Dictionary = intercept_context.request("attack_target_requested", enemy_attacker, interceptor, {"target_unit_id": interceptor.unit_id}, -1, root_log_id, ["attack", "target", "request"])
	assert(self_target_request["payload"].get("target_unit_id", "") == interceptor.unit_id, "Attack-target reactions should not consume themselves when the interceptor was already targeted.")

	var double_striker = _unit("Double Striker", "Allies")
	var stun_target = _unit("Stun Target", "Enemies")
	stun_target.hp = 30
	stun_target.max_hp = 30
	stun_target.next_action_time = 20
	var double_strike := SkillDefinition.new()
	double_strike.display_name = "Stunning Combination"
	double_strike.action = "Attack"
	double_strike.attack_count = 2
	double_strike.effects.append(_effect("Skill Completed", "Delay Action", "Event Target", 3))
	double_striker.current_skill = double_strike
	var double_log = CombatLogScript.new()
	var double_context = _context([double_striker, stun_target], double_log)
	CombatSimulatorScript.new()._resolve_skill(double_context, double_log, double_log.add("Double strike"), double_striker, stun_target, double_strike, "job skill")
	assert(double_context.events_of_type("attack_performed").size() == 2 and stun_target.hp == 20, "Authored attack_count should perform two complete attacks against a surviving target.")
	assert(double_striker.attack_streak_count == 2, "Each complete attack in a multi-hit skill should advance the same-target attack streak.")
	assert(stun_target.next_action_time == 23, "Skill Completed effects should delay the target only after the repeated attacks resolve.")

	var high_hp_target = _unit("High HP Target", "Enemies")
	high_hp_target.hp = 17
	var bridge_damage := SkillDefinition.new()
	bridge_damage.display_name = "Crushing Opener"
	bridge_damage.action = "Effects Only"
	var remaining_hp_damage := _effect("Skill Used", "Deal Damage", "Event Target")
	remaining_hp_damage.damage_type = "Physical"
	remaining_hp_damage.amount_source = "Target Current HP"
	remaining_hp_damage.amount_divisor = 4
	bridge_damage.effects.append(remaining_hp_damage)
	double_striker.current_skill = bridge_damage
	var bridge_damage_context = _context([double_striker, high_hp_target], log)
	bridge_damage_context.publish("skill_used", double_striker, high_hp_target, {"skill": bridge_damage.display_name}, -1, root_log_id)
	assert(high_hp_target.hp == 13, "Target Current HP should support proportional remaining-HP damage.")

	var speed_caster = _unit("Speed Caster", "Allies")
	speed_caster.action_interval = 10
	var slow_target = _unit("Slow Target", "Enemies")
	slow_target.action_interval = 30
	var speed_skill := SkillDefinition.new()
	speed_skill.display_name = "Exploit Delay"
	speed_skill.action = "Effects Only"
	var speed_damage := _effect("Skill Used", "Deal Damage", "Event Target")
	speed_damage.amount_source = "Target Action Interval"
	speed_damage.amount_divisor = 10
	speed_skill.effects.append(speed_damage)
	speed_caster.current_skill = speed_skill
	var speed_tactic := TacticDefinition.new()
	speed_tactic.condition = "Target Slower Than Self"
	assert(TacticResolverScript.condition_matches(speed_tactic.condition, speed_caster, [speed_caster, slow_target], slow_target, speed_tactic), "Tactics should identify targets slower than the acting unit.")
	var speed_context = _context([speed_caster, slow_target], log)
	speed_context.publish("skill_used", speed_caster, slow_target, {"skill": speed_skill.display_name}, -1, root_log_id)
	assert(slow_target.hp == 17, "Effects should scale damage from the target's authored action interval.")

	var monk = _unit("Monk", "Allies")
	var fist_target = _unit("Fist Target", "Enemies")
	var fists := PassiveDefinition.new()
	fists.display_name = "Practiced Fists"
	var fist_damage := _effect("Attack", "Add Attack Damage", "Self", 3)
	fist_damage.condition = "Owner Is Unarmed"
	fists.effects.append(fist_damage)
	monk.current_passive = fists
	var fist_skill := SkillDefinition.new()
	fist_skill.display_name = "Open Palm"
	fist_skill.action = "Attack"
	monk.current_skill = fist_skill
	var fist_context = _context([monk, fist_target], log)
	CombatSimulatorScript.new()._resolve_skill(fist_context, log, root_log_id, monk, fist_target, fist_skill, "job skill")
	assert(fist_target.hp == 12, "Unarmed attack damage should join the complete attack before armor mitigation.")

	var wounded_ally = _unit("Wounded Ally", "Allies")
	wounded_ally.hp = 10
	var healthy_ally = _unit("Healthy Ally", "Allies")
	var balm := PassiveDefinition.new()
	balm.display_name = "Open Palm Balm"
	balm.effects.append(_effect("Attack", "Apply Status", "Lowest HP Allied Unit", 0, RegenerationStatus))
	monk.current_passive = balm
	var balm_context = _context([monk, wounded_ally, healthy_ally, fist_target], log)
	balm_context.publish("attack_performed", monk, fist_target, {}, -1, root_log_id, ["attack"])
	assert(wounded_ally.has_status("Regeneration"), "Lowest HP Allied Unit should include the owner team and deterministically select the lowest current HP.")
	StatusResolverScript.apply_turn_start_statuses(log, root_log_id, wounded_ally, balm_context)
	assert(wounded_ally.hp == 12, "Regeneration should heal at turn start through the normal healing pipeline.")

	wounded_ally.add_status(BleedStatus, "test", 2, false)
	healthy_ally.add_status(BurningStatus, "test", 3, false)
	var burden := PassiveDefinition.new()
	burden.display_name = "Bear the Burden"
	var transfer := _effect("Skill Used", "Transfer Statuses", "Self")
	transfer.status_polarity = "Ailment"
	transfer.amount_target_selector = "Allied Units"
	burden.effects.append(transfer)
	monk.current_passive = burden
	var transfer_context = _context([monk, wounded_ally, healthy_ally], log)
	transfer_context.publish("skill_used", monk, monk, {"skill": "Bear the Burden"}, -1, root_log_id)
	assert(monk.has_status("Bleed") and monk.has_status("Burning") and not wounded_ally.has_status("Bleed") and not healthy_ally.has_status("Burning"), "Transfer Statuses should preserve and move matching allied statuses to the selected recipient.")

	var meditation := ReactionDefinition.new()
	meditation.display_name = "Stillness"
	var count_actions := _effect("Action Completed", "Modify Counter", "Self", 1)
	count_actions.counter_name = "untouched_actions"
	meditation.effects.append(count_actions)
	var meditation_heal := _effect("Action Completed", "Heal", "Self")
	meditation_heal.condition = "Owner Counter At Least"
	meditation_heal.counter_name = "untouched_actions"
	meditation_heal.counter_threshold = 3
	meditation_heal.amount_source = "Target Max HP"
	meditation_heal.amount_divisor = 5
	meditation.effects.append(meditation_heal)
	var clear_meditation := _effect("Action Completed", "Reset Counter", "Self")
	clear_meditation.condition = "Owner Counter At Least"
	clear_meditation.counter_name = "untouched_actions"
	clear_meditation.counter_threshold = 3
	meditation.effects.append(clear_meditation)
	var break_meditation := _effect("Enemy Attack Targeted", "Reset Counter", "Self")
	break_meditation.counter_name = "untouched_actions"
	meditation.effects.append(break_meditation)
	var meditating_monk = _unit("Meditating Monk", "Allies")
	meditating_monk.current_reaction = meditation
	meditating_monk.hp = 10
	var meditation_context = _context([meditating_monk, fist_target], log)
	meditation_context.publish("action_completed", meditating_monk, meditating_monk, {}, -1, root_log_id)
	meditation_context.publish("action_completed", meditating_monk, meditating_monk, {}, -1, root_log_id)
	meditation_context.publish("attack_targeted", fist_target, meditating_monk, {}, -1, root_log_id)
	assert(meditating_monk.counter_value("untouched_actions") == 0, "An authoritative enemy attack target should reset an authored untouched-action counter.")
	for _action in range(3):
		meditation_context.publish("action_completed", meditating_monk, meditating_monk, {}, -1, root_log_id)
	assert(meditating_monk.hp == 14 and meditating_monk.counter_value("untouched_actions") == 0, "Three completed actions without being targeted should support healing and resetting the streak.")

	var seal := PassiveDefinition.new()
	seal.display_name = "Threefold Seal"
	var seal_attack := _effect("Consecutive Attack", "Seal Next Attack", "Event Target")
	seal_attack.condition = "Event Count At Least"
	seal_attack.counter_threshold = 3
	seal.effects.append(seal_attack)
	monk.current_passive = seal
	var seal_context = _context([monk, fist_target], log)
	for _attack in range(3):
		seal_context.publish("attack_performed", monk, fist_target, {}, -1, root_log_id, ["attack"])
	var sealed_request: Dictionary = seal_context.request("attack_target_requested", fist_target, monk, {"target_unit_id": monk.unit_id}, -1, root_log_id, ["attack", "target", "request"])
	assert(bool(sealed_request["payload"].get("prevented", false)) and fist_target.attack_seals.is_empty(), "Three consecutive complete attacks should seal and consume the target's next complete attack.")

	var spike = _unit("Spike", "Allies")
	spike.armor = 8
	var spike_passive := PassiveDefinition.new()
	spike_passive.display_name = "Barbed Hide"
	spike_passive.effects.append(_effect("Battle Start", "Disable Armor", "Self"))
	var retaliate := _effect("Physically Damaged", "Deal Damage", "Event Source", 2)
	spike_passive.effects.append(retaliate)
	spike.current_passive = spike_passive
	var spike_attacker = _unit("Spike Attacker", "Enemies")
	var spike_context = _context([spike, spike_attacker], log)
	spike_context.publish("battle_started", null, null, {}, -1, root_log_id)
	assert(spike.total_armor() == 0, "Disable Armor should preserve stored armor while preventing every armor contribution from mitigating damage.")
	spike_context.apply_physical_damage(spike_attacker, spike, 5, -1, root_log_id, ["attack"])
	assert(spike.hp == 15 and spike_attacker.hp == 18, "Physical damage retaliation should remain authorable through ordinary triggered effects while disabled armor takes no effect.")

	var reprisal := ReactionDefinition.new()
	reprisal.display_name = "Fatal Reprisal"
	reprisal.trigger = "Lethal Physical Attack Requested"
	reprisal.reaction_type = "Effects Only"
	reprisal.prevents_triggering_request = true
	reprisal.cooldown_turns = 4
	var reflect_lethal := _effect("Reaction Triggered", "Deal Damage", "Event Target")
	reflect_lethal.amount_source = "Event Amount"
	reprisal.effects.append(reflect_lethal)
	spike.current_reaction = reprisal
	spike.hp = 4
	var lethal_skill := SkillDefinition.new()
	lethal_skill.display_name = "Lethal Swing"
	lethal_skill.action = "Attack"
	spike_attacker.physical_damage = 7
	var lethal_context = _context([spike, spike_attacker], log)
	CombatSimulatorScript.new()._resolve_skill(lethal_context, log, root_log_id, spike_attacker, spike, lethal_skill, "job skill")
	assert(spike.hp == 4 and spike_attacker.hp == 11, "A lethal physical attack reaction should prevent the complete pending damage and reflect its final amount.")
	assert(not spike.ability_is_ready("reaction|Lethal Physical Attack Requested|Fatal Reprisal"), "Lethal physical attack reactions should use ordinary reaction cooldowns.")

	var fortified_spike = _unit("Fortified Spike", "Allies")
	var fortify_skill := SkillDefinition.new()
	fortify_skill.display_name = "Fortifying Strike"
	fortify_skill.action = "Attack"
	fortify_skill.effects.append(_effect("Skill Completed", "Fortify Damage", "Self"))
	fortify_skill.effects[0].modifier_duration_turns = 2
	fortified_spike.current_skill = fortify_skill
	var fortify_target = _unit("Fortify Target", "Enemies")
	var fortify_context = _context([fortified_spike, fortify_target], log)
	CombatSimulatorScript.new()._resolve_skill(fortify_context, log, root_log_id, fortified_spike, fortify_target, fortify_skill, "job skill")
	fortify_context.publish("action_completed", fortified_spike, fortify_target, {}, -1, root_log_id)
	fortify_context.apply_direct_damage(fortify_target, fortified_spike, 9, -1, root_log_id, ["attack"])
	assert(fortified_spike.hp == 20 and fortified_spike.deferred_damage == 9, "Fortify Damage should prevent immediate damage and add it to a shared deferred pool.")
	fortify_context.publish("action_completed", fortified_spike, fortify_target, {}, -1, root_log_id)
	assert(fortified_spike.hp == 15 and fortified_spike.deferred_damage == 4, "Fortified should evenly distribute pooled damage across its remaining completed actions.")
	fortify_context.publish("action_completed", fortified_spike, fortify_target, {}, -1, root_log_id)
	assert(fortified_spike.hp == 11 and fortified_spike.deferred_damage == 0, "Fortified should deliver the complete remaining pool on its final action.")

	var protected_by_spike = _unit("Protected By Spike", "Allies")
	var redirect_skill := SkillDefinition.new()
	redirect_skill.display_name = "All Barbs Forward"
	redirect_skill.action = "Effects Only"
	redirect_skill.cooldown_turns = 4
	redirect_skill.effects.append(_effect("Skill Used", "Redirect Enemy Attacks", "Self"))
	redirect_skill.effects[0].modifier_duration_turns = 2
	spike.current_skill = redirect_skill
	var redirect_context = _context([protected_by_spike, spike, spike_attacker], log)
	CombatSimulatorScript.new()._resolve_skill(redirect_context, log, root_log_id, spike, spike, redirect_skill, "job skill")
	redirect_context.publish("action_completed", spike, spike, {}, -1, root_log_id)
	var forced_request: Dictionary = redirect_context.request("attack_target_requested", spike_attacker, protected_by_spike, {"target_unit_id": protected_by_spike.unit_id}, -1, root_log_id, ["attack", "target", "request"])
	assert(forced_request["payload"].get("target_unit_id", "") == spike.unit_id, "Redirect Enemy Attacks should override attacks aimed at another allied unit.")
	redirect_context.publish("action_completed", spike, spike, {}, -1, root_log_id)
	redirect_context.publish("action_completed", spike, spike, {}, -1, root_log_id)
	var expired_request: Dictionary = redirect_context.request("attack_target_requested", spike_attacker, protected_by_spike, {"target_unit_id": protected_by_spike.unit_id}, -1, root_log_id, ["attack", "target", "request"])
	assert(expired_request["payload"].get("target_unit_id", "") == protected_by_spike.unit_id, "Temporary enemy-attack redirection should expire after the configured owner actions.")
	assert(not spike.skill_is_ready(redirect_skill), "Skills with authored cooldowns should become unavailable after use.")
	for _turn in range(4):
		spike.tick_ability_cooldowns()
	assert(spike.skill_is_ready(redirect_skill), "Authored skill cooldowns should elapse on the owner's turns.")

	var sanguinist = _unit("Sanguinist", "Allies")
	sanguinist.base_action_interval = 10
	sanguinist.action_interval = 10
	sanguinist.action_interval_floor_active = true
	sanguinist.next_action_time = 20
	var blood_rush := PassiveDefinition.new()
	blood_rush.display_name = "Blood Rush"
	blood_rush.effects.append(_effect("Ailment Damaged", "Hasten Action For Battle", "Self", 2))
	sanguinist.current_passive = blood_rush
	var blood_source = _unit("Blood Source", "Enemies")
	var blood_context = _context([sanguinist, blood_source], log)
	for _tick in range(4):
		blood_context.apply_direct_damage(null, sanguinist, 1, -1, root_log_id, ["status", "bleed"])
	assert(sanguinist.action_interval == 5 and sanguinist.next_action_time == 15, "Battle-long ailment haste should stop at the global half-encounter-start interval floor.")
	blood_context.apply_direct_damage(blood_source, sanguinist, 1, -1, root_log_id, ["attack"])
	assert(sanguinist.action_interval == 5, "Ordinary damage should not trigger Ailment Damaged effects.")

	var bleeding_enemy = _unit("Bleeding Enemy", "Enemies")
	bleeding_enemy.hp = 1
	for _stack in range(3):
		bleeding_enemy.add_status(BleedStatus, "test", 3, false)
	var blood_feast := ReactionDefinition.new()
	blood_feast.display_name = "Blood Feast"
	blood_feast.trigger = "Enemy Died With Status"
	blood_feast.reaction_type = "Effects Only"
	blood_feast.status = BleedStatus
	var feast_heal := _effect("Reaction Triggered", "Heal", "Self")
	feast_heal.amount_source = "Target Max HP Times Event Status Stacks"
	feast_heal.amount_multiplier = 2
	feast_heal.amount_divisor = 100
	feast_heal.amount_rounding = "Ceil"
	blood_feast.effects.append(feast_heal)
	sanguinist.current_reaction = blood_feast
	sanguinist.hp = 10
	var feast_context = _context([sanguinist, bleeding_enemy], log)
	feast_context.apply_direct_damage(sanguinist, bleeding_enemy, 1, -1, root_log_id, ["attack"])
	assert(sanguinist.hp == 12, "Enemy-death reactions should preserve defeated Bleed stacks and support rounded-up max-HP-per-stack healing.")

	var shield_target = _unit("Shield Target", "Allies")
	var shield_context = _context([sanguinist, shield_target, blood_source], log)
	shield_context.apply_direct_damage(blood_source, shield_target, 6, -1, root_log_id, ["attack"])
	shield_context.publish("action_completed", shield_target, blood_source, {}, -1, root_log_id)
	shield_context.apply_physical_damage(blood_source, shield_target, 4, -1, root_log_id, ["attack"])
	assert(shield_target.recent_damage() == 10, "Recent damage should include the current unfinished action window and the immediately previous completed-action window.")
	shield_target.add_status(BleedStatus, "test", 3, false)
	var blood_shield := SkillDefinition.new()
	blood_shield.display_name = "Blood Shield"
	blood_shield.action = "Effects Only"
	var grant_shield := _effect("Skill Used", "Grant Energy Shield", "Event Target")
	grant_shield.amount_source = "Target Recent Damage"
	blood_shield.effects.append(grant_shield)
	sanguinist.current_skill = blood_shield
	CombatSimulatorScript.new()._resolve_skill(shield_context, log, root_log_id, sanguinist, shield_target, blood_shield, "job skill")
	assert(shield_target.energy_shield == 10, "Energy Shield grants should scale from the selected target's recent damage and stack without a cap.")
	shield_context.apply_direct_damage(blood_source, shield_target, 7, -1, root_log_id, ["attack"])
	assert(shield_target.hp == 10 and shield_target.energy_shield == 3, "Energy Shield should absorb magic damage before HP.")
	shield_context.apply_physical_damage(blood_source, shield_target, 3, -1, root_log_id, ["attack"])
	assert(shield_target.hp == 7 and shield_target.energy_shield == 3, "Physical damage should bypass Energy Shield.")
	var bleeding_target_tactic := TacticDefinition.new()
	bleeding_target_tactic.target = "Lowest HP Ally With Status"
	bleeding_target_tactic.status = BleedStatus
	assert(TacticResolverScript.find_tactic_target(bleeding_target_tactic.target, sanguinist, [sanguinist, shield_target], bleeding_target_tactic) == shield_target, "Bleeding-ally targeting should include every allied unit, including the acting unit when eligible.")
	shield_target.remove_status(BleedStatus.display_name)
	assert(TacticResolverScript.find_tactic_target(bleeding_target_tactic.target, sanguinist, [sanguinist, shield_target], bleeding_target_tactic) == null, "A status-required allied target should make the bridge unavailable when no ally has that status.")

	var rot_victim = _unit("Rot Victim", "Allies")
	rot_victim.add_status(RotStatus, "test", 3, false)
	var rot_haste := PassiveDefinition.new()
	rot_haste.display_name = "Rot Rush"
	rot_haste.effects.append(_effect("Ailment Damaged", "Hasten Action For Battle", "Self", 1))
	rot_victim.current_passive = rot_haste
	rot_victim.base_action_interval = 10
	rot_victim.action_interval = 10
	rot_victim.action_interval_floor_active = true
	rot_victim.hp = 10
	var rot_context = _context([rot_victim], log)
	rot_context.apply_healing(rot_victim, rot_victim, 1, -1, root_log_id, ["healing"])
	assert(rot_victim.action_interval == 10, "Rot max-HP loss should not count as ailment damage when current HP does not fall.")
	rot_victim.hp = rot_victim.max_hp - 1
	rot_context.apply_healing(rot_victim, rot_victim, 1, -1, root_log_id, ["healing"])
	assert(rot_victim.action_interval == 9, "Rot should count as ailment damage when max-HP loss also lowers current HP.")

	var battle_report: Dictionary = CombatSimulatorScript.new().run_battle_report([AldenGuard, IronBrute], "Scenario hook integration", [AshChokedRule])
	var scenario_status_events := 0
	for event: Dictionary in battle_report["combat_events"]:
		if event["type"] == "status_applied" and event["payload"].get("status", "") == "Confusion":
			scenario_status_events += 1
	assert(scenario_status_events == 2, "An authored scenario hook should apply through the complete CombatSimulator battle path.")

	print("Triggered effect validation passed: scenario hooks, formulas, counters, interception, stack consumption/detonation, expanded tactics, and JSON authoring worked.")
	quit(0)


func _effect(trigger: String, effect_type: String, target_selector: String, amount := 0, status: StatusDefinition = null) -> EffectDefinition:
	var effect := EffectDefinition.new()
	effect.display_name = "%s %s" % [trigger, effect_type]
	effect.trigger = trigger
	effect.effect_type = effect_type
	effect.target_selector = target_selector
	effect.amount = amount
	effect.status = status
	return effect


func _unit(display_name: String, team: String):
	var unit = UnitStateScript.new()
	unit.unit_name = display_name
	unit.unit_id = display_name.to_lower()
	unit.team = team
	unit.max_hp = 20
	unit.hp = 20
	unit.physical_damage = 5
	return unit


func _context(units: Array, log):
	var context = CombatContextScript.new(units, log)
	context.add_responder(CombatHookResolverScript.respond)
	return context
