extends SceneTree

var checks := 0
var failures := 0
var output := ""

func _initialize() -> void:
	verify.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1

func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func verify() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		var game = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		root.size = dimensions
		root.content_scale_size = dimensions
		game._onboarding.answer(true)
		game.checkpoints.store = StudioCheckpointStore.new("user://save-notification-"+str(dimensions.x),game.checkpoints._validate_payload)
		game.checkpoints.store._writer = TCPServer.new()
		expect(game.checkpoints.store._writer.listen(47755,"127.0.0.1") == OK, "Isolated save slot acquires its own test lease")
		game._on_studio_created("Notification Studio",&"action",[],game._active_phase)
		expect(game.checkpoints.failure.is_empty() and not game.checkpoints.last_payload.is_empty(), "Actual Studio save completes")
		var quit_buttons: Array = game.find_children("*","Button",true,false).filter(func(button): return button.text == "Quit" and button.is_visible_in_tree())
		expect(quit_buttons.is_empty(), "No persistent Quit button remains over the footer")
		var notice = game.get_node_or_null("SavePresentation/SaveNotification")
		expect(notice != null, "Successful saves have a dedicated notification")
		if notice == null:
			game.queue_free(); await process_frame
			continue
		var animation: Tween = notice._animation
		animation.pause()
		var focus := root.gui_get_focus_owner()
		var saved: Dictionary = game.checkpoints.last_payload.duplicate(true)
		animation.custom_step(0.10)
		expect(notice.visible and notice.modulate.a > 0.0 and notice.modulate.a < 1.0 and notice._surface.position.y > 0.0, "Notification enters with gradual fade and slide")
		animation.custom_step(0.20)
		expect(is_equal_approx(notice.modulate.a,1.0) and is_zero_approx(notice._surface.position.y), "Entrance settles at full opacity")
		expect(notice.message.text == "Studio saved" and root.gui_get_focus_owner() == focus, "Saved notification preserves keyboard focus")
		expect(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(notice.get_global_rect()) and notice.get_global_rect().end.y <= dimensions.y-64, "Notification fits above the footer at %s" % dimensions)
		expect(notice.mouse_filter == Control.MOUSE_FILTER_IGNORE and notice._surface.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Notification never blocks clicks")
		await capture("saved-%d" % dimensions.x)
		game._checkpoint_status()
		expect(notice._animation == animation, "Repeated status callbacks do not restart the success animation")
		animation.custom_step(2.30)
		animation.custom_step(0.10)
		expect(notice.visible and notice.modulate.a > 0.0 and notice.modulate.a < 1.0, "Notification disappears with a gradual fade")
		animation.custom_step(0.50)
		expect(not notice.visible, "Success notification disappears automatically")
		await capture("dismissed-%d" % dimensions.x)
		game._checkpoint_status()
		expect(not notice.visible and game.checkpoints.last_payload == saved, "A durable status refresh neither reopens the toast nor changes save data")
		# Pure presentation checks do not fabricate any successful disk publication.
		notice.update_status(true,"",game.checkpoints.completed_saves)
		animation = notice._animation
		animation.pause(); animation.custom_step(5.0)
		expect(notice.visible and notice.message.text == "Saving Studio…", "In-flight saves do not announce success or expire early")
		notice.update_status(false,"Injected presentation-only failure",game.checkpoints.completed_saves)
		animation = notice._animation
		animation.pause(); animation.custom_step(5.0)
		expect(notice.visible and notice.message.text == "Not saved", "Failure remains visible rather than fading as a success")
		notice.update_status(false,"",game.checkpoints.completed_saves+1)
		animation = notice._animation
		animation.pause(); animation.custom_step(0.3)
		expect(notice.message.text == "Studio saved", "A later success replaces the failure cleanly")
		paused = true
		animation.play()
		await create_timer(3.0,true).timeout
		expect(not notice.visible, "Notification animation completes while the game is paused")
		paused = false
		notice.update_status(true,"",game.checkpoints.completed_saves+1)
		notice.set_success_context(false)
		notice.update_status(false,"",game.checkpoints.completed_saves+2)
		animation = notice._animation
		animation.pause(); animation.custom_step(1.0)
		expect(not notice.visible, "Save completing outside Studio dismisses an existing in-flight panel")
		notice.update_status(false,"Presentation-only failure outside Studio",game.checkpoints.completed_saves+2)
		animation = notice._animation
		animation.pause(); animation.custom_step(1.0)
		expect(notice.visible and notice.message.text == "Not saved", "Failures remain visible outside Studio")
		notice.update_status(false,"",game.checkpoints.completed_saves+3)
		animation = notice._animation
		animation.pause(); animation.custom_step(1.0)
		expect(not notice.visible, "Recovery publication outside Studio dismisses an existing failure panel")
		notice.set_success_context(true)
		expect(game.checkpoints.last_payload == saved, "All presentation checks preserve the actual checkpoint")
		game.queue_free(); await process_frame
	print("Save notification: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
