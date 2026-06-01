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

func _ready() -> void:
	custom_minimum_size = Vector2(108, 132)


func configure(snapshot: Dictionary) -> void:
	unit_name = snapshot.get("name", unit_name)
	team = snapshot.get("team", team)
	max_hp = max(1, int(snapshot.get("max_hp", max_hp)))
	current_hp = clamp(int(snapshot.get("hp", current_hp)), 0, max_hp)
	action_interval = max(1, int(snapshot.get("action_interval", action_interval)))
	next_action_time = float(snapshot.get("next_action_time", next_action_time))
	display_time = float(snapshot.get("display_time", display_time))
	is_alive = bool(snapshot.get("is_alive", is_alive))
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 58)
	var body_radius := 28.0
	var team_color := _team_color()
	var body_color := team_color.darkened(0.55)
	if not is_alive:
		body_color = Color(0.18, 0.18, 0.2, 1.0)

	draw_circle(center, body_radius, body_color)
	draw_arc(center, body_radius, 0.0, TAU, 48, team_color, 2.5)

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

	var cooldown_background := Rect2(center.x - 28.0, center.y + 38.0, 56.0, 7.0)
	draw_rect(cooldown_background, Color(0.13, 0.14, 0.17, 1.0), true)
	var cooldown_ratio := _cooldown_ratio()
	var cooldown_width := cooldown_background.size.x * cooldown_ratio
	if cooldown_width > 0.0:
		draw_rect(Rect2(cooldown_background.position, Vector2(cooldown_width, cooldown_background.size.y)), team_color, true)

	var text_color := Color(0.9, 0.93, 0.97, 1.0) if is_alive else Color(0.55, 0.57, 0.62, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 42.0, 20.0), unit_name, HORIZONTAL_ALIGNMENT_LEFT, 84, 13, text_color)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(center.x - 30.0, center.y + 15.0),
		"%d/%d" % [current_hp, max_hp],
		HORIZONTAL_ALIGNMENT_LEFT,
		60,
		12,
		text_color
	)


func _team_color() -> Color:
	if team == TEAM_ENEMY:
		return Color(0.86, 0.34, 0.3, 1.0)
	return Color(0.33, 0.63, 0.94, 1.0)


func _cooldown_ratio() -> float:
	if not is_alive:
		return 0.0
	var remaining: float = max(0.0, next_action_time - display_time)
	return clamp(remaining / float(action_interval), 0.0, 1.0)
