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
