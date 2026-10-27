extends "res://scripts/debug/verify_pause_menu.gd"

func _initialize() -> void:
	await process_frame
	create_timer(90).timeout.connect(func(): push_error("Audibility timeout"); quit(2))
	node_added.connect(_replace_store)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	music = root.get_node("Soundtrack")
	if OS.get_environment("PN_PAUSE_FILTER_CANDIDATE") == "1":
		music.pause_filter.resonance = 0.5
	await process_frame
	game._on_studio_created("Pause audibility", &"action", [], game._active_phase)
	var prefs := DemoSettingsStore.defaults()
	prefs.Music = 13
	DemoSettingsStore.apply_audio(prefs)
	var bus := AudioServer.get_bus_index(&"Music")
	var pre := AudioEffectCapture.new()
	var post := AudioEffectCapture.new()
	var output := AudioEffectCapture.new()
	AudioServer.add_bus_effect(bus, pre, 0)
	AudioServer.add_bus_effect(bus, post)
	AudioServer.add_bus_effect(0, output)
	var rows := []
	var identity: int = music.player.get_stream_playback().get_instance_id()
	for theme in [&"main", &"studio"]:
		music.request_theme(theme, true)
		await create_timer(1.0).timeout
		await key(KEY_ESCAPE)
		var frozen := game_state()
		await create_timer(0.7).timeout
		for step in 28:
			pre.clear_buffer()
			post.clear_buffer()
			output.clear_buffer()
			await create_timer(0.5, true, false, true).timeout
			var a := stats(pre)
			var b := stats(post)
			var c := stats(output)
			rows.append({"theme":theme,"raw":music.player.get_playback_position(),"clock":music.presentation_seconds(),"paused":paused,"stream_paused":music.player.stream_paused,"pre":a,"post":b,"output":c,"gain_db":b.db-a.db})
			expect(paused and game_state() == frozen, "Gameplay frozen")
			expect(not music.player.stream_paused and music.player.get_stream_playback().get_instance_id() == identity, "Continuous transport identity")
		await key(KEY_ESCAPE)
		await create_timer(0.5).timeout
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"backend":AudioServer.get_driver_name(),"rows":rows,"checks":checks,"failures":failures},"\t"))
	print("AUDIBILITY checks=%d failures=%d" % [checks,failures])
	quit(failures)

func stats(capture: AudioEffectCapture) -> Dictionary:
	var frames := capture.get_buffer(capture.get_frames_available())
	var power := 0.0
	for f: Vector2 in frames: power += f.length_squared()
	var rms := sqrt(power / maxf(1.0, frames.size()*2.0))
	return {"frames":frames.size(),"rms":rms,"db":linear_to_db(maxf(rms,0.000000001))}
