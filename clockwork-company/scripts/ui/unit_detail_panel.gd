extends ScrollContainer
class_name UnitDetailPanel

const PlanningStatPreviewScript := preload("res://scripts/ui/planning_stat_preview.gd")

signal resource_tooltip_requested(source: Control, resource: Resource)
signal tooltip_cleared

var content: VBoxContainer = null


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ensure_content()


func show_unit(unit: UnitDefinition, party_units: Array[UnitDefinition] = []) -> void:
	_ensure_content()
	_clear_content()
	if unit == null:
		_add_plain_text("Select a unit to inspect details.")
		return

	var preview: Dictionary = _preview_for_unit(unit, party_units)
	var computed_stats: Dictionary = preview.get("before_battle_start", {})
	var battle_start_stats: Dictionary = preview.get("after_battle_start", {})
	_add_resource_text(unit, unit.display_name)
	_add_plain_text("Base stats: HP %d, physical %d, magic %d, armor %d, interval %d" % [unit.max_hp, unit.physical_damage, unit.magic_damage, unit.armor, unit.action_interval])
	_add_plain_text("Computed stats: %s" % PlanningStatPreviewScript.stats_line(computed_stats))
	if PlanningStatPreviewScript.stats_changed(computed_stats, battle_start_stats):
		_add_plain_text("After battle-start effects: %s" % PlanningStatPreviewScript.stats_line(battle_start_stats))
	var skipped_items: Array = preview.get("skipped_items", [])
	if not skipped_items.is_empty():
		_add_plain_text("Skipped equipment: %s" % _join_values(skipped_items, ", "))
	_add_plain_text("Tags: %s" % _join_values(unit.tags, ", "))
	_add_resource_text(unit.ancestry, "Ancestry: %s" % _resource_display_name(unit.ancestry))
	if unit.ancestry != null:
		_add_resource_text(unit.ancestry.feature, "Ancestry feature: %s" % _resource_display_name(unit.ancestry.feature))
	_add_plain_text("Job progress: %s" % _job_progress_summary(unit))
	_add_plain_text("")
	if unit.loadout == null:
		_add_plain_text("No loadout.")
		return

	var loadout := unit.loadout
	var skill = loadout.equipped_skill if loadout.equipped_skill != null else loadout.current_job.skill if loadout.current_job != null else null
	var passive = loadout.equipped_passive if loadout.equipped_passive != null else loadout.current_job.passive if loadout.current_job != null else null
	var reaction = loadout.equipped_reaction if loadout.equipped_reaction != null else loadout.current_job.reaction if loadout.current_job != null else null
	_add_resource_text(loadout, "Loadout: %s" % loadout.display_name)
	_add_resource_text(loadout.current_job, "Current job: %s" % _resource_display_name(loadout.current_job))
	_add_resource_text(skill, "Skill: %s (%s)" % [_resource_display_name(skill), _ability_source(loadout.equipped_skill)])
	_add_resource_text(passive, "Passive: %s (%s)" % [_resource_display_name(passive), _ability_source(loadout.equipped_passive)])
	_add_resource_text(reaction, "Reaction: %s (%s)" % [_resource_display_name(reaction), _ability_source(loadout.equipped_reaction)])
	_add_plain_text("")
	_add_plain_text("Equipment:")
	_add_item_row("Weapon", loadout.weapon)
	_add_item_row("Armor", loadout.armor)
	_add_item_row("Helmet", loadout.helmet)
	_add_item_row("Trinket", loadout.trinket)
	_add_plain_text("")
	_add_plain_text("Tactics:")
	if loadout.tactics.is_empty():
		_add_plain_text("- none")
	else:
		for index in loadout.tactics.size():
			var tactic = loadout.tactics[index]
			if tactic != null:
				_add_resource_text(tactic, "%d. %s: %s -> %s -> %s" % [index + 1, tactic.display_name, tactic.condition, tactic.action, tactic.target])
		if loadout.current_job != null and loadout.current_job.default_tactic != null:
			_add_resource_text(loadout.current_job.default_tactic, "%d. %s: %s -> %s -> %s (job default)" % [loadout.tactics.size() + 1, loadout.current_job.default_tactic.display_name, loadout.current_job.default_tactic.condition, loadout.current_job.default_tactic.action, loadout.current_job.default_tactic.target])


func _add_item_row(slot_name: String, item: ItemDefinition) -> void:
	_add_resource_text(item, "- %s: %s" % [slot_name, _item_detail_text(item)])
	if item == null:
		return
	for effect in item.effects:
		if effect != null:
			_add_resource_text(effect, "  - %s: %s %d" % [effect.trigger, effect.effect_type, effect.amount])


func _add_plain_text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(label)
	return label


func _add_resource_text(resource: Resource, text: String) -> Label:
	if resource == null:
		return _add_plain_text(text)
	var label := _add_plain_text(text)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.mouse_entered.connect(_on_resource_mouse_entered.bind(label, resource))
	label.mouse_exited.connect(_on_resource_mouse_exited)
	return label


func _on_resource_mouse_entered(source: Control, resource: Resource) -> void:
	resource_tooltip_requested.emit(source, resource)


func _on_resource_mouse_exited() -> void:
	tooltip_cleared.emit()


func _clear_content() -> void:
	_ensure_content()
	for child in content.get_children():
		child.queue_free()


func _ensure_content() -> void:
	if content != null:
		return
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(content)


func _preview_for_unit(unit: UnitDefinition, party_units: Array[UnitDefinition]) -> Dictionary:
	var units: Array[UnitDefinition] = party_units
	if units.is_empty():
		units = [unit]
	var previews: Dictionary = PlanningStatPreviewScript.build_party_preview_by_name(units)
	return previews.get(unit.display_name, {})


func _resource_display_name(resource) -> String:
	if resource == null:
		return "none"
	return String(resource.display_name)


func _ability_source(equipped_override: Resource) -> String:
	if equipped_override != null:
		return "equipped learned override"
	return "current job"


func _item_detail_text(item: ItemDefinition) -> String:
	if item == null:
		return "none"
	var parts: Array[String] = []
	_append_stat_part(parts, "HP", item.max_hp_modifier)
	_append_stat_part(parts, "P", item.physical_damage_modifier)
	_append_stat_part(parts, "M", item.magic_damage_modifier)
	_append_stat_part(parts, "A", item.armor_modifier)
	_append_stat_part(parts, "I", item.action_interval_modifier)
	var stat_text := "no stat changes" if parts.is_empty() else _join_values(parts, ", ")
	var effect_parts: Array[String] = []
	for effect in item.effects:
		if effect != null:
			effect_parts.append("%s: %s %d" % [effect.trigger, effect.effect_type, effect.amount])
	var effect_text := "no effects" if effect_parts.is_empty() else _join_values(effect_parts, "; ")
	return "%s [%s; %s]" % [item.display_name, stat_text, effect_text]


func _append_stat_part(parts: Array[String], label: String, amount: int) -> void:
	if amount == 0:
		return
	var prefix := "+" if amount > 0 else ""
	parts.append("%s %s%d" % [label, prefix, amount])


func _job_progress_summary(unit: UnitDefinition) -> String:
	if unit.job_progress.is_empty():
		return "none"
	var parts: Array[String] = []
	for progress in unit.job_progress:
		if progress != null and progress.job != null:
			parts.append("%s L%d XP%d" % [progress.job.display_name, progress.level, progress.xp])
	return "none" if parts.is_empty() else _join_values(parts, "; ")


func _join_values(values: Array, separator: String) -> String:
	if values.is_empty():
		return "none"
	var text := ""
	for value in values:
		if not text.is_empty():
			text += separator
		text += String(value)
	return text
