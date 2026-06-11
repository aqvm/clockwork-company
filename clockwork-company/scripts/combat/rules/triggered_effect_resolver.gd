extends RefCounted
class_name TriggeredEffectResolver

const StatusResolverScript := preload("res://scripts/combat/rules/status_resolver.gd")

const SHARED_EFFECT_TYPES := ["Apply Status", "Remove Status", "Modify Stat"]


static func respond(context, event: Dictionary) -> void:
	var event_type := String(event.get("type", ""))
	if event_type == "turn_completed":
		_elapse_modifiers(context, event)
	for unit in context.units:
		for item in unit.equipped_items:
			for effect in item.effects:
				if _can_resolve(context, event, unit, effect, item.display_name):
					_resolve(context, event, unit, effect, item.display_name, ["item"])
		for skill in [unit.current_skill, unit.assigned_skill]:
			if skill == null or String(event.get("type", "")) != "skill_used" or String(event["payload"].get("skill", "")) != skill.display_name:
				continue
			for effect in skill.effects:
				if _can_resolve(context, event, unit, effect, skill.display_name):
					_resolve(context, event, unit, effect, skill.display_name, ["skill"])
	for rule in context.scenario_rules:
		if rule == null:
			continue
		for effect in rule.effects:
			if _can_resolve(context, event, null, effect, rule.display_name):
				_resolve(context, event, null, effect, rule.display_name, ["scenario"])


static func _can_resolve(context, event: Dictionary, owner, effect: EffectDefinition, source_name: String) -> bool:
	if effect == null or not SHARED_EFFECT_TYPES.has(effect.effect_type):
		return false
	if not _trigger_matches(event, owner, effect.trigger):
		return false
	if not _condition_matches(event, owner, effect):
		return false
	var key := _usage_key(event, owner, effect, source_name)
	if context.triggered_effect_root_usage.has(key):
		return false
	if effect.once_per_battle and context.triggered_effect_battle_usage.has(_battle_usage_key(owner, effect, source_name)):
		return false
	return true


static func _resolve(context, event: Dictionary, owner, effect: EffectDefinition, source_name: String, source_tags: Array) -> void:
	context.triggered_effect_root_usage[_usage_key(event, owner, effect, source_name)] = true
	if effect.once_per_battle:
		context.triggered_effect_battle_usage[_battle_usage_key(owner, effect, source_name)] = true
	var targets := _targets(context, event, owner, effect.target_selector)
	for target in targets:
		if target == null:
			continue
		var effect_event_id: int = context.publish("triggered_effect_resolved", owner, target, {
			"source_name": source_name,
			"effect_name": effect.display_name,
			"effect_type": effect.effect_type,
			"trigger": effect.trigger,
		}, int(event.get("id", -1)), int(event.get("parent_log_id", -1)), source_tags + ["triggered_effect"])
		if effect.effect_type == "Apply Status":
			StatusResolverScript.apply_status(
				context.log,
				int(event.get("parent_log_id", -1)),
				target,
				effect.status,
				source_name,
				effect.status_duration_turns,
				effect.status_is_permanent,
				context,
				owner,
				effect_event_id
			)
		elif effect.effect_type == "Remove Status":
			_remove_status(context, event, owner, target, effect, source_name, effect_event_id)
		elif effect.effect_type == "Modify Stat":
			_apply_modifier(context, event, owner, target, effect, source_name, effect_event_id)


static func _apply_modifier(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	var previous_value: int = target.stat_value(effect.modified_stat)
	var modifier: Dictionary = target.add_temporary_modifier(effect.modified_stat, effect.amount, effect.modifier_duration_turns, source_name)
	if modifier.is_empty():
		context.log.add_child(int(event.get("parent_log_id", -1)), "%s cannot change %s's %s any further." % [source_name, target.unit_name, effect.modified_stat.to_lower()])
		return
	var new_value: int = target.stat_value(effect.modified_stat)
	context.log.add_child(int(event.get("parent_log_id", -1)), "%s changes %s's %s %d -> %d for %d completed turn%s." % [
		source_name,
		target.unit_name,
		effect.modified_stat.to_lower(),
		previous_value,
		new_value,
		effect.modifier_duration_turns,
		"" if effect.modifier_duration_turns == 1 else "s",
	])
	context.publish("temporary_modifier_applied", owner, target, {
		"source_name": source_name,
		"stat": effect.modified_stat,
		"amount": int(modifier.get("amount", 0)),
		"previous": previous_value,
		"new": new_value,
		"duration_turns": effect.modifier_duration_turns,
	}, effect_event_id, int(event.get("parent_log_id", -1)), ["modifier"])


static func _remove_status(context, event: Dictionary, owner, target, effect: EffectDefinition, source_name: String, effect_event_id: int) -> void:
	var eligible: Array[Dictionary] = []
	for instance: Dictionary in target.statuses:
		var definition := instance.get("definition", null) as StatusDefinition
		if definition == null:
			continue
		if effect.status_polarity != "Any" and definition.polarity != effect.status_polarity:
			continue
		if effect.status_removal_mode == "Specific Status":
			if effect.status == null or definition.status_type != effect.status.status_type:
				continue
		eligible.append(instance)
	if eligible.is_empty():
		context.log.add_child(int(event.get("parent_log_id", -1)), "%s finds no matching status to remove from %s." % [source_name, target.unit_name])
		return
	var selected: Dictionary = eligible[int(event.get("id", 0)) % eligible.size()]
	var status := selected.get("definition", null) as StatusDefinition
	StatusResolverScript.remove_status(
		context.log,
		int(event.get("parent_log_id", -1)),
		target,
		status.display_name,
		source_name,
		context,
		owner,
		effect_event_id
	)


static func _elapse_modifiers(context, event: Dictionary) -> void:
	var owner = event.get("source", null)
	if owner == null:
		return
	for modifier: Dictionary in owner.elapse_temporary_modifiers():
		var stat_name := String(modifier.get("stat", ""))
		context.log.add_child(int(event.get("parent_log_id", -1)), "%s's temporary %s modifier from %s expires." % [
			owner.unit_name,
			stat_name.to_lower(),
			String(modifier.get("source_name", "an effect")),
		])
		context.publish("temporary_modifier_removed", owner, owner, {
			"source_name": String(modifier.get("source_name", "")),
			"stat": stat_name,
			"amount": int(modifier.get("amount", 0)),
			"reason": "expired",
			"new": owner.stat_value(stat_name),
		}, int(event.get("id", -1)), int(event.get("parent_log_id", -1)), ["modifier", "expired"])


static func _trigger_matches(event: Dictionary, owner, trigger: String) -> bool:
	var event_type := String(event.get("type", ""))
	var source = event.get("source", null)
	var target = event.get("target", null)
	match trigger:
		"Battle Start":
			return event_type == "battle_started"
		"Turn Start":
			return event_type == "turn_started" and (owner == null or source == owner)
		"Turn Complete":
			return event_type == "turn_completed" and (owner == null or source == owner)
		"Skill Used":
			return event_type == "skill_used" and (owner == null or source == owner)
		"Attack":
			return event_type == "attack_performed" and (owner == null or source == owner)
		"Hit":
			return event_type == "damage_dealt" and event.get("tags", []).has("attack") and int(event["payload"].get("amount", 0)) > 0 and (owner == null or source == owner)
		"Damaged", "HP Below Threshold":
			return event_type == "damage_dealt" and int(event["payload"].get("amount", 0)) > 0 and (owner == null or target == owner)
		"Kill":
			return event_type == "unit_defeated" and (owner == null or source == owner)
		"Death":
			return event_type == "unit_defeated" and (owner == null or target == owner)
		"Status Applied":
			return event_type == "status_applied" and (owner == null or target == owner)
		"Status Removed":
			return event_type == "status_removed" and (owner == null or target == owner)
		"Reaction Triggered":
			return event_type == "reaction_triggered" and (owner == null or source == owner)
	return false


static func _condition_matches(event: Dictionary, owner, effect: EffectDefinition) -> bool:
	if effect.trigger == "HP Below Threshold":
		var threshold_subject = owner if owner != null else event.get("target", null)
		if threshold_subject == null or threshold_subject.hp * 100 > threshold_subject.max_hp * effect.threshold_percent:
			return false
	if effect.condition == "Self HP Below Percent":
		return owner != null and owner.hp * 100 <= owner.max_hp * effect.threshold_percent
	var target = event.get("target", null)
	if effect.condition == "Target Has Tag":
		return _target_has_any_tag(target, effect.tags)
	if effect.condition == "Target Missing Tag":
		return not _target_has_any_tag(target, effect.tags)
	return true


static func _targets(context, event: Dictionary, owner, selector: String) -> Array:
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
		"Random Allied Unit":
			return _one_deterministic(_living_team_units(context.units, owner.team if owner != null else "Allies"), int(event.get("id", 0)))
		"Random Enemy Unit":
			return _one_deterministic(_living_team_units(context.units, _other_team(owner.team) if owner != null else "Enemies"), int(event.get("id", 0)))
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


static func _one_deterministic(candidates: Array, event_id: int) -> Array:
	if candidates.is_empty():
		return []
	return [candidates[event_id % candidates.size()]]


static func _other_team(team: String) -> String:
	return "Enemies" if team == "Allies" else "Allies"


static func _target_has_any_tag(target, tags: Array[String]) -> bool:
	if target == null:
		return false
	for tag in tags:
		if target.tags.has(tag):
			return true
	return false


static func _usage_key(event: Dictionary, owner, effect: EffectDefinition, source_name: String) -> String:
	return "%d|%s|%s" % [
		int(event.get("root_id", event.get("id", -1))),
		owner.unit_id if owner != null else "scenario",
		_battle_usage_key(owner, effect, source_name),
	]


static func _battle_usage_key(owner, effect: EffectDefinition, source_name: String) -> String:
	return "%s|%s|%s|%s|%d" % [
		owner.unit_id if owner != null else "scenario",
		source_name,
		effect.trigger,
		effect.display_name if not effect.display_name.is_empty() else effect.effect_type,
		effect.get_instance_id(),
	]
