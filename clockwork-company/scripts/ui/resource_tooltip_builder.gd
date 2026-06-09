extends RefCounted
class_name ResourceTooltipBuilder


static func text_for_resource(resource) -> String:
	if resource == null:
		return ""
	var text := ""
	if resource is UnitDefinition:
		text = _unit_text(resource)
	elif resource is UnitLoadoutDefinition:
		text = _loadout_text(resource)
	elif resource is ItemDefinition:
		text = _item_text(resource)
	elif resource is AncestryDefinition:
		text = _ancestry_text(resource)
	elif resource is JobDefinition:
		text = _job_text(resource)
	elif resource is SkillDefinition:
		text = _skill_text(resource)
	elif resource is PassiveDefinition:
		text = _passive_text(resource)
	elif resource is ReactionDefinition:
		text = _reaction_text(resource)
	elif resource is TacticDefinition:
		text = _tactic_text(resource)
	elif resource is EffectDefinition:
		text = _effect_text(resource)
	elif "polarity" in resource and "status_type" in resource:
		text = _status_text(resource)
	elif resource is EncounterDefinition:
		text = _encounter_text(resource)
	elif resource is RewardDefinition:
		text = _reward_text(resource)
	elif resource is ScenarioDefinition:
		text = _scenario_text(resource)
	elif resource is ScenarioRuleDefinition:
		text = _scenario_rule_text(resource)
	elif resource is CampaignDefinition:
		text = _campaign_text(resource)
	elif resource is CampaignScenarioNodeDefinition:
		text = _campaign_node_text(resource)
	else:
		text = _generic_resource_text(resource)
	return _with_source_note(text, "Source: authored Resource data")


static func related_resources_for_resource(resource) -> Array:
	var related := []
	if resource == null:
		return related
	if resource is UnitDefinition:
		_append_related(related, "Ancestry", resource.ancestry)
		_append_related(related, "Loadout", resource.loadout)
		for progress in resource.job_progress:
			if progress != null:
				_append_related(related, "Job Progress", progress.job)
	elif resource is UnitLoadoutDefinition:
		_append_related(related, "Current Job", resource.current_job)
		_append_related(related, "Assigned Skill", resource.equipped_skill)
		_append_related(related, "Assigned Passive", resource.equipped_passive)
		_append_related(related, "Assigned Reaction", resource.equipped_reaction)
		_append_related(related, "Weapon", resource.weapon)
		_append_related(related, "Armor", resource.armor)
		_append_related(related, "Helmet", resource.helmet)
		_append_related(related, "Trinket", resource.trinket)
		for tactic in resource.tactics:
			_append_related(related, "Tactic", tactic)
	elif resource is ItemDefinition:
		for effect in resource.effects:
			_append_related(related, "Effect", effect)
	elif resource is EffectDefinition:
		_append_related(related, "Status", resource.status)
	elif resource is JobDefinition:
		_append_related(related, "Skill", resource.skill)
		_append_related(related, "Passive", resource.passive)
		_append_related(related, "Reaction", resource.reaction)
		_append_related(related, "Default Tactic", resource.default_tactic)
	elif resource is SkillDefinition:
		_append_related(related, "Status", resource.status)
	elif resource is AncestryDefinition:
		_append_related(related, "Feature", resource.feature)
	elif resource is EncounterDefinition:
		for enemy in resource.enemy_units:
			_append_related(related, "Enemy", enemy)
	elif resource is RewardDefinition:
		_append_related(related, "Item", resource.item)
	elif resource is ScenarioDefinition:
		for encounter in resource.encounters:
			_append_related(related, "Encounter", encounter)
		for rule in resource.scenario_rules:
			_append_related(related, "Rule", rule)
		for reward in resource.rewards:
			_append_related(related, "Reward", reward)
	elif resource is CampaignDefinition:
		for node in resource.scenario_nodes:
			_append_related(related, "Scenario Node", node)
	elif resource is CampaignScenarioNodeDefinition:
		_append_related(related, "Scenario", resource.scenario)
	return related


static func text_for_runtime_unit(snapshot: Dictionary) -> String:
	var name: String = String(snapshot.get("name", "Unit"))
	var team: String = String(snapshot.get("team", ""))
	var max_hp: int = int(snapshot.get("max_hp", 1))
	var hp: int = int(snapshot.get("hp", max_hp))
	var action_interval: int = int(snapshot.get("action_interval", 1))
	var next_action_time: float = float(snapshot.get("next_action_time", 0.0))
	var display_time: float = float(snapshot.get("display_time", 0.0))
	var remaining: float = max(0.0, next_action_time - display_time)
	var statuses: Array = snapshot.get("statuses", [])
	var status_text := "none"
	if not statuses.is_empty():
		var status_lines: Array[String] = []
		for raw_status in statuses:
			if raw_status is Dictionary:
				var status: Dictionary = raw_status
				var line := "%s %s: %s" % [String(status.get("polarity", "Status")), String(status.get("name", "Unknown")), String(status.get("description", ""))]
				line += " Permanent." if bool(status.get("is_permanent", false)) else " Remaining owner turns: %d." % int(status.get("remaining_turns", 0))
				line += " Stacks: %d." % int(status.get("stack_count", 1))
				var stored_damage := int(status.get("damage_since_last_turn", 0))
				if stored_damage > 0:
					line += " Stored damage: %d." % stored_damage
				status_lines.append(line)
			else:
				status_lines.append(String(raw_status))
		status_text = "\n- %s" % _join(status_lines, "\n- ")
	return _with_source_note("%s\nTeam: %s\nHP: %d/%d\nAction interval: %d\nNext action in: %.1f\nStatuses: %s" % [name, team, hp, max_hp, action_interval, remaining, status_text], "Source: runtime combat state")


static func text_for_glossary_term(term: String) -> String:
	var key := term.to_lower()
	var definitions := {
		"hp": "HP\nCurrent and maximum health. A unit is defeated when HP reaches 0.",
		"armor": "Armor\nReduces physical damage. Temporary guard armor is added on top of base battle armor.",
		"action interval": "Action Interval\nLower values act sooner. After a unit acts, its next action is scheduled by adding this interval.",
		"physical damage": "Physical Damage\nThe base damage used by normal attacks and non-magic damage sources. Armor reduces it.",
		"magic damage": "Magic Damage\nThe base damage used by magic-tagged actions and effects. It currently ignores armor.",
		"guard": "Guard\nA defensive action that grants temporary armor until the guarding unit's next turn.",
		"cooldown": "Cooldown\nA runtime wait on an ability or feature before it can trigger again.",
	}
	return _with_source_note(String(definitions.get(key, term)), "Source: rules glossary")


static func text_for_structured_events(events: Array[Dictionary]) -> String:
	var lines: Array[String] = ["Structured Event Payloads"]
	if events.is_empty():
		lines.append("No structured event payload is currently selected.")
		return _with_source_note(_join(lines, "\n"), "Source: structured combat report")

	for event in events:
		var event_type := String(event.get("event_type", "text"))
		var payload: Dictionary = event.get("payload", {})
		lines.append("")
		lines.append("%s:" % event_type)
		if payload.is_empty():
			lines.append("- payload: none")
		else:
			var keys := payload.keys()
			keys.sort()
			for key in keys:
				lines.append("- %s: %s" % [String(key), String(payload[key])])
	return _with_source_note(_join(lines, "\n"), "Source: structured combat report")


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
				progress_parts.append("%s L%d%s" % [progress.job.display_name, progress.level, " choice pending" if progress.pending_unlock_choice else ""])
		lines.append("Job progress: %s" % _join(progress_parts, "; "))
	return _join(lines, "\n")


static func _loadout_text(loadout: UnitLoadoutDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(loadout))
	lines.append("Current job: %s" % _name_or_none(loadout.current_job))
	lines.append("Assigned skill: %s" % _name_or_none(loadout.equipped_skill))
	lines.append("Assigned passive: %s" % _name_or_none(loadout.equipped_passive))
	lines.append("Assigned reaction: %s" % _name_or_none(loadout.equipped_reaction))
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
	lines.append("Unlock schedule: L1 choose skill/reaction, L2 passive, L3 remaining feature")
	return _join(lines, "\n")


static func _ancestry_text(ancestry: AncestryDefinition) -> String:
	var forbids: Array[String] = []
	if ancestry.forbid_weapon:
		forbids.append("weapon")
	if ancestry.forbid_armor:
		forbids.append("armor")
	if ancestry.forbid_helmet:
		forbids.append("helmet")
	if ancestry.forbid_trinket:
		forbids.append("trinket")
	return "%s\nTags: %s\nGrowth: HP %+d, physical %+d, magic %+d, armor %+d, interval %+d\nForbids: %s\nFeature: %s" % [
		_title(ancestry),
		_join(ancestry.tags),
		ancestry.max_hp_growth,
		ancestry.physical_damage_growth,
		ancestry.magic_damage_growth,
		ancestry.armor_growth,
		ancestry.action_interval_growth,
		_join(forbids),
		_name_or_none(ancestry.feature),
	]


static func _skill_text(skill: SkillDefinition) -> String:
	return "%s\nTags: %s\nAction: %s\nTarget: %s\nStatus: %s\nStatus duration: %s\nAmount modifier: %+d" % [_title(skill), _join(skill.tags), skill.action, skill.default_target, _name_or_none(skill.status), _status_duration_text(skill.status_duration_turns, skill.status_is_permanent), skill.amount_modifier]


static func _passive_text(passive: PassiveDefinition) -> String:
	return "%s\nTags: %s\nType: %s\nAmount: %+d\nCooldown turns: %d" % [_title(passive), _join(passive.tags), passive.passive_type, passive.amount, passive.cooldown_turns]


static func _reaction_text(reaction: ReactionDefinition) -> String:
	return "%s\nTags: %s\nTrigger: %s\nCondition: %s\nType: %s\nAmount: %+d\nThreshold: %d%%\nCooldown turns: %d" % [_title(reaction), _join(reaction.tags), reaction.trigger, reaction.condition, reaction.reaction_type, reaction.amount, reaction.threshold_percent, reaction.cooldown_turns]


static func _tactic_text(tactic: TacticDefinition) -> String:
	return "%s\nTags: %s\nRule: %s -> %s -> %s" % [_title(tactic), _join(tactic.tags), tactic.condition, tactic.action, tactic.target]


static func _effect_text(effect: EffectDefinition) -> String:
	return "%s\n%s\nResolver: %s" % [_title(effect), _effect_summary(effect), _effect_support_note(effect)]


static func _status_text(status: Resource) -> String:
	return "%s\nPolarity: %s\nType: %s\nStacking: %s, maximum %d\nTags: %s\nAmount percent: %d%%\n%s" % [_title(status), status.polarity, status.status_type, status.stacking_rule, status.max_stacks, _join(status.tags), status.amount_percent, status.description]


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


static func _scenario_text(scenario: ScenarioDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(scenario))
	if not scenario.description.is_empty():
		lines.append(scenario.description)
	if not scenario.story_intro.is_empty():
		lines.append("Intro: %s" % scenario.story_intro)
	lines.append("Party size: %d" % scenario.party_size)
	lines.append("Recommended level: %d-%d" % [scenario.recommended_level_min, scenario.recommended_level_max])
	lines.append("Tags: %s" % _join(scenario.tags))
	lines.append("Encounters: %s" % _join(_resource_names(scenario.encounters)))
	lines.append("Rules: %s" % _join(_resource_names(scenario.scenario_rules)))
	lines.append("Rewards: %s" % _join(_resource_names(scenario.rewards)))
	lines.append("Content unlocks: %s" % _join(scenario.content_unlocks))
	return _join(lines, "\n")


static func _scenario_rule_text(rule: ScenarioRuleDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(rule))
	if not rule.description.is_empty():
		lines.append(rule.description)
	lines.append("Rule id: %s" % rule.rule_id)
	lines.append("Tags: %s" % _join(rule.tags))
	return _join(lines, "\n")


static func _campaign_text(campaign: CampaignDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(campaign))
	if not campaign.description.is_empty():
		lines.append(campaign.description)
	lines.append("Starting scenarios: %s" % _join(campaign.starting_scenario_ids))
	lines.append("Starting roster ids: %s" % _join(campaign.starting_roster_ids))
	lines.append("Starting unlocks: %s" % _join(campaign.starting_unlocks))
	lines.append("Scenario nodes: %s" % _join(_resource_names(campaign.scenario_nodes)))
	return _join(lines, "\n")


static func _campaign_node_text(node: CampaignScenarioNodeDefinition) -> String:
	var lines: Array[String] = []
	lines.append(_title(node.scenario) if node.scenario != null else "Campaign Scenario Node")
	lines.append("Scenario: %s" % _name_or_none(node.scenario))
	lines.append("Unlocks scenarios: %s" % _join(node.unlock_scenario_ids_on_completion))
	lines.append("Unlocks content: %s" % _join(node.content_unlocks_on_completion))
	lines.append("Completes campaign: %s" % str(node.completes_campaign))
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
	var status_text := " (%s)" % _name_or_none(effect.status) if effect.status != null else ""
	var duration_text := ", %s" % _status_duration_text(effect.status_duration_turns, effect.status_is_permanent) if effect.status != null else ""
	return "%s%s when %s: %s %d to %s%s%s" % [effect.effect_type, status_text, effect.trigger, effect.condition, effect.amount, effect.target_selector, duration_text, limit_text]


static func _effect_support_note(effect: EffectDefinition) -> String:
	if effect.trigger == "Battle Start" and effect.effect_type == "Gain Armor":
		return "supported"
	if effect.trigger == "Battle Start" and effect.effect_type == "Apply Status" and effect.target_selector == "Self" and effect.status != null:
		return "supported"
	if effect.trigger == "Attack" and effect.effect_type == "Bonus Damage":
		return "supported"
	if effect.trigger == "Hit" and effect.effect_type == "Reduce Target Armor":
		return "supported"
	if (effect.trigger == "Damaged" or effect.trigger == "HP Below Threshold") and (effect.effect_type == "Heal" or effect.effect_type == "Heal Self" or effect.effect_type == "Increase Max HP"):
		return "supported"
	if effect.trigger == "Kill" and (effect.effect_type == "Heal" or effect.effect_type == "Heal Self"):
		return "supported"
	if effect.trigger == "Death" and effect.effect_type == "Damage Killer":
		return "supported"
	return "not implemented for this trigger/effect pair; combat logs will say so if it triggers"


static func _item_stats(item: ItemDefinition) -> String:
	var parts: Array[String] = []
	_append_amount(parts, "HP", item.max_hp_modifier)
	_append_amount(parts, "physical", item.physical_damage_modifier)
	_append_amount(parts, "magic", item.magic_damage_modifier)
	_append_amount(parts, "armor", item.armor_modifier)
	_append_amount(parts, "interval", item.action_interval_modifier)
	return _join(parts) if not parts.is_empty() else "no stat changes"


static func _status_duration_text(duration_turns: int, is_permanent: bool) -> String:
	return "permanent" if is_permanent else "%d owner turns" % duration_turns


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


static func _resource_names(resources: Array) -> Array[String]:
	var names: Array[String] = []
	for resource in resources:
		if resource != null:
			names.append(_name_or_none(resource))
	return names


static func _append_related(out: Array, label: String, resource) -> void:
	if resource == null:
		return
	out.append({
		"label": label,
		"resource": resource,
		"name": _name_or_none(resource),
	})


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


static func _with_source_note(text: String, note: String) -> String:
	if text.is_empty():
		return note
	return "%s\n\n%s" % [text, note]
