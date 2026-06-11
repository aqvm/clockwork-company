extends RefCounted
class_name CombatContext

const CombatEventsScript := preload("res://scripts/combat/logging/combat_events.gd")
const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")
const MAX_EVENTS_PER_BATTLE := 2000
const MAX_CHAIN_DEPTH := 32

var units: Array = []
var log = null
var scenario_rules: Array = []
var speculative := false
var history: Array[Dictionary] = []
var triggered_effect_root_usage := {}
var triggered_effect_battle_usage := {}

var _responders: Array[Callable] = []
var _queue: Array[Dictionary] = []
var _processing := false
var _request_depth := 0
var _next_event_id := 1


func _init(battle_units: Array = [], battle_log = null, battle_scenario_rules: Array = [], is_speculative := false) -> void:
	units = battle_units
	log = battle_log
	scenario_rules = battle_scenario_rules
	speculative = is_speculative


func add_responder(responder: Callable) -> void:
	if not responder.is_null():
		_responders.append(responder)


func request(
	event_type: String,
	source = null,
	target = null,
	payload: Dictionary = {},
	parent_event_id := -1,
	parent_log_id := -1,
	tags: Array = []
) -> Dictionary:
	assert(history.size() < MAX_EVENTS_PER_BATTLE, "Combat event count exceeded safety limit.")
	var event := _build_event(event_type, source, target, payload, parent_event_id, parent_log_id, tags)
	history.append(event)
	_request_depth += 1
	for responder: Callable in _responders:
		responder.call(self, event)
	_request_depth -= 1
	if _request_depth == 0 and not _processing and not _queue.is_empty():
		_process_queue()
	return event


func publish(
	event_type: String,
	source = null,
	target = null,
	payload: Dictionary = {},
	parent_event_id := -1,
	parent_log_id := -1,
	tags: Array = []
) -> int:
	var event := _build_event(event_type, source, target, payload, parent_event_id, parent_log_id, tags)
	_queue.append(event)
	if not _processing and _request_depth == 0:
		_process_queue()
	return int(event["id"])


func events_of_type(event_type: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for event: Dictionary in history:
		if String(event.get("type", "")) == event_type:
			matches.append(event)
	return matches


func event_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for event: Dictionary in history:
		snapshots.append({
			"id": int(event.get("id", -1)),
			"type": String(event.get("type", "")),
			"root_id": int(event.get("root_id", -1)),
			"parent_id": int(event.get("parent_id", -1)),
			"parent_log_id": int(event.get("parent_log_id", -1)),
			"depth": int(event.get("depth", 0)),
			"source_unit_id": String(event.get("source_unit_id", "")),
			"target_unit_id": String(event.get("target_unit_id", "")),
			"payload": event.get("payload", {}).duplicate(true),
			"tags": event.get("tags", []).duplicate(),
		})
	return snapshots


func apply_direct_damage(source, target, amount: int, parent_event_id := -1, parent_log_id := -1, tags: Array = []) -> Dictionary:
	var damage_request: Dictionary = request("damage_requested", source, target, {"amount": amount, "physical_amount": 0, "magic_amount": amount, "prevented": false}, parent_event_id, parent_log_id, tags)
	if bool(damage_request["payload"].get("prevented", false)):
		var prevented_event_id := publish("damage_prevented", source, target, damage_request["payload"], int(damage_request["id"]), parent_log_id, ["damage", "prevented"])
		return {"amount": 0, "event_id": prevented_event_id}
	amount = max(0, int(damage_request["payload"].get("amount", amount)))
	var previous_hp: int = target.hp
	target.hp = max(0, target.hp - max(0, amount))
	return record_damage(source, target, amount, previous_hp, 0, previous_hp - target.hp, int(damage_request["id"]), parent_log_id, tags)


func record_damage(
	source,
	target,
	attempted_amount: int,
	previous_hp: int,
	physical_amount: int,
	magic_amount: int,
	parent_event_id := -1,
	parent_log_id := -1,
	tags: Array = []
) -> Dictionary:
	var applied_amount: int = previous_hp - target.hp
	StatusResolverScript.record_damage(target, applied_amount)
	var event := CombatEventsScript.damage(source, target, attempted_amount, target.total_armor(), previous_hp, target.hp)
	if log != null:
		log.add_event("Damage dealt: %d. Physical %d, magic %d. HP: %d -> %d." % [attempted_amount, physical_amount, magic_amount, previous_hp, target.hp], event["event_type"], -1, parent_log_id, event["payload"], event["tags"])
	var damage_event_id := publish("damage_dealt", source, target, {
		"amount": applied_amount,
		"attempted_amount": attempted_amount,
		"physical_amount": physical_amount,
		"magic_amount": magic_amount,
		"previous_hp": previous_hp,
		"new_hp": target.hp,
	}, parent_event_id, parent_log_id, tags)
	if not target.is_alive():
		if log != null:
			var defeat_event := CombatEventsScript.defeat(target)
			log.add_event("%s is defeated." % target.unit_name, defeat_event["event_type"], -1, parent_log_id, defeat_event["payload"], defeat_event["tags"])
		publish("unit_defeated", source, target, {}, damage_event_id, parent_log_id, ["defeat"])
	return {"amount": applied_amount, "event_id": damage_event_id}


func apply_healing(source, target, amount: int, parent_event_id := -1, parent_log_id := -1, tags: Array = []) -> Dictionary:
	var healing_request: Dictionary = request("healing_requested", source, target, {"amount": amount, "prevented": false}, parent_event_id, parent_log_id, tags)
	if bool(healing_request["payload"].get("prevented", false)):
		var prevented_event_id := publish("healing_prevented", source, target, healing_request["payload"], int(healing_request["id"]), parent_log_id, ["healing", "prevented"])
		return {"amount": 0, "event_id": prevented_event_id}
	amount = max(0, int(healing_request["payload"].get("amount", amount)))
	var previous_hp: int = target.hp
	target.hp = min(target.max_hp, target.hp + max(0, amount))
	var applied_amount: int = target.hp - previous_hp
	var event := CombatEventsScript.heal(source, target, applied_amount, previous_hp, target.hp)
	if log != null:
		log.add_event("%s heals %s for %d HP. HP: %d -> %d." % [source.unit_name, target.unit_name, applied_amount, previous_hp, target.hp], event["event_type"], -1, parent_log_id, event["payload"], event["tags"])
	var healing_event_id := publish("healing_received", source, target, {
		"amount": applied_amount,
		"attempted_amount": amount,
		"previous_hp": previous_hp,
		"new_hp": target.hp,
	}, int(healing_request["id"]), parent_log_id, tags)
	return {"amount": applied_amount, "event_id": healing_event_id}


func _process_queue() -> void:
	_processing = true
	while not _queue.is_empty():
		assert(history.size() < MAX_EVENTS_PER_BATTLE, "Combat event count exceeded safety limit.")
		var event: Dictionary = _queue.pop_front()
		history.append(event)
		for responder: Callable in _responders:
			responder.call(self, event)
	_processing = false


func _event_by_id(event_id: int) -> Dictionary:
	if event_id < 0:
		return {}
	for event: Dictionary in history:
		if int(event.get("id", -1)) == event_id:
			return event
	for event: Dictionary in _queue:
		if int(event.get("id", -1)) == event_id:
			return event
	return {}


func _build_event(event_type: String, source, target, payload: Dictionary, parent_event_id: int, parent_log_id: int, tags: Array) -> Dictionary:
	var parent: Dictionary = _event_by_id(parent_event_id)
	var event_id := _next_event_id
	_next_event_id += 1
	var depth := int(parent.get("depth", -1)) + 1
	assert(depth <= MAX_CHAIN_DEPTH, "Combat event chain exceeded maximum depth at %s." % event_type)
	return {
		"id": event_id,
		"type": event_type,
		"root_id": int(parent.get("root_id", event_id)),
		"parent_id": parent_event_id,
		"parent_log_id": parent_log_id,
		"depth": depth,
		"source": source,
		"source_unit_id": source.unit_id if source != null else "",
		"target": target,
		"target_unit_id": target.unit_id if target != null else "",
		"payload": payload.duplicate(true),
		"tags": _string_tags(tags),
	}


func _string_tags(source_tags: Array) -> Array[String]:
	var result: Array[String] = []
	for tag in source_tags:
		result.append(String(tag))
	return result
