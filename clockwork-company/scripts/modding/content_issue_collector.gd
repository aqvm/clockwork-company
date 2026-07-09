extends RefCounted
class_name ContentIssueCollector

const ContentSchemaScript := preload("res://scripts/data/content_schema.gd")


static func collect_validation_issues(data: Dictionary, result) -> void:
	for collection in ["ancestries", "statuses", "items", "jobs", "tactics", "loadouts", "units", "demo_roster"]:
		if not data.has(collection):
			result.add_issue(collection, "Missing required content collection.")
	for status_id in data.get("statuses", {}).keys():
		var status: Dictionary = data["statuses"][status_id]
		_require_schema_value(result, "statuses/%s/polarity" % status_id, ContentSchemaScript.STATUS_POLARITY_VALUES, status.get("polarity", ""))
		_require_schema_value(result, "statuses/%s/status_type" % status_id, ContentSchemaScript.STATUS_TYPE_VALUES, status.get("status_type", ""))
		_require_schema_value(result, "statuses/%s/stacking_rule" % status_id, ContentSchemaScript.STATUS_STACKING_RULE_VALUES, status.get("stacking_rule", ""))
		_require_min_int(result, "statuses/%s/max_stacks" % status_id, status.get("max_stacks", 1), 1)
	for item_id in data.get("items", {}).keys():
		var item: Dictionary = data["items"][item_id]
		_require_schema_value(result, "items/%s/slot" % item_id, ContentSchemaScript.ITEM_SLOT_VALUES, item.get("slot", ""))
		_collect_effect_issues(data, item.get("effects", []), "items/%s/effects" % item_id, result)
	for job_id in data.get("jobs", {}).keys():
		var job: Dictionary = data["jobs"][job_id]
		_collect_skill_issues(data, job.get("skill", {}), "jobs/%s/skill" % job_id, result)
		_collect_skill_issues(data, job.get("secondary_skill", {}), "jobs/%s/secondary_skill" % job_id, result)
		_collect_effect_issues(data, job.get("passive", {}).get("effects", []), "jobs/%s/passive/effects" % job_id, result)
		_collect_effect_issues(data, job.get("reaction", {}).get("effects", []), "jobs/%s/reaction/effects" % job_id, result)
	for tactic_id in data.get("tactics", {}).keys():
		var tactic: Dictionary = data["tactics"][tactic_id]
		_require_schema_value(result, "tactics/%s/condition" % tactic_id, ContentSchemaScript.TACTIC_CONDITION_VALUES, tactic.get("condition", ""))
		_require_schema_value(result, "tactics/%s/action" % tactic_id, ContentSchemaScript.TACTIC_ACTION_VALUES, tactic.get("action", ""))
		_require_schema_value(result, "tactics/%s/target" % tactic_id, ContentSchemaScript.TACTIC_TARGET_VALUES, tactic.get("target", ""))
		_require_status_reference(result, data, "tactics/%s/status_id" % tactic_id, tactic.get("status_id", ""))
	for unit_id in data.get("units", {}).keys():
		var unit: Dictionary = data["units"][unit_id]
		_require_schema_value(result, "units/%s/team" % unit_id, ContentSchemaScript.TEAM_VALUES, unit.get("team", ""))
		_require_reference(result, data.get("loadouts", {}), "units/%s/loadout_id" % unit_id, unit.get("loadout_id", ""))
		_require_reference(result, data.get("ancestries", {}), "units/%s/ancestry_id" % unit_id, unit.get("ancestry_id", ""), false)


static func _collect_skill_issues(data: Dictionary, raw_skill: Variant, path: String, result) -> void:
	if typeof(raw_skill) != TYPE_DICTIONARY or raw_skill.is_empty():
		return
	var skill: Dictionary = raw_skill
	_require_schema_value(result, "%s/action" % path, ContentSchemaScript.SKILL_ACTION_VALUES, skill.get("action", ""))
	_require_schema_value(result, "%s/default_target" % path, ContentSchemaScript.SKILL_TARGET_VALUES, skill.get("default_target", ""))
	_require_schema_value(result, "%s/attack_damage_type" % path, ContentSchemaScript.SKILL_ATTACK_DAMAGE_TYPE_VALUES, skill.get("attack_damage_type", "Physical"))
	_require_status_reference(result, data, "%s/status_id" % path, skill.get("status_id", ""), skill.get("action", "") == "Apply Status")
	_collect_effect_issues(data, skill.get("effects", []), "%s/effects" % path, result)


static func _collect_effect_issues(data: Dictionary, raw_effects: Variant, path: String, result) -> void:
	if typeof(raw_effects) != TYPE_ARRAY:
		return
	for index in range(raw_effects.size()):
		if typeof(raw_effects[index]) != TYPE_DICTIONARY:
			result.add_issue("%s/%d" % [path, index], "Effect must be an object.")
			continue
		var effect: Dictionary = raw_effects[index]
		var effect_path := "%s/%d" % [path, index]
		_require_schema_value(result, "%s/trigger" % effect_path, ContentSchemaScript.EFFECT_TRIGGER_VALUES, effect.get("trigger", ""))
		_require_schema_value(result, "%s/condition" % effect_path, ContentSchemaScript.EFFECT_CONDITION_VALUES, effect.get("condition", ""))
		_require_schema_value(result, "%s/target_selector" % effect_path, ContentSchemaScript.EFFECT_TARGET_VALUES, effect.get("target_selector", ""))
		_require_schema_value(result, "%s/effect_type" % effect_path, ContentSchemaScript.EFFECT_TYPE_VALUES, effect.get("effect_type", ""))
		_require_schema_value(result, "%s/amount_source" % effect_path, ContentSchemaScript.EFFECT_AMOUNT_SOURCE_VALUES, effect.get("amount_source", "Fixed"))
		_require_status_reference(result, data, "%s/status_id" % effect_path, effect.get("status_id", ""), _effect_type_requires_status(effect))


static func _effect_type_requires_status(effect: Dictionary) -> bool:
	return String(effect.get("effect_type", "")) in ["Apply Status", "Maintain Status Aura", "Consume Status", "Detonate Status", "Gather Status", "Fuse Elemental Ailments", "Restore Max HP Lost To Status"]


static func _require_schema_value(result, path: String, allowed: Dictionary, raw_value: Variant) -> void:
	var value := String(raw_value)
	if not allowed.has(value):
		result.add_issue(path, "Unsupported value '%s'." % value)


static func _require_min_int(result, path: String, raw_value: Variant, minimum: int) -> void:
	if int(raw_value) < minimum:
		result.add_issue(path, "Value must be at least %d." % minimum)


static func _require_status_reference(result, data: Dictionary, path: String, raw_value: Variant, required := false) -> void:
	_require_reference(result, data.get("statuses", {}), path, raw_value, required)


static func _require_reference(result, collection: Dictionary, path: String, raw_value: Variant, required := true) -> void:
	var id := String(raw_value)
	if id.is_empty():
		if required:
			result.add_issue(path, "Required reference is empty.")
		return
	if not collection.has(id):
		result.add_issue(path, "Unknown reference '%s'." % id)

