extends SceneTree

var failures := 0

func _initialize() -> void:
	_verify.call_deferred()

func expect(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func _capture(name: String, width: int) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://design-logs/feature-radial-map-v1/%s-%d.png" % [name, width])

func _verify() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = dimensions
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		var menu: MainMenu = game.get("_active_phase")
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Radial Store Test"
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
		var run: RunState = game.run_state
		var studio: StudioPhase = game.get("_active_phase")
		studio.get_node("%FeatureStoreButton").pressed.emit()
		var store: FeatureStore = studio.get("_feature_store")
		var map := store._map
		await process_frame
		await process_frame
		await process_frame
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		var before := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids()]
		var primitive: Array[StringName] = []
		for entry: Dictionary in FeatureStoreCatalog.starting_features(): primitive.append(StringName(entry.id))
		expect(primitive.size() == 27 and store._nodes.size() == 38, "Complete ledger membership retained (%d)" % dimensions.x)
		var inside := true
		var outside := true
		var labels := true
		var colors := true
		var bounded := true
		var overlaps: Array = []
		var ids := store._nodes.keys()
		for i in range(ids.size()):
			var id: StringName = ids[i]
			var node: Button = store._nodes[id]
			var radius := node.get_rect().get_center().distance_to(map.center)
			if id in primitive: inside = inside and radius < map.core_radius
			else: outside = outside and radius > map.core_radius
			var name_label: Label = node.get_node("FeatureName")
			labels = labels and node.size == Vector2(128, 128) and name_label.position.y > node.size.y and not node.clip_contents
			var card: CardData = root.get_node("CardDatabase").get_card(id)
			for state in ["normal", "hover", "pressed", "focus"]:
				colors = colors and node.get_theme_stylebox(state).border_color == FeatureStore.SCORE_COLORS[card.primary_stat]
			bounded = bounded and Rect2(Vector2.ZERO, map.bounds).encloses(map.node_footprint(node))
			for j in range(i + 1, ids.size()):
				if map.node_footprint(node).grow(2).intersects(map.node_footprint(store._nodes[ids[j]]).grow(2)):
					overlaps.append([id, ids[j]])
		expect(inside and outside, "Only Primitive nodes occupy the central core; later roots and upgrades sit outside")
		expect(labels, "Every artwork node stays square and every name sits below its border")
		expect(colors and FeatureStore.SCORE_COLORS.size() == 4, "All four category colors follow ledger primary scores in every interaction state")
		expect(bounded and overlaps.is_empty(), "Map bounds include labels and no Feature footprints overlap: " + str(overlaps))
		var outward := true
		for edge: Array in store._edges:
			var parent: Control = store._gate if edge[0] == &"gameplay_gate" else store._nodes[edge[0]]
			var child: Control = store._nodes[edge[1]]
			outward = outward and parent.get_rect().get_center().distance_to(map.center) < child.get_rect().get_center().distance_to(map.center)
		expect(outward and store._edges.size() == 10 and not store._edges.any(func(edge: Array): return edge[1] == &"save_files"), "Every real prerequisite edge points outward; independent roots gain no fabricated parent")
		expect(map.bounds.x * map.zoom <= map._map_rect().size.x and map.bounds.y * map.zoom <= map._map_rect().size.y, "Initial overview fits the complete radial map")
		print("Map geometry: ", JSON.stringify({"bounds": str(map.bounds), "viewport": str(map.scroll.size), "zoom": map.zoom, "center": str(map.center)}))
		await _capture("overview", dimensions.x)
		for lane: StringName in store.LANE_ORDER:
			store._select_lane(lane)
			await process_frame
			await process_frame
			var point: Vector2 = map.tree.global_position + map.origins[lane] * map.zoom
			expect(map._map_rect().has_point(point), "Lane shortcut centers its Primitive sector: " + str(lane))
		map._focus_node(&"colored_text")
		await create_timer(0.56).timeout
		var selected: Button = store._nodes[&"colored_text"]
		expect(selected.get_theme_stylebox("normal").border_color == FeatureStore.SCORE_COLORS[&"graphics"] and selected.get_theme_stylebox("normal").border_width_left == 5, "Selection thickens the category border without replacing its color")
		var label_rect: Rect2 = selected.get_node("FeatureName").get_global_rect()
		expect(map._map_rect().encloses(label_rect) and store.get_global_rect().encloses(map.popup.get_global_rect()), "Keyboard reveal includes the external name and keeps details onscreen")
		await _capture("detail", dimensions.x)
		map.dismiss()
		expect(selected.get_theme_stylebox("normal").border_color == FeatureStore.SCORE_COLORS[&"graphics"] and selected.get_theme_stylebox("normal").border_width_left == 3, "Dismissing details restores width while retaining category color")
		for id: StringName in [&"text", &"save_files", &"difficulty_levels", &"branching_nodes"]:
			map._focus_node(id)
			await create_timer(0.56).timeout
			var back := map.popup.find_child("BackToMapButton", true, false) as Button
			expect(back != null and back.is_visible_in_tree() and not back.disabled and store.get_global_rect().encloses(map.popup.get_global_rect()) and map.popup.get_global_rect().encloses(back.get_global_rect()), "Back to Map is reachable for %s at %d" % [id, dimensions.x])
			if back != null:
				for pressed in [true, false]:
					var event := InputEventMouseButton.new()
					event.position = back.get_global_rect().get_center()
					event.global_position = event.position
					event.button_index = MOUSE_BUTTON_LEFT
					event.pressed = pressed
					root.push_input(event, true)
			expect(not map.popup.visible and store._selected.is_empty() and store.visible and root.gui_get_focus_owner() == map.scroll, "Back to Map dismisses details and restores map focus without closing Store")
		expect(before == [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids()], "Radial browsing preserves cash, calendar, redraws and ownership")
		game.queue_free()
		await process_frame
	print("Radial Feature Store verification: %d failures" % failures)
	quit(failures)
