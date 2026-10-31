extends SceneTree
func _initialize() -> void:
	var args=OS.get_cmdline_user_args()
	var s=preload("res://scripts/simulation/development_replay.gd").load_tape(args[0])
	var d: Dictionary=s.get("development",{})
	print("FAILURE_STATE_KEYS ",s.keys()," DEV ",d.keys())
	var project: Dictionary=d.get("project",{})
	var hand: Dictionary=d.get("hand",{})
	for key in project:
		if "scope" in key or "feature" in key or "cycle" in key:print("PROJECT ",key," ",project[key])
	for key in hand:
		if "available_features" in key or "exhausted" in key:print("HAND ",key," ",hand[key])
	quit(0)
