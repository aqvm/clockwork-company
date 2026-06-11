extends RefCounted
class_name ContentCatalog

const SCENARIO_DIR := "res://resources/scenarios"


static func load_scenarios() -> Array[ScenarioDefinition]:
	var scenarios: Array[ScenarioDefinition] = []
	var directory := DirAccess.open(SCENARIO_DIR)
	if directory == null:
		push_warning("Could not open scenario directory: %s" % SCENARIO_DIR)
		return scenarios

	var file_names := directory.get_files()
	file_names.sort()
	for file_name in file_names:
		if not file_name.ends_with(".tres"):
			continue
		var scenario := load("%s/%s" % [SCENARIO_DIR, file_name]) as ScenarioDefinition
		if scenario == null:
			push_warning("Skipping non-scenario resource: %s/%s" % [SCENARIO_DIR, file_name])
			continue
		scenarios.append(scenario)
	return scenarios
