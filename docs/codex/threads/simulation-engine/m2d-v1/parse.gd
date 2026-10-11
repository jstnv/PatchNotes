extends SceneTree
func _initialize() -> void:
	var script=load("res://scripts/debug/verify_development_protocol.gd")
	quit(0 if script!=null and script.can_instantiate() else 1)
