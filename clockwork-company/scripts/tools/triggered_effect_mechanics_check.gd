extends SceneTree

const CombatContextScript := preload("res://scripts/combat/runtime/combat_context.gd")
const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const CombatSimulatorScript := preload("res://scripts/combat/combat_simulator.gd")
const TriggeredEffectResolverScript := preload("res://scripts/combat/rules/triggered_effect_resolver.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const BleedStatus := preload("res://resources/statuses/bleed.tres")
const FrostStatus := preload("res://resources/statuses/frost.tres")
const NumbStatus := preload("res://resources/statuses/numb.tres")
const AshChokedRule := preload("res://resources/scenario_rules/ash_chapel_confusion.tres")
const AldenGuard := preload("res://resources/units/alden_guard.tres")
const IronBrute := preload("res://resources/units/iron_brute.tres")


func _init() -> void:
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
	assert(json_job != null and json_job.skill.action == "Effects Only" and json_job.skill.effects.size() == 1, "JSON should load effect-only job skills.")
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
	var battle_report: Dictionary = CombatSimulatorScript.new().run_battle_report([AldenGuard, IronBrute], "Scenario hook integration", [AshChokedRule])
	var scenario_status_events := 0
	for event: Dictionary in battle_report["combat_events"]:
		if event["type"] == "status_applied" and event["payload"].get("status", "") == "Confusion":
			scenario_status_events += 1
	assert(scenario_status_events == 2, "An authored scenario hook should apply through the complete CombatSimulator battle path.")

	print("Triggered effect validation passed: scenario hooks, job skills, broad status targets, deterministic cleanse/dispel, temporary stat modifier expiry, root-loop safety, and JSON authoring worked.")
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
