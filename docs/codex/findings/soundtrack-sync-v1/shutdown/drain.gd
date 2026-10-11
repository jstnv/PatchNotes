extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	await create_timer(0.1).timeout
	root.get_node("Soundtrack").player.stop()
	await create_timer(0.1).timeout
	quit()
