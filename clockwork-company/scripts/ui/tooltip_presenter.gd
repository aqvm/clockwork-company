extends PanelContainer
class_name TooltipPresenter

const ResourceTooltipBuilderScript := preload("res://scripts/ui/resource_tooltip_builder.gd")

const MOUSE_OFFSET := Vector2(18, 18)
const MAX_WIDTH := 420.0

var label: RichTextLabel = null
var follow_mouse := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.064, 0.08, 0.96)
	style.border_color = Color(0.34, 0.39, 0.48, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	label = RichTextLabel.new()
	label.bbcode_enabled = false
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(MAX_WIDTH, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(label)


func _process(_delta: float) -> void:
	if visible and follow_mouse:
		_place_near_mouse()


func show_resource(resource) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_resource(resource))


func show_runtime_unit(snapshot: Dictionary) -> void:
	show_text(ResourceTooltipBuilderScript.text_for_runtime_unit(snapshot))


func show_text(text: String) -> void:
	if text.is_empty():
		hide_tooltip()
		return
	label.clear()
	label.append_text(text)
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
		tooltip_size = label.get_combined_minimum_size() + Vector2(20, 16)
	var x: float = min(desired.x, viewport_size.x - tooltip_size.x - 8.0)
	var y: float = min(desired.y, viewport_size.y - tooltip_size.y - 8.0)
	global_position = Vector2(max(8.0, x), max(8.0, y))
