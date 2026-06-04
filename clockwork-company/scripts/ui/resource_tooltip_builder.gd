extends RefCounted
class_name ResourceTooltipBuilder


static func text_for_resource(resource) -> String:
	if resource == null:
		return ""
	if resource is UnitDefinition:
		return _unit_text(resource)
	if resource is UnitLoadoutDefinition:
		return _loadout_text(resource)
	if resource is ItemDefinition:
		return _item_text(resource)
	if resource is JobDefinition:
		return _job_text(resource)
	if resource is SkillDefinition:
		return _skill_text(resource)
	if resource is PassiveDefinition:
		return _passive_text(resource)
	if resource is ReactionDefinition:
		return _reaction_text(resource)
	if resource is TacticDefinition:
		return _tactic_text(resource)
	if resource is EffectDefinition:
		return _effect_text(resource)
	if resource is EncounterDefinition:
		return _encounter_text(resource)
	if resource is RewardDefinition:
		return _reward_text(resource)
	return _generic_resource_text(resource)


static func text_for_runtime_unit(snapshot: Dictionary) -> String:
	var name: String = String(snapshot.get("name", "Unit"))
	var team: String = String(snapshot.get("team", ""))
	var max_hp: int = int(snapshot.get("max_hp", 1))
	var hp: int = int(snapshot.get("hp", max_hp))
	var action_interval: int = int(snapshot.get("action_interval", 1))
	var next_action_time: float = float(snapshot.get("next_action_time", 0.0))
	var display_time: float = float(snapshot.get("display_time", 0.0))
	var remaining: float = max(0.0, next_action_time - display_time)
	return "%s\nTeam: %s\nHP: %d/%d\nAction interval: %d\nNext action in: %.1f" % [name, team, hp, max_hp, action_interval, remaining]


static func _unit_text(unit: UnitDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(unit))
	lines.append("Team: %s" % unit.team)
	lines.append("Stats: HP %d, physical %d, magic %d, armor %d, interval %d" % [unit.max_hp, unit.physical_damage, unit.magic_damage, unit.armor, unit.action_interval])
	lines.append("Tags: %s" % _join(unit.tags))
	lines.append("Ancestry: %s" % _name_or_none(unit.ancestry))
	lines.append("Loadout: %s" % _name_or_none(unit.loadout))
	if not unit.job_progress.is_empty():
		var progress_parts: Array[String] = []
		for progress in unit.job_progress:
			if progress != null and progress.job != null:
				progress_parts.append("%s L%d XP%d" % [progress.job.display_name, progress.level, progress.xp])
		lines.append("Job progress: %s" % _join(progress_parts, "; "))
	return _join(lines, "\n")


static func _loadout_text(loadout: UnitLoadoutDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(loadout))
	lines.append("Current job: %s" % _name_or_none(loadout.current_job))
	lines.append("Skill: %s" % _name_or_none(loadout.equipped_skill if loadout.equipped_skill != null else loadout.current_job.skill if loadout.current_job != null else null))
	lines.append("Passive: %s" % _name_or_none(loadout.equipped_passive if loadout.equipped_passive != null else loadout.current_job.passive if loadout.current_job != null else null))
	lines.append("Reaction: %s" % _name_or_none(loadout.equipped_reaction if loadout.equipped_reaction != null else loadout.current_job.reaction if loadout.current_job != null else null))
	lines.append("Weapon: %s" % _name_or_none(loadout.weapon))
	lines.append("Armor: %s" % _name_or_none(loadout.armor))
	lines.append("Helmet: %s" % _name_or_none(loadout.helmet))
	lines.append("Trinket: %s" % _name_or_none(loadout.trinket))
	var tactic_names: Array[String] = []
	for tactic in loadout.tactics:
		if tactic != null:
			tactic_names.append(tactic.display_name)
	lines.append("Tactics: %s" % _join(tactic_names))
	return _join(lines, "\n")


static func _item_text(item: ItemDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(item))
	lines.append("Slot: %s" % item.slot)
	lines.append("Tags: %s" % _join(item.tags))
	lines.append("Stats: %s" % _item_stats(item))
	if item.effects.is_empty():
		lines.append("Effects: none")
	else:
		lines.append("Effects:")
		for effect in item.effects:
			if effect != null:
				lines.append("- %s" % _effect_summary(effect))
	return _join(lines, "\n")


static func _job_text(job: JobDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(job))
	lines.append("Tags: %s" % _join(job.tags))
	lines.append("Growth: HP %+d, physical %+d, magic %+d, armor %+d, interval %+d" % [job.max_hp_growth, job.physical_damage_growth, job.magic_damage_growth, job.armor_growth, job.action_interval_growth])
	var forbids: Array[String] = []
	if job.forbid_weapon:
		forbids.append("weapon")
	if job.forbid_armor:
		forbids.append("armor")
	if job.forbid_helmet:
		forbids.append("helmet")
	if job.forbid_trinket:
		forbids.append("trinket")
	lines.append("Forbids: %s" % _join(forbids))
	lines.append("Skill: %s" % _name_or_none(job.skill))
	lines.append("Passive: %s" % _name_or_none(job.passive))
	lines.append("Reaction: %s" % _name_or_none(job.reaction))
	lines.append("Default tactic: %s" % _name_or_none(job.default_tactic))
	lines.append("Unlock levels: skill %d, passive %d, reaction %d" % [job.skill_unlock_level, job.passive_unlock_level, job.reaction_unlock_level])
	return _join(lines, "\n")


static func _skill_text(skill: SkillDefinition) -> String:
	return "%s\nTags: %s\nAction: %s\nTarget: %s\nAmount modifier: %+d" % [_title(skill), _join(skill.tags), skill.action, skill.default_target, skill.amount_modifier]


static func _passive_text(passive: PassiveDefinition) -> String:
	return "%s\nTags: %s\nType: %s\nAmount: %+d\nCooldown turns: %d" % [_title(passive), _join(passive.tags), passive.passive_type, passive.amount, passive.cooldown_turns]


static func _reaction_text(reaction: ReactionDefinition) -> String:
	return "%s\nTags: %s\nTrigger: %s\nCondition: %s\nType: %s\nAmount: %+d\nThreshold: %d%%\nCooldown turns: %d" % [_title(reaction), _join(reaction.tags), reaction.trigger, reaction.condition, reaction.reaction_type, reaction.amount, reaction.threshold_percent, reaction.cooldown_turns]


static func _tactic_text(tactic: TacticDefinition) -> String:
	return "%s\nTags: %s\nRule: %s -> %s -> %s" % [_title(tactic), _join(tactic.tags), tactic.condition, tactic.action, tactic.target]


static func _effect_text(effect: EffectDefinition) -> String:
	return "%s\n%s" % [_title(effect), _effect_summary(effect)]


static func _encounter_text(encounter: EncounterDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(encounter))
	if not encounter.scout_text.is_empty():
		lines.append("Scout note: %s" % encounter.scout_text)
	var enemies: Array[String] = []
	for enemy in encounter.enemy_units:
		if enemy != null:
			enemies.append(enemy.display_name)
	lines.append("Enemies: %s" % _join(enemies))
	return _join(lines, "\n")


static func _reward_text(reward: RewardDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(reward))
	if not reward.description.is_empty():
		lines.append(reward.description)
	if not reward.target_unit_name.is_empty():
		lines.append("Suggested unit: %s" % reward.target_unit_name)
	lines.append("Item: %s" % _name_or_none(reward.item))
	return _join(lines, "\n")


static func _generic_resource_text(resource) -> String:
	var lines: Array[String] = []
	lines.append(_title(resource))
	if "description" in resource and not String(resource.description).is_empty():
		lines.append(String(resource.description))
	if "story_intro" in resource and not String(resource.story_intro).is_empty():
		lines.append(String(resource.story_intro))
	if "tags" in resource:
		lines.append("Tags: %s" % _join(resource.tags))
	if not resource.resource_path.is_empty():
		lines.append(resource.resource_path)
	return _join(lines, "\n")


static func _effect_summary(effect: EffectDefinition) -> String:
	var limit_text := ", once per battle" if effect.once_per_battle else ""
	return "%s when %s: %s %d to %s%s" % [effect.effect_type, effect.trigger, effect.condition, effect.amount, effect.target_selector, limit_text]


static func _item_stats(item: ItemDefinition) -> String:
	var parts: Array[String] = []
	_append_amount(parts, "HP", item.max_hp_modifier)
	_append_amount(parts, "physical", item.physical_damage_modifier)
	_append_amount(parts, "magic", item.magic_damage_modifier)
	_append_amount(parts, "armor", item.armor_modifier)
	_append_amount(parts, "interval", item.action_interval_modifier)
	return _join(parts) if not parts.is_empty() else "no stat changes"


static func _append_amount(parts: Array[String], label: String, amount: int) -> void:
	if amount == 0:
		return
	parts.append("%s %+d" % [label, amount])


static func _title(resource) -> String:
	if resource != null and "display_name" in resource and not String(resource.display_name).is_empty():
		return String(resource.display_name)
	return "Resource"


static func _name_or_none(resource) -> String:
	if resource == null:
		return "none"
	if "display_name" in resource and not String(resource.display_name).is_empty():
		return String(resource.display_name)
	return "Resource"


static func _join(values: Array, separator := ", ") -> String:
	if values.is_empty():
		return "none"
	var text := ""
	for value in values:
		var value_text := String(value)
		if value_text.is_empty():
			continue
		if not text.is_empty():
			text += separator
		text += value_text
	return "none" if text.is_empty() else text
