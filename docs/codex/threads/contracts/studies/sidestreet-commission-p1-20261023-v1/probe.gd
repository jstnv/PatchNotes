extends SceneTree
func _initialize() -> void:
	var run := RunState.new()
	var ok := run.has_method("get_commission_quote")
	print("COMMISSION_API_PRESENT=",ok)
	quit(0 if ok else 1)
