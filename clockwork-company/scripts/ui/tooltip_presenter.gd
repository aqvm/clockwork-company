extends PanelContainer
class_name TooltipPresenter

const ResourceTooltipBuilderScript := preload("res://scripts/ui/resource_tooltip_builder.gd")

const MOUSE_OFFSET := Vector2(18, 18)
const MAX_WIDTH := 380.0
const PANEL_PADDING := Vector2(28, 22)

var label: RichTextLabel = null
var header_row: HBoxContainer = null
var pinned_label: Label = null
var close_button: Button = null
var related_label: Label = null
var related_list: VBoxContainer = null
var back_button: Button = null
var follow_mouse := false
var pinned := false
var current_resource = null
var resource_history: Array = []


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

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(content)

	header_row = HBoxContainer.new()
	header_row.visible = false
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(header_row)

	pinned_label = Label.new()
	pinned_label.text = "Pinned Tooltip"
	pinned_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pinned_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
	header_row.add_child(pinned_label)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func(): hide_tooltip(true))
	header_row.add_child(close_button)

	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(MAX_WIDTH, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("default_color", Color(0.88, 0.9, 0.94))
	label.add_theme_font_size_override("normal_font_size", 14)
	content.add_child(label)

	back_button = Button.new()
	back_button.text = "Back"
	back_button.visible = false
	back_button.pressed.connect(_on_back_pressed)
	content.add_child(back_button)

	related_label = Label.new()
	related_label.text = "Related Resources"
	related_label.visible = false
	related_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
	content.add_child(related_label)

	related_list = VBoxContainer.new()
	related_list.visible = false
	related_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(related_list)


func _process(_delta: float) -> void:
	if visible and follow_mouse:
		_place_near_mouse()


func show_resource(resource) -> void:
	if pinned:
		return
	current_resource = resource
	resource_history.clear()
	_show_resource_content(resource)


func show_runtime_unit(snapshot: Dictionary) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_runtime_unit(snapshot))


func show_glossary_term(term: String) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_glossary_term(term))


func show_structured_events(events: Array[Dictionary]) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_structured_events(events))


func show_text(text: String) -> void:
	if pinned:
		return
	current_resource = null
	resource_history.clear()
	_clear_related_links()
	if text.is_empty():
		hide_tooltip(true)
		return
	label.clear()
	label.append_text(_format_tooltip_text(text))
	visible = true
	follow_mouse = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	_place_near_mouse()


func hide_tooltip(force := false) -> void:
	if pinned and not force:
		return
	visible = false
	follow_mouse = false
	pinned = false
	current_resource = null
	resource_history.clear()
	_clear_related_links()
	_set_pinned_header_visible(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func handle_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			hide_tooltip(true)
			return true
	if not (event is InputEventMouseButton):
		return false
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return false
	if pinned:
		if not get_global_rect().has_point(mouse_event.global_position):
			hide_tooltip(true)
			return true
		return false
	pinned = true
	follow_mouse = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_pinned_header_visible(true)
	_render_related_links()
	_place_near_mouse()
	return false


func _place_near_mouse() -> void:
	var viewport_size := get_viewport_rect().size
	var desired := get_viewport().get_mouse_position() + MOUSE_OFFSET
	var tooltip_size := size
	if tooltip_size.x <= 1.0 or tooltip_size.y <= 1.0:
		tooltip_size = label.get_combined_minimum_size() + PANEL_PADDING
	var x: float = min(desired.x, viewport_size.x - tooltip_size.x - 8.0)
	var y: float = min(desired.y, viewport_size.y - tooltip_size.y - 8.0)
	global_position = Vector2(max(8.0, x), max(8.0, y))


func _show_resource_content(resource) -> void:
	if resource == null:
		show_text("")
		return
	var text: String = ResourceTooltipBuilderScript.text_for_resource(resource)
	label.clear()
	label.append_text(_format_tooltip_text(text))
	current_resource = resource
	visible = true
	if pinned:
		follow_mouse = false
		mouse_filter = Control.MOUSE_FILTER_STOP
		_render_related_links()
	else:
		follow_mouse = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_clear_related_links()
	await get_tree().process_frame
	_place_near_mouse()


func _render_related_links() -> void:
	_clear_related_links()
	if current_resource == null:
		return

	back_button.visible = not resource_history.is_empty()
	var related: Array = ResourceTooltipBuilderScript.related_resources_for_resource(current_resource)
	if related.is_empty():
		return
	related_label.visible = true
	related_list.visible = true
	for entry in related:
		var resource = entry.get("resource", null)
		if resource == null:
			continue
		var button := Button.new()
		button.text = "%s: %s" % [String(entry.get("label", "Resource")), String(entry.get("name", "Resource"))]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_related_resource_pressed.bind(resource))
		related_list.add_child(button)


func _clear_related_links() -> void:
	if back_button != null:
		back_button.visible = false
	if related_label != null:
		related_label.visible = false
	if related_list == null:
		return
	related_list.visible = false
	for child in related_list.get_children():
		child.queue_free()


func _set_pinned_header_visible(is_visible: bool) -> void:
	if header_row != null:
		header_row.visible = is_visible


func _on_related_resource_pressed(resource) -> void:
	if current_resource != null:
		resource_history.append(current_resource)
	_show_resource_content(resource)


func _on_back_pressed() -> void:
	if resource_history.is_empty():
		return
	var previous = resource_history.pop_back()
	_show_resource_content(previous)


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
