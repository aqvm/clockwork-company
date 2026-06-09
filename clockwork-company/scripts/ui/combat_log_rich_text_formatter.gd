extends RefCounted
class_name CombatLogRichTextFormatter


static func append_line(target_log: RichTextLabel, line: String, highlight_palette) -> void:
	target_log.append_text("%s\n" % format_line(line, highlight_palette))


static func format_line(line: String, highlight_palette) -> String:
	var safe_text := escape_bbcode_text(line)
	var color_text := highlight_color_for_line(line, highlight_palette)
	if color_text.is_empty():
		return safe_text
	return "[color=%s]%s[/color]" % [color_text, safe_text]


static func escape_bbcode_text(text: String) -> String:
	return text.replace("[", "[lb]")


static func highlight_color_for_line(line: String, highlight_palette) -> String:
	if highlight_palette == null:
		return ""
	if line.begins_with("Result:"):
		return bbcode_color_text(highlight_palette.result_color)
	if line.begins_with("t="):
		return bbcode_color_text(highlight_palette.timestamp_color)
	if "Damage dealt:" in line:
		return bbcode_color_text(highlight_palette.damage_color)
	if " attacks " in line:
		return bbcode_color_text(highlight_palette.attack_color)
	if " heals " in line:
		return bbcode_color_text(highlight_palette.heal_color)
	if " guards:" in line or "guard expires:" in line:
		return bbcode_color_text(highlight_palette.guard_color)
	if line.begins_with("Tactic selected:") or line.begins_with("No tactic matched;") or line.begins_with("Tactic skipped:"):
		return bbcode_color_text(highlight_palette.tactic_color)
	if line.begins_with("Job effect ") or line.begins_with("Ancestry feature "):
		return bbcode_color_text(highlight_palette.job_effect_color)
	if " triggers " in line:
		return bbcode_color_text(highlight_palette.item_trigger_color)
	if " gains boon " in line or " refreshes boon " in line or " intensifies boon " in line or line.begins_with("Boon "):
		return bbcode_color_text(highlight_palette.boon_color)
	if " gains ailment " in line or " refreshes ailment " in line or " intensifies ailment " in line or line.begins_with("Ailment "):
		return bbcode_color_text(highlight_palette.ailment_color)
	if " is defeated" in line:
		return bbcode_color_text(highlight_palette.defeat_color)
	return ""


static func bbcode_color_text(color: Color) -> String:
	return "#" + color.to_html(false)
