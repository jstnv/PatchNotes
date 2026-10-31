extends SceneTree
func _initialize() -> void:
	await process_frame
	var value={"runtime_source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"studio_build":StudioCheckpoint.BUILD,"content_revision":StudioCheckpoint.new().revision(),"godot":Engine.get_version_info().string,"catalog_total":FeatureStoreCatalog.starting_features().size()+FeatureStoreCatalog.entries().size(),"retired":FeatureStoreCatalog.RETIRED_IDS.size()}
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify(value,"\t"));quit(0)
