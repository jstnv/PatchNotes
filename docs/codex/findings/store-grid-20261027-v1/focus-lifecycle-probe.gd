extends SceneTree

var checks:=0
var failures:=0
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)

func opened(run: RunState)->FeatureStore:
	var store:=FeatureStore.new()
	root.add_child(store);store.setup(run);store.open_store()
	store._select_node(&"secrets")
	store._map._stop_focus_animation()
	store._map.focusing=true
	return store

func _initialize()->void:
	await process_frame
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/background_checkpoint_v003_c96.json"))
	var run:=StudioCheckpoint.new().hydrate(fixture.player)
	expect(run!=null,"Actual late Studio fixture restores")
	for frame_count in [0,1,2]:
		var store:=opened(run)
		var map:=store._map
		var entered: Array[bool]=[false]
		map._focus_tween=map.create_tween()
		map._focus_tween.tween_callback(map._finish_focus.bind(&"secrets",map.zoom,store._nodes[&"secrets"].get_rect().get_center(),map._view_revision))
		map._focus_tween.tween_callback(func():entered[0]=true)
		while not entered[0]:await process_frame
		for frame in frame_count:await process_frame
		store.free()
		for frame in 4:await process_frame
		expect(not is_instance_valid(map),"Freeing Store during focus frame%d safely cancels callbacks"%frame_count)
	var store:=opened(run)
	var map:=store._map
	var initial_zoom:=map.zoom
	var final_zoom:=initial_zoom*0.9
	map._finish_focus(&"secrets",final_zoom,store._nodes[&"secrets"].get_rect().get_center(),map._view_revision)
	await process_frame
	expect(map.focusing and is_equal_approx(map.zoom,initial_zoom),"First frame retains the camera and waits for layout")
	await process_frame
	expect(map.focusing and is_equal_approx(map.zoom,final_zoom),"Second frame applies the final camera before menu entrance")
	await process_frame
	expect(not map.focusing,"Third frame opens the live final menu")
	store.free()
	for frame in 3:await process_frame
	store=opened(run);map=store._map
	map._finish_focus(&"secrets",map.zoom,Vector2.ZERO,map._view_revision)
	map._view_revision+=1
	for frame in 5:await process_frame
	expect(map.focusing,"Superseded focus cannot open an obsolete menu")
	store._selected=&"text"
	map._finish_focus(&"text",map.zoom,store._nodes[&"text"].get_rect().get_center(),map._view_revision)
	for frame in 3:await process_frame
	expect(not map.focusing,"Replacement selection completes after obsolete work was cancelled")
	store.free()
	for frame in 3:await process_frame
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report));print(JSON.stringify(report));quit(1 if failures else 0)
