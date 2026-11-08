extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen := Control.new()
	screen.size = Vector2(1280, 720)
	root.add_child(screen)
	var hud := GameplayHUD.new()
	hud.size = screen.size
	screen.add_child(hud)
	var hub := preload("res://scripts/ui/studio_hub.gd").new()
	hub.position = Vector2(30, 100)
	hub.size = Vector2(1200, 500)
	screen.add_child(hub)
	await process_frame
	for name in [&"prepare_studio_bars", &"animate_studio_bars_in", &"animate_studio_bars_out"]:
		if not hud.has_method(name):
			_fail("HUD is missing " + String(name)); return
	for name in [&"prepare_studio_arrival", &"animate_studio_arrival"]:
		if not hub.has_method(name):
			_fail("Studio hub is missing " + String(name)); return
	var header_offsets := Vector2(hud.scoreboard.offset_top, hud.scoreboard.offset_bottom)
	var footer_offsets := Vector2(hud.footer_panel.offset_top, hud.footer_panel.offset_bottom)
	hud.call("prepare_studio_bars")
	hub._root_panel.hide()
	hub.call("prepare_studio_arrival")
	if hud.scoreboard.get_global_rect().end.y > 0.01 or hud.footer_panel.get_global_rect().position.y < 719.99:
		_fail("Studio bars must begin beyond the viewport"); return
	if not hub._root_panel.visible or hub._root_panel.get_global_rect().end.x > 0.01:
		_fail("Studio panel must begin beyond the viewport"); return
	await hud.call("animate_studio_bars_in")
	if Vector2(hud.scoreboard.offset_top, hud.scoreboard.offset_bottom) != header_offsets or Vector2(hud.footer_panel.offset_top, hud.footer_panel.offset_bottom) != footer_offsets:
		_fail("Studio bars did not return to their original anchors"); return
	await hub.call("animate_studio_arrival")
	if not is_equal_approx(hub._root_panel.position.x, hub.IDLE_OFFSET):
		_fail("Studio panel did not return to its idle position"); return
	# A tutorial may cover a selected Studio group; hide its companion during
	# entry and restore the same selection once the root panel reaches its place.
	hub.motion = MenuTransitions.new()
	hub.add_child(hub.motion)
	hub.motion.animate = false
	var choices: VBoxContainer = hub.add_group(&"management", "Studio Management")
	hub.select_group(&"management")
	if not hub._companion.visible or not choices.visible:
		_fail("Selected Studio companion was not visible before entry"); return
	hub.call("prepare_studio_arrival")
	if hub._companion.visible:
		_fail("Selected Studio companion appeared ahead of the root panel"); return
	await hub.call("animate_studio_arrival")
	if not hub._companion.visible or not choices.visible or hub.selected != &"management" or hub.requested != &"management" or not is_zero_approx(hub._root_panel.position.x):
		_fail("Selected Studio companion or its selection was not restored"); return
	await hud.call("animate_studio_bars_out")
	if hud.scoreboard.get_global_rect().end.y > 0.01 or hud.footer_panel.get_global_rect().position.y < 719.99:
		_fail("Studio bars did not exit the viewport"); return
	# An aborted scene switch must restore the same bars without another prepare.
	await hud.call("animate_studio_bars_in")
	if Vector2(hud.scoreboard.offset_top, hud.scoreboard.offset_bottom) != header_offsets or Vector2(hud.footer_panel.offset_top, hud.footer_panel.offset_bottom) != footer_offsets:
		_fail("Studio bars did not restore after an aborted exit"); return
	hud.hide()
	hud.call("prepare_studio_bars")
	hud.show()
	await hud.call("animate_studio_bars_in")
	if Vector2(hud.footer_panel.offset_top, hud.footer_panel.offset_bottom) != footer_offsets:
		_fail("Studio bars did not restore after a hidden tutorial"); return
	print("PASS: Studio bars and panel entrance/exit geometry")
	screen.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	printerr("FAIL: " + message)
	quit(1)
