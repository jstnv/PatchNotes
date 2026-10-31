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
	var session=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"bank_hub","studio_name":"Bank navigation","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
	var policy=preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Fixture","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
	check(session.drive(policy,120,2).ok,"Two actual releases")
	var r: RunState=session.run
	game.checkpoints.attach(r);check(game._finish_checkpoint_load(r),"Actual Gameplay Studio mounts");game.checkpoints.pending=true;check(await game.checkpoints.wait_saved(),"Studio save completes")
	var hud=game.get_node("%GameplayHUD");hud.contextual_tip.dismiss();hud.tutorial_overlay.close()
	var phase=game._active_phase;phase._hub_motion.animate=false
	var output=OS.get_cmdline_user_args()[0].trim_prefix("--output=").get_base_dir()
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions;await process_frame;await process_frame
		phase._open_management();await process_frame;await process_frame
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output+"/hub-"+str(dimensions.x)+".png")
		var routes=["engines","store","employees","info","summary","market","publishers","rivals","contracts","setup","bank"]
		var expected=phase.global_position+Vector2(32,28)
		for route in routes:
			phase._open_menu(&"production" if route in ["contracts","setup"] else &"market" if route in ["market","publishers","rivals"] else &"management")
			var view: Control;var back: Button
			match route:
				"engines":phase._open_engines();view=phase._engine_browser;back=view.find_child("Back",true,false)
				"store":phase._open_feature_store();view=phase._feature_store;back=view._close
				"employees":phase._open_employees();view=phase._employees_panel;back=view.back_button
				"info":phase._open_studio_info();view=phase._studio_info;back=view.find_child("Back",true,false)
				"summary":phase.open_summary();view=phase.get_node("%SummaryPanel");back=phase.get_node("%CloseSummaryButton")
				"market":phase._open_market();view=phase._market_browser;back=view.back_button
				"publishers":phase._open_publishers();view=phase._publisher_browser;back=view.find_child("ClosePublisherBrowser",true,false)
				"rivals":phase._open_rival_info();view=phase._rival_info;back=view.find_child("Back",true,false)
				"contracts":phase._open_contracts();view=phase._contract_detail;back=view.find_child("CloseContractDetailButton",true,false)
				"setup":phase._open_predevelopment();view=phase._predevelopment;back=view.back_button
				"bank":phase._open_bank();view=hud.studio_finances.dialog;back=hud.studio_finances.back_button
			await create_timer(0.3).timeout
			hud.contextual_tip.dismiss()
			for frame in range(3):await process_frame
			check(view.is_visible_in_tree(),route+" visible")
			check(back.global_position.is_equal_approx(expected),route+" consistent Back: "+str(back.global_position)+" expected "+str(expected))
			check(phase.get_global_rect().encloses(view.get_global_rect()),route+" destination bounds")
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(output+"/"+route+"-"+str(dimensions.x)+".png")
			back.pressed.emit();await process_frame
			check(phase._hub_motion.depth()==1 and phase.get_node("%Dashboard").visible,route+" returns to hub")
	game.queue_free();await process_frame;await process_frame
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures else 0)
