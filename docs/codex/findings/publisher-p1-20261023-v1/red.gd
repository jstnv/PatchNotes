extends SceneTree
func _initialize() -> void:
	var run := RunState.new()
	var present := run.has_method("get_publisher_relationships") and run.has_method("commit_publisher_relationship_event")
	print("P1 foundation API present: ",present)
	quit(0 if present else 1)
