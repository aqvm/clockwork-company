extends Control
class_name UnitStatusDot

const TEAM_ALLY := "Allies"
const TEAM_ENEMY := "Enemies"

var unit_name := ""
var team := TEAM_ALLY
var max_hp := 1
var current_hp := 1
var action_interval := 1
var next_action_time := 1.0
var display_time := 0.0
var is_alive := true
var is_acting := false
var turn_pulse_started_at := -9999.0
var floating_text := ""
var floating_text_started_at := -9999.0
var floating_text_pulse_started_at := -9999.0
var is_defeated := false
var defeat_time := -9999.0

const PULSE_DURATION := 0.45
const FLOATING_TEXT_DURATION := 6.0
const FLOATING_TEXT_PULSE_DURATION := 1.0
const DEFEAT_FADE_DURATION := 0.8

func _ready() -> void:
	custom_minimum_size = Vector2(122, 148)


func configure(snapshot: Dictionary) -> void:
	unit_name = snapshot.get("name", unit_name)
	team = snapshot.get("team", team)
	max_hp = max(1, int(snapshot.get("max_hp", max_hp)))
	current_hp = clamp(int(snapshot.get("hp", current_hp)), 0, max_hp)
	action_interval = max(1, int(snapshot.get("action_interval", action_interval)))
	next_action_time = float(snapshot.get("next_action_time", next_action_time))
	display_time = float(snapshot.get("display_time", display_time))
	is_alive = bool(snapshot.get("is_alive", is_alive))
	is_acting = bool(snapshot.get("is_acting", is_acting))
	turn_pulse_started_at = float(snapshot.get("turn_pulse_started_at", turn_pulse_started_at))
	floating_text = String(snapshot.get("floating_text", floating_text))
	floating_text_started_at = float(snapshot.get("floating_text_started_at", floating_text_started_at))
	floating_text_pulse_started_at = float(snapshot.get("floating_text_pulse_started_at", floating_text_pulse_started_at))
	is_defeated = bool(snapshot.get("is_defeated", is_defeated))
	defeat_time = float(snapshot.get("defeat_time", defeat_time))
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 64)
	var body_radius := 34.0
	var team_color := _team_color()
	team_color = _color_with_defeat_fade(team_color)
	var body_color := team_color.darkened(0.55)
	if not is_alive:
		body_color = Color(0.18, 0.18, 0.2, 1.0)

	draw_circle(center, body_radius, body_color)
	draw_arc(center, body_radius, 0.0, TAU, 48, team_color, 2.5)
	_draw_action_pulse(center, body_radius, team_color)

	var health_ratio := float(current_hp) / float(max_hp)
	var health_start := -PI * 0.8
	var health_end := PI * -0.2
	draw_arc(center, body_radius + 9.0, health_start, health_end, 32, Color(0.22, 0.24, 0.28, 1.0), 4.0)
	draw_arc(
		center,
		body_radius + 9.0,
		health_start,
		health_start + ((health_end - health_start) * health_ratio),
		32,
		Color(0.29, 0.88, 0.5, 1.0) if is_alive else Color(0.42, 0.42, 0.45, 1.0),
		4.0
	)

	var cooldown_background := Rect2(center.x - 32.0, center.y + 44.0, 64.0, 7.0)
	draw_rect(cooldown_background, Color(0.13, 0.14, 0.17, 1.0), true)
	var cooldown_ratio := _cooldown_ratio()
	var cooldown_width := cooldown_background.size.x * cooldown_ratio
	if cooldown_width > 0.0:
		draw_rect(Rect2(cooldown_background.position, Vector2(cooldown_width, cooldown_background.size.y)), team_color, true)

	var text_color := Color(0.9, 0.93, 0.97, 1.0) if is_alive else Color(0.55, 0.57, 0.62, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 46.0, 14.0), unit_name, HORIZONTAL_ALIGNMENT_LEFT, 92, 13, text_color)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(center.x - 34.0, center.y + 4.0),
		"%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_CENTER,
		68,
		13,
		text_color
	)
	_draw_floating_delta_text(center)


func _team_color() -> Color:
	if team == TEAM_ENEMY:
		return Color(0.86, 0.34, 0.3, 1.0)
	return Color(0.33, 0.63, 0.94, 1.0)


func _cooldown_ratio() -> float:
	if not is_alive:
		return 0.0
	var remaining: float = max(0.0, next_action_time - display_time)
	return clamp(remaining / float(action_interval), 0.0, 1.0)


func _draw_action_pulse(center: Vector2, body_radius: float, pulse_color: Color) -> void:
	var pulse_age: float = display_time - turn_pulse_started_at
	if pulse_age < 0.0 or pulse_age > PULSE_DURATION:
		return
	var t: float = pulse_age / PULSE_DURATION
	var ring_radius: float = body_radius + (2.0 + ((16.0 - 2.0) * t))
	var alpha: float = (1.0 - t) * 0.6
	draw_arc(center, ring_radius, 0.0, TAU, 48, Color(pulse_color.r, pulse_color.g, pulse_color.b, alpha), 3.0)


func _draw_floating_delta_text(center: Vector2) -> void:
	var text_age: float = display_time - floating_text_started_at
	if floating_text.is_empty() or text_age < 0.0 or text_age > FLOATING_TEXT_DURATION:
		return
	var t: float = text_age / FLOATING_TEXT_DURATION
	var y_offset: float = 0.0 + ((-8.0 - 0.0) * t)
	var alpha: float = 1.0 - t
	var pulse_age: float = display_time - floating_text_pulse_started_at
	var pulse_scale: float = 1.0
	if pulse_age >= 0.0 and pulse_age <= FLOATING_TEXT_PULSE_DURATION:
		var pulse_t: float = pulse_age / FLOATING_TEXT_PULSE_DURATION
		pulse_scale = 1.0 + (0.18 * (1.0 - pulse_t))
	var is_heal := floating_text.begins_with("+")
	var text_color := Color(0.45, 0.95, 0.6, alpha) if is_heal else Color(0.98, 0.48, 0.45, alpha)
	var text_size: int = int(round(15.0 * pulse_scale))
	var text_width: float = 44.0 * pulse_scale
	var text_pos := Vector2(center.x - (text_width * 0.5), center.y - 12.0 + y_offset)
	# Soft dark backdrop keeps values legible against arcs/fills.
	draw_rect(Rect2(center.x - 24.0, center.y - 27.0 + y_offset, 48.0, 16.0), Color(0.05, 0.06, 0.08, 0.52 * alpha), true)
	draw_string(
		ThemeDB.fallback_font,
		text_pos + Vector2(1.0, 1.0),
		floating_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		text_width,
		text_size,
		Color(0.02, 0.02, 0.03, alpha * 0.75)
	)
	draw_string(
		ThemeDB.fallback_font,
		text_pos,
		floating_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		text_width,
		text_size,
		text_color
	)


func _color_with_defeat_fade(source: Color) -> Color:
	if not is_defeated:
		return source
	var defeat_age: float = max(0.0, display_time - defeat_time)
	var t: float = clamp(defeat_age / DEFEAT_FADE_DURATION, 0.0, 1.0)
	var gray: float = source.get_luminance()
	var gray_color: Color = Color(gray, gray, gray, source.a)
	return source.lerp(gray_color.darkened(0.35), t)
