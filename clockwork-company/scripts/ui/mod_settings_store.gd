extends RefCounted
class_name ModSettingsStore

const MOD_SETTINGS_PATH := "user://mod_settings.cfg"
const MOD_SETTINGS_SECTION := "mods"
const MOD_SETTINGS_KEY_ENABLED_IDS := "enabled_pack_ids"


static func load_enabled_ids() -> Dictionary:
	var out := {}
	var config := ConfigFile.new()
	if config.load(MOD_SETTINGS_PATH) != OK:
		return out
	var raw_ids: Array = config.get_value(MOD_SETTINGS_SECTION, MOD_SETTINGS_KEY_ENABLED_IDS, [])
	for id in raw_ids:
		out[String(id)] = true
	return out


static func save_enabled_ids(enabled_ids: Array[String]) -> void:
	var config := ConfigFile.new()
	config.set_value(MOD_SETTINGS_SECTION, MOD_SETTINGS_KEY_ENABLED_IDS, enabled_ids)
	var err := config.save(MOD_SETTINGS_PATH)
	if err != OK:
		push_warning("Failed to save mod settings to %s" % MOD_SETTINGS_PATH)
