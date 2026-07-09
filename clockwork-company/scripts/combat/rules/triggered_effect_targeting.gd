extends RefCounted
class_name TriggeredEffectTargeting
static func targets(context, event: Dictionary, owner, selector: String) -> Array:
	var source = event.get("source", null)
	var target = event.get("target", null)
	match selector:
		"Self":
			return [owner] if owner != null else []
		"Event Source", "Attacker", "Killer":
			return [source] if source != null else []
		"Event Target", "Attack Target":
			return [target] if target != null else []
		"All Units":
			return _living_units(context.units)
		"Allied Units":
			return _living_team_units(context.units, owner.team if owner != null else "Allies")
		"Enemy Units":
			return _living_team_units(context.units, _other_team(owner.team) if owner != null else "Enemies")
		"Lowest HP Allied Unit":
			return _lowest_hp_unit(_living_team_units(context.units, owner.team if owner != null else "Allies"))
		"Random Allied Unit":
			return _one_deterministic(_living_team_units(context.units, owner.team if owner != null else "Allies"), int(event.get("id", 0)))
		"Random Damaged Allied Unit":
			return _one_deterministic(_living_damaged_team_units(context.units, owner.team if owner != null else "Allies"), int(event.get("id", 0)))
		"Random Enemy Unit":
			return _one_deterministic(_living_team_units(context.units, _other_team(owner.team) if owner != null else "Enemies"), int(event.get("id", 0)))
		"Most Ailmented Enemy Unit":
			return _most_ailmented_unit(_living_team_units(context.units, _other_team(owner.team) if owner != null else "Enemies"), context.units)
	return []


static func _living_team_units(units: Array, team: String) -> Array:
	var matches: Array = []
	for unit in units:
		if unit.team == team and unit.is_alive():
			matches.append(unit)
	return matches


static func _living_units(units: Array) -> Array:
	var matches: Array = []
	for unit in units:
		if unit.is_alive():
			matches.append(unit)
	return matches


static func _living_damaged_team_units(units: Array, team: String) -> Array:
	var matches: Array = []
	for unit in units:
		if unit.team == team and unit.is_alive() and unit.hp < unit.max_hp:
			matches.append(unit)
	return matches


static func _one_deterministic(candidates: Array, event_id: int) -> Array:
	if candidates.is_empty():
		return []
	return [candidates[event_id % candidates.size()]]


static func _lowest_hp_unit(candidates: Array) -> Array:
	if candidates.is_empty():
		return []
	var lowest = candidates[0]
	for candidate in candidates:
		if candidate.hp < lowest.hp:
			lowest = candidate
	return [lowest]


static func _most_ailmented_unit(candidates: Array, roster: Array) -> Array:
	if candidates.is_empty():
		return []
	var ranked: Array[Dictionary] = []
	for candidate in candidates:
		ranked.append({
			"unit": candidate,
			"ailment_stacks": status_stacks_by_polarity(candidate, "Ailment"),
			"hp": int(candidate.hp),
			"roster_index": roster.find(candidate),
		})
	ranked.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left["ailment_stacks"]) != int(right["ailment_stacks"]):
			return int(left["ailment_stacks"]) > int(right["ailment_stacks"])
		if int(left["hp"]) != int(right["hp"]):
			return int(left["hp"]) < int(right["hp"])
		return int(left["roster_index"]) < int(right["roster_index"])
	)
	return [ranked[0]["unit"]]


static func _other_team(team: String) -> String:
	return "Enemies" if team == "Allies" else "Allies"


static func amount_targets(context, owner, selector: String) -> Array:
	if context == null:
		return []
	match selector:
		"Self":
			return [owner] if owner != null else []
		"All Units":
			return _living_units(context.units)
		"Allied Units":
			return _living_team_units(context.units, owner.team if owner != null else "Allies")
		"Enemy Units":
			return _living_team_units(context.units, _other_team(owner.team) if owner != null else "Enemies")
	return []


static func total_status_stacks(units: Array, status: StatusDefinition) -> int:
	if status == null:
		return 0
	var total := 0
	for unit in units:
		total += unit.status_stack_count(status.status_type)
	return total


static func total_status_max_hp_loss(units: Array, status: StatusDefinition) -> int:
	if status == null:
		return 0
	var total := 0
	for unit in units:
		total += int(unit.status_instance(status.status_type).get("max_hp_lost", 0))
	return total


static func status_stacks_by_polarity(target, polarity: String) -> int:
	if target == null:
		return 0
	var total := 0
	for instance: Dictionary in target.statuses:
		var definition: StatusDefinition = instance.get("definition", null)
		if definition != null and definition.polarity == polarity:
			total += int(instance.get("stack_count", 1))
	return total


static func snapshot_status_stacks(snapshots: Array, status_type: String) -> int:
	for snapshot: Dictionary in snapshots:
		if String(snapshot.get("status_type", "")) == status_type:
			return int(snapshot.get("stack_count", 0))
	return 0


static func unique_statuses_by_polarity(target, polarity: String) -> int:
	if target == null:
		return 0
	var unique_types := {}
	for instance: Dictionary in target.statuses:
		var definition: StatusDefinition = instance.get("definition", null)
		if definition != null and definition.polarity == polarity:
			unique_types[definition.status_type] = true
	return unique_types.size()
