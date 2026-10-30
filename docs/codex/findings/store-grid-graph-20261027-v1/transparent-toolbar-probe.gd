extends SceneTree
var checks := 0
var failures := 0
var output := ""
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
func settle() -> void:
	for i in range(4): await process_frame
func click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	for resolution in [Vector2i(900,600), Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = resolution; root.content_scale_size = resolution
		var run := RunState.new()
		run.initialize_cash_cents(0)
		assert(run.create_studio_with_traits("Transparent Store", &"adventure", []))
		run.finalize_starter_selection()
		assert(run.spend_cash_cents(run.get_cash_cents() - 1))
		var before := StudioCheckpoint.new().capture(run)
		var store := FeatureStore.new()
		store.theme = load("res://resources/ui/workspace_theme.tres")
		store.setup(run); root.add_child(store); store.open_store()
		await settle()
		var rect := store._scroll.get_global_rect()
		expect(rect.encloses(store._research_button.get_global_rect()), "Map continues behind research controls " + str(resolution))
		expect(rect.encloses(store._spending_advice.get_global_rect()), "Map continues behind budget advice")
		var controls: Array[BaseButton] = [store._research_list,store._research_button,store._close,store._debug]
		for button in store.find_children("*","Button",true,false):
			if button.text in ["−", "+", "Show all"]: controls.append(button)
		for button in controls:
			for state in ["normal", "disabled"]:
				var style := button.get_theme_stylebox(state) as StyleBoxFlat
				expect(style != null and style.bg_color.a == 0, "Transparent " + state + " fill: " + button.text)
			var hover := button.get_theme_stylebox("hover") as StyleBoxFlat
			expect(hover != null and hover.border_color.a > 0,"Hover cue retained: " + button.text)
		var old_zoom := store._map.zoom
		var plus := controls.filter(func(button): return button.text == "+")[0] as Button
		click(plus.get_global_rect().get_center()); await settle()
		expect(store._map.zoom > old_zoom and not store._map.dragging,"Pointer reaches zoom through overlay without map gesture")
		click(store._debug.get_global_rect().get_center()); await settle()
		expect(store._debug_popup.visible, "Pointer reaches Debug above map")
		store._debug_popup.hide()
		store._map.navigate(&"Audio"); await settle()
		expect(store._nodes[&"sound_effects"].get_node("MapStatus").text == "Owned", "Root Sound Effects is owned")
		expect(not run.owns_feature(&"8_bit_sound") and run.get_primitive_reserve_offer(&"8_bit_sound").unlocked, "8-Bit Sound remains an optional unlocked child")
		if DisplayServer.get_name() != "headless" and not output.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("store-overlay-%d.png" % resolution.x))
		expect(StudioCheckpoint.new().capture(run) == before, "Overlay browsing preserves complete state and RNG")
		click(store._close.get_global_rect().get_center()); await settle()
		expect(not store.visible, "Pointer reaches Close Store above map")
		store.queue_free(); await settle()
	print("TRANSPARENT_TOOLBAR checks=%d failures=%d" % [checks, failures])
	quit(failures)
