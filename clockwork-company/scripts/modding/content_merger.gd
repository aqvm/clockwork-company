extends RefCounted
class_name ContentMerger


static func merge(base_data: Dictionary, mod_packs: Array) -> Dictionary:
	var merged := {
		"ancestries": base_data["ancestries"].duplicate(true),
		"statuses": base_data["statuses"].duplicate(true),
		"items": base_data["items"].duplicate(true),
		"jobs": base_data["jobs"].duplicate(true),
		"tactics": base_data["tactics"].duplicate(true),
		"loadouts": base_data["loadouts"].duplicate(true),
		"units": base_data["units"].duplicate(true),
		"demo_roster": base_data["demo_roster"].duplicate(),
	}

	for pack in mod_packs:
		_apply_collection_overrides(merged["ancestries"], pack.get("ancestries", []))
		_apply_collection_overrides(merged["statuses"], pack.get("statuses", []))
		_apply_collection_overrides(merged["items"], pack.get("items", []))
		_apply_collection_overrides(merged["jobs"], pack.get("jobs", []))
		_apply_collection_overrides(merged["tactics"], pack.get("tactics", []))
		_apply_collection_overrides(merged["loadouts"], pack.get("loadouts", []))
		_apply_collection_overrides(merged["units"], pack.get("units", []))
		if pack.has("demo_roster"):
			merged["demo_roster"] = pack["demo_roster"].duplicate()

	return merged


static func _apply_collection_overrides(target: Dictionary, entries: Array) -> void:
	for raw in entries:
		var entry: Dictionary = raw
		if not entry.has("id"):
			push_warning("Skipping mod entry without id.")
			continue
		var id := String(entry["id"]).strip_edges()
		if id.is_empty():
			push_warning("Skipping mod entry with empty id.")
			continue
		var merged_entry: Dictionary = Dictionary(target.get(id, {})).duplicate(true)
		for key in entry.keys():
			merged_entry[key] = entry[key]
		merged_entry["id"] = id
		target[id] = merged_entry
