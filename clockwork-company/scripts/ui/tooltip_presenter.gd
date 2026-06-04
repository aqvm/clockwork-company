extends PanelContainer
class_name TooltipPresenter

const ResourceTooltipBuilderScript := preload("res://scripts/ui/resource_tooltip_builder.gd")

const MOUSE_OFFSET := Vector2(18, 18)
const MAX_WIDTH := 380.0
const PANEL_PADDING := Vector2(28, 22)

var label: RichTextLabel = null
var follow_mouse := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.048, 0.052, 0.06, 0.98)
	style.border_color = Color(0.52, 0.58, 0.68, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14
	style.content_margin_top = 11
	style.content_margin_right = 14
	style.content_margin_bottom = 11
	add_theme_stylebox_override("panel", style)

	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(MAX_WIDTH, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("default_color", Color(0.88, 0.9, 0.94))
	label.add_theme_font_size_override("normal_font_size", 14)
	add_child(label)


func _process(_delta: float) -> void:
	if visible and follow_mouse:
		_place_near_mouse()


func show_resource(resource) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_resource(resource))


func show_runtime_unit(snapshot: Dictionary) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_runtime_unit(snapshot))


func show_glossary_term(term: String) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_glossary_term(term))


func show_structured_events(events: Array[Dictionary]) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_structured_events(events))


func show_text(text: String) -> void:
	if text.is_empty():
		hide_tooltip()
		return
	label.clear()
	label.append_text(_format_tooltip_text(text))
	visible = true
	follow_mouse = true
	await get_tree().process_frame
	_place_near_mouse()


func hide_tooltip() -> void:
	visible = false
	follow_mouse = false


func _place_near_mouse() -> void:
	var viewport_size := get_viewport_rect().size
	var desired := get_viewport().get_mouse_position() + MOUSE_OFFSET
	var tooltip_size := size
	if tooltip_size.x <= 1.0 or tooltip_size.y <= 1.0:
		tooltip_size = label.get_combined_minimum_size() + PANEL_PADDING
	var x: float = min(desired.x, viewport_size.x - tooltip_size.x - 8.0)
	var y: float = min(desired.y, viewport_size.y - tooltip_size.y - 8.0)
	global_position = Vector2(max(8.0, x), max(8.0, y))


func _format_tooltip_text(text: String) -> String:
	var lines := text.split("\n")
	var formatted: Array[String] = []
	for index in lines.size():
		var escaped: String = _escape_bbcode(String(lines[index]))
		if escaped.is_empty():
			formatted.append("")
		elif index == 0:
			formatted.append("[font_size=16][color=#f4d38b][b]%s[/b][/color][/font_size]" % escaped)
		elif escaped.ends_with(":"):
			formatted.append("[color=#b9c7dc][b]%s[/b][/color]" % escaped)
		elif escaped.begins_with("- "):
			formatted.append("  [color=#d7dde8]%s[/color]" % escaped)
		else:
			formatted.append(escaped)
	return "\n".join(formatted)


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")
