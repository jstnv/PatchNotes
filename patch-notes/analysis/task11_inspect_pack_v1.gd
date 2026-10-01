## External diagnostic, never shipped. Enumerates the mounted artifact itself.
extends SceneTree

var paths: Array[String] = []

func walk(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null: return
	directory.include_hidden = true
	for file in directory.get_files(): paths.append(path.path_join(file))
	for folder in directory.get_directories(): walk(path.path_join(folder))

func _initialize() -> void:
	walk("res://")
	paths.sort()
	var out := OS.get_cmdline_user_args()[0]
	FileAccess.open(out, FileAccess.WRITE).store_string(JSON.stringify({"engine": Engine.get_version_info(), "paths": paths}, "  "))
	print("PACK_INSPECTION paths=", paths.size())
	quit()
