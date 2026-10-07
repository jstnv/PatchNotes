extends SceneTree
func _initialize() -> void:
	go.call_deferred()
func go() -> void:
	var args := OS.get_cmdline_user_args()
	var expected := DemoSettingsStore.defaults()
	expected.width = 1152
	expected.height = 648
	expected.SFX = 37
	expected.Music_muted = true
	if "--write" in args:
		if DemoSettingsStore.write_settings(expected) != OK: quit(1); return
	else:
		var menu := DemoSettingsMenu.new()
		root.add_child(menu)
		await process_frame
		if menu.committed != expected or not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")): quit(2); return
		menu.queue_free()
		await process_frame
	print("PASS: separate process ", args, " preferences=", expected)
	quit(0)
