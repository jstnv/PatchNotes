extends SceneTree

var checks := 0
var failures := 0
func expect(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var run := RunState.new()
	run.initialize_cash_cents(1000000)
	var layout := load("res://scripts/ui/feature_store_layout.gd")
	var ids: Array=run._feature_definitions.keys()
	var duplicate:=ids.duplicate();duplicate[0]=duplicate[1]
	expect(layout.cells(duplicate).has("error"),"Duplicate occupied cells reject explicitly")
	var unknown:=ids.duplicate();unknown[0]=&"future_unplaced_node"
	expect(layout.cells(unknown).has("error"),"Unplaced new nodes reject explicitly")
	var before := run.random_streams.snapshot()
	var store := FeatureStore.new()
	root.add_child(store);store.setup(run);store.open_store()
	for frame in 5: await process_frame
	var map := store._map
	var origin: Vector2=store._nodes[&"text"].position
	var used := {}
	var lattice := true
	var clear := true
	for id: StringName in store._nodes:
		var point: Vector2=(store._nodes[id].position-origin)/212.0
		lattice=lattice and point.is_equal_approx(point.round())
		if used.has(point): clear=false
		used[point]=id
		for other: StringName in store._nodes:
			if id!=other and map.node_footprint(store._nodes[id]).intersects(map.node_footprint(store._nodes[other])): clear=false
	expect(lattice,"All47 node centers share one global integer lattice")
	expect(clear and used.size()==47,"All47 occupied cells and card/label footprints are unique")
	var headings_clear:=true
	for header: Label in map.category_headers.values():
		for node: Control in store._nodes.values():
			if map.header_rect(header).intersects(map.node_footprint(node)): headings_clear=false
	expect(headings_clear,"Every rotated heading is clear of all cards and labels")
	var palette: Vector2=store._nodes[&"4_color_palette"].position
	var text: Vector2=store._nodes[&"text"].position
	var sprites: Vector2=store._nodes[&"sprites"].position
	expect(palette==text+Vector2(0,-212),"Palette directly above Text")
	expect(store._nodes[&"colored_text"].position==text+Vector2(-212,0),"Colored Text directly left of Text")
	expect(sprites==palette+Vector2(-212,0),"Sprites directly left of Palette")
	expect(store._nodes[&"animated_sprites"].position==sprites+Vector2(-212,0),"Animated Sprites directly left of Sprites")
	expect(store._nodes[&"8_color_palette"].position==sprites+Vector2(0,-212),"Eight Color directly above Sprites")
	expect(store._nodes[&"scrolling"].position==store._nodes[&"colored_text"].position+Vector2(0,212),"Scrolling directly below Colored Text")
	expect(store._nodes[&"multi_directional_scrolling"].position.x<store._nodes[&"animated_sprites"].position.x,"Second left-of-Sprites request uses a separate outward cell")
	var audio_root: Vector2=store._nodes[&"8_bit_sound"].position
	expect(audio_root.x-text.x<=3.0*212.0,"Side-category roots share a compact central corridor")
	for id: StringName in [&"score_system",&"lives_system",&"controls",&"power_ups"]:
		expect(store._nodes[id].position.x==text.x,"Left roots share the inward column: "+str(id))
	for id: StringName in [&"simple_story",&"levels"]:
		expect(store._nodes[id].position.x==audio_root.x,"Right roots share the inward column: "+str(id))
	var menu: Vector2=store._nodes[&"menu_system"].position
	var keyboard: Vector2=store._nodes[&"keyboard_and_mouse"].position
	var controller: Vector2=store._nodes[&"controller"].position
	expect(menu.y==keyboard.y and menu.y==controller.y and menu.x<keyboard.x and keyboard.x<controller.x,"Technology root order Menu / Keyboard / Controller")
	expect(store._nodes[&"save_files"].position==menu+Vector2(0,-212),"Save Files follows Menu without the old root gap")
	expect(store._nodes[&"branching_nodes"].position==menu+Vector2(0,-424),"Branching Nodes follows Save Files")
	if map.get("edge_routes") is Dictionary:
		var graph:=FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
		var total:=0
		for id: StringName in graph.parents:
			for parent: StringName in graph.parents[id]:
				if store._lane_by_id[parent]==store._lane_by_id[id]: total+=1
		expect(map.edge_routes.size()==total,"Only same-category parents have map arrows")
		expect(not store._edges.any(func(edge: Array): return store._lane_by_id[edge[0]]!=store._lane_by_id[edge[1]]),"No cross-category connector is drawn")
		expect(graph.parents[&"split_screen"]==[&"branching_nodes",&"scrolling"] and store._nodes[&"split_screen"].get_node("AndGate").text=="AND: 2 parents","Hidden cross-category arrow keeps both real prerequisites")
		for edge: Array in store._edges:
			var key:=str(edge[0])+"->"+str(edge[1])
			var path: PackedVector2Array=map.edge_routes.get(key,PackedVector2Array())
			var safe:=path.size()>1
			for point: Vector2 in path:
				if not Rect2(Vector2.ZERO,map.bounds).grow(-10).has_point(point): safe=false
			for i in range(1,path.size()):
				for id: StringName in store._nodes:
					if segment_hits(path[i-1],path[i],map.node_footprint(store._nodes[id]).grow(4)): safe=false
				for header: Label in map.category_headers.values():
					if segment_hits(path[i-1],path[i],map.header_rect(header).grow(4)): safe=false
			expect(safe,"Bounded route avoids every card/label/header "+key)
	else:
		expect(false,"Map exposes precomputed obstacle-safe routes")
	var neutral_clear:=true
	for path: PackedVector2Array in map.category_paths:
		for i in range(1,path.size()):
			for node: Control in store._nodes.values():
				if segment_hits(path[i-1],path[i],map.node_footprint(node).grow(4)): neutral_clear=false
			for header: Label in map.category_headers.values():
				if segment_hits(path[i-1],path[i],map.header_rect(header).grow(4)): neutral_clear=false
	expect(neutral_clear,"Four category connectors avoid all cards, names and headers")
	if not neutral_clear: print("CATEGORY_PATHS ",map.category_paths)
	map._focus_node(&"character_classes")
	expect(store._buy.text=="Missing: Save Files","Cross-category prerequisite remains explicit in details")
	map._activate_action()
	expect(store._selected==&"save_files" and not map.parent_links.visible,"Hidden cross-category arrow still permits direct prerequisite navigation")
	expect(before==run.random_streams.snapshot(),"Layout and routing consume no gameplay RNG")
	store.queue_free();await process_frame
	print("Store common grid: %d checks, %d failures"%[checks,failures]);quit(failures)

func segment_hits(a: Vector2,b: Vector2,rect: Rect2) -> bool:
	if rect.has_point(a) or rect.has_point(b): return true
	var corners: Array[Vector2]=[rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a,b,corners[i],corners[(i+1)%4])!=null: return true
	return false
