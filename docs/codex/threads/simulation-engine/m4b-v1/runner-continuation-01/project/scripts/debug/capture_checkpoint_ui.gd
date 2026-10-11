extends SceneTree

func _init() -> void: call_deferred("_run")

func capture(label: String, width: int) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/codex/findings/checkpoint-runtime-v1/%s-%d.png" % [label,width])

func _run() -> void:
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = size
		root.content_scale_size = size
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		if game.checkpoints.store.inspect().status==&"empty":
			game._on_studio_created("Checkpoint UI",&"action",[],game._active_phase)
			await process_frame
			if game.checkpoints.store.inspect().status!=&"valid":
				push_error("Capture requires a saved Studio: "+game.checkpoints.failure)
				quit(1)
				return
			game.queue_free()
			await process_frame
			game = load("res://scenes/gameplay.tscn").instantiate()
			root.add_child(game)
			await process_frame
		root.size = size
		root.content_scale_size = size
		await capture("continue-menu",size.x)
		game._continue_checkpoint()
		await process_frame
		game.get_node("%GameplayHUD").tutorial_overlay.close()
		await capture("saved-studio",size.x)
		game.checkpoints.store.fault = &"before_write"
		game.run_state.add_cash_cents(1)
		await process_frame
		await capture("save-failure",size.x)
		game.queue_free()
		await process_frame
	quit()
