extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(110).timeout.connect(func(): push_error("Store verifier timed out"); quit(2))
	if not OS.get_environment("PN_CHECKPOINT_TEST_PORT").is_empty():
		node_added.connect(func(node: Node):
			if node is CheckpointCoordinator: node.store = preload("res://scripts/debug/verify_rival_gameplay_activation.gd").TestStore.new("user://saves/studio",node._validate_payload))
	_verify.call_deferred()

func expect(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func _capture(name: String, width: int) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var directory := "res://design-logs/feature-bloom-map-v1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): directory=arg.trim_prefix("--out=")
	root.get_texture().get_image().save_png(directory.path_join("%s-%d.png" % [name,width]))

func _verify() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(900, 600), Vector2i(1280, 720)]:
		root.size = dimensions
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		# Settings enforce the supported minimum; 900x600 is an explicit Store stress probe.
		root.min_size = Vector2i.ZERO
		root.size = dimensions
		root.content_scale_size = dimensions
		var menu: MainMenu = game.get("_active_phase")
		menu.navigation.animate=false
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		if is_instance_valid(menu._replace_dialog) and menu._replace_dialog.visible:
			menu._replace_dialog.hide()
			menu._replace_dialog.confirmed.emit()
		menu._name_input.text = "Category Store Test"
		menu._specialty.select(1)
		menu._play.pressed.emit()
		menu.call("_open_folder", &"traits")
		menu.call("_show_review")
		menu.call("_confirm_studio")
		await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
		var run: RunState = game.run_state
		var studio: StudioPhase = game.get("_active_phase")
		var actions:=preload("res://scripts/debug/ui_test_actions.gd")
		var engine_id: StringName=actions.create_feature_engine(run,"Radial Engine")
		var store: FeatureStore=await actions.open_feature_implementation(studio,engine_id)
		var map := store._map
		await process_frame
		await process_frame
		await process_frame
		expect(map.zoom>0 and map.zoom<=0.74 and map.center_square.size==Vector2.ONE*5*map.GridLayout.PITCH, "Initial view frames the five-cell center and nearby roots")
		map.fit_map()
		await process_frame
		await process_frame
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		var before := _passive_snapshot(run)
		var primitive: Array[StringName] = []
		for entry: Dictionary in FeatureStoreCatalog.starting_features(): primitive.append(StringName(entry.id))
		expect(primitive.size() == 27 and store._nodes.size() == 50, "Complete ledger membership retained (%d)" % dimensions.x)
		_verify_category_layout(store)
		var categorized := true
		var labels := true
		var colors := true
		var bounded := true
		var visible := true
		var overlaps: Array = []
		var ids := store._nodes.keys()
		for i in range(ids.size()):
			var id: StringName = ids[i]
			var node: Button = store._nodes[id]
			var lane: StringName = store._lane_by_id.get(id, &"")
			categorized = categorized and map.category_regions.has(lane) and store.LANE_MEMBERS[lane].has(id)
			if map.category_regions.has(lane):
				var region: Rect2 = map.category_regions[lane]
				categorized = categorized and region.encloses(map.node_footprint(node))
			var name_label: Label = node.get_node("FeatureName")
			labels = labels and node.size == Vector2(128, 128) and name_label.position.y > node.size.y and not node.clip_contents
			var card: CardData = root.get_node("CardDatabase").get_card(id)
			for state in ["normal", "hover", "pressed", "focus"]:
				colors = colors and node.get_theme_stylebox(state).border_color == FeatureStore.SCORE_COLORS[card.primary_stat]
			expect(bounded and overlaps.is_empty(), "Map bounds include names; no node or heading footprints overlap: " + str(overlaps))
		var outward := true
		for edge: Array in store._edges:
			var parent: Control = store._nodes[edge[0]]
			var child: Control = store._nodes[edge[1]]
			var parent_rect := map.node_footprint(parent)
			var lane: StringName = store._lane_by_id[edge[1]]
			if store._lane_by_id[edge[0]] == lane:
				outward = outward and _outward_rects(parent_rect, map.node_footprint(child), map.CATEGORY_DIRECTIONS[lane])
		var graph := FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
		var expected_edges: Array=[]
		for id: StringName in graph.parents:
			for parent: StringName in graph.parents[id]:
				if store._lane_by_id.has(id) and store._lane_by_id.has(parent) and store._lane_by_id[parent]==store._lane_by_id[id]: expected_edges.append([parent,id])
		expect(outward and store._edges==expected_edges, "Every same-category prerequisite is shown and grows outward; cross-category arrows omitted")
		expect(visible and map.bounds.x * map.zoom <= map._map_rect().size.x and map.bounds.y * map.zoom <= map._map_rect().size.y, "Show all displays all50 Features and their names")
		print("Map geometry: ", JSON.stringify({"bounds": str(map.bounds), "viewport": str(map.scroll.size), "zoom": map.zoom}))
		await _capture("overview", dimensions.x)
		store._select_node(&"16_bit_sound")
		await create_timer(1.1).timeout
		expect(store._details.text.contains("Replaces 8-Bit Sound") and store._details.text.contains("$0.00"),"Upgrade details show replacement and approved zero play cost")
		await _capture("audio-upgrade", dimensions.x)
		store._select_node(&"dynamic_sequencing")
		await create_timer(1.1).timeout
		expect(store._buy.text.contains("Multiple Soundtracks") and store._buy.text.contains("Instrumental Sounds"),"Audio convergence names both missing parents")
		map._activate_action()
		var links_deadline := Time.get_ticks_msec()+3000
		while not map.parent_links.visible and Time.get_ticks_msec()<links_deadline: await process_frame
		var settle_deadline:=Time.get_ticks_msec()+3000
		while map.parent_links.get_children().any(func(button: Button): return button.modulate.a<0.99) and Time.get_ticks_msec()<settle_deadline: await process_frame
		expect(map.parent_links.visible and map.parent_links.get_child_count()==2,"Audio missing-parent chooser exposes both links")
		for link: Button in map.parent_links.get_children():
			expect(link.modulate.a>=0.99 and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(link.get_global_rect()),"Animated Audio prerequisite link settles fully inside viewport")
		await _capture("audio-and", dimensions.x)
		map.dismiss()
		for lane: StringName in store.LANE_ORDER:
			store._select_lane(lane)
			await process_frame
			await process_frame
			# Scroll applies after two layout frames; observe its resulting transform.
			await process_frame
			var point: Vector2 = map.tree.global_position + map.origins[lane] * map.zoom
			expect(map._map_rect().has_point(point), "Category shortcut centers its branch: " + str(lane))
		map._focus_node(&"colored_text")
		await create_timer(0.56).timeout
		var selected: Button = store._nodes[&"colored_text"]
		expect(selected.get_theme_stylebox("normal").border_color == FeatureStore.SCORE_COLORS[&"graphics"] and selected.get_theme_stylebox("normal").border_width_left == 5, "Selection thickens the category border without replacing its color")
		var label_rect: Rect2 = selected.get_node("FeatureName").get_global_rect()
		if not store.get_global_rect().encloses(map.popup.get_global_rect()): print("STORE_POPUP_BOUNDS ",dimensions," store=",store.get_global_rect()," popup=",map.popup.get_global_rect())
		expect(map._map_rect().encloses(label_rect) and store.get_global_rect().encloses(map.popup.get_global_rect()), "Keyboard reveal includes the external name and keeps details onscreen")
		await _capture("detail", dimensions.x)
		map.dismiss()
		expect(selected.get_theme_stylebox("normal").border_color == FeatureStore.SCORE_COLORS[&"graphics"] and selected.get_theme_stylebox("normal").border_width_left == 3, "Dismissing details restores width while retaining category color")
		for id: StringName in [&"text", &"save_files", &"difficulty_levels", &"branching_nodes"]:
			map._focus_node(id)
			await create_timer(0.56).timeout
			var back := map.popup.find_child("BackToMapButton", true, false) as Button
			if not store.get_global_rect().encloses(map.popup.get_global_rect()): print("STORE_POPUP_BOUNDS ",dimensions," ",id," store=",store.get_global_rect()," popup=",map.popup.get_global_rect())
			expect(back != null and back.is_visible_in_tree() and not back.disabled and store.get_global_rect().encloses(map.popup.get_global_rect()) and map.popup.get_global_rect().encloses(back.get_global_rect()), "Back to Map is reachable for %s at %d" % [id, dimensions.x])
			if back != null:
				var motion := InputEventMouseMotion.new()
				motion.position=back.get_global_rect().get_center()
				root.push_input(motion,true)
				await process_frame
				for pressed in [true, false]:
					var event := InputEventMouseButton.new()
					event.position = back.get_global_rect().get_center()
					event.global_position = event.position
					event.button_index = MOUSE_BUTTON_LEFT
					event.pressed = pressed
					root.push_input(event, true)
					await process_frame
				await process_frame
			if map.popup.visible: print("BACK_CLICK_STATE ",dimensions," / ",id," selected=",store._selected," focus=",root.gui_get_focus_owner())
			expect(not map.popup.visible and store._selected.is_empty() and store.visible and root.gui_get_focus_owner() == map.scroll, "Back to Map dismisses details and restores map focus without closing Store")
		expect(before == _passive_snapshot(run), "Category browsing preserves cash, calendar, redraws, ownership and exact finance history")
		game.queue_free()
		await process_frame
	print("Bloom Feature Store verification: %d failures" % failures)
	quit(failures)

func _verify_category_layout(store: FeatureStore) -> void:
	var map := store._map
	expect(map.category_regions.size()==5 and map.category_headers.size()==5 and map.category_paths.size()==5 and map.tree.get_node_or_null("FeatureLibraryRoot")==null, "Five trees stem from a noninteractive empty square")
	var tech_row_bottom := map.node_footprint(store._nodes[&"keyboard_and_mouse"]).end.y
	for id: StringName in [&"menu_system", &"save_files", &"controller", &"split_screen"]:
		tech_row_bottom = maxf(tech_row_bottom, map.node_footprint(store._nodes[id]).end.y)
	var side_roots_top := minf(map.node_footprint(store._nodes[&"8_color_palette"]).position.y, map.node_footprint(store._nodes[&"16_bit_sound"]).position.y)
	expect(side_roots_top - tech_row_bottom >= 32.0 and side_roots_top - tech_row_bottom <= 64.0, "Technology crown clears the closer Visuals and Audio branches with room for labels")
	var complete := true
	for lane: StringName in store.LANE_ORDER:
		var area: Rect2 = map.category_regions[lane]
		var header: Label = map.category_headers[lane]
		complete = complete and Rect2(Vector2.ZERO,map.bounds).grow(0.1).encloses(area) and area.grow(0.1).encloses(map.header_rect(header))
		for id: StringName in store.LANE_MEMBERS[lane]:
			var footprint := map.node_footprint(store._nodes[id])
			for other_lane: StringName in store.LANE_ORDER:
				if other_lane == lane: continue
				if footprint.intersects(map.header_rect(map.category_headers[other_lane])):
					print("OVERLAP: ", id, " ", footprint, " / header ", other_lane, " ", map.header_rect(map.category_headers[other_lane]))
					complete = false
				for other_id: StringName in store.LANE_MEMBERS[other_lane]:
					if footprint.intersects(map.node_footprint(store._nodes[other_id])):
						print("OVERLAP: ", id, " / ", other_id)
						complete = false
		expect(is_zero_approx(header.rotation) if lane==&"Technology & Tools" else is_equal_approx(absf(header.rotation),PI/2), "Sideways heading except Technology & Tools: "+str(lane))
	expect(complete,"Five bounded categories with clear cards and headers")
	var routes_clear := true
	for path: PackedVector2Array in map.category_paths:
		routes_clear=routes_clear and _on_border(map.center_square,path[0])
		for index in range(1,path.size()):
			var a := path[index-1]
			var b := path[index]
			routes_clear = routes_clear and (is_equal_approx(a.x,b.x) or is_equal_approx(a.y,b.y)) and not _segment_crosses_interior(a,b,map.center_square)
			for node: Control in store._nodes.values(): routes_clear = routes_clear and not _segment_crosses_interior(a,b,map.node_footprint(node))
			for header: Label in map.category_headers.values(): routes_clear = routes_clear and not _segment_crosses_interior(a,b,map.header_rect(header))
	expect(routes_clear,"Five orthogonal stems leave the square without crossing its interior, cards or headings")

func _passive_snapshot(run: RunState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids(), run.get_studio_finance_snapshot()]

func _outward_rects(parent: Rect2, child: Rect2, direction: Vector2) -> bool:
	if direction == Vector2.LEFT: return child.end.x < parent.position.x
	if direction == Vector2.RIGHT: return child.position.x > parent.end.x
	return direction == Vector2.UP and child.end.y < parent.position.y

func _on_border(rect: Rect2, point: Vector2) -> bool:
	if not rect.grow(0.01).has_point(point): return false
	return minf(minf(absf(point.x - rect.position.x), absf(point.x - rect.end.x)), minf(absf(point.y - rect.position.y), absf(point.y - rect.end.y))) < 0.01

func _segment_crosses_interior(start: Vector2, end: Vector2, rect: Rect2) -> bool:
	var inner := rect.grow(-0.01)
	if is_equal_approx(start.x, end.x):
		return start.x > inner.position.x and start.x < inner.end.x and maxf(minf(start.y, end.y), inner.position.y) < minf(maxf(start.y, end.y), inner.end.y)
	if is_equal_approx(start.y, end.y):
		return start.y > inner.position.y and start.y < inner.end.y and maxf(minf(start.x, end.x), inner.position.x) < minf(maxf(start.x, end.x), inner.end.x)
	return true
