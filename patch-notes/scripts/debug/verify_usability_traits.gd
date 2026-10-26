extends SceneTree

var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures += 1
func settle() -> void:
	for i in 5: await process_frame
func _run() -> void:
	var many := [&"family_funding",&"publisher_connections",&"resourceful",&"studio_buzz",&"graduate",&"expensive_lease",&"unknown_name"]
	var evaluated := StudioTraits.evaluate_traits(many)
	check(evaluated.valid and evaluated.get("version")==9 and evaluated.get("remaining_points")==9,"New selection allows more than two positives and one negative")
	check(not StudioTraits.evaluate_traits(many,8).valid,"Historic v8 count limit unchanged")
	var negative := StudioTraits.evaluate_traits([&"family_funding",&"publisher_connections",&"resourceful",&"lean_production",&"studio_buzz"])
	check(not negative.valid and negative.get("remaining_points")==-3,"Negative draft balance remains inspectable")
	check(not StudioTraits.evaluate_traits([&"graduate",&"college_dropout"]).valid,"Education histories cannot create two refunds for one debt")
	check(StudioTraits.starting_fans(StudioTraits.evaluate_traits([&"cult_following"]))==20,"New uncapped version keeps 20 Fan trial")
	for resolution: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=resolution; root.content_scale_size=resolution
		var menu:=MainMenu.new();root.add_child(menu);await settle()
		menu.navigation.animate=false
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		menu._name_input.text="Trait Studio";menu._specialty.select(1);menu._open_folder(&"traits")
		for id: StringName in negative.get("trait_ids",[]): menu._trait_checks[id].button_pressed=true
		# Use the actual buttons even on the pre-change RED source.
		for id: StringName in [&"family_funding",&"publisher_connections",&"resourceful",&"lean_production",&"studio_buzz"]: menu._trait_checks[id].button_pressed=true
		await settle()
		check(menu._points.text.contains("-3") and menu._points.text.contains("cash"),"Pinned balance displays negative points and cash bonus")
		var scrolled:=false;var node:Node=menu._points.get_parent()
		while node!=menu: scrolled=scrolled or node is ScrollContainer;node=node.get_parent()
		check(not scrolled,"Point balance has no scrolling ancestor")
		check(menu._traits_step.find_child("Selected",true,false)!=null and menu._traits_step.find_child("Available",true,false)!=null,"Selected and Available lists exist")
		for id: StringName in menu._trait_checks:
			check(menu._trait_checks[id].text==StudioTraits.TRAITS[id].name and not menu._trait_checks[id].tooltip_text.is_empty(),"Names only; hover describes "+id)
		menu._show_review();await settle()
		check(menu._review.text.contains("Traits") and menu._review.text.to_lower().contains("negative"),"Negative Overview directs player to Traits")
		check(menu._review_step.find_child("PositiveTraits",true,false)!=null and menu._review_step.find_child("NegativeTraits",true,false)!=null,"Overview has two selected-trait columns")
		check(menu._play.get_global_rect().end.y<=resolution.y and menu._points.get_global_rect().end.y<=resolution.y,"Fixed creation controls fit "+str(resolution))
		menu.queue_free();await process_frame
	var tip:=ContextualTip.new();root.add_child(tip);await process_frame
	tip.show_tip("Persistent","Only close dismisses this tip.")
	check(tip.timer==null or tip.timer.is_stopped(),"No auto-dismiss timer is started")
	await create_timer(8.2).timeout
	check(tip.panel.visible,"Tip remains after former eight-second expiry")
	tip.dismiss_button.pressed.emit();check(not tip.panel.visible,"Dismiss button closes tip")
	tip.show_tip("Again","Tip can be reopened.");check(tip.panel.visible,"Tip reopens")
	tip.queue_free();await process_frame
	print("Usability traits: %d failures"%failures);quit(failures)
