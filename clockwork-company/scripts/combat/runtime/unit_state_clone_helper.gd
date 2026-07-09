extends RefCounted
class_name UnitStateCloneHelper


static func clone_runtime_state(source):
	var clone = source.get_script().new()
	clone.unit_name = source.unit_name
	clone.unit_id = source.unit_id
	clone.campaign_unit_id = source.campaign_unit_id
	clone.tags = source.tags.duplicate()
	clone.team = source.team
	clone.ancestry = _duplicate_resource(source.ancestry)
	clone.current_ancestry_feature = _duplicate_resource(source.current_ancestry_feature)
	clone.max_hp = source.max_hp
	clone.hp = source.hp
	clone.physical_damage = source.physical_damage
	clone.magic_damage = source.magic_damage
	clone.armor = source.armor
	clone.action_speed = source.action_speed
	clone.base_action_speed = source.base_action_speed
	clone.action_speed_cap_percent = source.action_speed_cap_percent
	clone.action_speed_cap_active = source.action_speed_cap_active
	clone.next_action_time = source.next_action_time
	clone.slot_index = source.slot_index
	clone.loadout = _duplicate_resource(source.loadout)
	clone.current_job = _duplicate_resource(source.current_job)
	clone.current_skill = _duplicate_resource(source.current_skill)
	clone.current_secondary_skill = _duplicate_resource(source.current_secondary_skill)
	clone.assigned_skill = _duplicate_resource(source.assigned_skill)
	clone.current_passive = _duplicate_resource(source.current_passive)
	clone.current_reaction = _duplicate_resource(source.current_reaction)
	clone.equipped_items = _duplicate_items(source.equipped_items)
	clone.skipped_items = _duplicate_items(source.skipped_items)
	clone.tactics = _duplicate_tactics(source.tactics)
	_rebind_cloned_loadout_resources(source, clone)
	clone.guard_armor = source.guard_armor
	clone.battle_armor = source.battle_armor
	clone.effect_usage_counts = source.effect_usage_counts.duplicate(true)
	clone.ability_cooldowns = source.ability_cooldowns.duplicate(true)
	clone.statuses = _duplicate_statuses(source.statuses)
	clone.next_status_instance_id = source.next_status_instance_id
	clone.temporary_modifiers = source.temporary_modifiers.duplicate(true)
	clone.next_temporary_modifier_id = source.next_temporary_modifier_id
	clone.dynamic_modifiers = source.dynamic_modifiers.duplicate(true)
	clone.counters = source.counters.duplicate(true)
	clone.attack_streak_target_id = source.attack_streak_target_id
	clone.attack_streak_count = source.attack_streak_count
	clone.attack_seals = source.attack_seals.duplicate()
	clone.armor_disabled = source.armor_disabled
	clone.deferred_damage = source.deferred_damage
	clone.fortification_actions_remaining = source.fortification_actions_remaining
	clone.fortification_pending_start = source.fortification_pending_start
	clone.attack_redirection_actions_remaining = source.attack_redirection_actions_remaining
	clone.attack_redirection_pending_start = source.attack_redirection_pending_start
	clone.energy_shield = source.energy_shield
	clone.damage_current_action_window = source.damage_current_action_window
	clone.damage_previous_action_window = source.damage_previous_action_window
	clone.enemy_action_healing_amount = source.enemy_action_healing_amount
	clone.enemy_action_healing_source = source.enemy_action_healing_source
	clone.prepared_base_attack_source = source.prepared_base_attack_source
	return clone


static func _rebind_cloned_loadout_resources(source, clone) -> void:
	if clone == null or clone.loadout == null:
		return
	clone.loadout.current_job = clone.current_job
	if source.loadout != null and source.loadout.equipped_skill != null:
		clone.loadout.equipped_skill = clone.assigned_skill
	if source.loadout != null and source.loadout.equipped_passive != null:
		clone.loadout.equipped_passive = clone.current_passive
	if source.loadout != null and source.loadout.equipped_reaction != null:
		clone.loadout.equipped_reaction = clone.current_reaction


static func _duplicate_resource(resource: Resource):
	if resource == null:
		return null
	return resource.duplicate(true)


static func _duplicate_items(items: Array[ItemDefinition]) -> Array[ItemDefinition]:
	var copies: Array[ItemDefinition] = []
	for item in items:
		copies.append(_duplicate_resource(item))
	return copies


static func _duplicate_tactics(source_tactics: Array[TacticDefinition]) -> Array[TacticDefinition]:
	var copies: Array[TacticDefinition] = []
	for tactic in source_tactics:
		copies.append(_duplicate_resource(tactic))
	return copies


static func _duplicate_statuses(source_statuses: Array[Dictionary]) -> Array[Dictionary]:
	var copies: Array[Dictionary] = []
	for source in source_statuses:
		var copy := source.duplicate(true)
		copy["definition"] = _duplicate_resource(source.get("definition", null))
		copies.append(copy)
	return copies
