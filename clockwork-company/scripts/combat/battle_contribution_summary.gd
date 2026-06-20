extends RefCounted
class_name BattleContributionSummary


static func build(roster_units: Array[Dictionary], combat_events: Array[Dictionary]) -> Array[Dictionary]:
	var rows_by_id := {}
	for unit: Dictionary in roster_units:
		var unit_id := String(unit.get("id", ""))
		if unit_id.is_empty():
			continue
		rows_by_id[unit_id] = {
			"id": unit_id,
			"name": String(unit.get("name", unit_id)),
			"team": String(unit.get("team", "")),
			"actions": 0,
			"damage_dealt": 0,
			"healing_done": 0,
			"damage_taken": 0,
			"kills": 0,
			"mitigation_prevention": 0,
			"preventions": 0,
		}

	for event: Dictionary in combat_events:
		var event_type := String(event.get("type", ""))
		var source_id := String(event.get("source_unit_id", ""))
		var target_id := String(event.get("target_unit_id", ""))
		var payload: Dictionary = event.get("payload", {})
		if event_type == "action_completed":
			_add_to_row(rows_by_id, source_id, "actions", 1)
		elif event_type == "damage_dealt":
			var amount: int = max(0, int(payload.get("amount", 0)))
			_add_to_row(rows_by_id, source_id, "damage_dealt", amount)
			_add_to_row(rows_by_id, target_id, "damage_taken", amount)
			_add_to_row(rows_by_id, target_id, "mitigation_prevention", max(0, int(payload.get("mitigated_amount", 0))))
		elif event_type == "healing_received":
			_add_to_row(rows_by_id, source_id, "healing_done", max(0, int(payload.get("amount", 0))))
		elif event_type == "unit_defeated":
			_add_to_row(rows_by_id, source_id, "kills", 1)
		elif event_type == "damage_prevented":
			_add_to_row(rows_by_id, target_id, "mitigation_prevention", _prevented_amount(payload))
			_add_to_row(rows_by_id, target_id, "preventions", 1)
		elif event_type == "attack_prevented":
			_add_to_row(rows_by_id, target_id, "preventions", 1)

	var rows: Array[Dictionary] = []
	for unit: Dictionary in roster_units:
		var unit_id := String(unit.get("id", ""))
		if rows_by_id.has(unit_id):
			rows.append(rows_by_id[unit_id].duplicate(true))
	return rows


static func _add_to_row(rows_by_id: Dictionary, unit_id: String, key: String, amount: int) -> void:
	if unit_id.is_empty() or not rows_by_id.has(unit_id) or amount <= 0:
		return
	rows_by_id[unit_id][key] = int(rows_by_id[unit_id].get(key, 0)) + amount


static func _prevented_amount(payload: Dictionary) -> int:
	var amount := int(payload.get("amount", 0))
	if amount <= 0:
		amount = int(payload.get("physical_amount", 0)) + int(payload.get("magic_amount", 0))
	return max(0, amount)
