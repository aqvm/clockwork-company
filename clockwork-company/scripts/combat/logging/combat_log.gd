extends RefCounted
class_name CombatLog

class CombatLogEntry:
	var id := 0
	var parent_id := -1
	var time := -1
	var text := ""
	var child_ids: Array[int] = []

	func _init(entry_id: int, entry_text: String, entry_time: int = -1, entry_parent_id: int = -1) -> void:
		id = entry_id
		text = entry_text
		time = entry_time
		parent_id = entry_parent_id
		child_ids = []


const NO_TIME := -1
const NO_PARENT := -1
const CHILD_INDENT := "      "

var entries: Array[CombatLogEntry] = []
var root_ids: Array[int] = []
var next_id := 0


func add(text: String) -> int:
	return _add_entry(text, NO_TIME, NO_PARENT)


func add_at_time(time: int, text: String) -> int:
	return _add_entry(text, time, NO_PARENT)


func add_child(parent_id: int, text: String) -> int:
	return _add_entry(text, NO_TIME, parent_id)


func to_lines() -> Array[String]:
	var lines: Array[String] = []
	for entry_id in root_ids:
		_append_entry_lines(lines, entry_id, 0)
	return lines


func _add_entry(text: String, time: int, parent_id: int) -> int:
	var entry_id := next_id
	next_id += 1

	var entry := CombatLogEntry.new(entry_id, text, time, parent_id)
	entries.append(entry)

	if parent_id == NO_PARENT:
		root_ids.append(entry_id)
	else:
		entries[parent_id].child_ids.append(entry_id)

	return entry_id


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
