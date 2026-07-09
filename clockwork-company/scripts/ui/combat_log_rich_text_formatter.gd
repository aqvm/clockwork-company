extends RefCounted
class_name CombatLogRichTextFormatter

const KEYWORD_RULES := [
	{"text": "Damage dealt", "color": "damage", "meta": "damage"},
	{"text": "Physical", "color": "damage", "meta": "physical_damage"},
	{"text": "physical", "color": "damage", "meta": "physical_damage"},
	{"text": "magic", "color": "heal", "meta": "magic_damage"},
	{"text": "attacks", "color": "attack", "meta": "attack"},
	{"text": "uses", "color": "attack", "meta": "skill"},
	{"text": "heals", "color": "heal", "meta": "healing"},
	{"text": "guards", "color": "guard", "meta": "guard"},
	{"text": "guard", "color": "guard", "meta": "guard"},
	{"text": "Tactic selected", "color": "tactic", "meta": "tactic"},
	{"text": "Tactic skipped", "color": "tactic", "meta": "tactic"},
	{"text": "No tactic matched", "color": "tactic", "meta": "tactic"},
	{"text": "Passive", "color": "job_effect", "meta": "passive"},
	{"text": "Reaction", "color": "job_effect", "meta": "reaction"},
	{"text": "resolves", "color": "job_effect", "meta": "triggered_effect"},
	{"text": "boon", "color": "boon", "meta": "boon"},
	{"text": "Boon", "color": "boon", "meta": "boon"},
	{"text": "ailment", "color": "ailment", "meta": "ailment"},
	{"text": "Ailment", "color": "ailment", "meta": "ailment"},
	{"text": "Burning", "color": "ailment", "meta": "burning"},
	{"text": "Shock", "color": "ailment", "meta": "shock"},
	{"text": "Frost", "color": "ailment", "meta": "frost"},
	{"text": "Ward", "color": "boon", "meta": "ward"},
	{"text": "Rot", "color": "ailment", "meta": "rot"},
	{"text": "Renewal", "color": "boon", "meta": "renewal"},
	{"text": "defeated", "color": "defeat", "meta": "defeat"},
	{"text": "Result", "color": "result", "meta": "result"},
]

const META_TOOLTIPS := {
	"timestamp": "Timeline\n`t=...` marks the simulation time when this log entry occurred. Lower times resolve earlier.",
	"damage": "Damage Dealt\nThe final HP damage event after armor, shields, prevention, and status hooks have had a chance to modify or stop it.",
	"physical_damage": "Physical Damage\nPhysical damage is reduced by armor before it becomes HP damage. Some statuses and reactions care specifically about physical damage.",
	"magic_damage": "Magic Damage\nMagic damage bypasses armor and interacts with magic-specific hooks such as Energy Shield, Shock propagation, and ally magic-damage reactions.",
	"attack": "Attack / Skill Use\nA unit is taking an active combat action. Attack entries can trigger targeting, hit, damage, reaction, and defeat hooks.",
	"skill": "Skill Use\nThe unit is resolving a job, bridge, or assigned skill. Skill effects can trigger when the skill is used or completed.",
	"healing": "Healing\nHealing restores HP up to the target's current maximum HP. Some reactions can prevent enemy healing, and Rot punishes healing received.",
	"guard": "Guard\nGuard adds temporary armor that can absorb later physical damage before HP is lost.",
	"tactic": "Tactic\nTactics are checked in order. The first tactic whose condition and target are valid chooses the unit's action.",
	"passive": "Passive\nA passive is an always-available job feature. Current-job passives are active by default unless a learned passive overrides them.",
	"reaction": "Reaction\nA reaction is a job feature that wakes up in response to combat events such as damage, status requests, or ally ailments.",
	"triggered_effect": "Triggered Effect\nAn authored effect resolved from an item, skill, passive, reaction, or scenario rule after its trigger and condition matched.",
	"boon": "Boon\nA beneficial status. Boons can have finite durations, stack rules, and special behavior depending on their status type.",
	"ailment": "Ailment\nA harmful status. Ailments can be blocked by Ward, transferred, consumed, detonated, or counted by ailment-based mechanics.",
	"burning": "Burning\nAn ailment that deals magic status damage after the afflicted unit completes an action, then decays by one stack.",
	"shock": "Shock\nAn ailment that discharges after magic damage, arcing part of that damage to another allied unit and consuming a stack when it arcs.",
	"frost": "Frost\nAn ailment that amplifies incoming physical damage, then shatters when physical damage lands.",
	"ward": "Ward\nA boon that blocks an incoming ailment application and consumes a stack when it does so.",
	"rot": "Rot\nAn ailment that removes maximum HP when healing lands on the afflicted unit.",
	"renewal": "Renewal\nA boon that heals the unit when an ailment is removed.",
	"defeat": "Defeat\nThe unit reached 0 HP. Defeat can trigger kill, death, and enemy-death status hooks.",
	"result": "Battle Result\nThe resolved winner and ending state for this simulated battle.",
}


static func append_line(target_log: RichTextLabel, line: String, highlight_palette, tooltip_lookup := {}) -> void:
	target_log.append_text("%s\n" % format_line(line, highlight_palette, tooltip_lookup))


static func format_line(line: String, highlight_palette, tooltip_lookup := {}) -> String:
	if highlight_palette == null:
		return escape_bbcode_text(line)
	var dynamic_rules := _dynamic_rules_for_line(line, tooltip_lookup)
	var out := ""
	var index := 0
	while index < line.length():
		var match := _keyword_at(line, index, dynamic_rules)
		if match.is_empty():
			out += escape_bbcode_text(line.substr(index, 1))
			index += 1
		else:
			out += _keyword_markup(String(match["text"]), String(match["color"]), String(match["meta"]), highlight_palette)
			index += String(match["text"]).length()
	if line.begins_with("t="):
		out = _keyword_markup(line.substr(0, 5), "timestamp", "timestamp", highlight_palette) + escape_bbcode_text(line.substr(5))
	return out


static func escape_bbcode_text(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")


static func tooltip_for_meta(meta: Variant, tooltip_lookup := {}) -> String:
	var meta_text := _decode_meta(String(meta))
	if meta_text.begins_with("lookup|"):
		var lookup_name := meta_text.trim_prefix("lookup|")
		return String(tooltip_lookup.get(lookup_name, ""))
	if meta_text.begins_with("detail|"):
		var parts := meta_text.split("|", false, 3)
		if parts.size() >= 3:
			if String(parts[1]) == "_":
				return String(parts[2])
			return "%s\n%s" % [String(parts[1]), String(parts[2])]
	return String(META_TOOLTIPS.get(meta_text, ""))


static func _keyword_at(line: String, index: int, dynamic_rules: Array) -> Dictionary:
	for rule in dynamic_rules:
		var text := String(rule["text"])
		if line.substr(index, text.length()) == text:
			return rule
	for rule in KEYWORD_RULES:
		var text := String(rule["text"])
		if line.substr(index, text.length()) == text:
			return rule
	return {}


static func _keyword_markup(text: String, color_key: String, meta: String, highlight_palette) -> String:
	var color_text := _color_for_key(color_key, highlight_palette)
	if color_text.is_empty():
		return escape_bbcode_text(text)
	return "[url=%s][color=%s]%s[/color][/url]" % [_encode_meta(meta), color_text, escape_bbcode_text(text)]


static func _dynamic_rules_for_line(line: String, tooltip_lookup: Dictionary) -> Array[Dictionary]:
	var rules: Array[Dictionary] = []
	_add_lookup_rules(rules, line, tooltip_lookup)
	_add_unit_action_rules(rules, line, tooltip_lookup)
	_add_tactic_rules(rules, line, tooltip_lookup)
	_add_triggered_effect_rules(rules, line, tooltip_lookup)
	_add_status_application_rules(rules, line, tooltip_lookup)
	rules.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("text", "")).length() > String(right.get("text", "")).length()
	)
	return rules


static func _add_lookup_rules(rules: Array[Dictionary], line: String, tooltip_lookup: Dictionary) -> void:
	for name in tooltip_lookup.keys():
		var text := String(name)
		if text.length() < 3 or line.find(text) < 0:
			continue
		_add_lookup_rule(rules, text, tooltip_lookup)


static func _add_unit_action_rules(rules: Array[Dictionary], line: String, tooltip_lookup: Dictionary) -> void:
	var marker := " uses "
	var marker_index := line.find(marker)
	if marker_index < 0:
		return
	var actor_name := line.substr(0, marker_index).strip_edges()
	var remaining := line.substr(marker_index + marker.length()).strip_edges()
	var period_index := remaining.find(".")
	if period_index >= 0:
		remaining = remaining.substr(0, period_index)
	var skill_name := remaining
	for prefix in ["job skill ", "secondary skill ", "assigned skill "]:
		if skill_name.begins_with(prefix):
			skill_name = skill_name.substr(prefix.length()).strip_edges()
	if not actor_name.is_empty() and not _add_lookup_rule(rules, actor_name, tooltip_lookup):
		_add_detail_rule(rules, actor_name, "Unit: %s" % actor_name, "This unit is the acting source for the log entry. Damage, healing, status application, and triggered effects may credit this unit.")
	if not skill_name.is_empty() and not _add_lookup_rule(rules, skill_name, tooltip_lookup):
		_add_detail_rule(rules, skill_name, "Skill: %s" % skill_name, "A named active skill. Skill tooltips in the lab show its exact action, target, status, cooldown, and authored effects.")


static func _add_tactic_rules(rules: Array[Dictionary], line: String, tooltip_lookup: Dictionary) -> void:
	if not line.begins_with("Tactic selected:"):
		return
	var tactic_text := line.trim_prefix("Tactic selected:").strip_edges()
	var period_index := tactic_text.find(".")
	if period_index >= 0:
		tactic_text = tactic_text.substr(0, period_index)
	var colon_index := tactic_text.find(":")
	var tactic_name := tactic_text.substr(0, colon_index).strip_edges() if colon_index >= 0 else tactic_text
	if not tactic_name.is_empty() and not _add_lookup_rule(rules, tactic_name, tooltip_lookup):
		_add_detail_rule(rules, tactic_name, "Tactic: %s" % tactic_name, "This named tactic was the first matching entry in the unit's ordered tactic list.")


static func _add_triggered_effect_rules(rules: Array[Dictionary], line: String, tooltip_lookup: Dictionary) -> void:
	var marker := " resolves "
	var marker_index := line.find(marker)
	if marker_index < 0:
		return
	var source_name := line.substr(0, marker_index).strip_edges()
	var remaining := line.substr(marker_index + marker.length())
	var target_marker := " on "
	var target_index := remaining.find(target_marker)
	var effect_name := remaining.substr(0, target_index).strip_edges() if target_index >= 0 else remaining.strip_edges().trim_suffix(".")
	if not source_name.is_empty() and not _add_lookup_rule(rules, source_name, tooltip_lookup):
		_add_detail_rule(rules, source_name, "Feature or Effect Source: %s" % source_name, "This is the item, skill, passive, reaction, or scenario rule whose authored effect resolved.")
	if not effect_name.is_empty() and not _add_lookup_rule(rules, effect_name, tooltip_lookup):
		_add_detail_rule(rules, effect_name, "Triggered Effect: %s" % effect_name, "A specific authored effect whose trigger and condition matched this combat event.")


static func _add_status_application_rules(rules: Array[Dictionary], line: String, tooltip_lookup: Dictionary) -> void:
	for verb in [" gains ", " refreshes ", " intensifies "]:
		var index := line.find(verb)
		if index < 0:
			continue
		var unit_name := line.substr(0, index).strip_edges()
		if not unit_name.is_empty() and not _add_lookup_rule(rules, unit_name, tooltip_lookup):
			_add_detail_rule(rules, unit_name, "Unit: %s" % unit_name, "This unit is receiving or updating a status.")
		return


static func _add_lookup_rule(rules: Array[Dictionary], text: String, tooltip_lookup: Dictionary, color := "job_effect") -> bool:
	if text.is_empty() or not tooltip_lookup.has(text):
		return false
	rules.append({
		"text": text,
		"color": color,
		"meta": "lookup|%s" % text,
	})
	return true


static func _add_detail_rule(rules: Array[Dictionary], text: String, title: String, body: String, color := "job_effect") -> void:
	if text.is_empty():
		return
	rules.append({
		"text": text,
		"color": color,
		"meta": "detail|%s|%s" % [title, body],
	})


static func _encode_meta(meta: String) -> String:
	return meta.uri_encode()


static func _decode_meta(meta: String) -> String:
	return meta.uri_decode()


static func _color_for_key(color_key: String, highlight_palette) -> String:
	match color_key:
		"timestamp":
			return bbcode_color_text(highlight_palette.timestamp_color)
		"attack":
			return bbcode_color_text(highlight_palette.attack_color)
		"damage":
			return bbcode_color_text(highlight_palette.damage_color)
		"heal":
			return bbcode_color_text(highlight_palette.heal_color)
		"guard":
			return bbcode_color_text(highlight_palette.guard_color)
		"tactic":
			return bbcode_color_text(highlight_palette.tactic_color)
		"job_effect":
			return bbcode_color_text(highlight_palette.job_effect_color)
		"item_trigger":
			return bbcode_color_text(highlight_palette.item_trigger_color)
		"boon":
			return bbcode_color_text(highlight_palette.boon_color)
		"ailment":
			return bbcode_color_text(highlight_palette.ailment_color)
		"defeat":
			return bbcode_color_text(highlight_palette.defeat_color)
		"result":
			return bbcode_color_text(highlight_palette.result_color)
	return ""


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
