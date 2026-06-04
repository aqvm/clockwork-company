extends RefCounted
class_name RunState

const CombatConstantsScript := preload("res://scripts/combat/combat_constants.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const UnitDefinitionScript := preload("res://scripts/data/unit_definition.gd")
const UnitLoadoutDefinitionScript := preload("res://scripts/data/unit_loadout_definition.gd")
const ItemDefinitionScript := preload("res://scripts/data/item_definition.gd")
const JobProgressDefinitionScript := preload("res://scripts/data/job_progress_definition.gd")
const ScenarioRunnerScript := preload("res://scripts/scenario/scenario_runner.gd")
const STATUS_ACTIVE := "active"
const STATUS_REWARD := "reward"
const STATUS_EQUIPMENT := "equipment"
const STATUS_WON := "won"
const STATUS_LOST := "lost"
const FIGHT_COUNT := 5
const MAX_UNIT_JOB_LEVELS := 5
const JOB_XP_PER_LEVEL := 1
const ENCOUNTER_PATHS := [
	"res://resources/encounters/phase7_fight_01_street_corner.tres",
	"res://resources/encounters/phase7_fight_02_toll_gate.tres",
	"res://resources/encounters/phase7_fight_03_rooftop.tres",
	"res://resources/encounters/phase7_fight_04_vault_annex.tres",
	"res://resources/encounters/phase7_fight_05_clocktower.tres",
]
const REWARD_PATHS := [
	"res://resources/rewards/guardplate_for_alden.tres",
	"res://resources/rewards/honed_blade_for_mira.tres",
	"res://resources/rewards/focus_lens_for_sol.tres",
]

var fight_index := 0
var status := STATUS_ACTIVE
var ally_definitions: Array[UnitDefinition] = []
var encounter_definitions: Array = []
var reward_definitions: Array = []
var inventory_items: Array[ItemDefinition] = []
var reward_history: Array[String] = []
var last_result_summary := ""
var loss_test_mode := false
var active_scenario: Resource = null
var scenario_runner = null


func start(enabled_mod_pack_ids: Array[String], should_force_loss := false) -> void:
	_start_common(enabled_mod_pack_ids, should_force_loss, [])
	encounter_definitions = _load_encounter_definitions()
	reward_definitions = _load_reward_definitions()


func start_scenario(enabled_mod_pack_ids: Array[String], scenario: Resource, should_force_loss := false, starting_allies: Array = []) -> void:
	_start_common(enabled_mod_pack_ids, should_force_loss, starting_allies)
	active_scenario = scenario
	scenario_runner = ScenarioRunnerScript.new()
	scenario_runner.start(scenario)
	encounter_definitions = scenario.encounters.duplicate() if scenario != null else []
	reward_definitions = scenario.rewards.duplicate() if scenario != null else []
	if reward_definitions.is_empty():
		reward_definitions = _load_reward_definitions()


func _start_common(enabled_mod_pack_ids: Array[String], should_force_loss := false, starting_allies: Array = []) -> void:
	fight_index = 0
	status = STATUS_ACTIVE
	inventory_items.clear()
	reward_history.clear()
	last_result_summary = ""
	loss_test_mode = should_force_loss
	active_scenario = null
	scenario_runner = null

	ally_definitions.clear()
	if starting_allies.is_empty():
		for definition: UnitDefinition in JsonContentLoaderScript.load_demo_unit_definitions(enabled_mod_pack_ids):
			var copy := _clone_unit_definition(definition)
			if copy.team == CombatConstantsScript.TEAM_ALLY:
				ally_definitions.append(copy)
	else:
		for definition: UnitDefinition in starting_allies:
			var copy := _clone_unit_definition(definition)
			copy.team = CombatConstantsScript.TEAM_ALLY
			ally_definitions.append(copy)

	if loss_test_mode:
		for ally in ally_definitions:
			ally.max_hp = 1
			ally.physical_damage = 1
			ally.magic_damage = 0
			ally.armor = 0


func current_fight_number() -> int:
	return fight_index + 1


func current_fight_title() -> String:
	var suffix := " (loss test)" if loss_test_mode else ""
	if active_scenario != null:
		return "%s encounter %d of %d: %s%s" % [active_scenario.display_name, current_fight_number(), current_fight_count(), current_encounter_name(), suffix]
	return "Phase 7 run fight %d of %d: %s%s" % [current_fight_number(), current_fight_count(), current_encounter_name(), suffix]


func current_fight_count() -> int:
	if not encounter_definitions.is_empty():
		return encounter_definitions.size()
	return FIGHT_COUNT


func current_encounter_name() -> String:
	var encounter = _current_encounter()
	if encounter == null:
		return "Missing Encounter"
	return encounter.display_name


func build_current_fight_definitions() -> Array[UnitDefinition]:
	var definitions: Array[UnitDefinition] = []
	for ally in ally_definitions:
		definitions.append(_clone_unit_definition(ally))
	var encounter = _current_encounter()
	if encounter == null:
		return definitions
	for enemy in encounter.enemy_units:
		var enemy_copy := _clone_unit_definition(enemy)
		_apply_loss_test_enemy_pressure(enemy_copy)
		definitions.append(enemy_copy)
	return definitions


func complete_fight(report: Dictionary) -> void:
	var winner := String(report.get("winner", "None"))
	if winner != CombatConstantsScript.TEAM_ALLY:
		status = STATUS_LOST
		last_result_summary = "Run lost on fight %d. The enemy team survived the battle." % current_fight_number()
		return

	if fight_index >= current_fight_count() - 1:
		_award_current_job_levels()
		if scenario_runner != null:
			scenario_runner.complete_current_encounter()
		status = STATUS_WON
		if active_scenario != null:
			last_result_summary = "Scenario complete: %s. %s" % [active_scenario.display_name, active_scenario.story_outro]
		else:
			last_result_summary = "Run won after fight %d. The party cleared the five-fight slice." % current_fight_number()
		return

	_award_current_job_levels()
	status = STATUS_REWARD
	last_result_summary = "Fight %d won. Choose one reward before fight %d." % [current_fight_number(), current_fight_number() + 1]


func reward_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for reward in reward_definitions:
		if reward == null or reward.item == null:
			continue
		options.append({
			"label": reward.display_name,
			"description": reward.description,
			"unit_name": reward.target_unit_name,
			"item": reward.item,
			"item_name": reward.item.display_name,
			"resource": reward,
		})
	return options


func apply_reward(reward_index: int) -> void:
	var options := reward_options()
	if reward_index < 0 or reward_index >= options.size():
		return

	var reward: Dictionary = options[reward_index]
	var item: ItemDefinition = _clone_item_definition(reward["item"])
	inventory_items.append(item)
	reward_history.append("%s gained after fight %d" % [item.display_name, current_fight_number()])
	fight_index += 1
	if scenario_runner != null:
		scenario_runner.progress.current_encounter_index = fight_index
	status = STATUS_EQUIPMENT
	last_result_summary = "Reward gained: %s. Equip inventory before fight %d, or continue as-is." % [String(reward["label"]), current_fight_number()]


func continue_to_next_fight() -> void:
	if status != STATUS_EQUIPMENT:
		return

	status = STATUS_ACTIVE
	last_result_summary = "Fight %d is ready." % current_fight_number()


func equip_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for item_index in inventory_items.size():
		var item := inventory_items[item_index]
		for ally in ally_definitions:
			if not _can_equip_item(ally, item):
				continue
			options.append({
				"item_index": item_index,
				"unit_name": ally.display_name,
				"label": "Equip %s -> %s" % [item.display_name, ally.display_name],
			})
	return options


func equip_inventory_item(item_index: int, unit_name: String) -> void:
	if item_index < 0 or item_index >= inventory_items.size():
		return

	var target := _find_ally(unit_name)
	if target == null:
		return

	var item := inventory_items[item_index]
	if not _can_equip_item(target, item):
		last_result_summary = "%s cannot equip %s." % [target.display_name, item.display_name]
		return

	var loadout := _ensure_loadout_clone(target)
	var replaced_item: ItemDefinition = null
	if item.slot == "Weapon":
		replaced_item = loadout.weapon
		loadout.weapon = item
	elif item.slot == "Armor":
		replaced_item = loadout.armor
		loadout.armor = item
	elif item.slot == "Helmet":
		replaced_item = loadout.helmet
		loadout.helmet = item
	elif item.slot == "Trinket":
		replaced_item = loadout.trinket
		loadout.trinket = item

	inventory_items.remove_at(item_index)
	if replaced_item != null:
		inventory_items.append(_clone_item_definition(replaced_item))
		last_result_summary = "Equipped %s on %s. %s returned to inventory." % [item.display_name, target.display_name, replaced_item.display_name]
	else:
		last_result_summary = "Equipped %s on %s." % [item.display_name, target.display_name]


func status_lines() -> Array[String]:
	var lines: Array[String] = []
	if scenario_runner != null:
		for scenario_line in scenario_runner.status_lines():
			lines.append(scenario_line)
	lines.append("Run status: %s" % status.capitalize())
	lines.append("Current fight: %d/%d" % [current_fight_number(), current_fight_count()])
	lines.append("Encounter: %s" % current_encounter_name())
	var encounter = _current_encounter()
	if encounter != null and not encounter.scout_text.is_empty():
		lines.append("Scout note: %s" % encounter.scout_text)
	if not last_result_summary.is_empty():
		lines.append(last_result_summary)
	if reward_history.is_empty():
		lines.append("Reward history: none yet")
	else:
		lines.append("Reward history:")
		for entry in reward_history:
			lines.append("- %s" % entry)
	if inventory_items.is_empty():
		lines.append("Inventory: empty")
	else:
		lines.append("Inventory:")
		for item in inventory_items:
			lines.append("- %s (%s)" % [item.display_name, item.slot])
	lines.append("Party equipment:")
	for ally in ally_definitions:
		lines.append("- %s: %s" % [ally.display_name, _equipment_summary(ally)])
	lines.append("Job progress:")
	for ally in ally_definitions:
		lines.append("- %s: %s" % [ally.display_name, _job_progress_summary(ally)])
	return lines


func _load_encounter_definitions() -> Array:
	var encounters: Array = []
	for path in ENCOUNTER_PATHS:
		var encounter = load(path)
		if encounter != null:
			encounters.append(encounter)
	assert(encounters.size() == FIGHT_COUNT, "Phase 7 run requires exactly %d encounters." % FIGHT_COUNT)
	return encounters


func _load_reward_definitions() -> Array:
	var rewards: Array = []
	for path in REWARD_PATHS:
		var reward = load(path)
		if reward != null:
			rewards.append(reward)
	assert(rewards.size() == REWARD_PATHS.size(), "Phase 7 run reward list is missing one or more rewards.")
	return rewards


func _current_encounter():
	if encounter_definitions.is_empty():
		return null
	var safe_index: int = clamp(fight_index, 0, encounter_definitions.size() - 1)
	return encounter_definitions[safe_index]


func _apply_loss_test_enemy_pressure(enemy: UnitDefinition) -> void:
	if not loss_test_mode:
		return

	enemy.max_hp += 30
	enemy.physical_damage += 10
	enemy.armor += 3
	enemy.action_interval = max(1, enemy.action_interval - 3)


func _award_current_job_levels() -> void:
	for ally in ally_definitions:
		if ally.loadout == null or ally.loadout.current_job == null:
			continue
		if _total_job_levels(ally) >= MAX_UNIT_JOB_LEVELS:
			continue
		var progress := _ensure_job_progress(ally, ally.loadout.current_job)
		progress.xp += 1
		while progress.xp >= JOB_XP_PER_LEVEL and progress.level < 5 and _total_job_levels(ally) < MAX_UNIT_JOB_LEVELS:
			progress.xp -= JOB_XP_PER_LEVEL
			progress.level += 1
			_apply_job_unlocks(progress)


func _ensure_job_progress(unit: UnitDefinition, job: JobDefinition) -> JobProgressDefinition:
	for progress: JobProgressDefinition in unit.job_progress:
		if progress != null and progress.job == job:
			return progress
	var progress: JobProgressDefinition = JobProgressDefinitionScript.new()
	progress.job = job
	unit.job_progress.append(progress)
	return progress


func _apply_job_unlocks(progress: JobProgressDefinition) -> void:
	var job := progress.job
	if job == null:
		return
	if progress.level >= job.skill_unlock_level:
		progress.skill_unlocked = true
	if progress.level >= job.passive_unlock_level:
		progress.passive_unlocked = true
	if progress.level >= job.reaction_unlock_level:
		progress.reaction_unlocked = true
	progress.pending_unlock_choice = false


func _total_job_levels(unit: UnitDefinition) -> int:
	var total := 0
	for progress: JobProgressDefinition in unit.job_progress:
		if progress != null:
			total += progress.level
	return total


func _job_progress_summary(unit: UnitDefinition) -> String:
	if unit.job_progress.is_empty():
		return "none"
	var parts: Array[String] = []
	for progress: JobProgressDefinition in unit.job_progress:
		if progress == null or progress.job == null:
			continue
		var unlocks: Array[String] = []
		if progress.skill_unlocked:
			unlocks.append("skill")
		if progress.passive_unlocked:
			unlocks.append("passive")
		if progress.reaction_unlocked:
			unlocks.append("reaction")
		var unlock_text := "no unlocks" if unlocks.is_empty() else _join_string_parts(unlocks, ",")
		parts.append("%s L%d XP%d [%s]" % [progress.job.display_name, progress.level, progress.xp, unlock_text])
	if parts.is_empty():
		return "none"
	return _join_string_parts(parts, "; ")


func _find_ally(unit_name: String) -> UnitDefinition:
	for ally in ally_definitions:
		if ally.display_name == unit_name:
			return ally
	return null


func _can_equip_item(unit: UnitDefinition, item: ItemDefinition) -> bool:
	if item == null:
		return false
	if unit.loadout == null or unit.loadout.current_job == null:
		return true
	var job := unit.loadout.current_job
	if item.slot == "Weapon":
		return not job.forbid_weapon
	if item.slot == "Armor":
		return not job.forbid_armor
	if item.slot == "Helmet":
		return not job.forbid_helmet
	if item.slot == "Trinket":
		return not job.forbid_trinket
	return false


func _equipment_summary(unit: UnitDefinition) -> String:
	if unit.loadout == null:
		return "no loadout"
	return "weapon %s, armor %s, helmet %s, trinket %s" % [
		_item_name_or_empty(unit.loadout.weapon),
		_item_name_or_empty(unit.loadout.armor),
		_item_name_or_empty(unit.loadout.helmet),
		_item_name_or_empty(unit.loadout.trinket),
	]


func _item_name_or_empty(item: ItemDefinition) -> String:
	if item == null:
		return "none"
	return item.display_name


func _ensure_loadout_clone(unit: UnitDefinition) -> UnitLoadoutDefinition:
	if unit.loadout == null:
		unit.loadout = UnitLoadoutDefinitionScript.new()
		unit.loadout.display_name = "%s Run Loadout" % unit.display_name
	else:
		unit.loadout = _clone_loadout_definition(unit.loadout)
	return unit.loadout


func _clone_unit_definition(source: UnitDefinition) -> UnitDefinition:
	var copy: UnitDefinition = UnitDefinitionScript.new()
	copy.display_name = source.display_name
	copy.tags = source.tags.duplicate()
	copy.team = source.team
	copy.ancestry = source.ancestry
	copy.max_hp = source.max_hp
	copy.physical_damage = source.physical_damage
	copy.magic_damage = source.magic_damage
	copy.armor = source.armor
	copy.action_interval = source.action_interval
	copy.job_progress = _clone_job_progress(source.job_progress)
	copy.loadout = _clone_loadout_definition(source.loadout) if source.loadout != null else null
	return copy


func _clone_loadout_definition(source: UnitLoadoutDefinition) -> UnitLoadoutDefinition:
	var copy: UnitLoadoutDefinition = UnitLoadoutDefinitionScript.new()
	copy.display_name = source.display_name
	copy.current_job = source.current_job
	copy.equipped_skill = source.equipped_skill
	copy.equipped_passive = source.equipped_passive
	copy.equipped_reaction = source.equipped_reaction
	copy.weapon = _clone_item_definition(source.weapon) if source.weapon != null else null
	copy.armor = _clone_item_definition(source.armor) if source.armor != null else null
	copy.helmet = _clone_item_definition(source.helmet) if source.helmet != null else null
	copy.trinket = _clone_item_definition(source.trinket) if source.trinket != null else null
	copy.tactics = source.tactics.duplicate()
	return copy


func _clone_item_definition(source: ItemDefinition) -> ItemDefinition:
	var copy: ItemDefinition = ItemDefinitionScript.new()
	copy.display_name = source.display_name
	copy.tags = source.tags.duplicate()
	copy.slot = source.slot
	copy.max_hp_modifier = source.max_hp_modifier
	copy.physical_damage_modifier = source.physical_damage_modifier
	copy.magic_damage_modifier = source.magic_damage_modifier
	copy.armor_modifier = source.armor_modifier
	copy.action_interval_modifier = source.action_interval_modifier
	copy.effects = source.effects.duplicate()
	return copy


func _clone_job_progress(source: Array[JobProgressDefinition]) -> Array[JobProgressDefinition]:
	var results: Array[JobProgressDefinition] = []
	for progress: JobProgressDefinition in source:
		if progress == null:
			continue
		var copy: JobProgressDefinition = JobProgressDefinitionScript.new()
		copy.job = progress.job
		copy.level = progress.level
		copy.xp = progress.xp
		copy.skill_unlocked = progress.skill_unlocked
		copy.passive_unlocked = progress.passive_unlocked
		copy.reaction_unlocked = progress.reaction_unlocked
		copy.pending_unlock_choice = progress.pending_unlock_choice
		results.append(copy)
	return results


func _join_string_parts(parts: Array[String], separator: String) -> String:
	var text := ""
	for part in parts:
		if not text.is_empty():
			text += separator
		text += part
	return text
