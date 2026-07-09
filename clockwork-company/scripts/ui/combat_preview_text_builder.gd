extends RefCounted

const COMBAT_LOG_HEADER := "Combat log:"


static func battle_static_lines(log_lines: Array[String]) -> Array[String]:
	var static_lines: Array[String] = []
	var found_combat_log := false
	var skipping_battle_start_event := false
	for line in log_lines:
		if line == COMBAT_LOG_HEADER:
			found_combat_log = true
			continue
		if line.begins_with("t=000 | Battle starts."):
			skipping_battle_start_event = true
			continue
		if skipping_battle_start_event and line == "Roster:":
			skipping_battle_start_event = false
		elif skipping_battle_start_event:
			continue

		if not found_combat_log:
			static_lines.append(line)
	return static_lines


static func run_static_lines(campaign_manager, run_state, fight_static_lines: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	if campaign_manager != null:
		for campaign_line in campaign_manager.status_lines():
			lines.append(campaign_line)
		lines.append("")
	if run_state != null:
		for run_line in run_state.status_lines():
			lines.append(run_line)
	lines.append("")
	for line in fight_static_lines:
		lines.append(line)
	return lines


static func combat_lab_static_lines(combat_lab_state, fight_static_lines: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	lines.append("Combat Lab: assemble arbitrary cloned catalog units, then resolve them through the real simulator.")
	if combat_lab_state != null:
		lines.append("Allies: %s" % _combat_lab_party_summary(combat_lab_state.allied_units))
		lines.append("Enemies: %s" % _combat_lab_party_summary(combat_lab_state.enemy_units))
		if not combat_lab_state.last_message.is_empty():
			lines.append(combat_lab_state.last_message)
	lines.append("")
	for line in fight_static_lines:
		lines.append(line)
	return lines


static func campaign_landing_lines(campaign_manager) -> Array[String]:
	var lines: Array[String] = []
	if campaign_manager == null:
		return lines
	lines = campaign_manager.status_lines()
	lines.append("")
	lines.append("Available scenarios:")
	var scenarios: Array = campaign_manager.available_scenarios()
	if scenarios.is_empty():
		lines.append("- none")
	else:
		for scenario in scenarios:
			lines.append("- %s: %s" % [scenario.display_name, scenario.story_intro])
	return lines


static func _combat_lab_party_summary(units: Array[UnitDefinition]) -> String:
	if units.is_empty():
		return "empty"
	var names: Array[String] = []
	for index in units.size():
		names.append("%d. %s" % [index + 1, units[index].display_name])
	return ", ".join(names)
