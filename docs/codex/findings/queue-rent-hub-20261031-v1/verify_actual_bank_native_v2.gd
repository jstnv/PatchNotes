extends SceneTree
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1152,648)
	var game=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame
	game._onboarding.answer(true)
	var r=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"bank_hub","studio_name":"Bank navigation","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog()).run
	game.checkpoints.attach(r);check(game._finish_checkpoint_load(r),"Actual Gameplay Studio mounts");game.checkpoints.pending=true;check(await game.checkpoints.wait_saved(),"Studio save completes")
	var hud=game.get_node("%GameplayHUD");hud.contextual_tip.dismiss();hud.tutorial_overlay.close()
	var phase=game._active_phase;phase._hub_motion.animate=false
	var output=OS.get_cmdline_user_args()[0].trim_prefix("--output=").get_base_dir()
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions;await process_frame;await process_frame
		phase._open_management();await process_frame;await process_frame
		check(phase._hub.get_global_rect().encloses(phase._hub._companion.get_global_rect()),"Companion inside real HUD bounds")
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output+"/actual-management-"+str(dimensions.x)+".png")
		phase._open_engines();await process_frame;await process_frame
		var expected=phase._engine_browser.find_child("Back",true,false).global_position
		phase._engine_browser.closed.emit()
		phase._open_feature_store();await process_frame;await process_frame
		check(phase._feature_store._close.global_position.is_equal_approx(expected),"Store shares Back target")
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output+"/actual-store-"+str(dimensions.x)+".png")
		phase._feature_store._close.pressed.emit()
		phase._open_bank();await process_frame;await process_frame
		check(hud.studio_finances.back_button.global_position.is_equal_approx(expected),"Bank shares Back target")
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output+"/actual-bank-"+str(dimensions.x)+".png")
		hud.studio_finances.back_button.pressed.emit()
	phase._open_management();phase._open_bank()
	check(hud.studio_finances.visible and hud.studio_finances.dialog.is_visible_in_tree() and phase._hub_motion.depth()==2,"Bank is visible shared destination")
	hud.studio_finances.back_button.pressed.emit()
	check(not hud.studio_finances.visible and phase._hub_motion.depth()==1 and phase._hub.selected==&"management","Bank Back closes shared destination")
	phase._open_bank();check(hud.studio_finances.dialog.is_visible_in_tree(),"Bank reopens after animated close")
	hud.studio_finances.back_button.pressed.emit()
	phase._open_engines();hud.studio_finances.open();hud.studio_finances.close()
	check(phase._hub_motion.depth()==2 and phase._engine_browser.is_visible_in_tree(),"Ordinary Cash overlay does not pop Engines after Bank visit")
	phase._engine_browser.closed.emit()
	check(r.get_studio_finance_report().monthly_rent_cents==30000,"Actual HUD uses new stored rent")
	game.queue_free();await process_frame;await process_frame
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures else 0)
