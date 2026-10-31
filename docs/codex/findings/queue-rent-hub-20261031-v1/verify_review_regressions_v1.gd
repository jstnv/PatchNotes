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
	check(session.drive(policy,120,2).ok,"Two legal games for Employees")
	var r: RunState=session.run
	game.checkpoints.attach(r);check(game._finish_checkpoint_load(r),"Actual Gameplay Studio mounts");game.checkpoints.pending=true;check(await game.checkpoints.wait_saved(),"Studio save completes")
	var hud=game.get_node("%GameplayHUD");hud.contextual_tip.dismiss();hud.tutorial_overlay.close()
	var phase=game._active_phase;phase._hub_motion.animate=false
	r._pending_publisher_notifications.append(PublisherCatalog.IRONCLAD)
	phase._show_pending_publisher_notice()
	check(phase._publisher_notice.is_visible_in_tree(),"Publisher unlock notice visible after queue consumption")
	for mode in ["market","employees","bank"]:
		for controller in [false,true]:
			phase._hub_motion.animate=false;phase._open_menu(&"market" if mode=="market" else &"management")
			phase._hub_motion.animate=true
			if mode=="market":phase._open_market()
			elif mode=="employees":phase._open_employees()
			else:phase._open_bank()
			var view: Control=phase._market_browser if mode=="market" else phase._employees_panel if mode=="employees" else hud.studio_finances.dialog
			var event: InputEvent
			if controller:
				event=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_B
			else:
				event=InputEventKey.new();event.keycode=KEY_ESCAPE
			event.pressed=true;Input.parse_input_event(event);await process_frame
			event=event.duplicate();event.pressed=false;Input.parse_input_event(event)
			await create_timer(0.3).timeout
			check(phase._hub_motion.depth()==2 and view.is_visible_in_tree(),"Entry cancellation cannot hide "+mode+str(controller))
			phase._hub_motion.animate=false;phase._open_menu(&"management")
	game.queue_free();await process_frame;await process_frame
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures else 0)
