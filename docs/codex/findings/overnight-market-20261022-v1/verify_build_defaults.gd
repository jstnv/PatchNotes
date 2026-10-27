extends SceneTree
func _initialize() -> void:
	var workers: int=ProjectSettings.get_setting("threading/worker_pool/max_threads")
	if workers != -1:
		push_error("Import-only worker limit leaked into packaged game")
		quit(1)
		return
	var expected := OS.get_cmdline_user_args()[0]
	var actual := preload("res://scripts/simulation/development_replay.gd").source_identity()
	if actual != expected:
		push_error("Packaged source identity differs from final snapshot: "+actual)
		quit(1)
		return
	var browser := preload("res://scripts/ui/market_browser.gd").new()
	var methods: Array=browser.get_script().get_script_method_list().map(func(method: Dictionary): return method.name)
	browser.free()
	if not methods.has("_input") or methods.has("_unhandled_key_input"):
		push_error("Packaged Market does not contain final cancel handler")
		quit(1)
		return
	print("PACKAGED_WORKER_DEFAULT PASS: ",workers)
	print("PACKAGED_SOURCE_IDENTITY PASS: ",actual)
	print("PACKAGED_MARKET_INPUT PASS")
	quit(0)
