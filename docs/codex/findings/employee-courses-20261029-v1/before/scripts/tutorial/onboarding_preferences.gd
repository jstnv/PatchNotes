class_name OnboardingPreferences
extends RefCounted

const PATH := "user://onboarding-v1.cfg"
var path := PATH
var error := ""

func read() -> Dictionary:
	error = ""
	var defaults := {"version":1,"answered":false,"experienced":false,"completed":false}
	if not FileAccess.file_exists(path): return defaults
	var file := ConfigFile.new()
	if file.load(path) != OK:
		error = "Could not read the tutorial preference."
		return defaults
	var values := defaults.duplicate()
	for key: String in defaults:
		if not file.has_section_key("tutorial",key):
			error = "Incomplete tutorial preference."
			return defaults
		var value: Variant = file.get_value("tutorial",key)
		if typeof(value) != typeof(defaults[key]) or (key == "version" and value != 1):
			error = "Unsupported tutorial preference."
			return defaults
		values[key] = value
	if values.completed and not values.answered:
		error = "Inconsistent tutorial preference."
		return defaults
	return values

func answer(experienced: bool) -> bool:
	var values := read()
	values.answered = true
	values.experienced = experienced
	return _write(values)

func finish() -> bool:
	var values := read()
	values.answered = true
	values.completed = true
	return _write(values)

func _write(values: Dictionary) -> bool:
	var file := ConfigFile.new()
	for key: String in values: file.set_value("tutorial",key,values[key])
	var result := file.save(path+".tmp")
	if result == OK: result = DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
	error = "" if result == OK else "Could not remember the tutorial preference; you can still continue."
	return result == OK
