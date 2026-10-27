extends SceneTree
var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures+=1
func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode=code;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
func _run() -> void:
	root.size=Vector2i(1152,648);root.content_scale_size=root.size
	var session: RefCounted=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"keyboard-links","studio_name":"Keyboard","specialty":"action","traits":[],"seed":"771"},root.get_node("CardDatabase").get_development_catalog())
	for id: StringName in [&"difficulty_levels",&"turn_based_combat",&"scripted_ai"]:session.run._owned_features.erase(id)
	var store:=FeatureStore.new();root.add_child(store);store.setup(session.run);store.open_store()
	await create_timer(.1).timeout
	store._map._focus_node(&"difficulty_levels");await create_timer(.8).timeout
	store._buy.grab_focus();await key(KEY_ENTER);await create_timer(1.0).timeout
	check(store._map.parent_links.is_visible_in_tree(),"Enter on Missing expands prerequisites")
	check(store._buy.has_focus(),"Animated expansion restores the activating action's keyboard focus")
	await key(KEY_RIGHT);await process_frame
	check(store._selected==&"difficulty_levels" and store._map.parent_links.is_visible_in_tree() and root.gui_get_focus_owner()==store._map.parent_links.get_child(0),"Right navigates to first prerequisite, not another map node")
	if failures==0:
		await key(KEY_ENTER);await create_timer(.8).timeout
		check(store._selected==&"turn_based_combat" and not store._map.parent_links.visible,"Enter follows the focused prerequisite")
	store._map._focus_node(&"difficulty_levels");await create_timer(.8).timeout
	store._buy.grab_focus();await key(KEY_ENTER);await create_timer(.03).timeout
	await key(KEY_ESCAPE);await create_timer(1.0).timeout
	check(not store._map.popup.visible and not store._map.parent_links.visible,"Escape during entrance prevents delayed reopening")
	store.queue_free();await process_frame;quit(failures)
