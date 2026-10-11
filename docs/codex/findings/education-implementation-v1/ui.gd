extends SceneTree
## Constructed headless UI fixtures; no rendered or legal-route claim.
var checks := 0
var failures: Array[String] = []
var captures: Array = []
var output := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error("FAIL: "+label)

func settle() -> void:
	await create_timer(0.3).timeout
	await process_frame

func named(trait_id: StringName = &"college_dropout") -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(0)
	check(run.create_studio_with_traits("Education UI",&"action",[] if trait_id.is_empty() else [trait_id]),"Create canonical UI fixture")
	return run

func snapshot(run: RunState) -> Array:
	return [run.get_cash_cents(),run.get_completed_run_cycles(),run.get_available_redraws(),run.random_streams.snapshot(),run.get_studio_finance_snapshot(),run.get_studio_traits(),run.get_owned_feature_ids(),run.get_released_game_ids()]

func bounds(menu: StudioFinances, dimensions: Vector2i, label: String) -> void:
	var viewport := Rect2(Vector2.ZERO,Vector2(dimensions))
	check(viewport.encloses(menu.dialog.get_global_rect()),label+" dialog fits")
	for control: Control in [menu.education_details,menu.education_payoff_button,menu.back_button]:
		check(menu.dialog.get_global_rect().encloses(control.get_global_rect()),label+" control fits: "+control.name)
	check(menu.education_details.size.y>=100 and menu.education_details.scroll_active,label+" scrollable readable history")
	captures.append({"label":label,"width":dimensions.x,"height":dimensions.y,"copy":menu.education_details.text,"dialog":str(menu.dialog.get_global_rect()),"details":str(menu.education_details.get_global_rect()),"button":str(menu.education_payoff_button.get_global_rect()),"headless":true})

func menu_for(run: RunState) -> StudioFinances:
	var menu := StudioFinances.new()
	root.add_child(menu)
	menu.bind_run(run)
	check(menu.open(),"Finance opens")
	menu.finance_tabs.current_tab=2
	return menu

func _run() -> void:
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions
		for trait_id: StringName in [&"college_dropout",&"graduate",&""]:
			var run := named(trait_id)
			var menu := menu_for(run)
			await settle()
			var before := snapshot(run)
			bounds(menu,dimensions,String(trait_id))
			if trait_id.is_empty():
				check(menu.education_payoff_button.disabled and menu.education_details.text.contains("No active education debt"),"No debt has no payoff")
			else:
				var principal := "$5000.00" if trait_id==&"college_dropout" else "$20000.00"
				var regular := "$70.68" if trait_id==&"college_dropout" else "$282.73"
				var final_due := "$71.11" if trait_id==&"college_dropout" else "$283.28"
				check(menu.education_details.text.contains(principal) and menu.education_details.text.contains(regular) and menu.education_details.text.contains(final_due),"Exact debt schedule copy")
				check(menu.education_details.text.contains("cycle 26") and menu.education_details.text.contains("8%/12") and not menu.education_details.text.contains("%%"),"Grace/rate copy")
				menu.education_payoff_button.pressed.emit()
				await settle()
				check(menu._confirm.visible and menu._confirm.title=="Confirm education payoff" and menu._confirm.dialog_autowrap,"Payoff awaits wrapped confirmation")
				check(menu._confirm.size.x<=dimensions.x and menu._confirm.size.y<=dimensions.y,"Confirmation fits viewport dimensions")
				check(menu._confirm.dialog_text.contains("rent, payroll and Bank") and menu._confirm.dialog_text.contains("zero-cycle"),"Confirmation describes separate due-bill service")
				check(snapshot(run)==before,"Opening confirmation is passive")
				menu._confirm.get_cancel_button().pressed.emit()
				await process_frame
				check(not menu._confirm.visible and snapshot(run)==before,"Cancel preserves all state")
				menu.education_payoff_button.pressed.emit()
				menu._confirm.confirmed.emit()
				if trait_id==&"graduate":
					check(snapshot(run)==before and menu.education_details.text.contains("Payoff rejected"),"Unaffordable confirmation rejects atomically")
				else:
					check(run.get_cash_cents()==80000 and run.get_completed_run_cycles()==0 and run.get_studio_finance_snapshot().education.closed,"Affordable confirmation pays exact principal without time")
					check(menu.education_payoff_button.disabled and menu.education_details.text.contains("Closed"),"Closed account remains visible without another payoff")
					var after := snapshot(run)
					menu._confirm.confirmed.emit()
					check(snapshot(run)==after,"Duplicate confirmation has no effect")
			menu.close();menu.queue_free();await process_frame
		var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/education-legacy-fixtures-v1/v5-graduate.payload.json"))
		var preview:=StudioCheckpoint.new().hydrate(old)
		check(preview!=null,"Authentic old preview for UI control")
		if preview!=null:
			var old_menu:=menu_for(preview);await settle();bounds(old_menu,dimensions,"v5-preview")
			check(old_menu.education_payoff_button.disabled and old_menu.education_details.text.contains("No active education debt"),"Supported old preview UI never offers education payoff")
			old_menu.close();old_menu.queue_free();await process_frame
		await stale_and_partial(dimensions)
		await phases(dimensions)
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"scope":"headless control/layout and constructed UI fixtures only"}))
	print("Education UI: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func stale_and_partial(dimensions: Vector2i) -> void:
	var run := named()
	var menu := menu_for(run)
	await settle()
	menu.education_payoff_button.pressed.emit()
	var old_quote := menu._education_payoff.duplicate(true)
	check(run.spend_cash_cents(1),"Public spending invalidates old quote")
	check(not menu._confirm.visible,"Finance change closes stale modal")
	var before := snapshot(run)
	menu._education_payoff=old_quote # Explicit stale-callback fixture.
	menu._confirmation_kind=&"education_payoff"
	menu._confirm_transaction()
	check(snapshot(run)==before and menu.education_details.text.contains("Payoff rejected"),"Stale callback cannot pay")
	menu.close()
	check(run.add_cash_cents(2000000,&"financing_in",&"education_ui_fixture"),"Explicitly funded UI fixture (not a legal route)")
	for i in range(25): check(run.complete_productive_action(),"Constructed UI calendar progression")
	check(run.spend_cash_cents(run.get_cash_cents()-50100) and run.complete_productive_action(),"Constructed UI partial education due")
	menu.open();menu.finance_tabs.current_tab=2;await settle()
	bounds(menu,dimensions,"partial")
	check(menu.education_details.text.contains("Original due Month 13 / cycle 26") and menu.education_details.text.contains("Interest paid $1.00 / $33.33") and menu.education_details.text.contains("Remaining $69.68"),"Partial due displays original split and remaining balance")
	check(menu.education_details.text.contains("Cycle 26: paid $1.00") and menu.education_details.text.contains("do not block production"),"Payment history and production rule visible")
	before=snapshot(run);menu.open_bank();menu.back();check(snapshot(run)==before,"Bank/Finances navigation leaves debt unchanged")
	menu.close();menu.queue_free();await process_frame

func phases(dimensions: Vector2i) -> void:
	for target in ["Studio","Design","Alpha","Beta"]:
		var run := named()
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		game.run_state=run
		if target!="Studio": game.project_state=ProjectState.new(30)
		root.add_child(game);await settle()
		var hud: GameplayHUD=game.get_node("%GameplayHUD")
		hud.tutorial_overlay.close();hud.contextual_tip.dismiss()
		if target!="Studio":
			check(game._active_phase.get_workspace().overlay.commit_draft(),"Design priorities for UI fixture")
			await settle()
		if target in ["Alpha","Beta"]:
			game._active_phase._exhausted_card_ids[&"text"]=true # Phase fixture, not played release.
			game._active_phase.get_node("%ProceedToAlphaButton").pressed.emit();await settle()
			check(game._active_phase is AlphaPhase,"UI fixture enters Alpha")
			check(game._active_phase.get_workspace().overlay.commit_draft(),"Alpha priorities for UI fixture");await settle()
		if target=="Beta":
			game.project_state.add_scope(30)
			check(game._active_phase._finalize_alpha(0.0,0.5),"UI fixture enters Beta");await settle()
			check(game._active_phase.get_workspace().overlay.commit_draft(),"Beta priorities for UI fixture");await settle()
		var before := snapshot(run)
		var project_before: Array = []
		if game.project_state!=null: project_before=[game.project_state.get_current_cycle(),game.project_state.get_current_scope(),game.project_state.get_known_bugs()]
		check(hud.show_finances(),target+" opens education through Cash HUD")
		var menu: StudioFinances=hud.studio_finances
		menu.finance_tabs.current_tab=2;await settle();bounds(menu,dimensions,target)
		check(snapshot(run)==before,target+" browsing is passive")
		menu.education_payoff_button.pressed.emit();menu._confirm.confirmed.emit()
		check(run.get_studio_finance_snapshot().education.closed and run.get_cash_cents()==before[0]-500000,target+" education payoff commits")
		check(run.get_completed_run_cycles()==before[1] and run.random_streams.snapshot()==before[3],target+" payoff preserves calendar/RNG")
		if game.project_state!=null: check(project_before==[game.project_state.get_current_cycle(),game.project_state.get_current_scope(),game.project_state.get_known_bugs()],target+" payoff preserves active project")
		menu.back_button.pressed.emit();check(not menu.visible,target+" Back closes")
		game.queue_free();await settle()
