extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func _initialize() -> void: verify.call_deferred()

func verify() -> void:
	var hud := GameplayHUD.new()
	root.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for frame in 4: await process_frame
	var notices: Control = hud.challenge_notices
	var entries := [
		{"title":"Production Specialist · Production Planning", "message":"Completed · Reward earned"},
		{"title":"Current Engine · Technology Regression Harness", "message":"Technology 12 / 12 Core · ready to implement"},
		{"title":"Project Manager · Project Management 1", "message":"2 / 2 specializations · release this game to count"},
		{"title":"QA Specialist · Search & Fix", "message":"3 / 4 qualifying hands"},
	]
	for dimensions in [Vector2i(1280,720), Vector2i(900,600)]:
		root.min_size = Vector2i.ZERO
		if DisplayServer.get_name() != "headless": DisplayServer.window_set_min_size(Vector2i.ZERO)
		root.size = dimensions
		root.content_scale_size = dimensions
		for frame in 5: await process_frame
		print("CHALLENGE_VIEWPORT requested=%s window=%s visible=%s texture=%s" % [dimensions,root.size,root.get_visible_rect(),root.get_texture().get_size()])
		notices.enqueue_all(entries)
		check(notices.active_count()==3 and notices._pending.size()==1, "Display three notices and queue overflow at %s" % dimensions)
		var first: Control = notices._visible[0]
		var surface: Control = first.get_child(0)
		check(first.clip_contents and surface.position.y <= -first.size.y + 1.0, "Notice begins hidden above its top entrance at %s" % dimensions)
		await create_timer(0.35).timeout
		var screen := Rect2(Vector2.ZERO,Vector2(dimensions))
		var header := hud.scoreboard.get_global_rect()
		var footer := hud.footer_panel.get_global_rect()
		for slot: Control in notices._visible:
			var card := slot.get_global_rect()
			check(card.size.x < 360 and card.size.y < 104 and screen.encloses(card), "Notice is smaller and inside the viewport at %s" % dimensions)
			check(card.position.y >= header.end.y and card.end.y < footer.position.y, "Notice stays below top HUD and above bottom HUD at %s" % dimensions)
			check(slot.mouse_filter == Control.MOUSE_FILTER_IGNORE and slot.get_child(0).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Notice does not intercept input at %s" % dimensions)
			var heading: Label = slot.get_child(0).get_child(0).get_child(0)
			var text: Label = slot.get_child(0).get_child(0).get_child(1)
			check(heading.get_visible_line_count() >= heading.get_line_count() and text.get_visible_line_count() >= text.get_line_count(), "Notice title and message do not clip at %s" % dimensions)
		check(first.get_global_rect().position.y < float(dimensions.y)*0.35, "Notice appears at the top of the screen at %s" % dimensions)
		var resting_x := first.position.x
		hud.contextual_tip.show_tip("Plan your game", "This persistent tip should not cover challenge progress.")
		for frame in 3: await process_frame
		var tip_rect := hud.contextual_tip.panel.get_global_rect()
		check(first.visible, "A persistent tip does not suppress the first progress notice at %s" % dimensions)
		for slot: Control in notices._visible:
			if slot.visible: check(not slot.get_global_rect().intersects(tip_rect), "Visible progress notice clears the actual persistent tip at %s" % dimensions)
		check(first.position.x != resting_x or first.position.y >= tip_rect.end.y, "Notices move when a persistent tip appears at %s" % dimensions)
		hud.contextual_tip.dismiss()
		for frame in 3: await process_frame
		check(absf(first.position.x-resting_x)<0.1, "Notices return to their normal column when the tip closes at %s" % dimensions)
		hud.synergy_notification.show_message("Specialization!", "Bonus applied")
		await create_timer(0.3).timeout
		var synergy_rect := hud.synergy_notification.banner.get_global_rect()
		for slot: Control in notices._visible:
			if slot.visible: check(not slot.get_global_rect().intersects(synergy_rect), "Progress notice clears the real synergy banner at %s" % dimensions)
		hud.synergy_notification.banner.hide()
		for frame in 3: await process_frame
		var guide := preload("res://scripts/ui/focused_guidance_overlay.gd").new()
		root.add_child(guide)
		guide.show_notice({"title":"Contracts unlocked!", "body":"Would you like a quick tour of the available work?"})
		await create_timer(0.35).timeout
		for slot: Control in notices._visible:
			if slot.visible:
				check(not slot.get_global_rect().intersects(guide.panel.get_global_rect()) and slot.get_global_rect().end.y < hud.footer_panel.get_global_rect().position.y, "Challenge notice clears unlock guidance and bottom HUD at %s" % dimensions)
		hud.contextual_tip.show_tip("Plan your game", "The active tip and guidance must both stay readable.")
		hud.synergy_notification.show_message("Specialization!", "Bonus applied")
		for frame in 3: await process_frame
		tip_rect = hud.contextual_tip.panel.get_global_rect()
		synergy_rect = hud.synergy_notification.banner.get_global_rect()
		check(not tip_rect.intersects(guide.panel.get_global_rect()), "Persistent tip remains readable beside focused guidance at %s" % dimensions)
		check(not tip_rect.intersects(guide.primary.get_global_rect()) and not tip_rect.intersects(guide.dismiss.get_global_rect()) and not guide.panel.get_global_rect().intersects(hud.contextual_tip.dismiss_button.get_global_rect()), "Guidance and tip controls stay accessible at %s" % dimensions)
		check(hud.contextual_tip.title_label.get_visible_line_count()>=hud.contextual_tip.title_label.get_line_count() and hud.contextual_tip.body_label.get_visible_line_count()>=hud.contextual_tip.body_label.get_line_count(), "Persistent tip text is fully visible alongside guidance at %s" % dimensions)
		check(first.visible, "Simultaneous overlays leave a progress notice visible at %s" % dimensions)
		for slot: Control in notices._visible:
			if slot.visible: check(not slot.get_global_rect().intersects(tip_rect) and not slot.get_global_rect().intersects(synergy_rect) and not slot.get_global_rect().intersects(guide.panel.get_global_rect()) and slot.get_global_rect().end.y < hud.footer_panel.get_global_rect().position.y, "Progress notices clear tip, synergy, guidance and bottom HUD together at %s" % dimensions)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var overlay_folder := OS.get_environment("PN_CHALLENGE_TOP_CAPTURE")
			if not overlay_folder.is_empty():
				DirAccess.make_dir_recursive_absolute(overlay_folder)
				check(root.get_texture().get_image().save_png(overlay_folder.path_join("challenge-all-overlays-%dx%d.png" % [dimensions.x,dimensions.y])) == OK, "Capture actual simultaneous overlays at %s" % dimensions)
		guide.close(true)
		for frame in 3: await process_frame
		check(hud.contextual_tip.panel.visible and absf(hud.contextual_tip.panel.get_global_rect().position.y-154.0)<0.1, "Tip remains open and returns to its normal dock after guidance closes at %s" % dimensions)
		hud.contextual_tip.dismiss_button.pressed.emit()
		check(not hud.contextual_tip.panel.visible, "Tip dismiss button remains functional after guidance closes at %s" % dimensions)
		hud.synergy_notification.banner.hide()
		for frame in 3: await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var folder := OS.get_environment("PN_CHALLENGE_TOP_CAPTURE")
			if not folder.is_empty():
				DirAccess.make_dir_recursive_absolute(folder)
				check(root.get_texture().get_image().save_png(folder.path_join("challenge-top-%dx%d.png" % [dimensions.x,dimensions.y])) == OK, "Capture native layout at %s" % dimensions)
		guide.queue_free()
		notices._pending.clear()
		for slot: Control in notices._visible.duplicate(): notices._remove_card(slot)
		for frame in 3: await process_frame
		notices.enqueue_all([{"title":"Very Long Independent Studio Engine · Technology Regression Harness", "message":"Technology 12 / 12 Core · ready to implement"}])
		var long_slot: Control = notices._visible[0]
		var long_card: Control = long_slot.get_child(0)
		var fully_hidden := long_card.position.y <= -long_slot.size.y
		for frame in 3:
			await process_frame
			if long_card.modulate.a <= 0.001 and long_card.position.y > -long_card.size.y + 0.1: fully_hidden = false
		check(fully_hidden, "Long wrapped notice remains hidden above its actual size before entrance at %s" % dimensions)
		await create_timer(0.3).timeout
		var long_heading: Label = long_card.get_child(0).get_child(0)
		var long_message: Label = long_card.get_child(0).get_child(1)
		check(long_heading.get_line_count()>1 and long_heading.get_visible_line_count()>=long_heading.get_line_count() and long_message.get_visible_line_count()>=long_message.get_line_count(), "Long wrapped notice remains readable without clipping at %s" % dimensions)
		check(screen.encloses(long_slot.get_global_rect()) and long_heading.get_global_rect().end.y<=long_message.get_global_rect().position.y, "Long notice stays in bounds with separate title and message at %s" % dimensions)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var folder := OS.get_environment("PN_CHALLENGE_TOP_CAPTURE")
			if not folder.is_empty():check(root.get_texture().get_image().save_png(folder.path_join("challenge-top-long-%dx%d.png" % [dimensions.x,dimensions.y])) == OK, "Capture long native notice at %s" % dimensions)
		notices._remove_card(long_slot)
		for frame in 3: await process_frame
		if dimensions == Vector2i(900,600):
			var very_long := {"title":"An unusually lengthy independent Studio engine with an extra long descriptive name · Technology Regression Harness", "message":"2 / 2 specializations · release this game to count"}
			notices.enqueue_all([very_long,very_long,very_long])
			var small_guide := preload("res://scripts/ui/focused_guidance_overlay.gd").new()
			root.add_child(small_guide)
			small_guide.show_notice({"title":"Contracts unlocked!", "body":"Would you like a quick tour of the available work?"})
			hud.contextual_tip.dock_below_menu_controls(true)
			hud.contextual_tip.show_tip("Studio tip", "The tip remains visible while notices wait.")
			await create_timer(0.35).timeout
			var hidden: Array[Control] = []
			for slot: Control in notices._visible:
				if not slot.visible:hidden.append(slot)
				else:check(not slot.get_global_rect().intersects(small_guide.panel.get_global_rect()) and not slot.get_global_rect().intersects(hud.contextual_tip.panel.get_global_rect()) and slot.get_global_rect().end.y < hud.footer_panel.get_global_rect().position.y, "Long notice avoids guidance, persistent tip and bottom HUD")
			check(not hidden.is_empty(), "Notices exceeding available space wait instead of covering the HUD")
			if not hidden.is_empty():
				var suspended: Tween = notices._animations.get(hidden[0])
				var elapsed := suspended.get_total_elapsed_time()
				await create_timer(0.3).timeout
				check(absf(suspended.get_total_elapsed_time()-elapsed)<0.01, "Hidden overflow retains its display time while waiting")
			small_guide.close(true)
			await create_timer(0.15).timeout
			check(notices._visible.all(func(slot):return slot.visible), "Waiting notices resume when the guidance clears")
			check(notices._visible.all(func(slot):return not slot.get_global_rect().intersects(hud.contextual_tip.panel.get_global_rect())), "Resumed notices clear the still-visible persistent tip")
			hud.contextual_tip.dismiss()
			hud.contextual_tip.dock_below_menu_controls(false)
			small_guide.queue_free()
			await create_timer(4.4).timeout
			check(notices._visible.is_empty() and notices._pending.is_empty() and notices._animations.is_empty(), "Resumed notices expire normally without losing overflow or retaining tweens")
			for frame in 3: await process_frame
	hud.queue_free()
	for frame in 3: await process_frame
	print("CHALLENGE_NOTICES_TOP checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
