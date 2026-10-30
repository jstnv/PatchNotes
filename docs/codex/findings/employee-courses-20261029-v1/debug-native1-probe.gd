extends "res://scripts/debug/verify_feature_store_radial.gd"
var checks:=0
func test(ok: bool,label: String) -> void:
	checks+=1;expect(ok,label)
func key(code: Key) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=down;root.push_input(event)
		await process_frame
func click(control: Control) -> void:
	var point:=control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;root.push_input(event)
		await process_frame
func _verify() -> void:
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame
		root.size=dimensions;root.content_scale_size=dimensions
		game._onboarding.answer(true)
		var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
		var session: RefCounted=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"developer_ui","studio_name":"Developer UI","specialty":"action","traits":[],"seed":"4417"},catalog)
		game.checkpoints.attach(session.run);test(game._finish_checkpoint_load(session.run),"Actual Gameplay mounts normal Studio")
		game.checkpoints.pending=true;test(await game.checkpoints.wait_saved(),"Normal save is durable before testing tools")
		var normal: Dictionary=game.checkpoints.store.inspect().payload
		await key(KEY_F8);await create_timer(0.3).timeout
		var tools: CanvasLayer=game.developer_tools
		test(tools.visible and tools.panel.visible and tools.surface.theme==FolderUI.THEME,"F8 opens the shared-style Developer panel")
		test(not game.checkpoints.debug_session and not tools.badge.visible,"Opening is passive and does not activate debug")
		test(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(tools.surface.get_global_rect()),"Developer panel fits supported resolution")
		await click(tools.unlimited)
		for i in 80:
			if game.checkpoints.debug_session and not tools._busy:break
			await process_frame
		test(game.checkpoints.debug_session and tools.sandbox.unlimited and tools.badge.is_visible_in_tree(),"Pointer activates unlimited cash and persistent unsaved badge")
		await click(tools.unlock)
		test(game.run_state.owns_feature(&"dynamic_sequencing") and game.run_state.owns_feature(&"player_level_editor"),"Unlock button grants current late Features")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("PN_CARD_FRAME_OUTPUT").get_basename()+"-%d.png"%dimensions.x)
		await key(KEY_ESCAPE)
		test(not tools.panel.visible and tools.badge.is_visible_in_tree(),"Escape closes tools while retaining debug indicator")
		await key(KEY_ESCAPE);await create_timer(0.3).timeout
		test(game.pause_menu.is_open(),"Hidden tools do not steal ordinary pause input")
		await key(KEY_ESCAPE);await create_timer(0.25).timeout
		test(not game.pause_menu.is_open(),"Resume still works in debug")
		test(game.checkpoints.store.inspect().payload==normal,"Native debug interaction never overwrites normal Continue")
		game.queue_free();await process_frame;await process_frame
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("DEVELOPER_UI checks=%d failures=%d"%[checks,failures]);quit(failures)
