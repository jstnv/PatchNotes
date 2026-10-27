extends SceneTree
const Replay := preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void:
	var paths: Array[String] = []
	Replay._collect("res://scripts",paths)
	Replay._collect("res://data",paths)
	for path in ["res://queries/market_release_index.gd","res://queries/market_release_index.gdc","res://queries/market_release_index.gd.remap"]:
		if FileAccess.file_exists(path): paths.append(path)
	paths.sort()
	var rows: Array = []
	for path in paths:
		if path.begins_with("res://scripts/debug/"): continue
		if path.ends_with(".gd") or path.ends_with(".gdc") or path.ends_with(".gd.remap") or path.ends_with(".json"):
			rows.append([path,FileAccess.get_sha256(path)])
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"identity":Replay.source_identity(),"rows":rows}))
	print("SCORE_FLOATS_SOURCE ",Replay.source_identity())
	quit()
