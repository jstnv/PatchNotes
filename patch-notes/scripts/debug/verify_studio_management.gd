extends "res://scripts/debug/verify_feature_store_radial.gd"
var checks:=0
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
func test(ok: bool,label: String) -> void:checks+=1;expect(ok,label)
func settle() -> void:await create_timer(0.4).timeout
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
			root.size=dimensions;root.content_scale_size=dimensions;game._onboarding.answer(true)
			var run: RunState
			if releases==2:run=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
			else:run=Factory.create_fresh_session({"schema_version":1,"studio_id":"management","studio_name":"Management Studio","specialty":"action","traits":[],"seed":"4417"},catalog).run
			game.checkpoints.attach(run);test(game._finish_checkpoint_load(run),"Actual Gameplay mounts Studio")
			game.checkpoints.pending=true;test(await game.checkpoints.wait_saved(),"Normal Studio checkpoint publishes")
			if "--capture-baseline" in OS.get_cmdline_user_args():
				FileAccess.open(output+".baseline.json",FileAccess.WRITE).store_string(JSON.stringify(game.checkpoints.store.inspect().payload));print("MANAGEMENT_BASELINE ",Replay.source_identity());game.queue_free();await process_frame;quit(failures);return
			var hud: GameplayHUD=game.get_node("%GameplayHUD");hud.contextual_tip.dismiss();hud.tutorial_overlay.close();await settle()
			var studio: StudioPhase=game._active_phase
			var management: Button=studio.get_node_or_null("%StudioManagementButton")
			test(management!=null,"Single Studio Management dashboard entry exists")
			if management==null:game.queue_free();await process_frame;quit(failures);return
			var store: Button=studio.get_node("%FeatureStoreButton");var employees: Button=studio.get_node("%Employees")
			test(not store.is_visible_in_tree() and not employees.is_visible_in_tree(),"Destination buttons no longer clutter dashboard")
			var before:=state(run)
			await click(management)
			test(store.is_visible_in_tree() and employees.is_visible_in_tree() and studio.get_node("%Dashboard").visible,"Management companion opens while root remains")
			test(store.get_parent()==employees.get_parent() and store.get_global_rect().position.y<employees.get_global_rect().position.y and is_equal_approx(store.get_global_rect().get_center().x,employees.get_global_rect().get_center().x),"Two choices form one vertical list")
			test(employees.disabled==(releases<2),"Existing Employees release gate remains")
			test(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(store.get_global_rect()) and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(employees.get_global_rect()),"Both choices fit supported viewport")
			if releases==0:
				await click(hud.cash_button);test(hud.studio_finances.visible,"Shared HUD still opens Finances from Management")
				await key(KEY_ESCAPE);test(not hud.studio_finances.visible and store.is_visible_in_tree(),"Finance Escape preserves Management beneath it")
				await click(hud.settings_button);test(hud.settings_menu.is_open(),"Shared HUD still opens Settings from Management")
				await key(KEY_ESCAPE);test(not hud.settings_menu.is_open() and store.is_visible_in_tree(),"Settings Escape preserves Management beneath it")
				await key(KEY_F8);test(game.developer_tools.panel.visible,"Developer Tools still open from Management")
				await key(KEY_ESCAPE);test(not game.developer_tools.panel.visible and store.is_visible_in_tree(),"Developer Escape preserves Management beneath it")
			if DisplayServer.get_name()!="headless" and releases==2:
				await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output.get_basename()+"-%d.png"%dimensions.x)
			await click(store)
			test(studio._feature_store!=null and studio._feature_store.is_visible_in_tree() and not employees.is_visible_in_tree(),"Pointer enters Feature Store")
			await click(studio._feature_store._close)
			test(store.is_visible_in_tree() and store.has_focus() and studio.get_node("%Dashboard").visible,"Store Close returns to Management with focus")
			if releases==2:
				store.grab_focus();await key(KEY_DOWN);test(employees.has_focus(),"Down navigates to Employees")
				await key(KEY_ENTER)
				test(studio._employees_panel!=null and studio._employees_panel.is_visible_in_tree() and not store.is_visible_in_tree(),"Keyboard enters Employees")
				await key(KEY_ESCAPE)
				print("MANAGEMENT_ESCAPE_STATE ",{"employees":studio._employees_panel.visible,"management":store.is_visible_in_tree(),"dashboard":studio.get_node("%Dashboard").visible,"paused":game.pause_menu.is_open(),"focus":str(root.gui_get_focus_owner())})
				test(employees.is_visible_in_tree() and employees.has_focus() and not game.pause_menu.is_open(),"Employees Escape returns one level without pausing")
			test(state(run)==before,"Browsing changes no cash, calendar, ownership, research, roster, finance or RNG")
			await key(KEY_ESCAPE)
			test(studio.get_node("%Dashboard").is_visible_in_tree() and management.has_focus() and not game.pause_menu.is_open(),"Management Escape returns to Studio with focus")
			await key(KEY_ESCAPE);test(game.pause_menu.is_open(),"Ordinary Studio Escape still pauses")
			await key(KEY_ESCAPE)
			game.queue_free();await process_frame;await process_frame
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));print("STUDIO_MANAGEMENT checks=%d failures=%d"%[checks,failures]);quit(failures)
