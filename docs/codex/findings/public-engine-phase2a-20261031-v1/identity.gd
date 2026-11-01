extends SceneTree
func _initialize() -> void:
 var data={"source_identity":preload("res://scripts/simulation/development_replay.gd").source_identity(),"studio_build":StudioCheckpoint.BUILD,"content_revision":StudioCheckpoint.new().revision()}
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify(data))
 quit(0)
