extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func session(id: String) -> RefCounted:
	return Factory.create_fresh_session({"schema_version":1,"studio_id":id,"studio_name":id,"specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
func _initialize() -> void:
	await process_frame
	var s=session("browser_buyer");var r: RunState=s.run
	check(r.finalize_starter_selection() and r.add_cash_cents(2000000),"Controlled test funds, no change to starting balance rules")
	check(r._register_proprietary_engine(&"b","Custom Engine B") and r.select_engine(&"b"),"Separate configured engine fixture")
	for id: StringName in [&"text",&"4_color_palette",&"scrolling"]:
		check(r.admit_feature_research(r.get_feature_research_quote(id)) and r.research_feature(r.get_feature_research_quote(id)),"Implement fixture "+str(id))
	check(r.stage_engine_features([&"text",&"4_color_palette",&"scrolling"] as Array[StringName]) and r.commit_engine_configuration(r.get_engine_configuration_quote()),"Commit B fixture")
	check(r.select_engine(&"legacy_engine"),"Legacy selected before browsing")
	var world=RivalWorld.new();world.player=r;world.studios={&"incumbent-action":session("incumbent-action"),&"incumbent-puzzle":session("incumbent-puzzle")}
	var studio=load("res://scenes/phases/studio_phase.tscn").instantiate();root.add_child(studio);studio._run_state=r;studio.set_rival_world(world)
	var money=r.get_cash_cents();var clock=r.get_completed_run_cycles();var rng=r.random_streams.snapshot()
	studio._open_engines();var browser=studio._engine_browser
	check(browser.buttons.size()==4,"Left list contains built-in, owned custom and market listings")
	browser.buttons[&"action_engine"].pressed.emit()
	check(browser.selected_id==&"action_engine" and r.get_selected_engine_id()==&"legacy_engine","Inspecting does not switch engine")
	check(r.get_cash_cents()==money and r.get_completed_run_cycles()==clock and r.random_streams.snapshot()==rng,"Browsing is free and RNG neutral")
	check(browser.description.text.contains("$7500.00") and browser.description.text.contains("20%"),"Selected details show existing license terms")
	var creator_cash=world.studios[&"incumbent-action"].run.get_cash_cents();browser.action.pressed.emit()
	check(r.get_cash_cents()==money-750000 and world.studios[&"incumbent-action"].run.get_cash_cents()==creator_cash+750000,"License uses exact existing transfer")
	check(r.get_selected_engine_id()==&"legacy_engine" and browser.action.text=="Use this engine","License does not silently select")
	browser.action.pressed.emit()
	check(r.get_selected_engine_id()==&"action_engine" and browser.action.disabled,"Explicit Use selects owned license")
	studio._show_predevelopment();var setup=studio._predevelopment
	check(setup.engine_picker.choices.item_count==3,"Game setup lists only owned/licensed engines")
	var b_index: int=setup.engine_picker.choices.item_count-1
	for i in setup.engine_picker.choices.item_count:
		if setup.engine_picker.choices.get_item_metadata(i)==&"b":b_index=i
	setup.name_input.text="Engine selected game";setup.engine_picker.choices.item_selected.emit(b_index)
	check(r.get_selected_engine_id()==&"b" and setup.name_input.text=="Engine selected game","Game selection works without clearing draft")
	await capture_surface("game-setup")
	setup.cancelled.emit();setup.hide()
	check(r.get_selected_engine_id()==&"b","Cancel keeps the explicitly selected Studio default")
	var started=s.execute(s.command(&"begin_development",{"name":"Selected engine","genre":"action","theme":"fantasy"}))
	check(started.ok,"Begin through canonical command")
	if started.ok:
		var project: ProjectState=s.development.project;var frozen=project.get_feature_supply_ids()
		check(project.get_engine_id()==&"b" and project.get_engine_max_scope()==20 and &"scrolling" in frozen,"Project freezes selected engine, cap and pool")
		r.select_engine(&"legacy_engine")
		check(project.get_engine_id()==&"b" and project.get_feature_supply_ids()==frozen,"Later selection cannot alter started game")
		var policy=preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Fixture","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
		check(s.drive(policy,100,1).ok,"Legal first release unlocks Contract fixture")
	studio._open_contracts();var picker=studio._contract_engine_picker
	check(picker!=null and picker.choices.item_count==3,"Contract setup has the same owned-engine picker")
	for i in picker.choices.item_count:
		if picker.choices.get_item_metadata(i)==&"b":picker.choices.item_selected.emit(i);break
	check(r.get_selected_engine_id()==&"b" and &"scrolling" in r._primitive_contract_eligible_ids(),"Contract picker refreshes eligible pool")
	await capture_surface("contract-setup")
	studio._accept_contract();var accepted=r.get_active_contract()
	check(accepted!=null and &"scrolling" in accepted.get_eligible_feature_ids(),"Acceptance freezes chosen configured features")
	if accepted!=null:
		var pool=accepted.get_eligible_feature_ids();r.select_engine(&"action_engine")
		check(accepted.get_eligible_feature_ids()==pool,"Later selection does not rewrite accepted Contract")
	studio._open_engines();browser=studio._engine_browser
	browser.buttons[&"b"].pressed.emit();browser.buttons[&"b"].grab_focus()
	var before=r.random_streams.snapshot();var before_cash=r.get_cash_cents();var before_cycle=r.get_completed_run_cycles()
	for dimensions: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.content_scale_size=dimensions;root.size=dimensions;studio.size=dimensions
		await create_timer(0.32).timeout
		var list_rect: Rect2=browser.engine_list.get_global_rect();var detail_rect: Rect2=browser.details.get_global_rect();var view=Rect2(Vector2.ZERO,root.get_visible_rect().size)
		check(list_rect.end.x<detail_rect.position.x and view.encloses(browser.action.get_global_rect()),"Browser left/right bounds "+str(dimensions))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].trim_prefix("--output=").get_base_dir()+"/engines-%d.png"%dimensions.x)
	check(r.get_cash_cents()==before_cash and r.get_completed_run_cycles()==before_cycle and r.random_streams.snapshot()==before,"Layout and inspection stay free")
	browser.find_child("Back",true,false).pressed.emit()
	check(studio._active_menu==&"management" and not browser.visible,"Back returns to Management")
	studio.queue_free();await process_frame
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));quit(0 if failures.is_empty() else 1)

func capture_surface(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	for dimensions: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.content_scale_size=dimensions;root.size=dimensions
		await create_timer(0.4).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].trim_prefix("--output=").get_base_dir()+"/%s-%d.png"%[label,dimensions.x])
