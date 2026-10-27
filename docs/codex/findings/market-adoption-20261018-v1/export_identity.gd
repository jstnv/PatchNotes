extends SceneTree
func _initialize() -> void:
	print("EXPORTED_SOURCE ",preload("res://scripts/simulation/development_replay.gd").source_identity())
	print("EXPORTED_CONTENT ",StudioCheckpoint.new().revision())
	quit()
