extends SceneTree

const CheckHarnessScript := preload("res://scripts/tools/check_harness.gd")
const ContentSchemaScript := preload("res://scripts/data/content_schema.gd")
const JsonContentLoaderScript := preload("res://scripts/modding/json_content_loader.gd")
const TriggeredEffectResolverScript := preload("res://scripts/combat/rules/triggered_effect_resolver.gd")

var check_completed := false


func _init() -> void:
	process_frame.connect(_quit_if_incomplete, CONNECT_ONE_SHOT)
	var checks = CheckHarnessScript.new()
	checks.run_case("content load result succeeds for authored content", _check_content_load_result_succeeds)
	checks.run_case("triggered resolver effect types are schema-owned", _check_triggered_effect_types_are_schema_owned)
	print("Content schema checks passed: %d cases." % checks.case_count)
	check_completed = true
	quit(0)


func _check_content_load_result_succeeds() -> bool:
	var result = JsonContentLoaderScript.load_content_result(["integration_test_mod_pack"])
	return result.succeeded() and not result.resources.is_empty()


func _check_triggered_effect_types_are_schema_owned() -> bool:
	for effect_type in TriggeredEffectResolverScript.SHARED_EFFECT_TYPES:
		if not ContentSchemaScript.EFFECT_TYPE_VALUES.has(effect_type):
			return false
	return true


func _quit_if_incomplete() -> void:
	if check_completed:
		return
	push_error("Content schema checks did not complete before the first frame.")
	quit(1)
