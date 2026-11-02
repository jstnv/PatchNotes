extends SceneTree

var checks:=0
var failures:=0
var output:=""
func check(ok:bool,label:String)->void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize()->void:
	node_added.connect(func(node:Node):
		if node is CheckpointCoordinator:node.store=preload("res://scripts/debug/verify_rival_gameplay_activation.gd").TestStore.new("user://saves/studio",node._validate_payload))
	_run.call_deferred()
func settle()->void:await create_timer(0.4).timeout
func capture(label:String)->void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(label+".png"))==OK,"Captured "+label)
func key(code:Key)->void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func pad(button:JoyButton)->void:
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func luminance(color:Color)->float:
	var linear:=color.srgb_to_linear()
	return 0.2126*linear.r+0.7152*linear.g+0.0722*linear.b
func contrast(a:Color,b:Color)->float:return (maxf(luminance(a),luminance(b))+0.05)/(minf(luminance(a),luminance(b))+0.05)
func _run()->void:
	create_timer(200).timeout.connect(func():push_error("Onyx verifier timed out");quit(2))
	output=OS.get_environment("PN_CONTRACT_REPORT").get_base_dir()
	var theme:Theme=load("res://resources/ui/onyx_theme.tres")
	for role in [&"TitleMenuButton",&"HubButton",&"SelectedButton",&"ArcadePrimary"]:
		for state in ["normal","hover","pressed","disabled"]:
			var font_key:String={"normal":"font_color","hover":"font_hover_color","pressed":"font_pressed_color","disabled":"font_disabled_color"}[state]
			check(contrast(theme.get_color(font_key,role),theme.get_stylebox(state,role).bg_color)>=4.5,str(role)+" "+state+" text contrast meets 4.5:1")
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=dimensions;root.content_scale_size=dimensions
		var menu:=MainMenu.new();root.add_child(menu);await settle()
		var bounds:=Rect2(Vector2.ZERO,Vector2(dimensions))
		for id in ["StartGame","Continue","HowToPlay","Settings","Quit"]:
			check(bounds.encloses(menu.action_button(id).get_global_rect()),id+" fits "+str(dimensions))
		check(menu.action_button("Continue").disabled,"No save disables Continue")
		menu.action_button("StartGame").grab_focus();await key(KEY_DOWN)
		check(menu.action_button("HowToPlay").has_focus(),"Keyboard skips disabled Continue")
		await pad(JOY_BUTTON_DPAD_DOWN)
		check(menu.action_button("Settings").has_focus(),"Controller D-pad moves menu focus")
		var requested:=[false];menu.settings_requested.connect(func():requested[0]=true)
		await pad(JOY_BUTTON_A);check(requested[0],"Controller confirm activates Settings")
		menu.action_button("StartGame").grab_focus();await settle()
		await capture("main-menu-"+str(dimensions.x))
		menu.free();await process_frame
	var saved:=MainMenu.new()
	saved.checkpoint_info={"status":&"valid","payload":{"run":{"studio_name":"Saved Studio","completed_run_cycles":12}}}
	root.add_child(saved);await settle()
	check(not saved.action_button("Continue").disabled and saved.action_button("StartGame").text=="New Run","Valid checkpoint enables Continue and preserves New Run label")
	var continued:=[false];saved.continue_requested.connect(func():continued[0]=true)
	saved.action_button("Continue").grab_focus();await key(KEY_ENTER)
	check(continued[0],"Keyboard confirm activates valid Continue")
	saved.free();await process_frame
	var long_save:=MainMenu.new()
	long_save.checkpoint_info={"status":&"valid","payload":{"run":{"studio_name":"A deliberately extremely long Studio name for menu wrapping and readability","completed_run_cycles":92,"calendar":{"cycles_per_month":4,"origin_cycle":0,"origin_week":0}}}}
	root.size=Vector2i(1152,648);root.content_scale_size=root.size;root.add_child(long_save);await settle()
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(long_save.action_button("Quit").get_global_rect()),"Saved long Studio metadata leaves Quit visible at1152")
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(long_save._title_screen.get_global_rect()),"Entire long-saved title stack including metadata and footer fits")
	await capture("long-saved-menu-1152");long_save.free();await process_frame
	var game:Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame;game._onboarding.answer(true)
	game.checkpoints.store._writer=TCPServer.new()
	check(game.checkpoints.store._writer.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")==OK,"Private save lease obtained")
	var catalog:RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var run:RunState=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"onyx-verifier","studio_name":"Patch Notes Studio","specialty":"action","traits":[],"seed":"4417"},catalog).run
	game.checkpoints.attach(run)
	check(game._finish_checkpoint_load(run),"Fresh Studio mounts")
	if game.checkpoints.is_saving():await game.checkpoints.wait_saved()
	var hud:GameplayHUD=game.get_node("%GameplayHUD");hud.contextual_tip.dismiss();hud.tutorial_overlay.close()
	var studio:StudioPhase=game._active_phase
	await settle()
	var overview:Control=studio._overview
	check(overview.values.Cash.text==CashFormatter.format_exact_cents(run.get_cash_cents()) and overview.values.Fans.text==str(run.get_fans()),"Overview displays actual cash and fans")
	check(run.add_cash_cents(12345),"Fixture income succeeds")
	check(overview.values.Cash.text==CashFormatter.format_exact_cents(run.get_cash_cents()),"Overview follows live cash changes")
	check(overview.values["Next Bill"].text==CashFormatter.format_exact_cents(run.get_studio_finance_report().monthly_rent_cents),"Next Bill uses the live rent installment")
	hud.refresh()
	await create_timer(2).timeout
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=dimensions;root.content_scale_size=dimensions;await settle()
		var bounds:=Rect2(Vector2.ZERO,Vector2(dimensions))
		check(bounds.encloses(overview.get_global_rect()),"Studio overview fits "+str(dimensions))
		for label in overview.values.values():check(bounds.encloses(label.get_global_rect()),"Live overview value fits")
		check(hud.header_title.text.contains("1980") and hud.header_title.text.contains("MONTH 1"),"Studio header uses live calendar")
		await capture("studio-phase-"+str(dimensions.x))
		studio.get_node("%StudioInfoMenuButton").grab_focus();await pad(JOY_BUTTON_A);await settle();studio._hub.settle_motion();await settle()
		check(studio._hub.groups[&"studio_info"].visible and not overview.visible,"Controller opens Studio Info and replaces overview")
		check(studio.get_node("%StudioInfoMenuButton").theme_type_variation==&"SelectedButton","Selected group uses indigo")
		await capture("studio-info-"+str(dimensions.x))
		await pad(JOY_BUTTON_B);await settle();studio._hub.settle_motion();await settle()
		check(overview.visible and studio.get_node("%StudioInfoMenuButton").has_focus(),"Controller Back restores overview and owning focus")
	var before:=preload("res://scripts/simulation/development_replay.gd").digest([run.get_cash_cents(),run.get_completed_run_cycles(),run.random_streams.snapshot(),run.get_studio_finance_snapshot()])
	for group in [&"management",&"market",&"production"]:
		studio._hub.select_group(group);studio._hub.settle_motion();await settle()
		check(studio._hub.selected==group and not overview.visible,"Current group opens: "+str(group))
		studio._hub.close_group();studio._hub.settle_motion();await settle()
	check(before==preload("res://scripts/simulation/development_replay.gd").digest([run.get_cash_cents(),run.get_completed_run_cycles(),run.random_streams.snapshot(),run.get_studio_finance_snapshot()]),"Presentation navigation preserves finance/calendar/RNG")
	if game.checkpoints.is_saving():await game.checkpoints.wait_saved()
	game.queue_free();await process_frame
	var file:=FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures}));file.close()
	print("ONYX_PRESENTATION checks=%d failures=%d"%[checks,failures]);quit(failures)
