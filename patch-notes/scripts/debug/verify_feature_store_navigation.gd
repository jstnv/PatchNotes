extends SceneTree

var failures := 0
var store: FeatureStore
var run: RunState
var studio: StudioPhase
var engine_id: StringName

func _initialize() -> void:
	_run.call_deferred()

func expect(value: bool, description: String) -> void:
	print("PASS: " if value else "FAIL: ", description)
	if not value: failures += 1

func _run() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = dimensions
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		# A bounded Store stress viewport, overriding the startup Settings minimum.
		root.min_size=Vector2i.ZERO
		root.size=dimensions
		root.content_scale_size=dimensions
		expect(root.size==dimensions,"Actual requested navigation viewport "+str(dimensions))
		var menu: MainMenu = game.get("_active_phase")
		menu.navigation.animate=false
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		if is_instance_valid(menu._replace_dialog) and menu._replace_dialog.visible:
			menu._replace_dialog.hide()
			menu._replace_dialog.confirmed.emit()
		menu._name_input.text = "Navigation Test"
		menu._specialty.select(1)
		menu._play.pressed.emit()
		menu.call("_open_folder", &"traits")
		menu.call("_show_review")
		menu.call("_confirm_studio")
		await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
		run = game.run_state
		studio = game.get("_active_phase")
		var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Navigation Engine"))
		expect(created.get("ok",false),"Navigation fixture creates a proprietary engine")
		if not created.get("ok",false):game.queue_free();continue
		engine_id=created.engine_id
		# This suite later verifies clicking an already-implemented Feature is a
		# no-op. New proprietary engines start empty; acquire Text legally first.
		var text_quote:=run.get_feature_research_quote(&"text",engine_id)
		expect(text_quote.get("can_admit",false) and run.admit_feature_research(text_quote),"Navigation fixture queues Text in its engine")
		expect(run.research_feature(run.get_feature_research_quote(&"text",engine_id)) and run.owns_feature(&"text",engine_id),"Navigation fixture completes Text implementation")
		studio._open_management()
		await _settle_studio(studio)
		studio._open_engines(created.engine_id)
		await _settle_studio(studio)
		studio._engine_browser._configure()
		await _settle_studio(studio)
		store = studio.get("_feature_store")
		expect(store!=null and store._engine_id==created.engine_id and store.is_visible_in_tree(),"Feature tree opens from the chosen engine detail")
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		await process_frame
		await process_frame
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		await _verify_interactions(dimensions.x, game.get_node("%GameplayHUD"))
		game.queue_free()
		await process_frame
	print("Feature Store navigation verification: %d failures" % failures)
	quit(failures)

func _settle_studio(studio: StudioPhase) -> void:
	var deadline:=Time.get_ticks_msec()+5000
	while studio._hub_motion.busy and Time.get_ticks_msec()<deadline:await process_frame
	for frame in 3:await process_frame

func _snapshot() -> Dictionary:
	var credits := {}
	for id in run.get_owned_feature_ids(): credits[id] = run.get_feature_familiarity(id)
	return {"cash": run.get_cash_cents(), "cycles": run.get_completed_run_cycles(),
		"redraws": run.get_available_redraws(), "owned": run.get_owned_feature_ids(), "credits": credits,
		"finance": run.get_studio_finance_snapshot()}

func _mouse(point: Vector2, pressed: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = button
	event.pressed = pressed
	event.button_mask = (MOUSE_BUTTON_MASK_MIDDLE if button == MOUSE_BUTTON_MIDDLE else MOUSE_BUTTON_MASK_LEFT) if pressed else 0
	root.push_input(event, true)

func _motion(point: Vector2, delta: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = delta
	event.button_mask = MOUSE_BUTTON_MASK_MIDDLE if button == MOUSE_BUTTON_MIDDLE else MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)

func _key(code: Key, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = echo
	root.push_input(event, true)
	event = InputEventKey.new()
	event.keycode = code
	root.push_input(event, true)

func _offset() -> Vector2i:
	return Vector2i(store._scroll.scroll_horizontal, store._scroll.scroll_vertical)

func _settle_focus() -> void:
	var deadline := Time.get_ticks_msec()+3000
	var map := store._map
	while map.focusing or (map._menu_tween!=null and map._menu_tween.is_running()):
		if Time.get_ticks_msec()>deadline:
			expect(false,"Focus/entry animation finishes within bounded wait")
			return
		await process_frame
	for frame in 2: await process_frame

func _reset_view() -> void:
	store._map.set_zoom(1.0)
	await process_frame
	await process_frame
	store._map._reveal_node(&"text")
	await process_frame
	store._scroll.grab_focus()

func _verify_interactions(width: int, hud: GameplayHUD) -> void:
	var before := _snapshot()
	await _reset_view()
	var map := store._map
	var text: Button = store._nodes[&"text"]
	var at := text.get_global_rect().get_center()
	print("INITIAL_MAP_INPUT ",width," point=",at," map=",map._map_rect()," at=",map._node_at(at)," focus=",root.gui_get_focus_owner()," body=",store._body.get_global_rect()," zoom=",map.zoom)
	_mouse(at, true)
	print("INITIAL_MAP_PRESS ",map._drag_button," pressed-node=",map._pressed_node)
	_motion(at + Vector2(2, 1), Vector2(2, 1))
	_mouse(at + Vector2(2, 1), false)
	expect(store._selected == &"text" and map.popup.visible and not map.dragging, "Small mouse jitter remains a node click (%d)" % width)
	expect(store._details.text.contains("Graphics") and store._owned_summary.text.contains("Graphics") and store._owned_summary.text.contains("Sound") and store._owned_summary.text.contains("Tech") and store._owned_summary.text.contains("Design"), "Details and totals spell out Core categories")
	_key(KEY_LEFT)
	await process_frame
	expect(store._selected == &"colored_text" and root.gui_get_focus_owner() == store._nodes[&"colored_text"], "Left selects the directly adjacent Colored Text cell")
	expect(store._details.text.begins_with("Colored Text\n") and map.popup.visible, "Arrow selection opens correct details")
	_key(KEY_RIGHT)
	expect(store._selected == &"text", "Right returns to inward Visuals parent")
	_key(KEY_UP)
	expect(store._selected == &"4_color_palette", "Up follows the inner root axis to 4-Color Palette")
	_key(KEY_DOWN)
	expect(store._selected == &"text", "Down returns to Text on the inner root axis")
	var top: StringName = &"text"
	for id: StringName in store._nodes:
		if store._nodes[id].position.y < store._nodes[top].position.y: top = id
	map._focus_node(top)
	_key(KEY_UP)
	expect(store._selected == top, "No node above preserves current selection")
	map._focus_node(&"colored_text")
	_key(KEY_ESCAPE)
	expect(not map.popup.visible, "Escape dismisses keyboard-opened details")
	_key(KEY_RIGHT)
	expect(store._selected == &"text", "Arrow browsing resumes from focused node after dismissal")
	for zoom: float in [0.75,1.00010396295693,1.5]:
		map.set_zoom(zoom)
		map._focus_node(&"colored_text")
		_key(KEY_ESCAPE)
		_key(KEY_RIGHT)
		expect(store._selected == &"text", "Equal-distance inward tie prefers parent at zoom " + str(zoom))
	# Actual GUI button routing, not direct calls to _input: drags must not click.
	await _reset_view()
	at = text.get_global_rect().get_center()
	var pan_start := _offset()
	_mouse(at, true)
	_motion(at - Vector2(90, 50), -Vector2(90, 50))
	expect(map.dragging and _offset() == pan_start + Vector2i(90, 50), "Left-drag begun on artwork pans both axes")
	_mouse(at - Vector2(90, 50), false)
	expect(not map.dragging and store._selected.is_empty() and not map.popup.visible, "Drag release does not activate a node")
	var blank := map._map_rect().position + Vector2(8, 8)
	_mouse(blank, true)
	_motion(blank - Vector2(40, 30), -Vector2(40, 30))
	_mouse(blank - Vector2(40, 30), false)
	expect(_offset() == pan_start + Vector2i(130, 80) and not map.dragging, "Blank-map drag continues outside viewport and releases cleanly")
	blank = map._map_rect().get_center()
	_mouse(blank, true, MOUSE_BUTTON_MIDDLE)
	_motion(blank - Vector2(30, 20), -Vector2(30, 20), MOUSE_BUTTON_MIDDLE)
	_mouse(blank - Vector2(30, 20), false, MOUSE_BUTTON_MIDDLE)
	expect(_offset() == pan_start + Vector2i(160, 100), "Existing middle-button pan remains available")
	_mouse(blank, true)
	var to_origin := Vector2(_offset()) + map.canvas.size
	_motion(blank + to_origin, to_origin)
	_mouse(blank + to_origin, false)
	expect(_offset() == Vector2i.ZERO, "Panning clamps at map origin")
	# Focus must reveal off-screen nodes at both low and high zoom.
	for scale_value in [0.5, 1.5]:
		map.set_zoom(scale_value)
		await process_frame
		await process_frame
		map._focus_node(&"text")
		for step in range(8): _key(KEY_RIGHT, step > 0)
		await _settle_focus()
		var focused: Button = store._nodes[store._selected]
		expect(map._map_rect().encloses(focused.get_global_rect()), "Keyboard keeps focused node visible at zoom %.1f" % scale_value)
		if not store.get_global_rect().encloses(map.popup.get_global_rect()): print("DETAIL_BOUNDS ",width," zoom=",scale_value," selected=",store._selected," store=",store.get_global_rect()," popup=",map.popup.get_global_rect()," map=",map._map_rect()," node=",focused.get_global_rect())
		expect(store.get_global_rect().encloses(map.popup.get_global_rect()), "Details stay within Store at zoom %.1f" % scale_value)
		_key(KEY_LEFT)
		expect(store._selected != &"", "Held/repeated arrows keep browsing")
	await _reset_view()
	# Clicking details is not a pan; pressing its disabled button cannot purchase.
	map._focus_node(&"text")
	await _settle_focus()
	var menu_point := map.popup.get_global_rect().position + Vector2(12, 12)
	_mouse(menu_point, true)
	_motion(menu_point + Vector2(20, 15), Vector2(20, 15))
	_mouse(menu_point + Vector2(20, 15), false)
	expect(not map.dragging and map.popup.visible and store._selected == &"text", "Dragging inside details leaves map and selection intact")
	var buy_point := store._buy.get_global_rect().get_center()
	_mouse(buy_point, true)
	_mouse(buy_point, false)
	expect(_snapshot() == before, "Passive navigation and owned purchase button preserve cash, cycles, redraws, ownership, familiarity and finance history")
	# Native Tab focus signal also opens and reveals a Tech card.
	store._nodes[&"keyboard_and_mouse"].grab_focus()
	await _settle_focus()
	expect(store._selected == &"keyboard_and_mouse" and store._details.text.contains("Tech") and not store._details.text.contains("Technology"), "Focused Tech node opens full-name score detail")
	expect(store._nodes[&"keyboard_and_mouse"].tooltip_text.contains("Tech"), "Tech abbreviation also appears in tooltip")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/feature-bloom-map-v1/navigation-%d.png" % width)
	_mouse(store.global_position + Vector2(2, 2), true)
	_mouse(store.global_position + Vector2(2, 2), false)
	expect(not map.popup.visible, "Click outside details dismisses")
	await _reset_view()
	blank = map._map_rect().get_center()
	_mouse(blank, true)
	_motion(blank - Vector2(30, 20), -Vector2(30, 20))
	store.hide()
	expect(not map.dragging, "Closing Store cancels in-progress drag")
	await _settle_studio(studio)
	studio._engine_browser._configure()
	await _settle_studio(studio)
	await process_frame
	var reopened := _offset()
	_motion(blank - Vector2(90, 60), -Vector2(60, 40))
	_mouse(blank - Vector2(90, 60), false)
	expect(_offset() == reopened and not map.popup.visible, "Reopening does not resume stale mouse gesture")
	_mouse(blank, true)
	map.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_motion(blank - Vector2(40, 30), -Vector2(40, 30))
	_mouse(blank - Vector2(40, 30), false)
	expect(_offset() == reopened and not map.dragging, "Losing window focus cancels pending pan")
	await _reset_view()
	map._focus_node(&"text")
	await _settle_focus()
	var selected_before := store._selected
	var offset_before := _offset()
	hud.show_tutorial()
	await process_frame
	_key(KEY_RIGHT)
	_key(KEY_DOWN)
	var tutorial := hud.tutorial_overlay
	var body_point := tutorial.body_label.get_global_rect().get_center()
	_mouse(body_point, true)
	_motion(body_point - Vector2(30, 20), -Vector2(30, 20))
	_mouse(body_point - Vector2(30, 20), false)
	expect(store._selected == selected_before and _offset() == offset_before and not map.dragging, "Tutorial overlay owns arrows and pointer input above map")
	var next_point := tutorial.next_button.get_global_rect().get_center()
	_mouse(next_point, true)
	_mouse(next_point, false)
	expect(tutorial.page_index == 1, "Tutorial Next Tip remains clickable above map")
	_key(KEY_ESCAPE)
	expect(not tutorial.visible, "Escape closes Tutorial overlay")
	_key(KEY_UP)
	expect(store._selected == &"4_color_palette", "Map arrow navigation resumes after closing Tutorial")
	expect(_snapshot() == before, "All navigation remains zero-cost")
	await _verify_hovered_escape()
	expect(_snapshot() == before, "Tooltip, details and Pause navigation remain zero-cost")

func _verify_hovered_escape() -> void:
	# Input.parse_input_event includes GUI tooltip cancellation; push_input alone
	# missed the actual exported mouse-hover regression.
	store._select_lane(&"Story & World")
	await create_timer(0.7).timeout
	store._map._focus_node(&"character_backstories")
	await create_timer(0.7).timeout
	var hover := InputEventMouseMotion.new()
	hover.position = store._nodes[&"character_backstories"].get_global_rect().get_center()
	hover.global_position = hover.position
	Input.parse_input_event(hover)
	await create_timer(1.0).timeout
	for step in range(3):
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.physical_keycode = KEY_ESCAPE
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		event = event.duplicate()
		event.pressed = false
		Input.parse_input_event(event)
		await process_frame
		expect(paused == (step == 1), "Hovered Store details dismiss, next Escape pauses, third resumes: %d" % step)
		if step == 0: expect(not store._map.popup.visible, "First Escape dismisses hovered details")
