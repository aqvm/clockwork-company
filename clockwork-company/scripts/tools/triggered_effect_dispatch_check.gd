extends SceneTree

const CheckHarnessScript := preload("res://scripts/tools/check_harness.gd")
const CombatContextScript := preload("res://scripts/combat/runtime/combat_context.gd")
const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const TriggeredEffectResolverScript := preload("res://scripts/combat/rules/triggered_effect_resolver.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")
const BleedStatus := preload("res://resources/statuses/bleed.tres")

var check_completed := false


func _init() -> void:
	process_frame.connect(_quit_if_incomplete, CONNECT_ONE_SHOT)
	var checks = CheckHarnessScript.new()
	checks.run_case("dispatch applies status effects", _check_dispatch_applies_status_effects)
	checks.run_case("dispatch applies request effects", _check_dispatch_applies_request_effects)
	print("Triggered effect dispatch checks passed: %d cases." % checks.case_count)
	check_completed = true
	quit(0)


func _check_dispatch_applies_status_effects() -> bool:
	var ally = _unit("Ally", "Allies")
	var effect := EffectDefinition.new()
	effect.display_name = "Opening Bleed"
	effect.trigger = "Battle Start"
	effect.effect_type = "Apply Status"
	effect.target_selector = "Self"
	effect.status = BleedStatus
	effect.amount = 1
	var item := ItemDefinition.new()
	item.display_name = "Dispatch Item"
	item.effects.append(effect)
	ally.equipped_items.append(item)
	var context = _context([ally])
	context.publish("battle_started", null, null, {}, -1, 0)
	return ally.has_status("Bleed")


func _check_dispatch_applies_request_effects() -> bool:
	var ally = _unit("Ally", "Allies")
	var effect := EffectDefinition.new()
	effect.display_name = "No Bleed"
	effect.trigger = "Status Application Requested"
	effect.condition = "Requested Status Matches"
	effect.effect_type = "Prevent Request"
	effect.target_selector = "Self"
	effect.status = BleedStatus
	var item := ItemDefinition.new()
	item.display_name = "Request Item"
	item.effects.append(effect)
	ally.equipped_items.append(item)
	var context = _context([ally])
	var event := {
		"id": 1,
		"type": "status_application_requested",
		"source": ally,
		"target": ally,
		"payload": {"status": "Bleed", "status_type": "Bleed"},
		"parent_log_id": 0,
	}
	TriggeredEffectResolverScript.respond(context, event)
	return bool(event["payload"].get("prevented", false))


func _unit(display_name: String, team: String):
	var unit := UnitDefinition.new()
	unit.display_name = display_name
	unit.team = team
	unit.max_hp = 20
	unit.physical_damage = 5
	unit.action_speed = 10
	return UnitStateScript.new(unit)


func _context(units: Array):
	var log = CombatLogScript.new()
	log.add("Dispatch check")
	var context = CombatContextScript.new(units, log)
	context.add_responder(TriggeredEffectResolverScript.respond)
	return context


func _quit_if_incomplete() -> void:
	if check_completed:
		return
	push_error("Triggered effect dispatch checks did not complete before the first frame.")
	quit(1)
