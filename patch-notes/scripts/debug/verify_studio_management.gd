extends "res://scripts/debug/verify_feature_store_radial.gd"
var checks:=0
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
func test(ok: bool,label: String) -> void:checks+=1;expect(ok,label)
func _initialize() -> void:
	# Four fresh/two-release, published-save routes now also cover Info,
	# Summary and Bank destinations; retain a bound sized for the added work.
	create_timer(240).timeout.connect(func():push_error("Studio Management verifier timed out");quit(2))
	if not OS.get_environment("PN_CHECKPOINT_TEST_PORT").is_empty():
		node_added.connect(func(node: Node):
			if node is CheckpointCoordinator:node.store=preload("res://scripts/debug/verify_rival_gameplay_activation.gd").TestStore.new("user://saves/studio",node._validate_payload))
	_verify.call_deferred()
func settle() -> void:
	await create_timer(0.4).timeout
	# A group switch retracts then reveals (two shared entrance durations).
	# Wait for the owner instead of clicking its intentionally disabled controls.
	var deadline:=Time.get_ticks_msec()+5000
	while is_instance_valid(current_scene) and current_scene.get("_active_phase") is StudioPhase:
		var phase: StudioPhase=current_scene.get("_active_phase")
		if not phase._hub.transitioning and not phase._hub_motion.busy:return
		if Time.get_ticks_msec()>=deadline:expect(false,"Studio navigation settles within five seconds");return
		await process_frame
func click(button: Control) -> void:
	var point:=root.get_final_transform()*button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion);await process_frame
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;Input.parse_input_event(event);await process_frame
	await settle()
func key(code: Key) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=down;Input.parse_input_event(event);await process_frame
	await settle()
func state(run: RunState) -> String:return Replay.digest([run.get_cash_cents(),run.get_completed_run_cycles(),run.random_streams.snapshot(),run.get_owned_feature_ids(),run._feature_research,run.get_employees(),run.get_studio_finance_snapshot()])
func _verify() -> void:
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		for releases in [0,2]:
			var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame
			var test_port:=OS.get_environment("PN_CHECKPOINT_TEST_PORT")
			if not test_port.is_empty():
				game.checkpoints.store._writer=TCPServer.new()
				if game.checkpoints.store._writer.listen(int(test_port),"127.0.0.1")!=OK:quit(2);return
			root.size=dimensions;root.content_scale_size=dimensions;game._onboarding.answer(true)
			var run: RunState
			if releases==2:run=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
			else:run=Factory.create_fresh_session({"schema_version":1,"studio_id":"management","studio_name":"Management Studio","specialty":"action","traits":[],"seed":"4417"},catalog).run
			var engine_id: StringName=preload("res://scripts/debug/ui_test_actions.gd").create_feature_engine(run,"Management Engine")
			game.checkpoints.attach(run);test(game._finish_checkpoint_load(run),"Actual Gameplay mounts Studio")
			game.checkpoints.pending=true;test(await game.checkpoints.wait_saved(),"Normal Studio checkpoint publishes")
			if "--capture-baseline" in OS.get_cmdline_user_args():
				FileAccess.open(output+".baseline.json",FileAccess.WRITE).store_string(JSON.stringify(game.checkpoints.store.inspect().payload));print("MANAGEMENT_BASELINE ",Replay.source_identity());game.queue_free();await process_frame;quit(failures);return
			var hud: GameplayHUD=game.get_node("%GameplayHUD");hud.contextual_tip.dismiss();hud.tutorial_overlay.close();await settle()
			var studio: StudioPhase=game._active_phase
			var management: Button=studio.get_node_or_null("%StudioManagementButton")
			test(management!=null,"Single Studio Management dashboard entry exists")
			if management==null:game.queue_free();await process_frame;quit(failures);return
			var engines: Button=studio.get_node("%StudioEnginesButton");var employees: Button=studio.get_node("%Employees")
			test(not engines.is_visible_in_tree() and not employees.is_visible_in_tree() and not studio.get_node("%FeatureStoreButton").visible,"Destinations stay in Management; global Store is retired")
			var before:=state(run)
			var info_group: Button=studio.get_node("%StudioInfoMenuButton")
			test(studio._hub.root_buttons.keys()==[&"studio_info",&"management",&"market",&"production"],"Four Studio groups follow approved order")
			test(studio._hub.groups[&"studio_info"].get_children().map(func(button):return button.text)==["Studio Info","Post Game Summaries","Bank"],"Studio Info owns exact destination order")
			test(studio._hub.groups[&"management"].get_children().map(func(button):return button.text)==["Employees","Engines"],"Management retains current engine-specific workflow")
			await click(info_group)
			test(studio.get_node("%PostGameSummaries").is_visible_in_tree() and studio.get_node("%PostGameSummaries").disabled==(releases==0),"Studio Info keeps existing Summary release gate")
			if DisplayServer.get_name()!="headless" and releases==0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.get_basename()+"-info-%d.png"%dimensions.x)
			if releases==2:
				await click(studio.get_node("%PostGameSummaries"))
				test(studio.get_node("%SummaryPanel").is_visible_in_tree(),"Pointer opens Summary from Studio Info")
				await click(studio.get_node("%CloseSummaryButton"))
				test(studio._hub.selected==&"studio_info" and studio.get_node("%PostGameSummaries").has_focus(),"Summary Back returns to Studio Info and focus")
			await click(studio.get_node("%StudioInfoButton"))
			test(studio._studio_info.is_visible_in_tree(),"Pointer opens Studio Info details")
			await key(KEY_ESCAPE)
			test(studio._hub.selected==&"studio_info" and studio.get_node("%StudioInfoButton").has_focus() and not game.pause_menu.is_open(),"Info Escape returns to Studio Info without pausing")
			await click(studio.get_node("%StudioBankButton"))
			test(hud.studio_finances.visible,"Pointer opens Bank from Studio Info")
			test(hud.studio_finances.back_button.tooltip_text.contains("Studio Info"),"Bank return label names Studio Info")
			await key(KEY_ESCAPE)
			print("BANK_GROUP_DIAG ",{"layer":hud.studio_finances.visible,"dialog":hud.studio_finances.dialog.visible,"depth":studio._hub_motion.depth(),"busy":studio._hub_motion.busy,"selected":studio._hub.selected,"active":studio._active_menu,"focus":str(root.gui_get_focus_owner()),"paused":game.pause_menu.is_open(),"page":hud.studio_finances.page})
			test(studio._hub.selected==&"studio_info" and studio.get_node("%StudioBankButton").has_focus() and not game.pause_menu.is_open(),"Bank Escape returns to Studio Info and focus")
			if failures>0:game.queue_free();await process_frame;quit(failures);return
			await click(management)
			test(engines.is_visible_in_tree() and employees.is_visible_in_tree() and studio.get_node("%Dashboard").visible,"Management companion opens while root remains")
			test(engines.get_parent()==employees.get_parent() and engines.get_global_rect().position.y>employees.get_global_rect().position.y and is_equal_approx(engines.get_global_rect().get_center().x,employees.get_global_rect().get_center().x),"Management destinations share one vertical list")
			test(employees.disabled==(releases<2),"Existing Employees release gate remains")
			test(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(engines.get_global_rect()) and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(employees.get_global_rect()),"Both choices fit supported viewport")
			if releases==0:
				await click(hud.cash_button);test(hud.studio_finances.visible,"Shared HUD still opens Finances from Management")
				await key(KEY_ESCAPE);test(not hud.studio_finances.visible and engines.is_visible_in_tree(),"Finance Escape preserves Management beneath it")
				await click(hud.settings_button);test(hud.settings_menu.is_open(),"Shared HUD still opens Settings from Management")
				await key(KEY_ESCAPE);test(not hud.settings_menu.is_open() and engines.is_visible_in_tree(),"Settings Escape preserves Management beneath it")
				await key(KEY_F8);test(game.developer_tools.panel.visible,"Developer Tools still open from Management")
				await key(KEY_ESCAPE);test(not game.developer_tools.panel.visible and engines.is_visible_in_tree(),"Developer Escape preserves Management beneath it")
			if DisplayServer.get_name()!="headless" and releases==2:
				await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output.get_basename()+"-%d.png"%dimensions.x)
			await click(engines)
			test(studio._engine_browser!=null and studio._engine_browser.is_visible_in_tree() and not employees.is_visible_in_tree(),"Pointer enters Engines")
			studio._engine_browser._inspect(engine_id)
			studio._engine_browser.configure_button.pressed.emit();await settle()
			test(studio._feature_store!=null and studio._feature_store.is_visible_in_tree(),"Owned engine detail opens Feature Implementation")
			await click(studio._feature_store._close)
			test(studio._engine_browser.is_visible_in_tree() and studio._engine_browser.selected_id==engine_id,"Implementation Close returns to the same engine detail")
			studio._engine_browser.closed.emit();await settle()
			test(engines.is_visible_in_tree() and engines.has_focus() and studio.get_node("%Dashboard").visible,"Engines Close returns to Management with focus")
			if releases==2:
				engines.grab_focus();await key(KEY_UP);test(employees.has_focus(),"Keyboard navigates to Employees")
				await key(KEY_ENTER)
				test(studio._employees_panel!=null and studio._employees_panel.is_visible_in_tree() and not engines.is_visible_in_tree(),"Keyboard enters Employees")
				await key(KEY_ESCAPE)
				print("MANAGEMENT_ESCAPE_STATE ",{"employees":studio._employees_panel.visible,"management":engines.is_visible_in_tree(),"dashboard":studio.get_node("%Dashboard").visible,"paused":game.pause_menu.is_open(),"focus":str(root.gui_get_focus_owner())})
				test(employees.is_visible_in_tree() and employees.has_focus() and not game.pause_menu.is_open(),"Employees Escape returns one level without pausing")
			test(state(run)==before,"Browsing changes no cash, calendar, ownership, research, roster, finance or RNG")
			for group in [&"market",&"production",&"studio_info"]:studio._open_menu(group)
			await create_timer(1.0).timeout
			test(studio._hub.selected==&"studio_info" and not studio._hub.transitioning and info_group.is_visible_in_tree(),"Rapid root changes settle on Studio Info beside persistent roots")
			studio._hub_motion.animate=false
			studio._open_management();studio._hub.settle_motion()
			test(engines.is_visible_in_tree() and not studio.get_node("%StudioInfoButton").is_visible_in_tree(),"Animation bypass preserves exclusive group state")
			studio._hub_motion.animate=true
			await key(KEY_ESCAPE)
			test(studio.get_node("%Dashboard").is_visible_in_tree() and management.has_focus() and not game.pause_menu.is_open(),"Management Escape returns to Studio with focus")
			await key(KEY_ESCAPE);test(game.pause_menu.is_open(),"Ordinary Studio Escape still pauses")
			await key(KEY_ESCAPE)
			game.queue_free();await process_frame;await process_frame
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));print("STUDIO_MANAGEMENT checks=%d failures=%d"%[checks,failures]);quit(failures)
