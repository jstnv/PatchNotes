extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", description)
	if not ok: failures += 1

func settle(frames := 6) -> void:
	for i in frames: await process_frame

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for dimensions in [Vector2i(900, 600), Vector2i(1152, 648), Vector2i(1280, 720)]:
		root.min_size = Vector2i.ZERO
		root.size = dimensions
		root.content_scale_size = dimensions
		var host := Control.new()
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(host)
		var prior := Control.new()
		host.add_child(prior)
		var motion := MenuTransitions.new()
		motion.automatic_entrances = false
		host.add_child(motion)
		motion.set_root(prior)
		var view: PostGameReview = load("res://scenes/phases/post_game_review.tscn").instantiate()
		host.add_child(view)
		await settle()
		var review_data := {"final_review": 7.7, "production_rating": 8.3, "scope_completion": 1.0, "awareness": 10, "projected_units": 123, "standards": [30,30,30,30], "cores": [32,33,34,35], "scope": 30, "required_scope": 30, "development_cycles": 20, "remaining_bugs": 0, "launch_marketing": 5, "launch_fans": 0, "fan_awareness": 0, "projected_gross_cents": 12300, "projected_net_cents": 9000}
		var metadata := {"review":review_data, "release_title":"Review Test", "release_year":1980}
		var sales := {"earned_units":25,"entitlement_cents":1600,"settled_cents":1200}
		check(view.setup_release_snapshot(metadata,sales), "Real historical review data is accepted at %s" % dimensions)
		var layout: VBoxContainer = view.get_node("Margin/Layout")
		var title: Control = layout.get_node("Title")
		var header := HBoxContainer.new()
		layout.add_child(header)
		layout.move_child(header,0)
		title.reparent(header,false)
		var back: Button = view.get_node("%ContinueButton")
		back.reparent(header,false)
		FolderUI.standard_back(back)
		view.get_node("Margin").add_theme_constant_override("margin_top",28)
		view.get_node("Margin").add_theme_constant_override("margin_left",32)
		view.get_node("Margin").add_theme_constant_override("margin_right",32)
		await settle()
		var surface := view.get_node_or_null("ReviewSurface") as PanelContainer
		check(surface != null, "Review has an outer menu panel at %s" % dimensions)
		if surface == null:
			host.queue_free()
			await settle()
			continue
		check(surface.is_visible_in_tree() and surface.theme_type_variation == &"FolderPanel", "Outer panel uses the shared FolderPanel theme at %s" % dimensions)
		check(surface.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Outer panel does not intercept content input at %s" % dimensions)
		var panel_rect := surface.get_global_rect().grow(1)
		check(panel_rect.encloses(title.get_global_rect()) and panel_rect.encloses(back.get_global_rect()) and panel_rect.encloses(view.get_node("%Categories").get_global_rect()), "Panel encloses heading, Back, and tabs at %s" % dimensions)
		check(Rect2(Vector2.ZERO,Vector2(dimensions)).grow(1).encloses(surface.get_global_rect()), "Panel remains inside the viewport at %s" % dimensions)
		check(view.get_node("%Categories").get_tab_count() == 5 and view.get_node("%GraphicsLabel").text.contains("32 points"), "The five tabs retain release content at %s" % dimensions)
		var moves_together := true
		view.hide()
		var pushed := motion.push_from_bottom(view,back,Callable(),float(dimensions.y))
		var initial_surface := surface.global_position
		var initial_title := title.global_position
		await create_timer(0.08).timeout
		var during_surface := surface.global_position
		var during_title := title.global_position
		moves_together = absf((during_surface.y-initial_surface.y)-(during_title.y-initial_title.y)) < 2.0
		check(pushed and moves_together and not initial_surface.is_equal_approx(during_surface), "Panel and heading move together during entry at %s" % dimensions)
		await create_timer(MenuTransitions.ENTRANCE_SECONDS + 0.12).timeout
		var callback := {"fired":false}
		view.continue_to_studio_requested.connect(func(): callback.fired = true; motion.pop())
		back.pressed.emit()
		await create_timer(MenuTransitions.ENTRANCE_SECONDS + 0.12).timeout
		check(callback.fired and not view.visible, "Back emits review navigation and closes the panel at %s" % dimensions)
		if DisplayServer.get_name() != "headless":
			var output := OS.get_environment("PN_REVIEW_SURFACE_CAPTURE")
			if not output.is_empty():
				view.show()
				await settle()
				await RenderingServer.frame_post_draw
				check(root.get_texture().get_image().save_png(output.path_join("review-surface-%dx%d.png" % [dimensions.x,dimensions.y])) == OK, "Native capture saved at %s" % dimensions)
		host.queue_free()
		await settle()
	print("REVIEW_SURFACE checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
