extends SceneTree
## Actual HUD and real guide catalog; isolated profile, no player save writes.
var checks:=0
var failures:=0

func check(ok:bool, message:String)->void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",message)
	if not ok:failures+=1

func frames(count:int=5)->void:
	for i in count:await process_frame

func clear_of_hud(panel:Control,hud:GameplayHUD)->bool:
	var bounds:=panel.get_global_rect()
	return bounds.position.y>=hud.scoreboard.get_global_rect().end.y+7.5 and bounds.end.y<=hud.footer_panel.get_global_rect().position.y-7.5

func _initialize()->void:
	_run.call_deferred()

func _run()->void:
	FolderUI.enable_menu_gamepad()
	root.size=Vector2i(1152,648);root.content_scale_size=root.size
	var host:=Control.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hud:=GameplayHUD.new();host.add_child(hud);hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await frames()
	# Settings initialization applies its saved window size; set the intended
	# test viewport afterward so the capture is truly the requested resolution.
	root.size=Vector2i(1152,648);root.content_scale_size=Vector2i(1152,648)
	await frames(10)
	check(root.size==Vector2i(1152,648),"Real viewport is the intended 1152 x 648")
	var guide:=hud.how_to_play
	var settings:=hud.settings_menu
	guide.open()
	await frames()
	check(guide.sections.size()==9,"Real guide catalog is loaded")
	check(clear_of_hud(guide.panel,hud),"Guide clears the visible real gameplay HUD")
	guide.select_folder(0)
	var tours_index:=-1
	for i in guide.sections[0].topics.size():
		if guide.sections[0].topics[i].id=="guided_tours":tours_index=i
	if tours_index>=0:guide.select_topic(tours_index)
	await frames()
	check(tours_index>=0 and guide.tour_list.get_child_count()>0,"Real guided-tour entries build without a stub")
	var capture_dir:=OS.get_environment("PN_PANEL_SAFE_CAPTURE")
	if not capture_dir.is_empty() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(capture_dir.path_join("guide-1152.png"))==OK,"Real guide capture saved")
	var action:=InputEventAction.new();action.action=&"ui_cancel";action.pressed=true;root.push_input(action,true)
	await frames()
	check(not guide.is_open(),"Guide Back action closes and releases input")
	guide.open()
	await frames()
	var controller:=InputEventJoypadButton.new();controller.device=0;controller.button_index=JOY_BUTTON_B;controller.pressed=true;root.push_input(controller,true)
	await frames()
	check(not guide.is_open(),"Controller Back closes the real guide")
	settings.open()
	await frames()
	check(clear_of_hud(settings.panel,hud),"Settings clears the visible real gameplay HUD")
	var settings_scroll:=settings.panel.find_child("SettingsScroll",true,false) as ScrollContainer
	var mode_bounds:=settings.mode.get_global_rect().grow(4.0)
	check(settings_scroll.get_global_rect().encloses(mode_bounds),"Initial Settings focus outline remains inside the scroll viewport")
	if not capture_dir.is_empty() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(capture_dir.path_join("settings-1152.png"))==OK,"Real Settings capture saved")
	for button:Control in settings._focusable():
		if button==settings.back_button:continue
		button.grab_focus()
		await frames()
		var scroll:=settings.panel.find_child("SettingsScroll",true,false) as ScrollContainer
		check(root.gui_get_focus_owner()==button and scroll.get_global_rect().encloses(button.get_global_rect().grow(4.0)),button.name+" focus and outline scroll into view")
	# Mouse browsing must remain free after keyboard focus has settled, even if
	# the focused Reset button is then outside the visible viewport.
	await frames(8)
	var scroll_before:=settings_scroll.scroll_vertical
	var wheel_point:=settings_scroll.get_global_rect().position+Vector2(settings_scroll.size.x-30,settings_scroll.size.y*0.5)
	var move:=InputEventMouseMotion.new();move.position=wheel_point;move.global_position=wheel_point;root.push_input(move,true)
	for pressed in [true,false]:
		var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=pressed;wheel.position=wheel_point;wheel.global_position=wheel_point;root.push_input(wheel,true)
	await frames(8)
	check(scroll_before>0 and settings_scroll.scroll_vertical<scroll_before and root.gui_get_focus_owner()==settings.reset_button,"Mouse wheel can scroll away after focused control settles")
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	await frames()
	check(clear_of_hud(settings.panel,hud),"Live resize keeps Settings clear of real gameplay HUD")
	settings.close()
	await frames()
	check(not settings.is_open(),"Settings closes cleanly")
	host.queue_free();await frames(2)
	print("FRAME_SAFE_LIVE checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
