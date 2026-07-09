extends RefCounted
class_name ContentValidator

const ContentSchemaScript := preload("res://scripts/data/content_schema.gd")
const ContentEffectSupportScript := preload("res://scripts/modding/content_effect_support.gd")
static func validate_merged_data(data: Dictionary) -> void:
	for status_id in data["statuses"].keys():
		var status: Dictionary = data["statuses"][status_id]
		assert(ContentSchemaScript.STATUS_POLARITY_VALUES.has(status.get("polarity", "")), "Invalid status polarity for id %s" % status_id)
		assert(ContentSchemaScript.STATUS_TYPE_VALUES.has(status.get("status_type", "")), "Invalid status type for id %s" % status_id)
		assert(ContentSchemaScript.STATUS_STACKING_RULE_VALUES.has(status.get("stacking_rule", "")), "Invalid status stacking rule for id %s" % status_id)
		assert(int(status.get("max_stacks", 1)) >= 1, "Status max_stacks must be at least 1 for id %s" % status_id)
		assert(int(status.get("amount_percent", 20)) in range(1, 101), "Status amount_percent must be between 1 and 100 for id %s" % status_id)
		assert(int(status.get("propagation_percent", 25)) in range(1, 101), "Status propagation_percent must be between 1 and 100 for id %s" % status_id)

	for ancestry_id in data["ancestries"].keys():
		var ancestry: Dictionary = data["ancestries"][ancestry_id]
		var feature: Dictionary = ancestry.get("feature", {})
		if not feature.is_empty():
			assert(ContentSchemaScript.ANCESTRY_FEATURE_TRIGGER_VALUES.has(feature.get("trigger", "")), "Invalid ancestry feature trigger for ancestry id %s" % ancestry_id)
			assert(ContentSchemaScript.ANCESTRY_FEATURE_CONDITION_VALUES.has(feature.get("condition", "")), "Invalid ancestry feature condition for ancestry id %s" % ancestry_id)
			assert(ContentSchemaScript.ANCESTRY_FEATURE_TYPE_VALUES.has(feature.get("feature_type", "")), "Invalid ancestry feature type for ancestry id %s" % ancestry_id)

	for item_id in data["items"].keys():
		var item: Dictionary = data["items"][item_id]
		assert(ContentSchemaScript.ITEM_SLOT_VALUES.has(item.get("slot", "")), "Invalid item slot for id %s" % item_id)
		for effect in item.get("effects", []):
			var effect_data: Dictionary = effect
			assert(ContentSchemaScript.EFFECT_TRIGGER_VALUES.has(effect_data.get("trigger", "")), "Invalid authored effect trigger for item id %s" % item_id)
			assert(ContentSchemaScript.EFFECT_CONDITION_VALUES.has(effect_data.get("condition", "")), "Invalid authored effect condition for item id %s" % item_id)
			assert(ContentSchemaScript.EFFECT_TARGET_VALUES.has(effect_data.get("target_selector", "")), "Invalid authored effect target selector for item id %s" % item_id)
			assert(ContentSchemaScript.EFFECT_TYPE_VALUES.has(effect_data.get("effect_type", "")), "Invalid authored effect type for item id %s" % item_id)
			assert(ContentEffectSupportScript.support_error(effect_data).is_empty(), "Unsupported effect in item %s: %s" % [item_id, ContentEffectSupportScript.support_error(effect_data)])
			_validate_formula_fields(data, effect_data, "item %s" % item_id)
			var effect_status_id := String(effect_data.get("status_id", ""))
			if effect_data.get("effect_type", "") == "Apply Status":
				assert(data["statuses"].has(effect_status_id), "Unknown status id '%s' in item %s" % [effect_status_id, item_id])
				assert(int(effect_data.get("status_duration_turns", 3)) >= 1, "Status duration must be at least 1 turn in item %s" % item_id)
			if effect_data.get("effect_type", "") == "Remove Status":
				assert(ContentSchemaScript.EFFECT_STATUS_POLARITY_VALUES.has(effect_data.get("status_polarity", "Any")), "Invalid status polarity filter in item %s" % item_id)
				assert(ContentSchemaScript.EFFECT_STATUS_REMOVAL_MODE_VALUES.has(effect_data.get("status_removal_mode", "Random Matching")), "Invalid status removal mode in item %s" % item_id)
				if effect_data.get("status_removal_mode", "Random Matching") == "Specific Status":
					assert(data["statuses"].has(effect_status_id), "Unknown specific removal status id '%s' in item %s" % [effect_status_id, item_id])
					var filter_polarity := String(effect_data.get("status_polarity", "Any"))
					if filter_polarity != "Any":
						assert(String(data["statuses"][effect_status_id].get("polarity", "")) == filter_polarity, "Specific removal polarity does not match status '%s' in item %s" % [effect_status_id, item_id])
			if effect_data.get("effect_type", "") == "Modify Stat":
				assert(ContentSchemaScript.EFFECT_MODIFIED_STAT_VALUES.has(effect_data.get("modified_stat", "")), "Invalid modified stat in item %s" % item_id)
				assert(int(effect_data.get("modifier_duration_turns", 1)) >= 1, "Modifier duration must be at least 1 turn in item %s" % item_id)

	for job_id in data["jobs"].keys():
		var job: Dictionary = data["jobs"][job_id]
		_validate_job_skill(data, job.get("skill", {}), job_id, "skill")
		_validate_job_skill(data, job.get("secondary_skill", {}), job_id, "secondary skill")
		var passive: Dictionary = job.get("passive", {})
		if not passive.is_empty():
			assert(ContentSchemaScript.PASSIVE_TYPE_VALUES.has(passive.get("passive_type", "")), "Invalid passive type for job id %s" % job_id)
			for effect in passive.get("effects", []):
				_validate_shared_effect(data, effect, "passive in job %s" % job_id)
		var reaction: Dictionary = job.get("reaction", {})
		if not reaction.is_empty():
			assert(ContentSchemaScript.REACTION_TRIGGER_VALUES.has(reaction.get("trigger", "")), "Invalid reaction trigger for job id %s" % job_id)
			assert(ContentSchemaScript.REACTION_CONDITION_VALUES.has(reaction.get("condition", "")), "Invalid reaction condition for job id %s" % job_id)
			assert(ContentSchemaScript.REACTION_TYPE_VALUES.has(reaction.get("reaction_type", "")), "Invalid reaction type for job id %s" % job_id)
			assert(not bool(reaction.get("prevents_triggering_request", false)) or reaction.get("trigger", "") in ["Status Application Requested", "Enemy Healing Requested", "Lethal Physical Attack Requested"], "Reaction request prevention requires a request trigger for job id %s" % job_id)
			if reaction.get("condition", "") == "Self Status Stacks At Least":
				assert(data["statuses"].has(String(reaction.get("status_id", ""))), "Unknown reaction condition status in job %s" % job_id)
			if reaction.get("trigger", "") == "Enemy Status Threshold Reached":
				assert(data["statuses"].has(String(reaction.get("status_id", ""))), "Enemy Status Threshold Reached requires a status in job %s" % job_id)
			if reaction.get("trigger", "") == "Enemy Died With Status":
				assert(data["statuses"].has(String(reaction.get("status_id", ""))), "Enemy Died With Status requires a status in job %s" % job_id)
			if reaction.get("condition", "") == "Requested Status Matches":
				assert(data["statuses"].has(String(reaction.get("status_id", ""))), "Requested Status Matches requires a status in job %s" % job_id)
			for replacement_id in reaction.get("replacement_status_ids", []):
				assert(data["statuses"].has(String(replacement_id)), "Unknown reaction replacement status in job %s" % job_id)
				assert(String(data["statuses"][String(replacement_id)].get("polarity", "")) == "Boon", "Reaction replacement statuses must be boons in job %s" % job_id)
			for effect in reaction.get("effects", []):
				_validate_shared_effect(data, effect, "reaction in job %s" % job_id)
		var default_tactic: Dictionary = job.get("default_tactic", {})
		if not default_tactic.is_empty():
			assert(ContentSchemaScript.TACTIC_CONDITION_VALUES.has(default_tactic.get("condition", "")), "Invalid default tactic condition for job id %s" % job_id)
			assert(ContentSchemaScript.TACTIC_ACTION_VALUES.has(default_tactic.get("action", "")), "Invalid default tactic action for job id %s" % job_id)
			assert(ContentSchemaScript.TACTIC_TARGET_VALUES.has(default_tactic.get("target", "")), "Invalid default tactic target for job id %s" % job_id)
			_validate_tactic_status(data, default_tactic, "default tactic in job %s" % job_id)

	for tactic_id in data["tactics"].keys():
		var tactic: Dictionary = data["tactics"][tactic_id]
		assert(ContentSchemaScript.TACTIC_CONDITION_VALUES.has(tactic.get("condition", "")), "Invalid tactic condition for id %s" % tactic_id)
		assert(ContentSchemaScript.TACTIC_ACTION_VALUES.has(tactic.get("action", "")), "Invalid tactic action for id %s" % tactic_id)
		assert(ContentSchemaScript.TACTIC_TARGET_VALUES.has(tactic.get("target", "")), "Invalid tactic target for id %s" % tactic_id)
		_validate_tactic_status(data, tactic, "tactic %s" % tactic_id)

	for loadout_id in data["loadouts"].keys():
		var loadout: Dictionary = data["loadouts"][loadout_id]
		var current_job_id := String(loadout.get("current_job_id", ""))
		if not current_job_id.is_empty():
			assert(data["jobs"].has(current_job_id), "Unknown job id '%s' in loadout %s" % [current_job_id, loadout_id])
		for item_key in ["weapon_id", "armor_id", "helmet_id", "trinket_id"]:
			var item_id := String(loadout.get(item_key, ""))
			if not item_id.is_empty():
				assert(data["items"].has(item_id), "Unknown item id '%s' in loadout %s" % [item_id, loadout_id])
		for tactic_id in loadout.get("tactic_ids", []):
			assert(data["tactics"].has(String(tactic_id)), "Unknown tactic id '%s' in loadout %s" % [String(tactic_id), loadout_id])
		for feature_key in ["equipped_skill_job_id", "equipped_passive_job_id", "equipped_reaction_job_id"]:
			var source_job_id := String(loadout.get(feature_key, ""))
			if not source_job_id.is_empty():
				assert(data["jobs"].has(source_job_id), "Unknown source job id '%s' in loadout %s" % [source_job_id, loadout_id])

	for unit_id in data["units"].keys():
		var unit: Dictionary = data["units"][unit_id]
		assert(ContentSchemaScript.TEAM_VALUES.has(unit.get("team", "")), "Invalid team value for unit id %s" % unit_id)
		var ancestry_id := String(unit.get("ancestry_id", ""))
		if not ancestry_id.is_empty():
			assert(data["ancestries"].has(ancestry_id), "Unknown ancestry id '%s' in unit %s" % [ancestry_id, unit_id])
		var loadout_id := String(unit.get("loadout_id", ""))
		if not loadout_id.is_empty():
			assert(data["loadouts"].has(loadout_id), "Unknown loadout id '%s' in unit %s" % [loadout_id, unit_id])
		for raw_progress in unit.get("job_progress", []):
			var progress: Dictionary = raw_progress
			var job_id := String(progress.get("job_id", ""))
			assert(data["jobs"].has(job_id), "Unknown job id '%s' in job_progress for unit %s" % [job_id, unit_id])
		_validate_unit_feature_assignments(data, unit_id, unit)

	for roster_unit_id in data.get("demo_roster", []):
		assert(data["units"].has(String(roster_unit_id)), "Unknown unit id '%s' in demo_roster" % String(roster_unit_id))
static func _validate_job_skill(data: Dictionary, raw_skill: Variant, job_id: String, label: String) -> void:
	var skill: Dictionary = raw_skill
	if skill.is_empty():
		return
	assert(ContentSchemaScript.SKILL_ACTION_VALUES.has(skill.get("action", "")), "Invalid %s action for job id %s" % [label, job_id])
	assert(ContentSchemaScript.SKILL_TARGET_VALUES.has(skill.get("default_target", "")), "Invalid %s default target for job id %s" % [label, job_id])
	assert(ContentSchemaScript.SKILL_ATTACK_DAMAGE_TYPE_VALUES.has(skill.get("attack_damage_type", "Physical")), "Invalid %s attack damage type for job id %s" % [label, job_id])
	var skill_status_id := String(skill.get("status_id", ""))
	if skill.get("action", "") == "Apply Status":
		assert(data["statuses"].has(skill_status_id), "Unknown status id '%s' in %s for job %s" % [skill_status_id, label, job_id])
		assert(int(skill.get("status_duration_turns", 3)) >= 1, "Status duration must be at least 1 turn in %s for job %s" % [label, job_id])
	if skill.get("action", "") == "Effects Only":
		assert(not skill.get("effects", []).is_empty(), "Effects Only %s requires at least one effect for job %s" % [label, job_id])
	assert(int(skill.get("attack_count", 1)) >= 1, "%s attack_count must be at least 1 for job %s" % [label.capitalize(), job_id])
	assert(int(skill.get("cooldown_turns", 0)) >= 0, "%s cooldown_turns cannot be negative for job %s" % [label.capitalize(), job_id])
	for effect in skill.get("effects", []):
		var effect_data: Dictionary = effect
		assert(effect_data.get("trigger", "") in ["Skill Used", "Skill Completed"], "%s effects must use Skill Used or Skill Completed for job %s" % [label.capitalize(), job_id])
		assert(ContentSchemaScript.EFFECT_CONDITION_VALUES.has(effect_data.get("condition", "")), "Invalid %s effect condition for job %s" % [label, job_id])
		assert(ContentSchemaScript.EFFECT_TARGET_VALUES.has(effect_data.get("target_selector", "")), "Invalid %s effect target for job %s" % [label, job_id])
		assert(ContentSchemaScript.EFFECT_TYPE_VALUES.has(effect_data.get("effect_type", "")), "Invalid %s effect type for job %s" % [label, job_id])
		assert(ContentEffectSupportScript.support_error(effect_data).is_empty(), "Unsupported %s effect in job %s: %s" % [label, job_id, ContentEffectSupportScript.support_error(effect_data)])
		_validate_formula_fields(data, effect_data, "%s in job %s" % [label, job_id])
		var effect_status_id := String(effect_data.get("status_id", ""))
		if effect_data.get("effect_type", "") == "Apply Status":
			assert(data["statuses"].has(effect_status_id), "Unknown %s effect status id '%s' in job %s" % [label, effect_status_id, job_id])
		if effect_data.get("effect_type", "") == "Remove Status" and effect_data.get("status_removal_mode", "Random Matching") == "Specific Status":
			assert(data["statuses"].has(effect_status_id), "Unknown specific removal status id '%s' in %s for job %s" % [effect_status_id, label, job_id])
			var filter_polarity := String(effect_data.get("status_polarity", "Any"))
			if filter_polarity != "Any":
				assert(String(data["statuses"][effect_status_id].get("polarity", "")) == filter_polarity, "Specific %s removal polarity does not match status '%s' in job %s" % [label, effect_status_id, job_id])
		if effect_data.get("effect_type", "") == "Remove Status":
			assert(ContentSchemaScript.EFFECT_STATUS_POLARITY_VALUES.has(effect_data.get("status_polarity", "Any")), "Invalid %s status polarity filter in job %s" % [label, job_id])
			assert(ContentSchemaScript.EFFECT_STATUS_REMOVAL_MODE_VALUES.has(effect_data.get("status_removal_mode", "Random Matching")), "Invalid %s status removal mode in job %s" % [label, job_id])
		if effect_data.get("effect_type", "") == "Modify Stat":
			assert(ContentSchemaScript.EFFECT_MODIFIED_STAT_VALUES.has(effect_data.get("modified_stat", "")), "Invalid %s modified stat in job %s" % [label, job_id])
			assert(int(effect_data.get("modifier_duration_turns", 1)) >= 1, "%s modifier duration must be at least 1 turn in job %s" % [label.capitalize(), job_id])
static func _validate_shared_effect(data: Dictionary, raw_effect: Variant, label: String) -> void:
	var effect: Dictionary = raw_effect
	assert(ContentSchemaScript.EFFECT_TRIGGER_VALUES.has(effect.get("trigger", "")), "Invalid effect trigger for %s" % label)
	assert(ContentSchemaScript.EFFECT_CONDITION_VALUES.has(effect.get("condition", "")), "Invalid effect condition for %s" % label)
	assert(ContentSchemaScript.EFFECT_TARGET_VALUES.has(effect.get("target_selector", "")), "Invalid effect target for %s" % label)
	assert(ContentSchemaScript.EFFECT_TYPE_VALUES.has(effect.get("effect_type", "")), "Invalid effect type for %s" % label)
	assert(ContentEffectSupportScript.support_error(effect).is_empty(), "Unsupported effect for %s: %s" % [label, ContentEffectSupportScript.support_error(effect)])
	_validate_formula_fields(data, effect, label)


static func _validate_formula_fields(data: Dictionary, effect: Dictionary, label: String) -> void:
	var amount_source := String(effect.get("amount_source", "Fixed"))
	assert(ContentSchemaScript.EFFECT_AMOUNT_SOURCE_VALUES.has(amount_source), "Invalid amount source for %s" % label)
	assert(ContentSchemaScript.EFFECT_AMOUNT_TARGET_VALUES.has(effect.get("amount_target_selector", "Self")), "Invalid amount target selector for %s" % label)
	assert(ContentSchemaScript.EFFECT_MODIFIER_MODE_VALUES.has(effect.get("modifier_mode", "Temporary Flat")), "Invalid modifier mode for %s" % label)
	assert(ContentSchemaScript.EFFECT_MODIFIER_DIRECTION_VALUES.has(effect.get("modifier_direction", "Increase")), "Invalid modifier direction for %s" % label)
	assert(ContentSchemaScript.EFFECT_DAMAGE_TYPE_VALUES.has(effect.get("damage_type", "Magic")), "Invalid damage type for %s" % label)
	assert(ContentSchemaScript.EFFECT_AMOUNT_ROUNDING_VALUES.has(effect.get("amount_rounding", "Floor")), "Invalid amount rounding for %s" % label)
	var status_id := String(effect.get("status_id", ""))
	var amount_status_id := String(effect.get("amount_status_id", ""))
	if amount_status_id.is_empty():
		amount_status_id = status_id
	if effect.get("effect_type", "") in ["Apply Status", "Maintain Status Aura", "Consume Status", "Detonate Status", "Gather Status", "Fuse Elemental Ailments", "Restore Max HP Lost To Status"] or effect.get("condition", "") in ["Target Status Stacks At Least", "Target Pending Status Damage At Least HP", "Requested Status Matches"]:
		assert(data["statuses"].has(status_id), "Unknown required status id '%s' for %s" % [status_id, label])
	if effect.get("effect_type", "") == "Fuse Elemental Ailments":
		assert(String(data["statuses"][status_id].get("status_type", "")) == "Elemental Fusion", "Fuse Elemental Ailments requires an Elemental Fusion output status for %s" % label)
	for replacement_id in effect.get("replacement_status_ids", []):
		assert(data["statuses"].has(String(replacement_id)), "Unknown replacement status id for %s" % label)
		assert(String(data["statuses"][String(replacement_id)].get("polarity", "")) == "Boon", "Replacement statuses must be boons for %s" % label)
	if amount_source in ["Target Status Stacks", "Event Target Status Stacks", "Defeated Target Status Stacks", "Total Status Stacks On Selected Group", "Total Status Max HP Loss On Selected Group", "Target Pending Status Damage"]:
		assert(data["statuses"].has(amount_status_id), "Unknown amount status id for %s" % label)
	if effect.get("condition", "") == "Applied Status Matches":
		assert(data["statuses"].has(String(effect.get("condition_status_id", ""))), "Unknown condition status id for %s" % label)
	if amount_source in ["Overhealing Diminishing", "Owner Counter", "Target Counter"] or effect.get("effect_type", "") in ["Modify Counter", "Reset Counter"] or effect.get("condition", "") in ["Owner Counter At Least", "Target Counter At Least"]:
		assert(not String(effect.get("counter_name", "")).is_empty(), "Counter name is required for %s" % label)
	assert(int(effect.get("status_stacks", 1)) >= 1, "Status stacks must be at least 1 for %s" % label)
	assert(int(effect.get("status_stack_threshold", 1)) >= 1, "Status stack threshold must be at least 1 for %s" % label)
	assert(int(effect.get("counter_threshold", 1)) >= 1, "Counter threshold must be at least 1 for %s" % label)
	assert(int(effect.get("amount_multiplier", 1)) >= 1, "Amount multiplier must be at least 1 for %s" % label)
	assert(int(effect.get("amount_divisor", 1)) >= 1, "Amount divisor must be at least 1 for %s" % label)
	assert(int(effect.get("interval_time", 10)) >= 1, "Interval time must be at least 1 for %s" % label)
	assert(int(effect.get("max_action_speed_percent", 200)) >= 100, "Maximum action speed percent must be at least 100 for %s" % label)


static func _validate_tactic_status(data: Dictionary, tactic: Dictionary, label: String) -> void:
	if tactic.get("condition", "") in ["Target Has Status", "Target Status Stacks At Least", "Target Pending Status Damage At Least HP"] or tactic.get("target", "") == "Lowest HP Ally With Status":
		assert(data["statuses"].has(String(tactic.get("status_id", ""))), "Unknown required status id for %s" % label)
	assert(int(tactic.get("status_stack_threshold", 1)) >= 1, "Status stack threshold must be at least 1 for %s" % label)


static func _validate_unit_feature_assignments(data: Dictionary, unit_id: String, unit: Dictionary) -> void:
	var loadout_id := String(unit.get("loadout_id", ""))
	if loadout_id.is_empty() or not data["loadouts"].has(loadout_id):
		return
	var loadout: Dictionary = data["loadouts"][loadout_id]
	var progress_by_job_id := {}
	for raw_progress in unit.get("job_progress", []):
		var progress: Dictionary = raw_progress
		progress_by_job_id[String(progress.get("job_id", ""))] = progress
	var current_job_id := String(loadout.get("current_job_id", ""))
	for feature_type in ["skill", "passive", "reaction"]:
		var source_job_id := String(loadout.get("equipped_%s_job_id" % feature_type, ""))
		if source_job_id.is_empty():
			continue
		assert(progress_by_job_id.has(source_job_id), "Unit %s equips %s from job '%s' without matching job_progress." % [unit_id, feature_type, source_job_id])
		if progress_by_job_id.has(source_job_id):
			var progress: Dictionary = progress_by_job_id[source_job_id]
			assert(bool(progress.get("%s_unlocked" % feature_type, false)), "Unit %s equips locked %s from job '%s'." % [unit_id, feature_type, source_job_id])
		if feature_type == "skill":
			assert(source_job_id != current_job_id, "Unit %s assigns its current job skill through the cross-job skill slot." % unit_id)
