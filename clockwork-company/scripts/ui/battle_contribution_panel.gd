extends PanelContainer
class_name BattleContributionPanel

const UIStyleHelperScript := preload("res://scripts/ui/ui_style_helper.gd")

const HEADERS := ["Unit", "Team", "Act", "Dmg", "Heal", "Taken", "Kills", "Mit/Prev"]
const MIN_COLUMN_WIDTHS := [96, 64, 38, 48, 48, 54, 42, 66]
const MAX_COLUMN_WIDTHS := [260, 110, 60, 78, 78, 78, 60, 90]

var rows_box: VBoxContainer = null
var column_widths: Array[float] = []


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
	_recalculate_column_widths(contributions)
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
	for index in HEADERS.size():
		var label := _cell(HEADERS[index], index)
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(label)
	rows_box.add_child(row)


func _add_contribution_row(contribution: Dictionary) -> void:
	var row := _row()
	var values := [
		String(contribution.get("name", "")),
		String(contribution.get("team", "")),
		str(int(contribution.get("actions", 0))),
		str(int(contribution.get("damage_dealt", 0))),
		str(int(contribution.get("healing_done", 0))),
		str(int(contribution.get("damage_taken", 0))),
		str(int(contribution.get("kills", 0))),
		"%d/%d" % [int(contribution.get("mitigation_prevention", 0)), int(contribution.get("preventions", 0))],
	]
	for index in values.size():
		row.add_child(_cell(values[index], index))
	rows_box.add_child(row)


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	return row


func _cell(text: String, column_index := 0) -> Label:
	var label := Label.new()
	label.text = text
	var width := 72.0
	if column_index >= 0 and column_index < column_widths.size():
		width = column_widths[column_index]
	label.custom_minimum_size = Vector2(width, 0)
	label.clip_text = false
	return label


func _recalculate_column_widths(contributions: Array) -> void:
	column_widths.clear()
	for index in HEADERS.size():
		var width: float = _text_width(HEADERS[index])
		for row in contributions:
			if row is Dictionary:
				width = max(width, _text_width(_value_for_column(row, index)))
		column_widths.append(clamp(width + 14.0, MIN_COLUMN_WIDTHS[index], MAX_COLUMN_WIDTHS[index]))


func _value_for_column(contribution: Dictionary, index: int) -> String:
	match index:
		0:
			return String(contribution.get("name", ""))
		1:
			return String(contribution.get("team", ""))
		2:
			return str(int(contribution.get("actions", 0)))
		3:
			return str(int(contribution.get("damage_dealt", 0)))
		4:
			return str(int(contribution.get("healing_done", 0)))
		5:
			return str(int(contribution.get("damage_taken", 0)))
		6:
			return str(int(contribution.get("kills", 0)))
		7:
			return "%d/%d" % [int(contribution.get("mitigation_prevention", 0)), int(contribution.get("preventions", 0))]
	return ""


func _text_width(text: String) -> float:
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	if font == null:
		return float(text.length() * 8)
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _clear_rows() -> void:
	for child in rows_box.get_children():
		rows_box.remove_child(child)
		child.queue_free()
