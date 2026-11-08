extends "res://scripts/debug/capture_primitive_branches.gd"

func _verify_category_layout(store: FeatureStore) -> void:
	super._verify_category_layout(store)
	var map := store._map
	var graph := FeatureStoreCatalog.graph(store._run._feature_definitions, store._run._feature_offers)
	var positions := {}
	for lane: StringName in store.LANE_ORDER:
		var roots: Array = []
		for id: StringName in store.LANE_MEMBERS[lane]:
			if graph.parents[id].is_empty(): roots.append(id)
		var direction: Vector2 = map.CATEGORY_DIRECTIONS[lane]
		var anchor: Vector2 = store._nodes[roots[0]].position
		var aligned := true
		var grid := true
		var outward := true
		for id: StringName in store.LANE_MEMBERS[lane]:
			var delta: Vector2 = store._nodes[id].position - anchor
			positions[id] = [store._nodes[id].position.x, store._nodes[id].position.y]
			grid = grid and is_zero_approx(fposmod(absf(delta.x), map.BRANCH_STEP)) and is_zero_approx(fposmod(absf(delta.y), map.ROW_STEP))
			if roots.has(id): aligned = aligned and is_zero_approx(delta.dot(direction))
			else: outward = outward and delta.dot(direction) > 0.0
		expect(aligned and grid and outward, "inner root axis, cardinal grid and no root in front of branches: " + str(lane))
		var cone: PackedVector2Array = map.category_cones[lane]
		expect(cone.size() >= 5, "outward cone polygon " + str(lane))
		if lane == &"Visuals": expect(roots == [&"text", &"4_color_palette"], "Visuals has exactly the two approved roots")
		if lane == &"Audio": expect(roots == [&"sound_effects", &"music"], "Audio has exactly the two approved roots")
	var children := {}
	for edge: Array in store._edges:
		if graph.parents[edge[1]][0] != edge[0]: continue
		if not children.has(edge[0]): children[edge[0]] = []
		children[edge[0]].append(edge[1])
	for parent: StringName in children:
		if children[parent].size() < 2: continue
		# Same-tree AND convergence reserves another grid row for its second arm.
		if children[parent].any(func(child):return store._edges.any(func(edge):return edge[0]==child and graph.parents[edge[1]].size()==2 and graph.parents[edge[1]][1]==child)): continue
		var descendants: Array = map._children(parent, children)
		var lane: StringName = store._lane_by_id[parent]
		var across: Vector2 = map._across(lane)
		var first: Vector2 = store._nodes[descendants[0]].position
		var source: Vector2 = store._nodes[parent].position
		var sibling: Vector2 = store._nodes[descendants[1]].position
		expect(is_zero_approx((first-source).dot(across)) and sibling-first == across, "every fork has aligned first child and adjacent sibling: " + str(parent))
	var combat: Vector2 = store._nodes[&"general_combat"].position
	var turn: Vector2 = store._nodes[&"turn_based_combat"].position
	var classes: Vector2 = store._nodes[&"character_classes"].position
	expect(turn.y == combat.y and turn.x < combat.x and classes.x == turn.x and classes.y == turn.y + map.ROW_STEP, "Combat continues straight to Turn-Based with Classes in adjacent row below")
	var middle: Vector2 = map.center
	for lane: StringName in store.LANE_ORDER:
		var region: Rect2 = map.category_regions[lane]
		if lane in [&"Gameplay", &"Story & World"]: expect(region.position.y > middle.y, "lower cone " + str(lane))
		else: expect(region.end.y < middle.y, "upper cone " + str(lane))
	var folder := OS.get_environment("PN_STORE_CAPTURE")
	if not folder.is_empty(): FileAccess.open(folder.path_join("positions.json"), FileAccess.WRITE).store_string(JSON.stringify(positions,"\t"))

func _capture(label: String, width: int) -> void:
	var folder := OS.get_environment("PN_STORE_CAPTURE")
	if folder.is_empty(): return
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	expect(picture.get_width() == width, "native capture width")
	picture.save_png(folder.path_join("store-%s-%d.png" % [label,width]))
	if label != "overview": return
	var map := active_store._map
	for lane: StringName in active_store.LANE_ORDER:
		var area: Rect2 = map.category_regions[lane]
		var lane_view: Vector2 = map._map_rect().size - Vector2(24,24)
		map.set_zoom(minf(lane_view.x / area.size.x, lane_view.y / area.size.y))
		map.center_after_layout(area.get_center(), map._view_revision)
		await create_timer(0.2).timeout
		await _capture(str(lane).replace(" & ","-").to_lower(), width)
	# Show the requested fork at readable scale, without the detail popup.
	map.set_zoom(minf(0.8, (map._map_rect().size.y - 24.0) / (map.ROW_STEP + 172.0)))
	map.center_after_layout(active_store._nodes[&"turn_based_combat"].position + Vector2((map.SIDE_BRANCH_STEP + 128.0) / 2.0, (map.ROW_STEP + 172.0) / 2.0), map._view_revision)
	await create_timer(0.2).timeout
	await _capture("combat-fork", width)
	var merge := map.node_footprint(active_store._nodes[&"difficulty_levels"])
	for id: StringName in [&"enemies", &"general_combat", &"turn_based_combat", &"scripted_ai", &"character_classes"]:
		merge=merge.merge(map.node_footprint(active_store._nodes[id]))
	merge=merge.grow(32)
	var view: Vector2=map._map_rect().size-Vector2(24,24)
	map.set_zoom(minf(view.x/merge.size.x,view.y/merge.size.y))
	map.center_after_layout(merge.get_center(),map._view_revision)
	await create_timer(0.2).timeout
	await _capture("gameplay-merge",width)
	map._focus_node(&"difficulty_levels")
	await create_timer(0.8).timeout
	expect(map.parent_links.get_child_count()==2 and not active_store._details.text.contains("3 distinct Gameplay"),"Difficulty details expose both parent links without obsolete count copy")
	await _capture("difficulty-details",width)
	map.dismiss()
	map.fit_map()
	await create_timer(0.2).timeout
