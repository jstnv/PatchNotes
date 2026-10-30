extends SceneTree
func _initialize() -> void:
	var run := RunState.new()
	if not run.has_method("get_publisher_relationships"):
		print("EXPECTED FAIL: RunState has no relationship observation API")
		quit(1)
	else:
		quit(0)
