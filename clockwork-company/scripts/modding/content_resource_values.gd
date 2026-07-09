extends RefCounted

const EffectDefinitionScript := preload("res://scripts/data/effect_definition.gd")
const TagDefinitionScript := preload("res://scripts/data/tag_definition.gd")


static func set_content_id(resource: Resource, id: String) -> void:
	if resource != null and not id.is_empty():
		resource.set_meta("content_id", id)


static func effect_resources(effects_data: Array, statuses_by_id: Dictionary) -> Array[EffectDefinition]:
	var effects: Array[EffectDefinition] = []
	for raw in effects_data:
		var src: Dictionary = raw
		var effect: EffectDefinition = EffectDefinitionScript.new()
		set_content_id(effect, String(src.get("id", "")))
		effect.display_name = String(src.get("display_name", ""))
		effect.tooltip_text = String(src.get("tooltip_text", ""))
		effect.tags = tag_array(src.get("tags", []))
		effect.trigger = String(src.get("trigger", "Battle Start"))
		effect.condition = String(src.get("condition", "Always"))
		effect.target_selector = String(src.get("target_selector", "Self"))
		effect.effect_type = String(src.get("effect_type", "Gain Armor"))
		effect.status = statuses_by_id.get(String(src.get("status_id", "")), null)
		effect.condition_status = statuses_by_id.get(String(src.get("condition_status_id", "")), null)
		effect.amount_status = statuses_by_id.get(String(src.get("amount_status_id", "")), null)
		for replacement_id in src.get("replacement_status_ids", []):
			var replacement = statuses_by_id.get(String(replacement_id), null)
			if replacement != null:
				effect.replacement_statuses.append(replacement)
		effect.override_status_duration = bool(src.get("override_status_duration", src.has("status_duration_turns") or src.has("status_is_permanent")))
		effect.status_duration_turns = int(src.get("status_duration_turns", 3))
		effect.status_is_permanent = bool(src.get("status_is_permanent", false))
		effect.status_stacks = int(src.get("status_stacks", 1))
		effect.status_stack_threshold = int(src.get("status_stack_threshold", 1))
		effect.status_polarity = String(src.get("status_polarity", "Any"))
		effect.status_removal_mode = String(src.get("status_removal_mode", "Random Matching"))
		effect.modified_stat = String(src.get("modified_stat", "Physical Damage"))
		effect.modifier_mode = String(src.get("modifier_mode", "Temporary Flat"))
		effect.modifier_direction = String(src.get("modifier_direction", "Increase"))
		effect.modifier_duration_turns = int(src.get("modifier_duration_turns", 1))
		effect.amount_source = String(src.get("amount_source", "Fixed"))
		effect.amount_rounding = String(src.get("amount_rounding", "Floor"))
		effect.amount_target_selector = String(src.get("amount_target_selector", "Self"))
		effect.counter_name = String(src.get("counter_name", ""))
		effect.counter_threshold = int(src.get("counter_threshold", 1))
		effect.amount_multiplier = int(src.get("amount_multiplier", 1))
		effect.amount_divisor = int(src.get("amount_divisor", 1))
		effect.interval_time = int(src.get("interval_time", 10))
		effect.amount = int(src.get("amount", 0))
		effect.damage_type = String(src.get("damage_type", "Magic"))
		effect.threshold_percent = int(src.get("threshold_percent", 50))
		effect.max_action_speed_percent = int(src.get("max_action_speed_percent", 200))
		effect.ignore_events_from_same_effect_source = bool(src.get("ignore_events_from_same_effect_source", false))
		effect.repeat_within_event_chain = bool(src.get("repeat_within_event_chain", false))
		effect.once_per_battle = bool(src.get("once_per_battle", false))
		effects.append(effect)
	return effects


static func string_array(raw_values: Variant) -> Array[String]:
	var values: Array[String] = []
	if typeof(raw_values) != TYPE_ARRAY:
		return values
	for raw_value in raw_values:
		values.append(String(raw_value))
	return values


static func tag_array(raw_values: Variant) -> Array[Resource]:
	var values: Array[Resource] = []
	for tag_id in string_array(raw_values):
		var tag := TagDefinitionScript.new()
		tag.tag_id = tag_id
		tag.display_name = tag_id.capitalize()
		values.append(tag)
	return values
