class_name DemoSettingsStore
extends RefCounted

const PATH := "user://preferences-v1.cfg"
const BUSES := ["Master", "Music", "SFX"]

static func defaults() -> Dictionary:
	return {"version": 1, "fullscreen": false, "width": 1280, "height": 720,
		"Master": 80, "Music": 80, "SFX": 80,
		"Master_muted": false, "Music_muted": false, "SFX_muted": false}

static func valid(value: Dictionary) -> bool:
	if value.keys().size() != defaults().keys().size(): return false
	for key: String in defaults():
		if not value.has(key) or typeof(value[key]) != typeof(defaults()[key]): return false
	if value.version != 1 or Vector2i(value.width, value.height) not in [Vector2i(1152,648), Vector2i(1280,720)]: return false
	for bus: String in BUSES:
		if value[bus] < 0 or value[bus] > 100: return false
	return true

static func read_settings(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return {"values": defaults(), "error": ""}
	var config := ConfigFile.new()
	if config.load(path) != OK: return {"values": defaults(), "error": "Settings could not be read. Using defaults; the original file is preserved."}
	var values := {}
	for key: String in defaults():
		if not config.has_section_key("settings", key): return {"values": defaults(), "error": "Incomplete settings. Using defaults; original file preserved until Apply."}
		values[key] = config.get_value("settings", key)
	if not valid(values): return {"values": defaults(), "error": "Unsupported or invalid settings. Using defaults; the original file is preserved until you Apply."}
	return {"values": values, "error": ""}

static func write_settings(values: Dictionary, path: String = PATH) -> Error:
	if not valid(values): return ERR_INVALID_DATA
	var config := ConfigFile.new()
	for key: String in values: config.set_value("settings", key, values[key])
	var temporary := path + ".tmp"
	var result := config.save(temporary)
	if result != OK: return result
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))

static func apply_audio(values: Dictionary) -> void:
	for bus: String in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index == -1:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
		AudioServer.set_bus_volume_db(index, linear_to_db(float(values[bus]) / 100.0) if values[bus] > 0 else -80.0)
		AudioServer.set_bus_mute(index, values[bus + "_muted"])
