extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	run_checks.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	print("PASS: " if condition else "FAIL: ", description)
	if not condition: failures += 1

func settle() -> void:
	for i in range(8): await process_frame

func close_enough(a: float, b: float) -> bool:
	return absf(a - b) <= 2.0

func verify_geometry(store: FeatureStore, dimensions: Vector2i, label: String) -> void:
	var back := store._close.get_global_rect()
	var title := store._cash.get_global_rect()
	var summary := store._owned_summary.get_global_rect()
	var queue := store._research_list.get_global_rect()
	var action := store._research_button.get_global_rect()
	var viewport := Rect2(Vector2.ZERO, Vector2(dimensions))
	var context := "%s at %s" % [label, dimensions]
	check(store._close.is_visible_in_tree() and store._research_list.is_visible_in_tree() and store._research_button.is_visible_in_tree(), "Back, queue and action are visible " + context)
	check(close_enough(queue.end.y, back.end.y) and close_enough(action.end.y, back.end.y), "Queue and action align with Back bottom " + context)
	check(close_enough(summary.position.y, back.position.y) and close_enough(summary.end.y, back.end.y), "Library summary matches Back height " + context)
	check(not back.intersects(queue) and not back.intersects(action) and not queue.intersects(action), "Back, queue and action do not overlap " + context)
	check(not title.intersects(queue) and not title.intersects(action) and not summary.intersects(queue) and not summary.intersects(action), "Title and summary clear the controls " + context)
	check(viewport.encloses(back) and viewport.encloses(title) and viewport.encloses(summary) and viewport.encloses(queue) and viewport.encloses(action), "Header controls stay inside the viewport " + context)
	check(store._over_floating_control(queue.get_center()) and store._over_floating_control(action.get_center()), "Queue and action block map input " + context)
	check(store._owned_summary.get_line_count() == 2 and store._owned_summary.get_visible_line_count() == 2 and store._owned_summary.get_theme_font_size("font_size") >= 12, "Both library lines remain visible and readable " + context)
	check(action.size.x >= store._research_button.get_combined_minimum_size().x, "Implement label is not clipped " + context)

func run_checks() -> void:
	for dimensions in [Vector2i(900, 600), Vector2i(1152, 648), Vector2i(1280, 720)]:
		root.min_size = Vector2i.ZERO
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		var catalog = root.get_node("CardDatabase").get_development_catalog()
		var session = preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1, "studio_id":"header", "studio_name":"Header Test", "specialty":"action", "traits":[], "seed":"7301"}, catalog)
		var run: RunState = session.run
		var created := run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Header Engine"))
		if not created.get("ok", false):
			check(false, "A real proprietary engine can be created")
			quit(1)
			return
		var engine: StringName = created.engine_id
		check(run.select_engine(engine) and run.finalize_starter_selection(), "Studio setup finalized")
		var store := FeatureStore.new()
		store.theme = load("res://resources/ui/onyx_theme.tres")
		root.add_child(store)
		store.setup(run)
		store.open_store(engine)
		await settle()
		verify_geometry(store, dimensions, "empty queue")
		var quote := run.get_feature_research_quote(&"text", engine)
		check(quote.get("can_admit", false) and run.admit_feature_research(quote), "Real implementation is queued")
		await settle()
		check(not store._research_button.disabled and not store._research_list.disabled, "Queued implementation remains actionable")
		verify_geometry(store, dimensions, "queued action")
		store._research_button.text = "Implement $1,234,567.89 - 1 cycle"
		store._layout_store_chrome()
		await settle()
		verify_geometry(store, dimensions, "long action label")
		if DisplayServer.get_name() != "headless":
			var capture := OS.get_environment("PN_STORE_HEADER_CAPTURE")
			if not capture.is_empty():
				await RenderingServer.frame_post_draw
				check(root.get_texture().get_image().save_png(capture.path_join("store-header-%dx%d.png" % [dimensions.x, dimensions.y])) == OK, "Saved native capture")
		var click_point := store._research_button.get_global_rect().get_center()
		for down in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = down
			click.position = click_point
			click.global_position = click_point
			root.push_input(click, true)
		await settle()
		check(run.owns_feature(&"text", engine) and run.get_feature_research_queue().is_empty(), "Implement button completes the queued Feature")
		store.queue_free()
		await settle()
	print("STORE_COMPACT_HEADER checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
