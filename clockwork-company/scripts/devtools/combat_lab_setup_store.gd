extends RefCounted

const SETUP_FILE_EXTENSION := ".json"


static func save_dictionary(path: String, setup: Dictionary, overwrite := false) -> Dictionary:
	if path.strip_edges().is_empty():
		return {"ok": false, "message": "empty file path"}
	if FileAccess.file_exists(path) and not overwrite:
		return {"ok": false, "message": "%s already exists" % path}
	var dir_path := path.get_base_dir()
	var dir_err := ensure_directory(dir_path)
	if dir_err != OK:
		return {"ok": false, "message": "could not create %s (error %d)" % [dir_path, dir_err]}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "could not write %s" % path}
	file.store_string(JSON.stringify(setup, "\t"))
	file.close()
	return {"ok": true}


static func load_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "%s was not found" % path}
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK or not (json.data is Dictionary):
		return {"ok": false, "message": "invalid JSON in %s" % path}
	return {"ok": true, "setup": json.data}


static func list_saved_setups(setup_dir: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var dir := DirAccess.open(setup_dir)
	if dir == null:
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(SETUP_FILE_EXTENSION):
			results.append(_setup_entry(setup_dir, file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	results.sort_custom(func(a, b): return String(a.get("display_name", "")) < String(b.get("display_name", "")))
	return results


static func delete_setup_at_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "%s was not found" % path}
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if err != OK:
		return {"ok": false, "message": "%s (error %d)" % [path, err]}
	return {"ok": true}


static func setup_path_for_id(id: String, setup_dir: String) -> String:
	return "%s/%s%s" % [setup_dir.trim_suffix("/"), sanitize_setup_id(id), SETUP_FILE_EXTENSION]


static func sanitize_setup_id(value: String) -> String:
	var sanitized := value.strip_edges().to_lower()
	var out := ""
	var previous_was_separator := false
	for index in sanitized.length():
		var character := sanitized.substr(index, 1)
		var is_alnum := (character >= "a" and character <= "z") or (character >= "0" and character <= "9")
		if is_alnum:
			out += character
			previous_was_separator = false
		elif not previous_was_separator:
			out += "_"
			previous_was_separator = true
	return out.strip_edges().trim_prefix("_").trim_suffix("_")


static func ensure_directory(path: String) -> int:
	if path.strip_edges().is_empty():
		return ERR_INVALID_PARAMETER
	var absolute_path := ProjectSettings.globalize_path(path)
	return DirAccess.make_dir_recursive_absolute(absolute_path)


static func _setup_entry(setup_dir: String, file_name: String) -> Dictionary:
	var path := "%s/%s" % [setup_dir.trim_suffix("/"), file_name]
	var entry := {
		"setup_id": file_name.get_basename(),
		"display_name": file_name.get_basename(),
		"notes": "",
		"path": path,
	}
	var load_result := load_dictionary(path)
	if bool(load_result.get("ok", false)):
		var setup: Dictionary = load_result.get("setup", {})
		entry["setup_id"] = String(setup.get("setup_id", entry["setup_id"]))
		entry["display_name"] = String(setup.get("display_name", entry["display_name"]))
		entry["notes"] = String(setup.get("notes", ""))
	return entry
