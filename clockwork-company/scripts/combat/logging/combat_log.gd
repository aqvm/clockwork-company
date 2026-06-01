extends RefCounted
class_name CombatLog
const CombatEventSchemaScript := preload("res://scripts/combat/logging/combat_event_schema.gd")

class CombatLogEntry:
	var id := 0
	var parent_id := -1
	var time := -1
	var text := ""
	var child_ids: Array[int] = []
	var event_type := "text"
	var payload := {}
	var tags: Array[String] = []

	func _init(
		entry_id: int,
		entry_text: String,
		entry_time: int = -1,
		entry_parent_id: int = -1,
		entry_event_type: String = "text",
		entry_payload: Dictionary = {},
		entry_tags: Array = []
	) -> void:
		id = entry_id
		text = entry_text
		time = entry_time
		parent_id = entry_parent_id
		child_ids = []
		event_type = entry_event_type
		payload = entry_payload.duplicate(true)
		tags = []
		for tag in entry_tags:
			tags.append(String(tag))


const NO_TIME := -1
const NO_PARENT := -1
const CHILD_INDENT := "      "

var entries: Array[CombatLogEntry] = []
var root_ids: Array[int] = []
var next_id := 0


func add(text: String) -> int:
	return _add_entry(text, NO_TIME, NO_PARENT, "text", {}, [])


func add_at_time(time: int, text: String) -> int:
	return _add_entry(text, time, NO_PARENT, "text", {}, [])


func add_child(parent_id: int, text: String) -> int:
	return _add_entry(text, NO_TIME, parent_id, "text", {}, [])


func add_event(
	text: String,
	event_type: String,
	time: int = NO_TIME,
	parent_id: int = NO_PARENT,
	payload: Dictionary = {},
	tags: Array = []
) -> int:
	_validate_event(event_type, payload)
	return _add_entry(text, time, parent_id, event_type, payload, tags)


func to_lines() -> Array[String]:
	var lines: Array[String] = []
	for entry_id in root_ids:
		_append_entry_lines(lines, entry_id, 0)
	return lines


func to_event_objects() -> Array[Dictionary]:
	var objects: Array[Dictionary] = []
	for entry in entries:
		objects.append({
			"id": entry.id,
			"parent_id": entry.parent_id,
			"time": entry.time,
			"text": entry.text,
			"event_type": entry.event_type,
			"payload": entry.payload.duplicate(true),
			"tags": entry.tags.duplicate(),
			"depth": _entry_depth(entry.id),
			"rendered_line": _format_entry(entry, _entry_depth(entry.id)),
		})
	return objects


func _add_entry(
	text: String,
	time: int,
	parent_id: int,
	event_type: String,
	payload: Dictionary,
	tags: Array
) -> int:
	var entry_id := next_id
	next_id += 1

	var entry := CombatLogEntry.new(entry_id, text, time, parent_id, event_type, payload, tags)
	entries.append(entry)

	if parent_id == NO_PARENT:
		root_ids.append(entry_id)
	else:
		entries[parent_id].child_ids.append(entry_id)

	return entry_id


func _entry_depth(entry_id: int) -> int:
	var depth := 0
	var parent_id := entries[entry_id].parent_id
	while parent_id != NO_PARENT:
		depth += 1
		parent_id = entries[parent_id].parent_id
	return depth


func _validate_event(event_type: String, payload: Dictionary) -> void:
	assert(CombatEventSchemaScript.is_known_event_type(event_type), "Unknown combat event type: %s" % event_type)
	var required: Array = CombatEventSchemaScript.required_keys(event_type)
	for key in required:
		assert(payload.has(key), "Missing '%s' in event payload for type %s" % [String(key), event_type])


func _append_entry_lines(lines: Array[String], entry_id: int, depth: int) -> void:
	var entry := entries[entry_id]
	lines.append(_format_entry(entry, depth))
	for child_id in entry.child_ids:
		_append_entry_lines(lines, child_id, depth + 1)


func _format_entry(entry: CombatLogEntry, depth: int) -> String:
	if entry.text.is_empty():
		return ""

	var indentation := ""
	for _count in depth:
		indentation += CHILD_INDENT

	if entry.time == NO_TIME:
		return "%s%s" % [indentation, entry.text]

	return "%st=%03d | %s" % [indentation, entry.time, entry.text]
