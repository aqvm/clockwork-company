extends RefCounted
class_name UnitState

var unit_name := ""
var unit_id := ""
var campaign_unit_id := ""
var tags: Array[String] = []
var team := ""
var ancestry: Resource = null
var current_ancestry_feature: Resource = null
var max_hp := 1
var hp := 1
var physical_damage := 1
var magic_damage := 0
var armor := 0
var action_interval := 10
var next_action_time := 10
var slot_index := 0
var loadout: UnitLoadoutDefinition = null
var current_job: JobDefinition = null
var current_skill: SkillDefinition = null
var assigned_skill: SkillDefinition = null
var current_passive: PassiveDefinition = null
var current_reaction: ReactionDefinition = null
var equipped_items: Array[ItemDefinition] = []
var skipped_items: Array[ItemDefinition] = []
var tactics: Array[TacticDefinition] = []
var guard_armor := 0
var effect_usage_counts := {}
var ability_cooldowns := {}
var statuses: Array[Dictionary] = []
var next_status_instance_id := 1
var temporary_modifiers: Array[Dictionary] = []
var next_temporary_modifier_id := 1


func _init(definition: UnitDefinition = null, unit_slot_index: int = 0) -> void:
	if definition == null:
		return
	unit_name = definition.display_name
	unit_id = _build_unit_id(definition.team, unit_slot_index, definition.display_name)
	campaign_unit_id = String(definition.get_meta("campaign_unit_id", definition.display_name))
	tags = definition.tags.duplicate()
	team = definition.team
	ancestry = definition.ancestry
	current_ancestry_feature = ancestry.feature if ancestry != null else null
	max_hp = definition.max_hp
	physical_damage = definition.physical_damage
	magic_damage = definition.magic_damage
	armor = definition.armor
	action_interval = definition.action_interval
	slot_index = unit_slot_index
	loadout = definition.loadout
	equipped_items = []
	skipped_items = []

	if loadout != null:
		current_job = loadout.current_job
		tactics = loadout.tactics.duplicate()

	if current_job != null:
		current_skill = current_job.skill if _job_feature_unlocked(definition.job_progress, current_job, "skill") else null
		assigned_skill = loadout.equipped_skill if _feature_is_unlocked(definition.job_progress, loadout.equipped_skill, "skill") else null
		current_passive = loadout.equipped_passive if _feature_is_unlocked(definition.job_progress, loadout.equipped_passive, "passive") else null
		current_reaction = loadout.equipped_reaction if _feature_is_unlocked(definition.job_progress, loadout.equipped_reaction, "reaction") else null
		if current_job.default_tactic != null:
			tactics.append(current_job.default_tactic)

	_apply_ancestry_growth(definition.job_progress)
	_apply_job_progress_growth(definition.job_progress)

	for item in assigned_items():
		if _can_equip_item(item):
			equipped_items.append(item)
			_apply_item_stat_modifiers(item)
		else:
			skipped_items.append(item)

	hp = max_hp
	next_action_time = action_interval


func is_alive() -> bool:
	return hp > 0


func forecast_capable() -> bool:
	return current_passive != null and current_passive.passive_type == "Forecast"


func clone_runtime_state():
	var clone = get_script().new()
	clone.unit_name = unit_name
	clone.unit_id = unit_id
	clone.campaign_unit_id = campaign_unit_id
	clone.tags = tags.duplicate()
	clone.team = team
	clone.ancestry = _duplicate_resource(ancestry)
	clone.current_ancestry_feature = _duplicate_resource(current_ancestry_feature)
	clone.max_hp = max_hp
	clone.hp = hp
	clone.physical_damage = physical_damage
	clone.magic_damage = magic_damage
	clone.armor = armor
	clone.action_interval = action_interval
	clone.next_action_time = next_action_time
	clone.slot_index = slot_index
	clone.loadout = _duplicate_resource(loadout)
	clone.current_job = _duplicate_resource(current_job)
	clone.current_skill = _duplicate_resource(current_skill)
	clone.assigned_skill = _duplicate_resource(assigned_skill)
	clone.current_passive = _duplicate_resource(current_passive)
	clone.current_reaction = _duplicate_resource(current_reaction)
	clone.equipped_items = _duplicate_items(equipped_items)
	clone.skipped_items = _duplicate_items(skipped_items)
	clone.tactics = _duplicate_tactics(tactics)
	clone.guard_armor = guard_armor
	clone.effect_usage_counts = effect_usage_counts.duplicate(true)
	clone.ability_cooldowns = ability_cooldowns.duplicate(true)
	clone.statuses = _duplicate_statuses(statuses)
	clone.next_status_instance_id = next_status_instance_id
	clone.temporary_modifiers = temporary_modifiers.duplicate(true)
	clone.next_temporary_modifier_id = next_temporary_modifier_id
	return clone


func _duplicate_resource(resource: Resource):
	if resource == null:
		return null
	return resource.duplicate(true)


func _duplicate_items(items: Array[ItemDefinition]) -> Array[ItemDefinition]:
	var copies: Array[ItemDefinition] = []
	for item in items:
		copies.append(_duplicate_resource(item))
	return copies


func _duplicate_tactics(source_tactics: Array[TacticDefinition]) -> Array[TacticDefinition]:
	var copies: Array[TacticDefinition] = []
	for tactic in source_tactics:
		copies.append(_duplicate_resource(tactic))
	return copies


func _duplicate_statuses(source_statuses: Array[Dictionary]) -> Array[Dictionary]:
	var copies: Array[Dictionary] = []
	for source in source_statuses:
		var copy := source.duplicate(true)
		copy["definition"] = _duplicate_resource(source.get("definition", null))
		copies.append(copy)
	return copies


func add_status(status: Resource, source_name: String, duration_turns: int, is_permanent: bool) -> String:
	if status == null or status.display_name.is_empty():
		return "invalid"
	var existing := status_instance_by_name(status.display_name)
	if not existing.is_empty():
		if status.stacking_rule == "Ignore":
			return "ignored"
		existing["source_name"] = source_name
		existing["remaining_turns"] = max(int(existing.get("remaining_turns", 1)), max(1, duration_turns))
		existing["is_permanent"] = bool(existing.get("is_permanent", false)) or is_permanent
		if status.stacking_rule == "Intensify":
			var previous_stacks := int(existing.get("stack_count", 1))
			existing["stack_count"] = min(status.max_stacks, previous_stacks + 1)
			return "intensified" if int(existing["stack_count"]) > previous_stacks else "refreshed"
		return "refreshed"
	statuses.append({
		"instance_id": next_status_instance_id,
		"definition": status,
		"source_name": source_name,
		"remaining_turns": max(1, duration_turns),
		"is_permanent": is_permanent,
		"stack_count": 1,
		"damage_since_last_turn": 0,
	})
	next_status_instance_id += 1
	return "added"


func has_status(status_name: String) -> bool:
	return not status_instance_by_name(status_name).is_empty()


func status_instance_by_name(status_name: String) -> Dictionary:
	for instance: Dictionary in statuses:
		var definition: Resource = instance.get("definition", null)
		if definition != null and definition.display_name == status_name:
			return instance
	return {}


func status_instance(status_type: String) -> Dictionary:
	for instance: Dictionary in statuses:
		var definition: Resource = instance.get("definition", null)
		if definition != null and definition.status_type == status_type:
			return instance
	return {}


func status_names() -> Array[String]:
	var names: Array[String] = []
	for instance: Dictionary in statuses:
		var definition: Resource = instance.get("definition", null)
		if definition != null:
			names.append(definition.display_name)
	return names


func status_instance_ids() -> Array[int]:
	var ids: Array[int] = []
	for instance: Dictionary in statuses:
		ids.append(int(instance.get("instance_id", -1)))
	return ids


func consume_status_stack(status_name: String) -> int:
	for index in range(statuses.size()):
		var instance: Dictionary = statuses[index]
		var definition: Resource = instance.get("definition", null)
		if definition == null or definition.display_name != status_name:
			continue
		var remaining_stacks := int(instance.get("stack_count", 1)) - 1
		if remaining_stacks <= 0:
			statuses.remove_at(index)
			return 0
		instance["stack_count"] = remaining_stacks
		return remaining_stacks
	return 0


func remove_status(status_name: String) -> Dictionary:
	for index in range(statuses.size()):
		var instance: Dictionary = statuses[index]
		var definition: Resource = instance.get("definition", null)
		if definition == null or definition.display_name != status_name:
			continue
		statuses.remove_at(index)
		return instance
	return {}


func elapse_status_turns(instance_ids: Array[int]) -> Array[Dictionary]:
	var expired: Array[Dictionary] = []
	for index in range(statuses.size() - 1, -1, -1):
		var instance: Dictionary = statuses[index]
		var definition: Resource = instance.get("definition", null)
		if not instance_ids.has(int(instance.get("instance_id", -1))) or bool(instance.get("is_permanent", false)):
			continue
		if definition != null and not bool(definition.elapses_naturally):
			continue
		instance["remaining_turns"] = int(instance.get("remaining_turns", 1)) - 1
		if int(instance["remaining_turns"]) <= 0:
			expired.append(instance)
			statuses.remove_at(index)
	return expired


func status_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for instance: Dictionary in statuses:
		var definition: Resource = instance.get("definition", null)
		if definition == null:
			continue
		snapshots.append({
			"name": definition.display_name,
			"polarity": definition.polarity,
			"description": definition.description,
			"source_name": String(instance.get("source_name", "")),
			"remaining_turns": int(instance.get("remaining_turns", 0)),
			"is_permanent": bool(instance.get("is_permanent", false)),
			"stack_count": int(instance.get("stack_count", 1)),
			"damage_since_last_turn": int(instance.get("damage_since_last_turn", 0)),
		})
	return snapshots


func add_temporary_modifier(stat_name: String, amount: int, duration_turns: int, source_name: String) -> Dictionary:
	if amount == 0:
		return {}
	var previous_value := stat_value(stat_name)
	_apply_stat_delta(stat_name, amount)
	var applied_amount := stat_value(stat_name) - previous_value
	if applied_amount == 0:
		return {}
	var modifier := {
		"instance_id": next_temporary_modifier_id,
		"stat": stat_name,
		"amount": applied_amount,
		"remaining_turns": max(1, duration_turns),
		"source_name": source_name,
	}
	next_temporary_modifier_id += 1
	temporary_modifiers.append(modifier)
	return modifier


func elapse_temporary_modifiers() -> Array[Dictionary]:
	var expired: Array[Dictionary] = []
	for index in range(temporary_modifiers.size() - 1, -1, -1):
		var modifier: Dictionary = temporary_modifiers[index]
		modifier["remaining_turns"] = int(modifier.get("remaining_turns", 1)) - 1
		if int(modifier["remaining_turns"]) > 0:
			continue
		_apply_stat_delta(String(modifier.get("stat", "")), -int(modifier.get("amount", 0)))
		expired.append(modifier)
		temporary_modifiers.remove_at(index)
	return expired


func temporary_modifier_snapshots() -> Array[Dictionary]:
	return temporary_modifiers.duplicate(true)


func stat_value(stat_name: String) -> int:
	match stat_name:
		"Max HP":
			return max_hp
		"Physical Damage":
			return physical_damage
		"Magic Damage":
			return magic_damage
		"Armor":
			return armor
		"Action Interval":
			return action_interval
	return 0


func _apply_stat_delta(stat_name: String, amount: int) -> void:
	match stat_name:
		"Max HP":
			max_hp = max(1, max_hp + amount)
			hp = min(hp, max_hp)
		"Physical Damage":
			physical_damage = max(1, physical_damage + amount)
		"Magic Damage":
			magic_damage = max(0, magic_damage + amount)
		"Armor":
			armor = max(0, armor + amount)
		"Action Interval":
			action_interval = max(1, action_interval + amount)


func total_armor() -> int:
	return armor + guard_armor


func current_job_name() -> String:
	if current_job == null:
		return "No Job"
	return current_job.display_name


func loadout_name() -> String:
	if loadout == null:
		return "No Loadout"
	return loadout.display_name


func job_effect() -> String:
	if current_passive != null and not current_passive.display_name.is_empty():
		return current_passive.display_name
	return "none"


func ancestry_name() -> String:
	if ancestry == null or ancestry.display_name.is_empty():
		return "Unknown"
	return ancestry.display_name


func ancestry_feature_name() -> String:
	if current_ancestry_feature == null or current_ancestry_feature.display_name.is_empty():
		return "none"
	return current_ancestry_feature.display_name


func skill_name() -> String:
	if current_skill == null:
		return "none"
	return current_skill.display_name


func assigned_skill_name() -> String:
	if assigned_skill == null:
		return "none"
	return assigned_skill.display_name


func reaction_name() -> String:
	if current_reaction == null:
		return "none"
	return current_reaction.display_name


func tick_ability_cooldowns() -> void:
	for key in ability_cooldowns.keys():
		ability_cooldowns[key] = max(0, int(ability_cooldowns[key]) - 1)


func ability_is_ready(key: String) -> bool:
	return int(ability_cooldowns.get(key, 0)) <= 0


func start_ability_cooldown(key: String, cooldown_turns: int) -> void:
	if cooldown_turns <= 0:
		return
	ability_cooldowns[key] = cooldown_turns


func assigned_items() -> Array[ItemDefinition]:
	var items: Array[ItemDefinition] = []
	if loadout == null:
		return items

	for item in [loadout.weapon, loadout.armor, loadout.helmet, loadout.trinket]:
		if item != null:
			items.append(item)

	return items


func _apply_item_stat_modifiers(item: ItemDefinition) -> void:
	max_hp = max(1, max_hp + item.max_hp_modifier)
	physical_damage = max(1, physical_damage + item.physical_damage_modifier)
	magic_damage = max(0, magic_damage + item.magic_damage_modifier)
	armor = max(0, armor + item.armor_modifier)
	action_interval = max(1, action_interval + item.action_interval_modifier)


func _apply_ancestry_growth(job_progress: Array[JobProgressDefinition]) -> void:
	if ancestry == null:
		return
	var total_level := 0
	for progress: JobProgressDefinition in job_progress:
		if progress != null:
			total_level += clamp(progress.level, 0, 5)
	if total_level <= 0:
		return
	max_hp = max(1, max_hp + ancestry.max_hp_growth * total_level)
	physical_damage = max(1, physical_damage + ancestry.physical_damage_growth * total_level)
	magic_damage = max(0, magic_damage + ancestry.magic_damage_growth * total_level)
	armor = max(0, armor + ancestry.armor_growth * total_level)
	action_interval = max(1, action_interval + ancestry.action_interval_growth * total_level)


func _apply_job_progress_growth(job_progress: Array[JobProgressDefinition]) -> void:
	for progress: JobProgressDefinition in job_progress:
		if progress == null or progress.job == null or progress.level <= 0:
			continue
		var level: int = clamp(progress.level, 0, 5)
		max_hp = max(1, max_hp + progress.job.max_hp_growth * level)
		physical_damage = max(1, physical_damage + progress.job.physical_damage_growth * level)
		magic_damage = max(0, magic_damage + progress.job.magic_damage_growth * level)
		armor = max(0, armor + progress.job.armor_growth * level)
		action_interval = max(1, action_interval + progress.job.action_interval_growth * level)


func _can_equip_item(item: ItemDefinition) -> bool:
	if item == null:
		return false

	if item.slot == "Weapon":
		return not _slot_forbidden("forbid_weapon")
	if item.slot == "Armor":
		return not _slot_forbidden("forbid_armor")
	if item.slot == "Helmet":
		return not _slot_forbidden("forbid_helmet")
	if item.slot == "Trinket":
		return not _slot_forbidden("forbid_trinket")

	return false


func _slot_forbidden(property_name: String) -> bool:
	return (current_job != null and bool(current_job.get(property_name))) or (ancestry != null and bool(ancestry.get(property_name)))


func _job_feature_unlocked(job_progress: Array[JobProgressDefinition], job: JobDefinition, feature_type: String) -> bool:
	for progress in job_progress:
		if progress == null or progress.job != job:
			continue
		if feature_type == "skill":
			return progress.skill_unlocked
		if feature_type == "passive":
			return progress.passive_unlocked
		if feature_type == "reaction":
			return progress.reaction_unlocked
	return false


func _feature_is_unlocked(job_progress: Array[JobProgressDefinition], feature: Resource, feature_type: String) -> bool:
	if feature == null:
		return false
	for progress in job_progress:
		if progress == null or progress.job == null:
			continue
		if feature_type == "skill" and progress.job.skill == feature:
			return progress.skill_unlocked
		if feature_type == "passive" and progress.job.passive == feature:
			return progress.passive_unlocked
		if feature_type == "reaction" and progress.job.reaction == feature:
			return progress.reaction_unlocked
	return false


func _build_unit_id(unit_team: String, unit_slot_index: int, display_name: String) -> String:
	var safe_name := display_name.to_lower().replace(" ", "_")
	return "%s_%d_%s" % [unit_team.to_lower(), unit_slot_index, safe_name]
