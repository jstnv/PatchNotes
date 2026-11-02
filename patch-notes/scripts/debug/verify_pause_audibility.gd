extends "res://scripts/debug/verify_pause_menu.gd"

func _initialize() -> void:
	await process_frame
	create_timer(115).timeout.connect(func(): push_error("Audibility timeout"); quit(2))
	node_added.connect(_replace_store)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	music = root.get_node("Soundtrack")
	await process_frame
	game._on_studio_created("Pause audibility", &"action", [], game._active_phase)
	await process_frame
	await skip_save_invitation()
	var prefs := DemoSettingsStore.defaults()
	prefs.Music = 13
	DemoSettingsStore.apply_audio(prefs)
	var bus := AudioServer.get_bus_index(&"Music")
	var original_volume := AudioServer.get_bus_volume_db(bus)
	var original_player_volume: float = music.player.volume_db
	var reverb_count:=0
	var analyzer_count:=0
	var approved_chain:=true
	for slot in AudioServer.get_bus_effect_count(bus):
		var effect:=AudioServer.get_bus_effect(bus,slot)
		if effect==music.pause_reverb:reverb_count+=1
		elif effect is AudioEffectSpectrumAnalyzer:analyzer_count+=1
		else:approved_chain=false
	expect(approved_chain and reverb_count==1 and analyzer_count<=1,"Pause uses its exact reverb plus optional passive visualizer analyzer; no low-pass or other processing")
	var pre := AudioEffectCapture.new()
	var post := AudioEffectCapture.new()
	var output := AudioEffectCapture.new()
	AudioServer.add_bus_effect(bus, pre, 0)
	AudioServer.add_bus_effect(bus, post)
	AudioServer.add_bus_effect(0, output)
	var rows := []
	var identity: int = music.player.get_stream_playback().get_instance_id()
	var levels := []
	for theme in [&"main", &"studio"]:
		music.request_theme(theme, true)
		await create_timer(1.0).timeout
		await key(KEY_ESCAPE)
		var frozen := game_state()
		await create_timer(music.PAUSE_FADE + 0.2).timeout
		var source_power := 0.0
		var filtered_power := 0.0
		var prior_clock: float = music.presentation_seconds()
		# A complete phrase prevents a quiet bar or reverb tail passing as music.
		for step in ceili(music.player.stream.get_length()*2.0):
			pre.clear_buffer()
			post.clear_buffer()
			output.clear_buffer()
			await create_timer(0.5, true, false, true).timeout
			var a := stats(pre)
			var b := stats(post)
			var c := stats(output)
			source_power += a.rms*a.rms
			filtered_power += b.rms*b.rms
			expect(a.frames > 1000 and b.frames > 1000 and c.frames > 1000, "Actual mixer produced PCM")
			expect(music.presentation_seconds() > prior_clock + 0.25, "Music clock advances while paused")
			prior_clock = music.presentation_seconds()
			rows.append({"theme":theme,"raw":music.player.get_playback_position(),"clock":music.presentation_seconds(),"paused":paused,"stream_paused":music.player.stream_paused,"pre":a,"post":b,"output":c,"gain_db":b.db-a.db})
			expect(paused and game_state() == frozen, "Gameplay frozen")
			expect(not music.player.stream_paused and music.player.get_stream_playback().get_instance_id() == identity, "Continuous transport identity")
			expect(music.pause_reverb.dry == 1.0 and AudioServer.get_bus_volume_db(bus) == original_volume and music.player.volume_db == original_player_volume, "Pause preserves dry signal and chosen music gain")
		var gain := sqrt(filtered_power/maxf(source_power, 0.000000001))
		levels.append({"theme":theme,"rms_ratio":gain,"attenuation_db":linear_to_db(gain)})
		# Wet reflections can change summed RMS; allow small capture/phase variance,
		# but no material song attenuation. Dry unity is checked separately above.
		expect(source_power > 0.001 and gain >= 0.95, "Paused %s retains the dry song level with room reverb: %.2f dB" % [theme,linear_to_db(gain)])
		await key(KEY_ESCAPE)
		await create_timer(music.PAUSE_FADE + 0.2).timeout
		expect(not paused and music.pause_weight == 0.0, "Resume clears pause treatment")
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"backend":AudioServer.get_driver_name(),"rows":rows,"levels":levels,"checks":checks,"failures":failures},"\t"))
	print("PAUSE_AUDIBILITY checks=%d failures=%d" % [checks,failures])
	quit(failures)

func stats(capture: AudioEffectCapture) -> Dictionary:
	var frames := capture.get_buffer(capture.get_frames_available())
	var power := 0.0
	for f: Vector2 in frames: power += f.length_squared()
	var rms := sqrt(power / maxf(1.0, frames.size()*2.0))
	return {"frames":frames.size(),"rms":rms,"db":linear_to_db(maxf(rms,0.000000001))}
