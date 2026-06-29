extends RefCounted
class_name UIStyleHelper

const PANEL_BG := Color(0.095, 0.105, 0.125, 1.0)
const SECTION_BG := Color(0.125, 0.135, 0.158, 1.0)
const ROW_BG := Color(0.155, 0.16, 0.18, 1.0)
const BORDER := Color(0.34, 0.38, 0.45, 1.0)
const ACCENT := Color(0.78, 0.63, 0.34, 1.0)
const TEXT := Color(0.9, 0.92, 0.95, 1.0)
const MUTED_TEXT := Color(0.68, 0.73, 0.8, 1.0)


static func apply_panel(control: PanelContainer, variant := "section") -> void:
	control.add_theme_stylebox_override("panel", panel_style(variant))


static func panel_style(variant := "section") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if variant == "row":
		style.bg_color = ROW_BG
	elif variant == "root":
		style.bg_color = PANEL_BG
	else:
		style.bg_color = SECTION_BG
	style.border_color = BORDER
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
	return style


static func style_title(label: Label) -> void:
	label.add_theme_color_override("font_color", ACCENT)
	label.add_theme_font_size_override("font_size", 16)


static func style_heading(label: Label) -> void:
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", 14)


static func style_muted(label: Label) -> void:
	label.add_theme_color_override("font_color", MUTED_TEXT)
