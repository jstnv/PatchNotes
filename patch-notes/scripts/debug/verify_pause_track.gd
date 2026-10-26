extends "res://scripts/debug/verify_pause_menu.gd"

func _initialize() -> void:
	await process_frame
	create_timer(45).timeout.connect(func(): push_error("Pause track timeout"); quit(2))
	node_added.connect(_replace_store)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	music = root.get_node("Soundtrack")
	await process_frame
	game._on_studio_created("Pause music transport", &"action", [], game._active_phase)
	await create_timer(1.5).timeout
	var bus := AudioServer.get_bus_index(&"Music")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(bus, capture)
	var backend: String = AudioServer.get_driver_name()
	var record := {"backend":backend,"samples":[]}
	var identity: int = music.player.get_stream_playback().get_instance_id()
	var before := game_state()
	await key(KEY_ESCAPE)
	expect(paused and game.pause_menu.is_open(), "Real Esc menu owns pause")
	var raw_start: float = music.player.get_playback_position()
	var heard_start: float = music.presentation_seconds()
	for step in 12:
		capture.clear_buffer()
		await create_timer(0.5).timeout
		var buffer := capture.get_buffer(capture.get_frames_available())
		var power := 0.0
		for frame: Vector2 in buffer: power += frame.length_squared()
		var raw: float = music.player.get_playback_position()
		var expected: float = (step + 1) * 0.5
		var delta := fposmod(raw - raw_start, music.player.stream.get_length())
		record.samples.append({"raw_position":raw,"elapsed":delta,"expected":expected,"energy":power,"frames":buffer.size(),"stream_paused":music.player.stream_paused,"can_process":music.player.can_process(),"player_mode":music.player.process_mode,"filter":music.pause_weight})
		expect(delta > expected * 0.75, "Actual WAV playhead advances during pause, sample " + str(step))
		expect(buffer.size() > 1000 and power > 0.001, "Actual filtered song continues producing audio, sample " + str(step))
	expect(game_state() == before and music.pause_weight == 1.0, "Gameplay frozen, full existing filter retained")
	expect(music.presentation_seconds() > heard_start + 4.5, "Shared music time map advances with real song")
	expect(music.player.get_stream_playback().get_instance_id() == identity, "No restart or replacement while paused")
	await key(KEY_ESCAPE)
	await create_timer(0.5).timeout
	expect(not paused and music.pause_weight == 0.0, "Esc resumes gameplay and clears filter")
	AudioServer.remove_bus_effect(bus, AudioServer.get_bus_effect_count(bus)-1)
	record.checks = checks
	record.failures = failures
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"), FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	print("PAUSE_TRACK backend=%s checks=%d failures=%d" % [backend,checks,failures])
	quit(failures)
