extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var failures := 0
var checks := 0
var output := ""

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func settle(seconds: float = 0.04) -> void:
	await create_timer(seconds).timeout
	for i in 4: await process_frame

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func opened(links: Control) -> void:
	for i in 100:
		if links.is_visible_in_tree(): return
		await settle(0.02)

func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	for resolution in [Vector2i(1152,648), Vector2i(1280,720), Vector2i(900,600)]:
		root.size = resolution
		root.content_scale_size = resolution
		var session: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"prereq-ui","studio_name":"Prerequisite UI","specialty":"action","traits":[],"seed":"771"},root.get_node("CardDatabase").get_development_catalog())
		var run: RunState = session.run
		# Controlled absent-ownership UI fixture; not a claimed funded campaign.
		for id: StringName in [&"turn_based_combat",&"scripted_ai",&"difficulty_levels"]: run._owned_features.erase(id)
		var store := FeatureStore.new()
		store.theme = preload("res://resources/ui/workspace_theme.tres")
		root.add_child(store)
		store.setup(run)
		store.open_store()
		await settle()
		store._map._focus_node(&"difficulty_levels")
		await settle(0.8)
		var before := Replay.digest(StudioCheckpoint.new().capture(run))
		var compact_height := store._map.popup.size.y
		await click(store._buy)
		await opened(store._map.parent_links)
		await settle(0.5)
		var links: Control = store._map.parent_links
		check(links.is_visible_in_tree() and links.get_child_count()==2,"Two named prerequisite buttons appear")
		check(not store._map.popup.is_ancestor_of(links),"Links expand beside, not inside the detail panel")
		check(is_equal_approx(compact_height,store._map.popup.size.y),"Opening links does not add vertical detail rows")
		if links.get_child_count()==2:
			var first := links.get_child(0) as Button
			var second := links.get_child(1) as Button
			check(first.get_global_rect().position.x >= store._buy.get_global_rect().end.x,"Links lie to the right of the Missing action")
			check(second.get_global_rect().position.x > first.get_global_rect().end.x and absf(first.global_position.y-second.global_position.y)<1,"Targets share one horizontal row")
			check(first.text=="Turn-Based Combat" and second.text=="Scripted AI","Both exact node names remain readable")
			check(first.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING and second.autowrap_mode!=TextServer.AUTOWRAP_OFF,"Labels wrap without ellipses")
			check(store._body.get_global_rect().encloses(first.get_global_rect()) and store._body.get_global_rect().encloses(second.get_global_rect()),"Expanded buttons fit the Store at "+str(resolution))
			check(not first.get_global_rect().intersects(store._map.popup.get_global_rect()),"Expanded row does not cover detail actions")
			check(is_equal_approx(first.modulate.a,1) and is_equal_approx(second.modulate.a,1),"Entrance finishes with visible controls")
			await capture("prerequisites-%d"%resolution.x)
			await click(second)
			await settle(0.8)
			check(store._selected==&"scripted_ai","Actual pointer click outside the popup follows the right-side link")
		check(before==Replay.digest(StudioCheckpoint.new().capture(run)),"Inspecting prerequisites preserves complete Studio state/RNG")
		store._map._focus_node(&"difficulty_levels")
		await settle(0.8)
		await click(store._buy)
		await opened(store._map.parent_links)
		await settle(0.4)
		await click(store._buy)
		await settle()
		check(not store._map.parent_links.is_visible_in_tree(),"Second Missing click collapses links")
		# Handoff 022: one missing parent follows directly without a chooser.
		run._owned_features[&"turn_based_combat"] = true
		store._refresh()
		store._map._focus_node(&"difficulty_levels")
		await settle(0.8)
		var single_before := Replay.digest(StudioCheckpoint.new().capture(run))
		await click(store._buy)
		await settle(0.8)
		check(store._selected==&"scripted_ai" and not store._map.parent_links.is_visible_in_tree(),"Single missing prerequisite navigates directly without chooser")
		check(single_before==Replay.digest(StudioCheckpoint.new().capture(run)),"Direct prerequisite navigation preserves complete state/RNG")
		check(store._body.get_global_rect().encloses(store._map.popup.get_global_rect()),"Direct target details remain inside the Store")
		await capture("single-prerequisite-%d"%resolution.x)
		store._map._focus_node(&"difficulty_levels")
		await settle(0.8)
		store._buy.grab_focus()
		for pressed in [true, false]:
			var accept := InputEventKey.new()
			accept.keycode = KEY_ENTER
			accept.pressed = pressed
			Input.parse_input_event(accept)
			await process_frame
		await settle(0.8)
		check(store._selected==&"scripted_ai" and not store._map.parent_links.is_visible_in_tree(),"Keyboard activation directly follows the single prerequisite")
		check(single_before==Replay.digest(StudioCheckpoint.new().capture(run)),"Keyboard navigation preserves state/RNG")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		Input.parse_input_event(escape)
		await settle()
		check(not store._map.popup.visible and not store._map.parent_links.is_visible_in_tree(),"Escape closes details and external links together")
		store.queue_free()
		await settle()
	print("Store prerequisite links: %d checks, %d failures"%[checks,failures])
	quit(failures)
