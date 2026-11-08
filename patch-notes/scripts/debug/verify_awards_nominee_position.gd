extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
func _initialize() -> void: verify.call_deferred()
func verify() -> void:
	var nominees: Array = []
	for i in 3:
		nominees.append({"studio_id": "owner%d" % i, "studio_name": "Studio %d" % i, "release_id": "release%d" % i, "title": "Game %d" % i, "score": 70-i*5, "rank": i+1})
	var result := {"year": 1980, "awards": [{"id":"technology", "name":"Technology", "metric_kind":"core", "nominees":nominees}]}
	var ui = load("res://scripts/ui/annual_awards_ceremony.gd").new()
	ui.animate_counters = false
	ui.configure(result, 2, true, false)
	root.add_child(ui)
	for dimensions: Vector2i in [Vector2i(900,600), Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for frame in 8: await process_frame
		var panel_bottom: float = ui.podium.get_global_rect().end.y
		var footer_top: float = ui.next_button.get_global_rect().position.y
		var gap := footer_top - panel_bottom
		check(gap >= 0.0 and gap <= 32.0, "Nominee cards end just above Next at %s (gap %.1f)" % [dimensions, gap])
		check(ui.scroll.get_global_rect().encloses(ui.podium.get_global_rect()), "Full podium remains visible at %s" % dimensions)
		if DisplayServer.get_name() != "headless" and not OS.get_environment("PN_AWARDS_CAPTURE").is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("PN_AWARDS_CAPTURE").path_join("nominees-%d.png" % dimensions.x))
	# A visible tie explanation stays between the nominees and the fixed actions.
	nominees[1].score = nominees[0].score
	ui.configure(result, 2, true, false)
	for frame in 8: await process_frame
	check(ui.tie_note.visible and ui.tie_note.get_global_rect().position.y >= ui.podium.get_global_rect().end.y, "Tie explanation remains visible beneath the nominees")
	check(ui.tie_note.get_global_rect().end.y <= ui.next_button.get_global_rect().position.y, "Tie explanation stays clear of Next")
	ui.set_stage(0)
	for frame in 8: await process_frame
	check(ui.podium == null and ui._body.size_flags_vertical == Control.SIZE_FILL, "Intro page retains its original top-aligned layout")
	ui.queue_free()
	await process_frame
	print("Awards nominee position: %d checks, %d failures" % [checks, failures])
	quit(failures)
