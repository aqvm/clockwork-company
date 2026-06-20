extends RefCounted
class_name TagUtils


static func id_for_tag(tag) -> String:
	if tag == null:
		return ""
	if tag is Resource:
		var resource_tag_id := String(tag.get("tag_id"))
		if not resource_tag_id.is_empty():
			return resource_tag_id.strip_edges().to_lower()
	return String(tag).strip_edges().to_lower()


static func has_tag(tags: Array, tag_id: String) -> bool:
	var normalized := tag_id.strip_edges().to_lower()
	for tag in tags:
		if id_for_tag(tag) == normalized:
			return true
	return false


static func has_any_tag(tags: Array, candidates: Array) -> bool:
	for candidate in candidates:
		if has_tag(tags, id_for_tag(candidate)):
			return true
	return false


static func ids(tags: Array) -> Array[String]:
	var results: Array[String] = []
	for tag in tags:
		var id := id_for_tag(tag)
		if not id.is_empty():
			results.append(id)
	return results
