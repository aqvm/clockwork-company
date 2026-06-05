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
var current_passive: PassiveDefinition = null
var current_reaction: ReactionDefinition = null
var equipped_items: Array[ItemDefinition] = []
var skipped_items: Array[ItemDefinition] = []
var tactics: Array[TacticDefinition] = []
var guard_armor := 0
var effect_usage_counts := {}
var ability_cooldowns := {}


func _init(definition: UnitDefinition, unit_slot_index: int) -> void:
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
		current_skill = loadout.equipped_skill if loadout.equipped_skill != null else current_job.skill
		current_passive = loadout.equipped_passive if loadout.equipped_passive != null else current_job.passive
		current_reaction = loadout.equipped_reaction if loadout.equipped_reaction != null else current_job.reaction
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

	if current_job == null:
		return true

	if item.slot == "Weapon":
		return not current_job.forbid_weapon

	if item.slot == "Armor":
		return not current_job.forbid_armor

	if item.slot == "Helmet":
		return not current_job.forbid_helmet

	if item.slot == "Trinket":
		return not current_job.forbid_trinket

	return false


func _build_unit_id(unit_team: String, unit_slot_index: int, display_name: String) -> String:
	var safe_name := display_name.to_lower().replace(" ", "_")
	return "%s_%d_%s" % [unit_team.to_lower(), unit_slot_index, safe_name]
