extends "res://scripts/debug/verify_ui_folder_navigation.gd"
func click(button: Button) -> void:
	await settle()
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position=point
	Input.parse_input_event(motion)
	await process_frame
	var hovered := root.gui_get_hovered_control()
	print("POINTER_DIAGNOSTIC ",{"target":button.get_path(),"point":point,"hovered":hovered.get_path() if hovered else "none","mouse":root.get_mouse_position(),"input_disabled":root.gui_disable_input,"viewport":root.get_visible_rect(),"screen_transform":root.get_screen_transform(),"size":root.size})
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
	root.size=Vector2i(1280,720); root.content_scale_size=root.size
	await integration()
	quit(failures)
func integration() -> void:
	if failures>0: return
	node_added.connect(_replace_store)
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await settle()
	var menu: MainMenu=game._active_phase
	var hud: GameplayHUD=game.get_node("%GameplayHUD")
	var original := StudioCheckpoint.new().capture(game.run_state)
	await click(action(menu,"HowToPlay"))
	expect(hud.how_to_play.is_open() and menu.navigation.depth()==2,"Main Menu pointer action opens the existing full guide on the stack")
	await capture("how-to-play-1280")
	await key(KEY_ESCAPE)
	await click(action(menu,"Settings"))
	expect(hud.settings_menu.is_open() and menu.navigation.depth()==2,"Main Menu pointer action opens existing Settings on the stack")
	await key(KEY_ESCAPE)
	expect(not hud.settings_menu.is_open() and menu.navigation.depth()==1 and StudioCheckpoint.new().capture(game.run_state)==original,"Settings Back restores root without changing run state")
	await click(action(menu,"StartGame"))
	menu._name_input.text="Reference Studio"
	for index in range(1,menu._specialty.item_count):
		menu._specialty.select(index); menu._specialty.item_selected.emit(index)
		var roster := StudioSpecialties.preview(menu._specialty.get_item_metadata(index))
		expect(roster.names.all(func(name): return menu._preview.text.contains(name)),"Every unchanged specialty roster is fully bound to its preview")
	menu._trait_checks[&"studio_buzz"].button_pressed=true
	menu._open_folder(&"traits"); menu._show_review()
	game._onboarding.answer(true)
	await capture("before-create")
	await click(menu._play)
	if is_instance_valid(menu): print("CREATE_DIAGNOSTIC ",{"error":menu._error.text,"status":menu.checkpoint_info.status,"depth":menu.navigation.depth(),"busy":menu.navigation.busy,"submitted":menu._submitted,"attention":[menu._needs_attention(&"genre"),menu._needs_attention(&"traits"),menu._needs_attention(&"overview")],"button":menu._play.get_global_rect(),"setup":menu._setup_surface.get_global_rect(),"root":root.size})
	expect(game._active_phase is StudioPhase and game.run_state.get_studio_name()=="Reference Studio","Actual pointer Create enters regular Studio through the existing gameplay callback")
	expect(game.checkpoints.store.inspect().status==&"valid" and game.guided_tutorial==null and not root.gui_disable_input,"Creation publishes a normal Studio-only save and releases navigation")
	await capture("created-studio-1280")
	game.queue_free(); await process_frame
	# Destroy a menu during motion, rather than only after its animation settles.
	var closing := MainMenu.new()
	root.add_child(closing); await settle()
	action(closing,"StartGame").pressed.emit()
	expect(root.gui_disable_input,"Teardown fixture owns an active navigation input lock")
	closing.queue_free(); await process_frame
	expect(not root.gui_disable_input,"Teardown during motion releases the owned input lock")
