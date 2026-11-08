extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if value else "FAIL: ") + label)
	if not value: failures += 1
func _initialize() -> void: verify.call_deferred()
func verify() -> void:
	var view = load("res://scripts/ui/focused_guidance_overlay.gd").new()
	root.add_child(view)
	await process_frame
	for dimensions: Vector2i in [Vector2i(900,600),Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		view.queued_notice = true
		view.show_notice({"title":"Publisher unlocked", "body":"Neon Circuit Publishing"})
		view._notice_slide = 0.0
		view._fit()
		await process_frame
		var rect: Rect2 = view.panel.get_global_rect()
		check(rect.position.y >= 78 and rect.size.y < 360, "Publisher surface stays compact below the bar at %s" % dimensions)
		check(root.get_visible_rect().encloses(rect), "Entire publisher surface fits at %s" % dimensions)
		check(view.primary.is_visible_in_tree() and view.dismiss.is_visible_in_tree(), "Both actions remain visible at %s" % dimensions)
		if DisplayServer.get_name() != "headless" and not OS.get_environment("PN_NOTICE_CAPTURE").is_empty():
			await create_timer(0.35).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("PN_NOTICE_CAPTURE").path_join("publisher-%d.png" % dimensions.x))
		view.close(true)
	print("Studio notice surface: %d checks, %d failures" % [checks, failures])
	view.queue_free()
	await process_frame
	quit(failures)
