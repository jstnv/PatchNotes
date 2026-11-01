extends SceneTree
func _initialize() -> void:
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"source":preload("res://scripts/simulation/development_replay.gd").source_identity()}));quit()
