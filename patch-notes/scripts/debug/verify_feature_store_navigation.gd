extends SceneTree

var failures := 0
var store: FeatureStore
var run: RunState

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
		var menu: MainMenu = game.get("_active_phase")
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Navigation Test"
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
		menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
		run = game.run_state
		var studio: StudioPhase = game.get("_active_phase")
		studio.get_node("%FeatureStoreButton").pressed.emit()
		store = studio.get("_feature_store")
		await process_frame
		await process_frame
		await _verify_interactions(dimensions.x, game.get_node("%GameplayHUD"))
		game.queue_free()
		await process_frame
	print("Feature Store navigation verification: %d failures" % failures)
	quit(failures)

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
	_mouse(at, true)
	_motion(at + Vector2(2, 1), Vector2(2, 1))
	_mouse(at + Vector2(2, 1), false)
	expect(store._selected == &"text" and map.popup.visible and not map.dragging, "Small mouse jitter remains a node click (%d)" % width)
	expect(store._details.text.contains("Graphics") and store._owned_summary.text.contains("Graphics") and store._owned_summary.text.contains("Sound") and store._owned_summary.text.contains("Tech") and store._owned_summary.text.contains("Design"), "Details and totals spell out Core categories")
	_key(KEY_LEFT)
	await process_frame
	expect(store._selected == &"colored_text" and root.gui_get_focus_owner() == store._nodes[&"colored_text"], "Left selects and focuses outward Visuals child")
	expect(store._details.text.contains("2 Graphics · 1 Scope") and map.popup.visible, "Arrow selection opens correct details")
	_key(KEY_RIGHT)
	expect(store._selected == &"text", "Right returns to inward Visuals parent")
	_key(KEY_DOWN)
	expect(store._selected == &"sprites", "Down chooses next root on the adjacent track")
	_key(KEY_UP)
	expect(store._selected == &"text", "Up returns to previous root")
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
	_motion(blank + Vector2(2000, 2000), Vector2(2000, 2000))
	_mouse(blank + Vector2(2000, 2000), false)
	expect(_offset() == Vector2i.ZERO, "Panning clamps at map origin")
	# Focus must reveal off-screen nodes at both low and high zoom.
	for scale_value in [0.5, 1.5]:
		map.set_zoom(scale_value)
		await process_frame
		await process_frame
		map._focus_node(&"text")
		for step in range(8): _key(KEY_RIGHT, step > 0)
		await create_timer(0.56).timeout
		var focused: Button = store._nodes[store._selected]
		expect(map._map_rect().encloses(focused.get_global_rect()), "Keyboard keeps focused node visible at zoom %.1f" % scale_value)
		expect(store.get_global_rect().encloses(map.popup.get_global_rect()), "Details stay within Store at zoom %.1f" % scale_value)
		_key(KEY_LEFT)
		expect(store._selected != &"", "Held/repeated arrows keep browsing")
	await _reset_view()
	# Clicking details is not a pan; pressing its disabled button cannot purchase.
	map._focus_node(&"text")
	await create_timer(0.56).timeout
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
	await create_timer(0.56).timeout
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
	store.open_store()
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
	await create_timer(0.56).timeout
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
	_key(KEY_DOWN)
	expect(store._selected == &"sprites", "Map arrow navigation resumes after closing Tutorial")
	expect(_snapshot() == before, "All navigation remains zero-cost")
