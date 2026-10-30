extends SceneTree
var checks:=0
var failures:=0
var output:=""
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void: _run.call_deferred()
func frames(count: int) -> void:
	for i in count: await process_frame
func maximum(values: PackedFloat32Array) -> float:
	var result:=0.0
	for value in values:result=maxf(result,value)
	return result
func _run() -> void:
	create_timer(30.0).timeout.connect(func():push_error("Menu visualizer check timed out");quit(2))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var music:=AudioServer.get_bus_index(&"Music")
	var baseline:=AudioServer.get_bus_effect_count(music)
	var song:=root.get_node("Soundtrack")
	var player_id: int=song.player.get_instance_id()
	var before: float=song.presentation_seconds()
	var menu:=MainMenu.new();root.add_child(menu);await frames(3)
	var visual: Control=menu.get("_visualizer")
	expect(visual!=null,"Actual title owns a music spectrum visualizer")
	if visual==null:menu.free();quit(failures);return
	expect(visual.mouse_filter==Control.MOUSE_FILTER_IGNORE and visual.focus_mode==Control.FOCUS_NONE,"Decorative spectrum never consumes pointer or keyboard input")
	expect(AudioServer.get_bus_effect_count(music)==baseline+1,"Only one owned analyser joins the Music bus")
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720),Vector2i(900,600),Vector2i(1920,1080),Vector2i(720,600)]:
		root.size=dimensions;root.content_scale_size=dimensions;await frames(3)
		var title: Control=menu.get("_title_screen")
		if visual.visible:
			expect(root.get_visible_rect().encloses(visual.get_global_rect()) and not visual.get_global_rect().intersects(title.get_global_rect()),"Spectrum fits unused title space at "+str(dimensions))
			for index in visual.BANDS:
				expect(Rect2(Vector2.ZERO,visual.size).encloses(visual.bar_rect(index)),"Each drawn bar stays inside its allocated bounds")
		else:expect(dimensions.x<800,"Compact windows omit spectrum instead of covering controls")
	root.size=Vector2i(1152,648);root.content_scale_size=Vector2i(1152,648)
	await create_timer(0.7).timeout
	var high:=maximum(visual.levels)
	expect(high>0.01,"Real running soundtrack produces nonzero FFT energy")
	var first: PackedFloat32Array=visual.levels.duplicate()
	await create_timer(0.25).timeout
	expect(visual.levels!=first,"Actual audio changes the bars over time")
	await capture("main-menu-spectrum-1152")
	for bus in [&"Music",&"Master"]:
		var index:=AudioServer.get_bus_index(bus)
		var prior:=AudioServer.is_bus_mute(index)
		AudioServer.set_bus_mute(index,true)
		await create_timer(0.8).timeout
		expect(maximum(visual.levels)<0.02,"Muted "+str(bus)+" settles to silence, not fake beat motion")
		AudioServer.set_bus_mute(index,prior)
		await create_timer(0.3).timeout
	var volume:=AudioServer.get_bus_volume_db(music)
	AudioServer.set_bus_volume_db(music,-80)
	await create_timer(0.8).timeout
	expect(maximum(visual.levels)<0.02,"Zero music volume leaves a quiet graph")
	AudioServer.set_bus_volume_db(music,volume)
	menu.navigation.animate=false
	menu.open_setup();await frames(3)
	expect(not visual.visible and AudioServer.get_bus_effect_count(music)==baseline,"Creation folders hide spectrum and release FFT work")
	menu.navigate_back();await frames(3)
	expect(visual.visible and AudioServer.get_bus_effect_count(music)==baseline+1,"Returning to title reacquires exactly one analyser")
	var folder:=PanelContainer.new();var back:=Button.new();folder.add_child(back);menu.add_child(folder)
	menu.navigation.push(folder,back);await frames(3)
	expect(not visual.visible and AudioServer.get_bus_effect_count(music)==baseline,"Other title navigation destinations stop the spectrum too")
	menu.navigation.pop();await frames(3)
	expect(visual.visible and AudioServer.get_bus_effect_count(music)==baseline+1,"Folder Back restores spectrum without a leak")
	await create_timer(0.35).timeout
	for dimensions in [Vector2i(1280,720),Vector2i(900,600)]:
		root.size=dimensions;root.content_scale_size=dimensions;await frames(3)
		await capture("main-menu-spectrum-"+str(dimensions.x))
	expect(song.player.get_instance_id()==player_id and song.player.playing and song.presentation_seconds()>before,"Observer never restarts, seeks or pauses the existing soundtrack")
	menu.free();await frames(2)
	expect(AudioServer.get_bus_effect_count(music)==baseline,"Scene teardown removes only the owned analyser")
	expect(is_equal_approx(AudioServer.get_bus_volume_db(music),volume),"Visualizer never changes the music mix gain")
	print("MENU_VISUALIZER checks=%d failures=%d peak=%f"%[checks,failures,high])
	quit(failures)
func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	expect(image.save_png(output.path_join(label+".png"))==OK,"Native menu screenshot saved")
