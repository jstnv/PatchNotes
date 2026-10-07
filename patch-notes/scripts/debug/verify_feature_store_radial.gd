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
	root.get_texture().get_image().save_png("res://design-logs/feature-bloom-map-v1/%s-%d.png" % [name, width])

func _verify() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(900, 600), Vector2i(1280, 720)]:
		root.size = dimensions
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		var menu: MainMenu = game.get("_active_phase")
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Category Store Test"
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
		menu.get("_background").select(1)
		menu.call("_show_review")
		menu.call("_confirm_studio")
		var run: RunState = game.run_state
		var studio: StudioPhase = game.get("_active_phase")
		studio.get_node("%FeatureStoreButton").pressed.emit()
		var store: FeatureStore = studio.get("_feature_store")
		var map := store._map
		await process_frame
		await process_frame
		await process_frame
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		var before := _passive_snapshot(run)
		var primitive: Array[StringName] = []
		for entry: Dictionary in FeatureStoreCatalog.starting_features(): primitive.append(StringName(entry.id))
		expect(primitive.size() == 27 and store._nodes.size() == 38, "Complete ledger membership retained (%d)" % dimensions.x)
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
			bounded = bounded and Rect2(Vector2.ZERO, map.bounds).encloses(map.node_footprint(node))
			visible = visible and node.is_visible_in_tree() and map._map_rect().encloses(node.get_global_rect()) and map._map_rect().encloses(name_label.get_global_rect())
			if map.node_footprint(node).grow(2).intersects(store._gate.get_rect().grow(2)):
				overlaps.append([id, &"gameplay_gate"])
			if map.node_footprint(node).intersects(map.category_headers[lane].get_rect()):
				overlaps.append([id, lane])
			for j in range(i + 1, ids.size()):
				if map.node_footprint(node).grow(2).intersects(map.node_footprint(store._nodes[ids[j]]).grow(2)):
					overlaps.append([id, ids[j]])
		expect(categorized and store._lane_by_id.size() == 38, "Every Feature appears once inside its assigned category branch")
		expect(labels, "Every artwork node stays square and every name sits below its border")
		expect(colors and FeatureStore.SCORE_COLORS.size() == 4, "All four category colors follow ledger primary scores in every interaction state")
		bounded = bounded and Rect2(Vector2.ZERO, map.bounds).encloses(store._gate.get_rect()) and map.category_regions[&"Gameplay"].encloses(store._gate.get_rect())
		visible = visible and map._map_rect().encloses(store._gate.get_global_rect())
		expect(bounded and overlaps.is_empty(), "Map bounds include names and Gameplay gate; no node, gate or heading footprints overlap: " + str(overlaps))
		var outward := true
		for edge: Array in store._edges:
			var parent: Control = store._gate if edge[0] == &"gameplay_gate" else store._nodes[edge[0]]
			var child: Control = store._nodes[edge[1]]
			var parent_rect := parent.get_rect() if parent == store._gate else map.node_footprint(parent)
			var lane: StringName = store._lane_by_id[edge[1]]
			outward = outward and _outward_rects(parent_rect, map.node_footprint(child), map.CATEGORY_DIRECTIONS[lane])
			if edge[0] == &"gameplay_gate":
				outward = outward and lane == &"Gameplay"
			else:
				outward = outward and store._lane_by_id[edge[0]] == lane
		expect(outward and store._edges.size() == 10 and not store._edges.any(func(edge: Array): return edge[1] == &"save_files"), "Every real prerequisite grows outward within its category; independent roots gain no fabricated parent")
		expect(visible and map.bounds.x * map.zoom <= map._map_rect().size.x and map.bounds.y * map.zoom <= map._map_rect().size.y, "Initial overview shows all 38 Features and their names")
		print("Map geometry: ", JSON.stringify({"bounds": str(map.bounds), "viewport": str(map.scroll.size), "zoom": map.zoom, "hub": str(map.hub.get_rect())}))
		await _capture("overview", dimensions.x)
		for lane: StringName in store.LANE_ORDER:
			store._select_lane(lane)
			await process_frame
			await process_frame
			var point: Vector2 = map.tree.global_position + map.origins[lane] * map.zoom
			expect(map._map_rect().has_point(point), "Category shortcut centers its branch: " + str(lane))
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
		expect(before == _passive_snapshot(run), "Category browsing preserves cash, calendar, redraws, ownership and exact finance history")
		game.queue_free()
		await process_frame
	print("Bloom Feature Store verification: %d failures" % failures)
	quit(failures)

func _verify_category_layout(store: FeatureStore) -> void:
	var map := store._map
	var complete := map.category_regions.size() == 5 and map.category_headers.size() == 5 and map.category_paths.size() == 5 and map.hub != null
	var orderly := true
	var contained := true
	var counts := {Vector2.LEFT: 0, Vector2.UP: 0, Vector2.RIGHT: 0}
	var seen: Dictionary = {}
	var assigned: Dictionary = {}
	var hub_rect := map.hub.get_rect() if map.hub != null else Rect2()
	for index in range(store.LANE_ORDER.size()):
		var lane: StringName = store.LANE_ORDER[index]
		complete = complete and map.category_regions.has(lane) and map.category_headers.has(lane) and map.origins.has(lane)
		if not map.category_regions.has(lane) or not map.category_headers.has(lane): continue
		var region: Rect2 = map.category_regions[lane]
		var header: Label = map.category_headers[lane]
		contained = contained and Rect2(Vector2.ZERO, map.bounds).encloses(region) and region.encloses(header.get_rect())
		contained = contained and header.is_visible_in_tree() and header.text.to_lower().contains(str(lane).to_lower())
		contained = contained and header.get_rect().end.y < region.get_center().y
		var direction: Vector2 = map.CATEGORY_DIRECTIONS.get(lane, Vector2.ZERO)
		orderly = orderly and counts.has(direction)
		if counts.has(direction): counts[direction] += 1
		if direction == Vector2.LEFT: orderly = orderly and region.end.x < hub_rect.position.x
		elif direction == Vector2.RIGHT: orderly = orderly and region.position.x > hub_rect.end.x
		elif direction == Vector2.UP:
			orderly = orderly and region.end.y < hub_rect.position.y and is_equal_approx(region.get_center().x, hub_rect.get_center().x)
		for other: StringName in seen:
			orderly = orderly and not region.intersects(map.category_regions[other])
		seen[lane] = true
		for id: StringName in store.LANE_MEMBERS[lane]:
			complete = complete and not assigned.has(id) and store._nodes.has(id) and store._lane_by_id.get(id, &"") == lane
			assigned[id] = lane
	complete = complete and assigned.size() == store._nodes.size()
	orderly = orderly and counts[Vector2.LEFT] == 2 and counts[Vector2.UP] == 1 and counts[Vector2.RIGHT] == 2
	orderly = orderly and map.CATEGORY_DIRECTIONS.get(&"Visuals") == Vector2.LEFT and map.CATEGORY_DIRECTIONS.get(&"Audio") == Vector2.LEFT
	orderly = orderly and map.CATEGORY_DIRECTIONS.get(&"Technology & Tools") == Vector2.UP and map.CATEGORY_DIRECTIONS.get(&"Gameplay") == Vector2.RIGHT and map.CATEGORY_DIRECTIONS.get(&"Story & World") == Vector2.RIGHT
	var routes_bounded := true
	var routes_clear := true
	for index in range(map.category_paths.size()):
		var path: PackedVector2Array = map.category_paths[index]
		routes_bounded = routes_bounded and path.size() >= 2
		for point: Vector2 in path:
			routes_bounded = routes_bounded and Rect2(Vector2.ZERO, map.bounds).has_point(point)
		if path.size() < 2: continue
		var destination: Rect2 = map.category_regions[store.LANE_ORDER[index]]
		routes_clear = routes_clear and _on_border(hub_rect.grow(8.0), path[0]) and _on_border(destination, path[-1])
		for segment in range(1, path.size()):
			var start := path[segment - 1]
			var end := path[segment]
			routes_clear = routes_clear and (is_equal_approx(start.x, end.x) or is_equal_approx(start.y, end.y))
			for lane: StringName in store.LANE_ORDER:
				routes_clear = routes_clear and not _segment_crosses_interior(start, end, map.category_regions[lane])
	var centered := false
	if map.hub != null:
		var left_inner: float = map.category_regions[&"Audio"].end.x
		var right_inner: float = map.category_regions[&"Story & World"].position.x
		centered = map.hub.is_visible_in_tree() and is_equal_approx(hub_rect.get_center().x, (left_inner + right_inner) / 2.0)
		centered = centered and Rect2(Vector2.ZERO, map.bounds).encloses(hub_rect)
	expect(complete and routes_bounded, "One central root has five category routes and complete ledger membership")
	expect(orderly and contained, "Five disjoint bounded branches bloom two left, one upward and two right with upright top headings")
	expect(centered, "Feature Library root sits centrally beneath the upward branch")
	expect(routes_clear, "Five orthogonal category paths join hub and region borders without crossing any category interior")

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
