extends SceneTree

const CombatContextScript := preload("res://scripts/combat/runtime/combat_context.gd")
const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")

var observed: Array[String] = []


func _init() -> void:
	var source = _unit("Source", 10)
	var target = _unit("Target", 10)
	var context = CombatContextScript.new([source, target], CombatLogScript.new())
	context.add_responder(_first_responder)
	context.add_responder(_second_responder)

	var result: Dictionary = context.apply_direct_damage(source, target, 3)
	assert(int(result["amount"]) == 8 and target.hp == 2, "Request responders should modify damage in stable registration order.")
	assert(observed.slice(0, 2) == ["first:damage_requested", "second:damage_requested"], "Request responder order should be deterministic.")

	observed.clear()
	context.request("test_request", source, target)
	assert(observed == ["first:test_request", "second:test_request", "first:test_request_child", "second:test_request_child"], "Facts created while modifying a request should wait until every request responder has run.")

	observed.clear()
	var root_id: int = context.publish("action_completed", source, target)
	assert(observed == ["first:action_completed", "second:action_completed", "first:test_child", "second:test_child"], "Nested facts should queue behind all responders for the current fact.")
	var children: Array[Dictionary] = context.events_of_type("test_child")
	assert(children.size() == 1 and int(children[0]["parent_id"]) == root_id and int(children[0]["root_id"]) == root_id, "Nested facts should preserve causal parent and root ids.")
	var snapshots: Array[Dictionary] = context.event_snapshots()
	assert(not snapshots.is_empty() and not snapshots[-1].has("source"), "Published battle-report snapshots should not expose runtime unit references.")

	print("Combat event pipeline validation passed: request mutation, deterministic responder order, queued facts, causal ids, and sanitized snapshots worked.")
	quit(0)


func _first_responder(context, event: Dictionary) -> void:
	var event_type := String(event["type"])
	observed.append("first:%s" % event_type)
	if event_type == "damage_requested":
		event["payload"]["amount"] = int(event["payload"]["amount"]) + 1
	elif event_type == "test_request":
		context.publish("test_request_child", event.get("source", null), event.get("target", null), {}, int(event["id"]))
	elif event_type == "action_completed":
		context.publish("test_child", event.get("source", null), event.get("target", null), {}, int(event["id"]))


func _second_responder(_context, event: Dictionary) -> void:
	var event_type := String(event["type"])
	observed.append("second:%s" % event_type)
	if event_type == "damage_requested":
		event["payload"]["amount"] = int(event["payload"]["amount"]) * 2


func _unit(display_name: String, hp: int):
	var unit = UnitStateScript.new()
	unit.unit_name = display_name
	unit.unit_id = display_name.to_lower()
	unit.max_hp = hp
	unit.hp = hp
	return unit
