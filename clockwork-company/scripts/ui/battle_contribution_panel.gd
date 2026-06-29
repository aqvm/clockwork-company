extends PanelContainer
class_name BattleContributionPanel

const UIStyleHelperScript := preload("res://scripts/ui/ui_style_helper.gd")

var rows_box: VBoxContainer = null


func _ready() -> void:
	if get_child_count() == 0:
		_build_ui()


func show_contributions(contributions: Array) -> void:
	if rows_box == null:
		_build_ui()
	_clear_rows()
	visible = not contributions.is_empty()
	if contributions.is_empty():
		return
	_add_header()
	for row in contributions:
		if row is Dictionary:
			_add_contribution_row(row)


func clear_contributions() -> void:
	if rows_box != null:
		_clear_rows()
	visible = false


func _build_ui() -> void:
	UIStyleHelperScript.apply_panel(self)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)
	var title := Label.new()
	title.text = "Battle Contributions"
	UIStyleHelperScript.style_heading(title)
	root.add_child(title)
	rows_box = VBoxContainer.new()
	rows_box.add_theme_constant_override("separation", 2)
	root.add_child(rows_box)
	visible = false


func _add_header() -> void:
	var row := _row()
	for text in ["Unit", "Team", "Act", "Dmg", "Heal", "Taken", "Kills", "Mit/Prev"]:
		var label := _cell(text)
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(label)
	rows_box.add_child(row)


func _add_contribution_row(contribution: Dictionary) -> void:
	var row := _row()
	for text in [
		String(contribution.get("name", "")),
		String(contribution.get("team", "")),
		str(int(contribution.get("actions", 0))),
		str(int(contribution.get("damage_dealt", 0))),
		str(int(contribution.get("healing_done", 0))),
		str(int(contribution.get("damage_taken", 0))),
		str(int(contribution.get("kills", 0))),
		"%d/%d" % [int(contribution.get("mitigation_prevention", 0)), int(contribution.get("preventions", 0))],
	]:
		row.add_child(_cell(text))
	rows_box.add_child(row)


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	return row


func _cell(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(72, 0)
	label.clip_text = true
	return label


func _clear_rows() -> void:
	for child in rows_box.get_children():
		rows_box.remove_child(child)
		child.queue_free()
