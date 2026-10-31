extends SceneTree
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1152,648)
	await process_frame
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var s=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"hub_fixture","studio_name":"Studio hub","specialty":"action","traits":[],"seed":"4417"},catalog)
	var policy=preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Fixture","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
	check(s.drive(policy,120,2).ok,"Legal two-release Studio")
	var phase=load("res://scenes/phases/studio_phase.tscn").instantiate();root.add_child(phase);phase.setup(null,s.run,s.snapshots);phase._hub_motion.animate=false
	await process_frame
	var before=StudioCheckpoint.new().capture(s.run)
	for group in [&"market",&"management",&"production"]:
		phase._open_menu(group)
		check(phase._hub.selected==group,"Group selected "+String(group))
		for button: Button in phase._menu_buttons.values():check(button.is_visible_in_tree(),"Root remains visible")
	phase._open_management();phase.get_node("%StudioEnginesButton").grab_focus();phase._open_engines()
	check(phase._hub_motion.depth()==2 and phase._hub_motion.is_top(phase._engine_browser),"Engine destination in shared stack")
	check(not phase.get_node("%Dashboard").visible,"Destination hides root on completion")
	phase._engine_browser.closed.emit()
	check(phase._hub_motion.depth()==1 and phase.get_node("%Dashboard").visible,"Engine Back restores root")
	check(phase._hub.selected==&"management","Engine Back restores group")
	check(root.gui_get_focus_owner()==phase.get_node("%StudioEnginesButton"),"Engine Back restores invoking choice")
	phase.get_node("%FeatureStoreButton").grab_focus();phase._open_feature_store()
	check(phase._hub_motion.depth()==2,"Store in shared stack")
	phase._feature_store.close_store()
	check(phase._hub_motion.depth()==1 and phase._hub.selected==&"management","Store visibility close returns once")
	check(root.gui_get_focus_owner()==phase.get_node("%FeatureStoreButton"),"Store focus restored")
	phase._open_menu(&"market");phase._open_rival_info();phase._rival_info.closed.emit()
	check(phase._hub_motion.depth()==1 and phase._hub.selected==&"market","Rivals Back returns market")
	phase._open_menu(&"production");phase._open_predevelopment();phase._predevelopment.cancelled.emit()
	check(phase._hub_motion.depth()==1 and phase._hub.selected==&"production","Setup cancellation returns production")
	check(JSON.stringify(StudioCheckpoint.new().capture(s.run))==JSON.stringify(before),"Navigation changes no player/RNG/history/finance")
	phase._hub_motion.animate=true
	phase._open_menu(&"market");phase._open_menu(&"management");phase._open_menu(&"production")
	await create_timer(0.85).timeout
	check(phase._hub.selected==&"production" and not phase._hub.transitioning,"Rapid requests settle latest")
	phase._open_engines()
	check(phase._hub_motion.busy and root.gui_disable_input,"Destination owns transition input lock")
	await create_timer(0.3).timeout
	check(not phase._hub_motion.busy and not root.gui_disable_input,"Opening releases input")
	phase._engine_browser.closed.emit();await create_timer(0.3).timeout
	check(phase._hub_motion.depth()==1 and not root.gui_disable_input,"Closing releases input")
	phase._open_engines();phase.queue_free();await process_frame
	check(not root.gui_disable_input,"Teardown during motion releases input")
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures else 0)
