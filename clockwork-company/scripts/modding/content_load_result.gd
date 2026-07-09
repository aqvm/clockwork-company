extends RefCounted
class_name ContentLoadResult

var merged_data: Dictionary = {}
var resources: Dictionary = {}
var issues: Array[Dictionary] = []


func succeeded() -> bool:
	return issues.is_empty()


func add_issue(path: String, message: String, severity := "error") -> void:
	issues.append({
		"path": path,
		"message": message,
		"severity": severity,
	})


func error_messages() -> Array[String]:
	var messages: Array[String] = []
	for issue: Dictionary in issues:
		messages.append("%s: %s" % [String(issue.get("path", "<content>")), String(issue.get("message", ""))])
	return messages
