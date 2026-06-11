extends RefCounted

const CombatLogScript := preload("res://scripts/combat/logging/combat_log.gd")
const UnitStateScript := preload("res://scripts/combat/runtime/unit_state.gd")
const CombatContextScript := preload("res://scripts/combat/runtime/combat_context.gd")
const CombatHookResolverScript := preload("res://scripts/combat/rules/combat_hook_resolver.gd")


static func build_party_preview_by_name(units: Array[UnitDefinition]) -> Dictionary:
	var unit_states: Array = []
	for index in units.size():
		unit_states.append(UnitStateScript.new(units[index], index))

	var previews := {}
	for state in unit_states:
		previews[state.unit_name] = {
			"before_battle_start": _stats_from_state(state),
			"after_battle_start": {},
			"skipped_items": _item_names(state.skipped_items),
		}

	var log = CombatLogScript.new()
	var battle_start_entry_id: int = log.add("Planning battle-start preview")
	var context = CombatContextScript.new(unit_states, log, [], true)
	context.add_responder(CombatHookResolverScript.respond)
	context.publish("battle_started", null, null, {}, -1, battle_start_entry_id, ["battle", "preview"])

	for state in unit_states:
		var preview: Dictionary = previews[state.unit_name]
		preview["after_battle_start"] = _stats_from_state(state)
	return previews


static func stats_line(stats: Dictionary) -> String:
	if stats.is_empty():
		return "HP ?, physical ?, magic ?, armor ?, interval ?"
	return "HP %d, physical %d, magic %d, armor %d, interval %d" % [
		int(stats.get("max_hp", 0)),
		int(stats.get("physical_damage", 0)),
		int(stats.get("magic_damage", 0)),
		int(stats.get("armor", 0)),
		int(stats.get("action_interval", 0)),
	]


static func compact_stats_line(stats: Dictionary) -> String:
	if stats.is_empty():
		return "HP ? | P? M? A? I?"
	return "HP %d | P%d M%d A%d I%d" % [
		int(stats.get("max_hp", 0)),
		int(stats.get("physical_damage", 0)),
		int(stats.get("magic_damage", 0)),
		int(stats.get("armor", 0)),
		int(stats.get("action_interval", 0)),
	]


static func stats_changed(left: Dictionary, right: Dictionary) -> bool:
	for key in ["max_hp", "physical_damage", "magic_damage", "armor", "action_interval"]:
		if int(left.get(key, 0)) != int(right.get(key, 0)):
			return true
	return false


static func _stats_from_state(state) -> Dictionary:
	return {
		"max_hp": state.max_hp,
		"physical_damage": state.physical_damage,
		"magic_damage": state.magic_damage,
		"armor": state.total_armor(),
		"action_interval": state.action_interval,
	}


static func _item_names(items: Array[ItemDefinition]) -> Array[String]:
	var names: Array[String] = []
	for item: ItemDefinition in items:
		if item != null:
			names.append(item.display_name)
	return names
