extends SceneTree

const Map := preload("res://scripts/audio/theme_map.gd")
const Grid := preload("res://scripts/audio/music_grid.gd")
const Blend := preload("res://scripts/audio/theme_blend.gd")
var checks := 0
var failures := 0
var music: Node
var fake_time := 0.0
var traces: Array = []
var resumes: Array = []

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	music = root.get_node("Soundtrack")
	music.presentation_resumed.connect(func(beats: int): resumes.append(beats))
	var bus := AudioServer.get_bus_index(&"Music")
	var sfx := AudioServer.get_bus_index(&"SFX")
	var sfx_effects := AudioServer.get_bus_effect_count(sfx)
	var volume := AudioServer.get_bus_volume_db(bus)
	var player_volume: float = music.player.volume_db
	var playback: int = 0
	check(AudioServer.get_bus_effect_count(bus) == 1 and AudioServer.get_bus_effect(bus, 0) == music.pause_reverb, "Only room reverb is on Music")
	check(not AudioServer.is_bus_effect_enabled(bus, 0), "Unpaused sound bypasses reverb")
	# Actual backend crosses the WAV wrap while paused and changes arrangement.
	music.player.seek(Map.LENGTH - 0.15)
	playback = music.player.get_stream_playback().get_instance_id()
	music.grid = Grid.new()
	music.last_sample_usec = 0
	music.blend = Blend.new()
	music._apply_blend(0.0)
	music.request_theme(&"studio", true)
	var banner := SynergyNotification.new()
	root.add_child(banner)
	banner.show_message("Pause test", "Keep the pending popup")
	await create_timer(0.06).timeout
	var banner_started := banner._started
	var scale_before := banner.banner.scale
	var alpha_before := banner.banner.modulate.a
	paused = true
	await create_timer(0.1).timeout
	check(music.pause_weight > 0 and music.pause_weight < 1, "Pause treatment fades in")
	check(music.pause_reverb.dry == 1.0 and music.player.volume_db == player_volume and AudioServer.get_bus_volume_db(bus) == volume, "Fade-in preserves full dry signal and music gain")
	var entry_wet: float = music.pause_reverb.wet
	check(entry_wet < music.PAUSE_REVERB_WET * music.pause_weight, "Gentle entry eases in instead of jumping to linear wetness")
	await create_timer(0.35).timeout
	check(music.pause_weight < 1.0 and music.pause_reverb.wet > entry_wet, "Filter is still gradually entering after nearly half a second")
	var before: float = music.presentation_seconds()
	await create_timer(1.0).timeout
	check(music.presentation_seconds() > before + 0.7 and music.grid.loops >= 1, "Pause clock crosses real loop boundary")
	check(music.pause_weight == 1.0 and not music.player.stream_paused, "Reverberant audio transport keeps playing")
	check(music.pause_reverb.dry == 1.0 and is_equal_approx(music.pause_reverb.wet, 0.38), "Bathroom reverb preserves dry level and reaches intended wetness")
	check(music.blend.weight == 1.0 and music.player.get_stream_playback().get_instance_id() == playback, "Studio transition completes during pause without restart")
	check(AudioServer.get_bus_effect_count(sfx) == sfx_effects and AudioServer.get_bus_volume_db(bus) == volume and music.player.volume_db == player_volume, "Effect leaves SFX and music gain alone")
	await create_timer(0.2).timeout
	check(banner.banner.scale == scale_before, "Synergy popup pose remains frozen")
	paused = false
	await process_frame
	await process_frame
	check(resumes.size() == 1 and resumes[0] > 0, "One shared subdivision shift on resume")
	check(is_equal_approx(banner._started - banner_started, resumes[0] * Map.STEP), "Popup uses the identical hand grid shift")
	check(banner.banner.scale.x >= scale_before.x and banner.banner.modulate.a >= alpha_before, "Partly visible popup never rewinds on rejoin")
	await create_timer(0.3).timeout
	check(music.pause_weight > 0.0 and music.pause_weight < 1.0 and AudioServer.is_bus_effect_enabled(bus, 0), "Resume gradually removes reverb instead of bypassing it immediately")
	await create_timer(music.PAUSE_FADE).timeout
	check(music.pause_weight == 0 and not AudioServer.is_bus_effect_enabled(bus, 0) and music.pause_reverb.dry == 1.0, "Resume clears reverb with original dry level intact")
	banner.queue_free()
	# Reverse the envelope midway, including at zero gameplay time scale.
	paused = true
	await create_timer(0.22).timeout
	var partial_wet: float = music.pause_reverb.wet
	paused = false
	await process_frame
	check(absf(music.pause_reverb.wet - partial_wet) < 0.03, "Rapid reversal retains current wetness without a jump")
	await create_timer(0.08).timeout
	var reversed_wet: float = music.pause_reverb.wet
	check(reversed_wet > 0.0 and reversed_wet < partial_wet, "Partial resume reverses the existing envelope")
	paused = true
	Engine.time_scale = 0.0
	await create_timer(0.2, true, false, true).timeout
	check(music.pause_reverb.wet > reversed_wet and music.pause_weight < 1.0, "Filter gradually advances with gameplay time scale zero")
	Engine.time_scale = 1.0
	paused = false
	await create_timer(music.PAUSE_FADE + 0.15).timeout
	check(music.pause_weight == 0.0 and not AudioServer.is_bus_effect_enabled(bus, 0), "Rapid toggles finish cleanly and bypass at zero wetness")
	# Rapid pause toggles, low FPS and settings changes cannot duplicate effects,
	# restart playback, or leave reverb latched on after scene/menu teardown.
	Engine.max_fps = 5
	for i in range(3):
		paused = true
		await create_timer(0.25).timeout
		var settings := DemoSettingsStore.defaults()
		settings.Music = 37
		settings.Music_muted = true
		DemoSettingsStore.apply_audio(settings)
		check(AudioServer.is_bus_mute(bus), "Mute works during pause")
		paused = false
		await create_timer(music.PAUSE_FADE + 0.25).timeout
		check(music.pause_weight == 0 and AudioServer.is_bus_mute(bus), "Resume preserves saved mute and clears treatment")
	Engine.max_fps = 0
	DemoSettingsStore.apply_audio(DemoSettingsStore.defaults())
	check(music.player.get_stream_playback().get_instance_id() == playback and AudioServer.get_bus_effect_count(bus) == 1, "Repeated pauses reuse playback and reverb")
	await verify_dsp(bus)
	for count in [1, 4, 7]:
		for bonus in [false, true]:
			for fps in [60.0, 5.0]:
				await sequence(count, bonus, 1.0 / fps)
	# Synthetic sequences can queue several SFX in one frame. Let the audio
	# thread drain stopped playback instances before this short verifier exits.
	await create_timer(0.4).timeout
	if OS.get_environment("PN_AUDIO_LONG") == "1":
		var laps: int = music.grid.loops
		before = music.presentation_seconds()
		var began := Time.get_ticks_msec()
		paused = true
		# Dummy audio can run slower than wall time under CI load. Observe actual
		# sample-led laps; a bounded wall deadline still detects a stalled clock.
		while music.presentation_seconds() < before + 2 * Map.LENGTH and Time.get_ticks_msec() - began < 90000:
			await create_timer(0.05).timeout
		traces.append({"paused_loops": music.grid.loops - laps,
			"audio_elapsed": music.presentation_seconds() - before,
			"wall_elapsed": (Time.get_ticks_msec() - began) / 1000.0})
		check(music.grid.loops >= laps + 2 and music.presentation_seconds() >= before + 2 * Map.LENGTH, "Two full real-time paused loops retain continuous beat count")
		paused = false
		await create_timer(music.PAUSE_FADE + 0.15).timeout
	var path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not path.is_empty(): FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures, "resumes": resumes, "traces": traces}, "\t"))
	print("PAUSE_MUSIC checks=%d failures=%d" % [checks, failures])
	quit(failures)

func sequence(count: int, bonus: bool, frame_step: float) -> void:
	var motion := HandPresentation.new()
	var fan := Control.new()
	root.add_child(fan)
	root.add_child(motion)
	motion.set_process(false)
	fake_time = 63.7 * Map.STEP
	motion.clock_source = func(): return fake_time
	var selected: Array = []
	for i in range(count):
		var card := load("res://scenes/cards/card_view.tscn").instantiate() as CardView
		card.set_card(root.get_node("CardDatabase").get_card(&"graphics_pass"))
		fan.add_child(card)
		selected.append(card)
	var state := {"_cycle": 0, &"graphics": 0}
	var calls := [0]
	var action := func():
		calls[0] += 1
		state._cycle += 1
		state[&"graphics"] = count * (3 if bonus else 2)
		if bonus: motion.note_specialization(Callable())
	check(motion.play("play", fan, selected, action, func(): return state.duplicate(), Callable(), Callable()), "Accept sequence")
	var first_beat: int = motion._first_beat
	# Pause in centering, rise, fall, popup lead and bonus motion. Includes a
	# multi-loop pause and a second pause before the previous rejoin is reached.
	var offsets := [-0.8, 0.25, 0.75, count + 0.4, count + 1.25, count + 1.75] if bonus else [-0.8, 0.25, 0.75]
	var total_shift := 0
	for offset in offsets:
		var target: float = (first_beat + total_shift + offset) * Map.STEP
		while fake_time < target:
			fake_time = minf(target, fake_time + frame_step)
			motion.advance_music(fake_time)
		var positions: Array = motion._ghosts.map(func(c): return c.position)
		var labels: Array = motion._bonus_labels.map(func(e): return [e.label.position, e.label.modulate.a])
		var rows := motion.trace.size()
		var duration := 2 * Map.LENGTH + 0.137
		fake_time += duration
		var shift := ceili(duration / Map.STEP)
		motion._rejoin_music_grid(shift)
		total_shift += shift
		motion.advance_music(fake_time)
		check(motion.trace.size() == rows + 1 and motion._ghosts.map(func(c): return c.position) == positions, "Long pause retains pose/events until next matching music phase")
		check(motion._bonus_labels.map(func(e): return [e.label.position, e.label.modulate.a]) == labels, "Floating bonus labels do not rewind while awaiting rejoin")
		fake_time += 0.01
		motion._rejoin_music_grid(1)
		total_shift += 1
		motion.advance_music(fake_time)
		check(motion._ghosts.map(func(c): return c.position) == positions, "Repeated pause during rejoin wait stays frozen")
	var deadline := fake_time + (count * 3 + 4) * Map.STEP
	while motion._music_driven and fake_time < deadline:
		fake_time += frame_step
		motion.advance_music(fake_time)
	check(calls[0] == 1 and state._cycle == 1 and motion.display_values[&"graphics"] == state[&"graphics"], "Resume never repeats authoritative action; final display agrees")
	for event in ["rise", "score", "grounded", "bonus_rise", "bonus", "bonus_grounded"]:
		var rows: Array = motion.trace.filter(func(e): return e.event == event)
		check(rows.size() == (count if bonus or not event.begins_with("bonus") else 0), "Exactly-once " + event)
		for i in range(rows.size()):
			check(rows[i].index == i, "Resume preserves left-to-right order")
			check(rows[i].lateness_seconds >= -0.00001 and rows[i].lateness_seconds <= frame_step + 0.00001, "Resumed event stays within one frame of music grid")
	traces.append({"count": count, "bonus": bonus, "frame_step": frame_step, "events": motion.trace.duplicate(true)})
	motion.cancel()
	motion.queue_free()
	fan.queue_free()
	await process_frame

func verify_dsp(bus: int) -> void:
	# Feed an impulse through the actual Music effects and capture post-effect
	# samples. This exercises DSP even on the Dummy driver, without device output.
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	AudioServer.add_bus_effect(bus, capture)
	music.player.volume_db = -80
	var probe := AudioStreamPlayer.new()
	probe.bus = &"Music"
	probe.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(probe)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 48000
	var data := PackedByteArray()
	data.resize(48000)
	data.encode_s16(0, 24000)
	wav.data = data
	probe.stream = wav
	var measurements: Array = []
	for filtered in [false, true]:
		paused = filtered
		await create_timer(music.PAUSE_FADE + 0.2).timeout
		capture.clear_buffer()
		probe.play()
		await create_timer(0.8).timeout
		var samples := capture.get_buffer(capture.get_frames_available())
		var peak := 0.0
		var peak_at := 0
		for i in range(samples.size()):
			if samples[i].length() > peak:
				peak = samples[i].length()
				peak_at = i
		var tail := 0.0
		for i in range(peak_at + 4800, samples.size()): tail += samples[i].length_squared()
		measurements.append({"filtered": filtered, "peak": peak, "tail_energy": tail, "samples": samples.size()})
	check(measurements[0].peak > 0.05, "Actual mixer capture contains test impulse")
	check(absf(measurements[1].peak / measurements[0].peak - 1.0) < 0.02, "Paused reverb preserves the dry impulse peak without attenuation")
	check(measurements[1].tail_energy > maxf(0.000001, measurements[0].tail_energy * 10), "Paused Music adds a measurable room reverb tail")
	traces.append({"dsp": measurements})
	paused = false
	await create_timer(music.PAUSE_FADE + 0.15).timeout
	music.player.volume_db = 0
	probe.queue_free()
	for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
		if AudioServer.get_bus_effect(bus, i) == capture: AudioServer.remove_bus_effect(bus, i)
