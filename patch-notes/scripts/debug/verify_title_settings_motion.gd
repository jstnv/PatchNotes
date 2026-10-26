extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func motion(menu: MainMenu, settings: DemoSettingsMenu, opening: bool) -> void:
	var rest := 20.0
	var positions := []
	if opening: settings.open(menu.navigation)
	else: settings.close()
	var deadline := Time.get_ticks_msec() + 4000
	while menu.navigation.busy and Time.get_ticks_msec()<deadline:
		await process_frame
		if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
		positions.append(settings.panel.position.x)
	print("SETTINGS_TRAJECTORY ","open" if opening else "back"," ",positions)
	expect(not menu.navigation.busy,"Settings navigation completes within bound")
	expect(positions.any(func(x):return x>rest+2.0 and x<rest+settings.panel.size.x-2.0),"Settings visibly slides through intermediate positions: "+str(opening))
	expect(not root.gui_disable_input,"Settings navigation releases input lock")
func _run() -> void:
	# A cold native renderer can spend more than0.24s compiling its first frame.
	# Optional slow-clock capture exposes the full trajectory without changing
	# the production tween duration or any settings/gameplay behavior.
	if "--slow-ui" in OS.get_cmdline_user_args(): Engine.time_scale=0.1
	var menu := MainMenu.new()
	root.add_child(menu)
	var settings := DemoSettingsMenu.new()
	root.add_child(settings)
	for i in range(6): await process_frame
	var button := menu.get_node("CenterContainer/MenuLayout/Settings") as Button
	button.grab_focus()
	await motion(menu,settings,true)
	expect(settings.is_open() and menu.navigation.depth()==2 and settings.mode.has_focus(),"Settings opens on title stack with control focus")
	await motion(menu,settings,false)
	expect(not settings.is_open() and menu.navigation.depth()==1 and button.has_focus(),"Back restores Main Menu and Settings focus")
	await motion(menu,settings,true)
	await motion(menu,settings,false)
	settings.queue_free();menu.queue_free()
	await process_frame
	Engine.time_scale=1.0
	print("TITLE_SETTINGS_MOTION checks=%d failures=%d"%[checks,failures])
	quit(failures)
