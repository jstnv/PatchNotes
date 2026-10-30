extends "res://scripts/debug/verify_sales_revenue_hud.gd"

func _initialize() -> void:
	await process_frame
	create_timer(120).timeout.connect(func(): push_error("Store HUD timeout"); quit(2))
	node_added.connect(func(node: Node):
		if node is CheckpointCoordinator: node.store = TestStore.new("user://saves/studio",node._validate_payload))
	var run := fixture_run()
	for i in range(6):
		release_fixture(run,"Store HUD release %d" % i)
		expect(run.complete_productive_action(),"Constructed release earns through normal calendar")
	# Legal research creates owned Features whose play fees remain unspecified.
	for id: StringName in [&"colored_text", &"save_files", &"branching_nodes", &"animated_sprites"]:
		var quote := run.get_feature_research_quote(id)
		if quote.can_admit:
			expect(run.admit_feature_research(quote),"HUD fixture admits research " + str(id))
			while run.get_feature_research_quote(id).queued:
				expect(run.research_feature(run.get_feature_research_quote(id)),"HUD fixture completes research " + str(id))
	expect(run.admit_feature_research(run.get_feature_research_quote(&"8_color_palette")),"Create a real pending queue for the compact control row")
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(run)
	expect(not payload.is_empty(),"Fixture captures through normal checkpoint codec")
	for resolution in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(900,600)]:
		var fixture := adapter.hydrate(payload)
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		game.run_state = fixture
		root.add_child(game)
		await settle()
		await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
		root.min_size = Vector2i.ZERO
		root.size = resolution
		root.content_scale_size = resolution
		await settle()
		var studio: StudioPhase = game._active_phase
		var hud: GameplayHUD = game.get_node("%GameplayHUD")
		studio._open_feature_store()
		hud.tutorial_overlay.close()
		hud.contextual_tip.dismiss()
		await settle()
		await settle()
		var store := studio._feature_store
		store._map.fit_map()
		await create_timer(0.8).timeout
		var before := Replay.digest(fixture)
		var chart := hud.sales_hud.get_global_rect()
		var header := store._header.get_global_rect()
		print("STORE_BOUNDS ",resolution," store=",store.get_global_rect()," body=",store._body.get_global_rect()," map=",store._scroll.get_global_rect()," header=",header," chart=",chart)
		var viewport := Rect2(Vector2.ZERO,Vector2(resolution))
		expect(hud.sales_hud.visible and hud.sales_hud.model.market_count == 6,"Live market chart is present")
		expect(store._cash.global_position.y >= chart.end.y and is_equal_approx(store._cash.global_position.y,store._owned_summary.global_position.y),"Store title and pool share a row below the chart HUD")
		expect(viewport.encloses(header) and not header.intersects(chart) and hud.get_node("PersistentHeader").get_global_rect().encloses(chart),"Store header clears chart inside shared top HUD "+str(resolution))
		expect(store._cash.get_global_rect().end.x < store._owned_summary.global_position.x,"Owned pool is to the right of title")
		var summary := store._summarize_owned_features()
		expect(summary.unpriced_count > 0 and store._owned_summary.text.contains("Scope %d" % summary.scope),"Owned Scope binds to real owned Features")
		for stat in [&"graphics", &"sound", &"technology", &"design"]:
			expect(store._owned_summary.text.contains("%s %d" % [FeatureStore.score_label(stat),summary[stat]]),"Correct category total "+str(stat))
		expect(not store._owned_summary.text.contains("Core Score") and not store._owned_summary.text.contains("TBD"),"Header omits aggregate Core Score and TBD copy")
		expect(store._owned_summary.get_line_count() == store._owned_summary.get_visible_line_count(),"All pool text is visible")
		if resolution.x >= 1152: expect(store._owned_summary.get_line_count()==1,"Supported-size pool stays on one line")
		expect(not store._body.get_global_rect().intersects(chart) and store._close.global_position.y >= chart.end.y,"Body and Close Store clear chart")
		expect(store._debug.get_global_rect().end.x <= store._close.global_position.x and viewport.encloses(store._debug.get_global_rect()),"Debug is beside Close Store")
		if store._research_list.visible:
			expect(store._research_list.get_parent()==store._close.get_parent() and store._research_button.get_parent()==store._close.get_parent(),"Research queue and action share Debug / Close row")
		var category_buttons := store.find_children("*","Button",true,false).filter(func(button: Button):return button.text in FeatureStore.LANE_ORDER)
		expect(category_buttons.is_empty(),"Category zoom shortcut buttons removed")
		expect(store._scroll.size.y >= resolution.y - 360,"Map receives reclaimed header space")
		expect(store._debug.tooltip_text.contains("play cost TBD") and store._debug.tooltip_text.contains("unknown"),"Debug contains prototype fee and unknown-cost explanations")
		var entered := [false]
		hud.sales_hud.chart.mouse_entered.connect(func(): entered[0]=true)
		motion(Vector2(3,3))
		await settle()
		motion(hud.sales_hud.chart.get_global_rect().get_center())
		await settle()
		expect(entered[0],"Chart remains mouse-reachable above Store for tooltips")
		motion(Vector2(3,3))
		await picture("store",resolution)
		store._debug.grab_focus()
		key(KEY_ENTER)
		await settle()
		expect(store._debug_popup.visible and viewport.encloses(store._debug_popup.get_global_rect()),"Keyboard opens bounded scrollable Debug notes")
		var zoom_before := store._map.zoom
		var wheel := InputEventMouseButton.new()
		wheel.position=store._debug_scroll.get_global_rect().get_center()
		wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed=true
		root.push_input(wheel,true)
		await settle()
		expect(store._debug_scroll.scroll_vertical>0 and store._map.zoom==zoom_before,"Debug wheel scrolls notes without zooming the map underneath")
		store._debug_scroll.scroll_vertical=0
		await picture("debug",resolution)
		key(KEY_ESCAPE)
		await settle()
		expect(not store._debug_popup.visible and not paused and store._debug.has_focus(),"Escape closes Debug and returns focus without pausing")
		store._select_node(&"branching_nodes")
		await create_timer(0.8).timeout
		expect(not store._map.popup.get_global_rect().intersects(chart),"Feature details never cover persistent chart")
		store._map.dismiss()
		expect(Replay.digest(fixture)==before,"Browsing chart and Debug leaves finance, RNG, cards and calendar unchanged")
		store._close.grab_focus()
		key(KEY_ENTER)
		await settle()
		expect(not store.visible and studio.get_node("%Dashboard").visible,"Close Store returns to Studio")
		expect(game.get_node("%PhaseRoot").offset_top==88,"Closing keeps shared top HUD")
		studio._open_feature_store()
		await settle()
		expect(store.visible and not store._debug_popup.visible and game.get_node("%PhaseRoot").offset_top==88,"Reopening keeps shared top HUD and closes Debug")
		game.queue_free()
		await settle()
	# Pre-release Store remains usable without the sales chart.
	var fresh := RunState.new()
	fresh.initialize_cash_cents(0)
	fresh.create_studio_with_traits("First Store",&"action",[])
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state=fresh
	root.add_child(game)
	await settle()
	root.size=Vector2i(1152,648)
	root.content_scale_size=root.size
	var studio: StudioPhase=game._active_phase
	studio._open_feature_store()
	await settle()
	var hud: GameplayHUD=game.get_node("%GameplayHUD")
	hud.contextual_tip.dismiss()
	await create_timer(0.8).timeout
	print("STARTER_HEADER visible=",hud.sales_hud.visible," offset=",studio._feature_store._header.offset_right," header=",studio._feature_store._header.get_rect()," store=",studio._feature_store.get_rect())
	expect(not hud.sales_hud.visible and studio._feature_store._header.offset_right==-16,"Pre-release header uses available width")
	expect(studio._feature_store._cash.global_position.y>=hud.get_node("PersistentHeader").get_global_rect().end.y and studio._feature_store._owned_summary.global_position.y==studio._feature_store._cash.global_position.y and studio._feature_store._header.size.y<50,"Starter labels stay below the shared top HUD after resize")
	expect(studio._feature_store._owned_summary.tooltip_text.contains("0 cycles"),"Starter purchase explanation remains available")
	await picture("starter",Vector2i(1152,648))
	game.queue_free()
	await settle()
	print("STORE_HUD checks=%d failures=%d" % [checks,failures])
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	quit(0 if failures==0 else 1)

func motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position=point
	event.global_position=point
	root.push_input(event,true)

func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode=code
		event.physical_keycode=code
		event.pressed=pressed
		root.push_input(event,true)

func picture(label: String,resolution: Vector2i) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	expect(screenshot.get_size()==resolution,"PNG has requested native dimensions")
	expect(screenshot.save_png(OS.get_environment("PN_STORE_CAPTURE").path_join("%s-%dx%d.png" % [label,resolution.x,resolution.y]))==OK,"Saved native "+label)
