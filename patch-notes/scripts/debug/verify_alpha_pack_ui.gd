extends SceneTree
const IDS := [&"turn_based_combat",&"character_classes",&"character_development",&"branching_dialogue"]
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("Alpha pack UI: "+label)
func _initialize() -> void:
	if DisplayServer.get_name()=="headless": Engine.max_fps=60
	await process_frame
	create_timer(90).timeout.connect(func(): quit(2))
	var database:=root.get_node("CardDatabase")
	var directory:=OS.get_environment("PN_CARD_FRAME_OUTPUT").get_base_dir()
	for size: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size;root.content_scale_size=size
		var run:=RunState.new();run.initialize_cash_cents(3000000)
		var store:=FeatureStore.new();root.add_child(store);store.setup(run);store.open_store()
		for frame in 5: await process_frame
		var before:=run.random_streams.snapshot()
		for id: StringName in IDS:
			check(store._nodes.has(id),"mapped visible node "+str(id))
			store._map._focus_node(id)
			for frame in 240:
				await process_frame
				if not store._map.focusing and (store._map._menu_tween==null or not store._map._menu_tween.is_running()): break
			await process_frame;await process_frame
			check(store._selected==id and store._map.popup.visible,"keyboard-focusable inspect "+str(id))
			var rect:=store._map.popup.get_global_rect()
			check(Rect2(Vector2.ZERO,Vector2(size)).encloses(rect),"detail fits viewport "+str(size)+str(id)+str(rect))
			check(store._map._map_rect().encloses(store._nodes[id].get_global_rect()),"selected node fully visible")
			check(store._buy.text.begins_with("Missing:") or store._buy.text.contains("850.00"),"missing-parent navigation replaces price; otherwise exact deposit is on action button")
			check(store._details.text.contains(database.get_card(id).card_name),"full stable name shown")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(directory.path_join("store-%d-%s.png"%[size.x,id]))
		check(run.random_streams.snapshot()==before and run.get_completed_run_cycles()==0,"browsing stays passive")
		store.queue_free();await process_frame
		var cards: Array[CardView]=[]
		for i in IDS.size():
			var view: CardView=load("res://scenes/cards/card_view.tscn").instantiate()
			root.add_child(view);view.set_card(database.get_card(IDS[i]));view.position=Vector2(40+i*260,100)
			check(view.artwork_fallback.texture!=null and view.artwork_fallback.visible,"visible fallback artwork "+str(IDS[i]))
			cards.append(view)
		await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory.path_join("cards-%d.png"%size.x))
		for view in cards: view.queue_free()
		await process_frame
	print("ALPHA_PACK_UI checks=%d failures=%d"%[checks,failures]);quit(failures)
