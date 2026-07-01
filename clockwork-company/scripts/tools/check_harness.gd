extends RefCounted
class_name CheckHarness

var case_count := 0


func run_case(name: String, callback: Callable) -> void:
	case_count += 1
	var passed := bool(callback.call())
	assert(passed, "Check case failed: %s" % name)


func require(condition: bool, message: String) -> bool:
	assert(condition, message)
	return condition
