extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
var out:=""
var failures:=0
var checks:=0
func _initialize() -> void:_run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",message)
	if not ok:failures+=1
func settle() -> void:
	for i in 8:await process_frame
func capture(name:String) -> void:
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func _run() -> void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	root.title="Patch Notes — isolated usability verification"
	for size:Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size;root.content_scale_size=size
		var menu:=MainMenu.new();root.add_child(menu);await settle()
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		menu._name_input.text="The Jooce";menu._specialty.select(1);menu._specialty.item_selected.emit(1);menu._open_folder(&"traits")
		for id:StringName in [&"family_funding",&"publisher_connections",&"resourceful",&"lean_production",&"studio_buzz"]:menu._trait_checks[id].button_pressed=true
		await settle()
		check(menu._points.text.contains("-3") and menu._points.get_global_rect().end.y<menu._play.get_global_rect().position.y,"Negative balance is pinned above Play")
		for check_button:CheckBox in menu._trait_checks.values():check(check_button.get_parent().get_parent().get_parent() is ScrollContainer,"Trait row is inside its own scrolling list")
		await capture("traits-negative-%d"%size.x)
		menu._trait_checks[&"lean_production"].button_pressed=false
		for id:StringName in [&"graduate",&"expensive_lease",&"unknown_name"]:menu._trait_checks[id].button_pressed=true
		await capture("traits-selected-%d"%size.x)
		menu._show_review();await settle()
		check(menu._overview_lists[true].get_child_count()==4 and menu._overview_lists[false].get_child_count()==3,"Overview has separate selected positive and negative columns")
		check(menu._folder_surface.get_global_rect().end.y<menu._play.get_global_rect().position.y,"Overview lists do not move or cover Play")
		await capture("overview-%d"%size.x)
		menu.queue_free();await process_frame
		var session:RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"native-store","studio_name":"The Jooce","specialty":"action","traits":[],"seed":"771"},root.get_node("CardDatabase").get_development_catalog())
		var run:RunState=session.run
		for id:StringName in [&"turn_based_combat",&"scripted_ai",&"difficulty_levels"]:run._owned_features.erase(id)
		var store:=FeatureStore.new();root.add_child(store);store.setup(run);store.open_store();await settle()
		await capture("store-map-%d"%size.x)
		store._map._focus_node(&"difficulty_levels")
		await create_timer(.8).timeout;await settle()
		store._buy.pressed.emit();await settle()
		check(store._map.popup.get_global_rect().encloses(store._buy.get_global_rect()),"Wrapped missing-parent button fits details")
		check(Rect2(Vector2.ZERO,Vector2(size)).encloses(store._map.popup.get_global_rect()),"Store details fit supported viewport")
		check(store._map.parent_links.get_child_count()==2,"Two-parent chooser is available")
		await capture("store-missing-%d"%size.x)
		store.queue_free();await process_frame
		var phase:=ContractPhase.new();root.add_child(phase);await settle()
		phase._priority_modal.show()
		phase._priority_inputs[0].value=30
		phase._priority_budget.set_process(false);phase._priority_budget.advance(.7)
		await settle()
		for slider:VSlider in phase._priority_inputs.values():
			check(Rect2(Vector2.ZERO,Vector2(size)).encloses(slider.get_global_rect()),"Contract slider fits viewport")
		check(phase._priority_total.text=="105/100" and phase._priority_chart.total==105,"Contract graph and allocation agree")
		await capture("contract-priority-%d"%size.x)
		phase.queue_free();await process_frame
		# Native Run recovery and finance confirmation, not a fabricated loan DTO.
		check(run.spend_cash_cents(run.get_cash_cents()) and run.complete_productive_action() and run.complete_productive_action(),"Controlled legal finance calls reach overdue rent")
		var finance:=StudioFinances.new();root.add_child(finance);finance.bind_run(run);finance.open();finance.open_bank();finance.amount_input.text="999999.00";finance._preview_quote();await settle()
		check(finance._quote.get("accepted",false) and finance.quote_details.text.contains("Cash received"),"Native quote shows adjustment and net proceeds")
		finance._confirm_accept();await settle()
		check(finance._confirm.dialog_text.contains("Overdue bills paid") and finance._confirm.dialog_text.contains("full principal"),"Confirmation explicitly states deduction and debt")
		finance._confirm.hide();finance._confirm_transaction();await settle()
		check(finance.loan_selector.item_count==1 and run.get_cash_cents()==100000,"Confirmed recovery pays rent and lists its loan")
		check(finance.dialog.get_global_rect().encloses(finance.loan_selector.get_global_rect()),"Loan selector remains inside Bank dialog")
		await capture("bank-recovery-%d"%size.x)
		finance.queue_free();await process_frame
	FileAccess.open(out.path_join("native-result.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"kind":"Isolated native component/render/input-signal checks, not direct release EXE or human comprehension."}))
	print("Native usability: %d checks, %d failures"%[checks,failures]);quit(failures)
