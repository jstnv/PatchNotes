extends "res://scripts/debug/verify_pause_menu.gd"

var output := ""

func _initialize() -> void:
	await process_frame
	create_timer(60, true, false, true).timeout.connect(func(): push_error("Pause motion timeout"); quit(2))
	node_added.connect(_replace_store)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	music = root.get_node("Soundtrack")
	await process_frame
	game._on_studio_created("Pause motion", &"action", [], game._active_phase)
	await process_frame
	await skip_save_invitation()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	var view: PauseMenu = game.pause_menu
	var animated: bool = "_animation" in view and "_content" in view
	expect(animated, "Pause menu has an interruptible visual transition")
	if not animated:
		print("PAUSE_MOTION checks=%d failures=%d" % [checks,failures])
		quit(failures)
		return
	for dimensions in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await process_frame
		var before := game_state()
		var playback: int = music.player.get_stream_playback().get_instance_id()
		var focus: Control = game.get_node("%GameplayHUD").settings_button
		focus.grab_focus()
		view.open()
		var motion: Tween = view._animation
		motion.pause()
		expect(paused and view.is_open() and root.gui_get_focus_owner() == view.resume_button, "Pause and Resume focus apply immediately on entrance")
		view.open()
		expect(view._animation == motion, "Duplicate open does not restart the entrance")
		motion.custom_step(view.ENTER_SECONDS * 0.4)
		expect(view.panel.visible and view.panel.modulate.a > 0.0 and view.panel.modulate.a < 1.0 and view._content.position.y > 0.0, "Menu and dimmer fade in while content slides")
		await capture_motion("enter", dimensions)
		motion.custom_step(view.ENTER_SECONDS)
		expect(is_equal_approx(view.panel.modulate.a,1.0) and is_zero_approx(view._content.position.y), "Entrance settles at authored opacity and alignment")
		expect(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(view.resume_button.get_global_rect()) and Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(view.main_menu_button.get_global_rect()), "Pause controls fit supported viewport")
		await capture_motion("open", dimensions)
		var signals := [0]
		view.settings_requested.connect(func(): signals[0] += 1, CONNECT_ONE_SHOT)
		view.close()
		motion = view._animation
		motion.pause()
		expect(not paused and not view.is_open() and root.gui_get_focus_owner() == focus, "Resume and previous focus restore immediately during exit")
		expect(_panel_input(view,false), "Fading menu releases mouse and keyboard input recursively")
		view.settings_button.pressed.emit()
		expect(signals[0] == 0, "Closing buttons cannot dispatch a stale menu action")
		motion.custom_step(view.EXIT_SECONDS * 0.4)
		expect(view.panel.visible and view.panel.modulate.a > 0.0 and view.panel.modulate.a < 1.0 and view._content.position.y > 0.0, "Exit stays visible for a gradual fade and slide")
		await capture_motion("exit", dimensions)
		var alpha: float = view.panel.modulate.a
		var offset: float = view._content.position.y
		view.open()
		expect(is_equal_approx(view.panel.modulate.a,alpha) and is_equal_approx(view._content.position.y,offset), "Reopening during exit retains the current pose")
		motion = view._animation
		motion.pause(); motion.custom_step(view.ENTER_SECONDS + 0.1)
		expect(paused and view.panel.visible and _panel_input(view,true), "Reversal completes without an old hide callback or lost input")
		view.close()
		motion = view._animation
		motion.pause(); motion.custom_step(view.EXIT_SECONDS + 0.1)
		expect(not view.panel.visible and not paused, "Completed exit hides the overlay and leaves gameplay active")
		expect(game_state() == before and music.player.get_stream_playback().get_instance_id() == playback, "Animation preserves gameplay/RNG and audio playback identity")
		# The real tween must advance even with both gameplay clocks suspended.
		Engine.time_scale = 0.0
		view.open()
		await create_timer(view.ENTER_SECONDS + 0.15, true, false, true).timeout
		expect(paused and is_equal_approx(view.panel.modulate.a,1.0), "Real entrance completes while paused at zero time scale")
		view.close()
		await create_timer(view.EXIT_SECONDS + 0.15, true, false, true).timeout
		expect(not view.panel.visible and not paused, "Real exit completes at zero time scale")
		Engine.time_scale = 1.0
	# Destroying a paused owner must release its pause and bound tween.
	view.open()
	game.queue_free()
	await process_frame
	expect(not paused, "Scene teardown releases pause during entrance")
	print("PAUSE_MOTION checks=%d failures=%d" % [checks,failures])
	quit(failures)

func capture_motion(label: String, dimensions: Vector2i) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(output.path_join("%s-%d.png" % [label,dimensions.x])) == OK, "Captured " + label)

func _panel_input(view: PauseMenu,active: bool) -> bool:
	if ClassDB.class_get_integer_constant_list("Control").has("MOUSE_BEHAVIOR_ENABLED"):
		return view.panel.get("mouse_behavior_recursive")==ClassDB.class_get_integer_constant("Control","MOUSE_BEHAVIOR_ENABLED" if active else "MOUSE_BEHAVIOR_DISABLED") and view.panel.get("focus_behavior_recursive")==ClassDB.class_get_integer_constant("Control","FOCUS_BEHAVIOR_ENABLED" if active else "FOCUS_BEHAVIOR_DISABLED")
	if active:return view._compat_input_modes.is_empty()
	return view.resume_button.mouse_filter==Control.MOUSE_FILTER_IGNORE and view.resume_button.focus_mode==Control.FOCUS_NONE
