extends "res://scripts/debug/verify_feature_store_radial.gd"
var active_store: FeatureStore
func _capture(label: String, width: int) -> void:
	var folder:=OS.get_environment("PN_STORE_CAPTURE")
	if folder.is_empty(): return
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	expect(picture.get_width()==width,"native capture width")
	picture.save_png(folder.path_join("store-%s-%d.png" % [label,width]))
	if label=="overview":
		active_store._select_lane(&"Story & World")
		await create_timer(0.2).timeout
		var map:=active_store._map
		var area:Rect2=map.category_regions[&"Story & World"]
		var view:Vector2=map._map_rect().size-Vector2(24,24)
		map.set_zoom(minf(view.x/area.size.x,view.y/area.size.y))
		map._scroll_after_layout(map.tree.position+area.position*map.zoom-Vector2(12,12),map._view_revision)
		await create_timer(0.2).timeout
		await _capture("story",width)
		for id:StringName in [&"dialogue",&"branching_dialogue"]:
			active_store._map._focus_node(id)
			for frame in 300:
				await process_frame
				if not map.focusing and (map._menu_tween==null or not map._menu_tween.is_running()): break
			expect(active_store.get_global_rect().encloses(active_store._map.popup.get_global_rect()),"new branch details fit " + str(id))
			expect(map._map_rect().encloses(active_store._nodes[id].get_global_rect()),"overview-to-card jump reveals selected card " + str(id))
			await _capture(str(id),width)
		active_store._map.dismiss()
func _verify_category_layout(store: FeatureStore) -> void:
	active_store=store
	super._verify_category_layout(store)
	var graph:=FeatureStoreCatalog.graph(store._run._feature_definitions,store._run._feature_offers)
	var map:=store._map
	for child: StringName in FeatureStoreCatalog.PRIMITIVE_PARENTS:
		expect(store._edges.has([graph.parents[child][0],child]),"draw enforced Primitive edge " + str(child))
	for edge:Array in store._edges:
		var a:Control=store._nodes[edge[0]]
		var b:Control=store._nodes[edge[1]]
		var ar:Rect2=map.node_footprint(a)
		var br:Rect2=map.node_footprint(b)
		var direction:Vector2=(br.get_center()-ar.get_center()).normalized()
		var start:Vector2=map.edge_port(ar,direction)
		var end:Vector2=map.edge_port(br,-direction)
		var clear:=true
		for id:StringName in store._nodes:
			if id in edge:continue
			clear=clear and not crosses(start,end,map.node_footprint(store._nodes[id]).grow(3))
		for rect:Control in map.category_headers.values(): clear=clear and not crosses(start,end,map.header_rect(rect).grow(3))
		expect(clear,"connector avoids unrelated card/name/status/header/gate " + str(edge))
	# This synchronous check does not disturb the inherited navigation checks.
	for child:StringName in FeatureStoreCatalog.PRIMITIVE_PARENTS:
		var offer:=store._run.get_primitive_reserve_offer(child)
		if not offer.owned and not offer.unlocked:
			expect(store._nodes[child].tooltip_text.contains(offer.prerequisite),"visible parent blocker " + str(child))
func crosses(a:Vector2,b:Vector2,rect:Rect2) -> bool:
	if rect.has_point(a) or rect.has_point(b):return true
	var p:=rect.position;var e:=rect.end
	for line:Array in [[p,Vector2(e.x,p.y)],[Vector2(e.x,p.y),e],[e,Vector2(p.x,e.y)],[Vector2(p.x,e.y),p]]:
		if Geometry2D.segment_intersects_segment(a,b,line[0],line[1])!=null:return true
	return false
