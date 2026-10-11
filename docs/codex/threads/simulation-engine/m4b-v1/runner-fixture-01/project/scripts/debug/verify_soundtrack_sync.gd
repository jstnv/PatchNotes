extends SceneTree

const Grid := preload("res://scripts/audio/music_grid.gd")
var failures := 0
var checks := 0
var traces: Array = []
var fake_time := 0.0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	var music := root.get_node("Soundtrack")
	check(music.player.stream is AudioStreamWAV and music.player.bus == &"Music", "WAV on Music bus")
	var length: float = music.player.stream.get_length()
	check(absf(length - 27.4285625) < 0.0001, "70 BPM eight-bar sample length")
	var grid := Grid.new()
	check(is_equal_approx(grid.sample(1.0, 0, length, 0.02, 0.08, false), 0.94 * 64 * Grid.STEP / length), "Mix and output correction")
	var held := grid.seconds
	check(grid.sample(0.0, 0, length, 0.0, 0.08, false) == held, "Jitter never rewinds")
	check(grid.sample(4.0, 0, length, 0.1, 0.08, true) == held, "Pause freezes grid")
	for loop in range(1, 1001):
		grid.unwrap(length - 0.1, length, length - 0.1 if loop == 1 else length - 0.2, false)
		var laps := grid.unwrap(0.1, length, 0.2, false)
		check(laps == loop, "Position wraps once")
		var t := grid.sample(0.0, laps, length, 0.08, 0.08, false)
		check(absf(t / Grid.STEP - loop * 64) < 0.000001, "Repeated loop endpoints stay on musical grid")
	# Production still uses four cards. Other sizes exercise the visual scheduler,
	# not permission for illegal gameplay hands. Short/long valid production
	# passes are four base events versus four base + four bonus events.
	for count in [1, 3, 4, 7]:
		for bonus in [false, true]:
			for frame_step in [1.0/60.0, 1.0/5.0, 1.1]:
				await sequence(count, bonus, frame_step)
	await balanced_sequence(1.0 / 60.0)
	await balanced_sequence(0.31)
	# Real backend wrap and pause, independent of synthetic clock samples.
	music.grid = Grid.new()
	music.player.seek(length - 0.1)
	await create_timer(0.35).timeout
	print("BACKEND ", AudioServer.get_driver_name(), " position=",music.player.get_playback_position(), " loops=",music.player.get_stream_playback().get_loop_count(), " length=",length, " time=",music.presentation_seconds())
	check(music.grid.loops >= 1, "WAV position unwrap observes actual wrap")
	check(music.presentation_seconds() > length, "Actual wrap stays unwrapped")
	music.set_paused(true)
	var stopped: float = music.presentation_seconds()
	await create_timer(0.15).timeout
	check(music.presentation_seconds() == stopped, "Actual pause freezes presentation clock")
	music.set_paused(false)
	await create_timer(0.2).timeout
	check(music.presentation_seconds() > stopped, "Actual resume advances")
	paused = true
	await create_timer(0.05).timeout
	var tree_stopped: float = music.presentation_seconds()
	await create_timer(0.1).timeout
	check(music.presentation_seconds() == tree_stopped, "SceneTree pause freezes clock")
	paused = false
	await create_timer(0.2).timeout
	check(music.presentation_seconds() > tree_stopped, "SceneTree resume advances clock")
	if OS.get_environment("PN_AUDIO_LONG") == "1":
		music.player.stop()
		music.grid = Grid.new()
		music.last_sample_usec = 0
		music.player.play()
		await create_timer(length * 2.0 + 0.3).timeout
		check(music.grid.loops == 2, "Two complete real-time WAV loops observed")
		check(music.presentation_seconds() > 128 * Grid.STEP, "Real repeated loops preserve beat indices")
	var identity: int = music.get_instance_id()
	var scene := Control.new()
	root.add_child(scene)
	scene.queue_free()
	await process_frame
	check(root.get_node("Soundtrack").get_instance_id() == identity, "Scene replacement preserves transport")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "traces": traces}, "\t"))
	print("Soundtrack sync: %d checks, %d failures" % [checks, failures])
	quit(failures)

func sequence(count: int, bonus: bool, frame_step: float) -> void:
	var motion := HandPresentation.new()
	var fan := Control.new()
	root.add_child(fan)
	root.add_child(motion)
	motion.set_process(false)
	fake_time = 63.7 * Grid.STEP # Straddle a loop boundary.
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
	check(motion.play("play", fan, selected, action, func(): return state.duplicate(), Callable(), Callable()), "Accepted visual sequence")
	var expected: int = state[&"graphics"]
	# The music cursor does not move during pause, even if many render frames pass.
	for i in range(10): motion.advance_music(fake_time)
	check(motion.trace.is_empty(), "No events while clock is stationary")
	var deadline := fake_time + (count * 3 + 4) * Grid.STEP
	while motion._music_driven and fake_time < deadline:
		fake_time += frame_step
		motion.advance_music(fake_time)
	check(calls[0] == 1 and state[&"graphics"] == expected, "No gameplay replay")
	check(selected[0].input_button.get_theme_stylebox("focus") is StyleBoxEmpty, "Card focus does not paint cyan border")
	check(motion.display_values[&"graphics"] == expected, "Final display equals committed total")
	for event in ["rise", "score", "grounded", "bonus_rise", "bonus", "bonus_grounded"]:
		var rows := motion.trace.filter(func(e): return e.event == event)
		var wanted := count if not event.begins_with("bonus") or bonus else 0
		check(rows.size() == wanted, "No missing or duplicate " + event)
		for i in range(rows.size()):
			check(rows[i].index == i, "Left-to-right event order")
			check(rows[i].lateness_seconds >= -0.00001 and rows[i].lateness_seconds <= frame_step + 0.00001, "Event error bounded by one render frame")
			if i > 0: check(is_equal_approx(rows[i].beat_index - rows[i-1].beat_index, 1.0), "Fixed subdivision cadence")
	check(motion._play_sound.bus == &"SFX" and motion._remove_sound.bus == &"SFX", "Both cues obey SFX settings")
	check(motion._play_sound.stream is AudioStreamWAV and motion._remove_sound.stream is AudioStreamWAV, "Original WAV cues loaded")
	if bonus:
		var start: Array = motion.trace.filter(func(e): return e.event == "specialization_started")
		var rise: Array = motion.trace.filter(func(e): return e.event == "bonus_rise")
		check(rise[0].beat_index - start[0].beat_index == HandPresentation.SPECIALIZATION_LEAD_BEATS, "Popup precedes bonuses by one music subdivision")
		check(motion.trace.filter(func(e): return e.event in ["exit_bounce", "exit_grounded"]).is_empty(), "No extra victory wave after synergy")
	check(motion.trace.filter(func(e): return e.event == "exit_slide").size() == 1, "Exactly one removal cue boundary")
	traces.append({"count": count, "bonus": bonus, "frame_step": frame_step, "events": motion.trace.duplicate(true)})
	motion.cancel()
	motion.queue_free()
	fan.queue_free()
	await process_frame


func balanced_sequence(frame_step: float) -> void:
	var motion := HandPresentation.new()
	var fan := Control.new()
	root.add_child(fan)
	root.add_child(motion)
	motion.set_process(false)
	fake_time = 63.7 * Grid.STEP
	motion.clock_source = func(): return fake_time
	var selected: Array = []
	for i in range(4):
		var view := load("res://scenes/cards/card_view.tscn").instantiate() as CardView
		var card := CardData.new()
		card.id = StringName("balanced_motion_" + str(i))
		card.primary_stat = HandPresentation.CORE[i]
		card.primary_value = 6 if i == 3 else 5
		view.set_card(card)
		fan.add_child(view)
		selected.append(view)
	var state := {"_cycle": 0, &"graphics": 100, &"sound": 20, &"technology": 0, &"design": 1}
	var calls := [0]
	var snapshots: Array = []
	motion.card_step.connect(func(_index, event): snapshots.append({"event":event, "values":motion.display_values.duplicate()}))
	var action := func():
		calls[0] += 1
		state._cycle += 1
		for i in range(4): state[HandPresentation.CORE[i]] += 6 if i == 0 else 5
		motion.note_specialization(Callable(), true)
	check(motion.play("play", fan, selected, action, func(): return state.duplicate(), Callable(), Callable()), "Balanced visual sequence accepted")
	for i in range(10): motion.advance_music(fake_time)
	check(motion.trace.is_empty(), "Balanced pause holds events")
	var deadline := fake_time + 15 * Grid.STEP
	while motion._music_driven and fake_time < deadline:
		fake_time += frame_step
		motion.advance_music(fake_time)
	var played := snapshots.filter(func(row): return row.event == "score")
	check(played.size() == 4 and played[-1].values[&"graphics"] == 105 and played[-1].values[&"design"] == 7, "Balanced first displays printed hand gains")
	var shared := snapshots.filter(func(row): return row.event == "balanced_redistributed")
	check(shared.size() == 1 and shared[0].values[&"graphics"] == 106 and shared[0].values[&"design"] == 6, "Balanced applies signed transfer once after cards play")
	check(calls[0] == 1 and state._cycle == 1, "Balanced presentation never replays gameplay")
	for key in HandPresentation.CORE: check(motion.display_values[key] == state[key], "Balanced display matches authoritative final score")
	var starts := motion.trace.filter(func(e): return e.event == "specialization_started")
	var splits := motion.trace.filter(func(e): return e.event == "balanced_redistributed")
	check(starts.size() == 1 and splits.size() == 1 and splits[0].beat_index - starts[0].beat_index == 1, "Balanced popup then redistribution share continuous music grid")
	check(motion.trace.filter(func(e): return e.event in ["bonus_rise", "exit_bounce"]).is_empty(), "Balanced has no second bounce wave")
	check(splits[0].lateness_seconds >= -0.00001 and splits[0].lateness_seconds <= frame_step + 0.00001, "Balanced low-frame-rate event stays within one frame")
	traces.append({"balanced":true, "frame_step":frame_step, "events":motion.trace.duplicate(true)})
	motion.cancel()
	motion.queue_free()
	fan.queue_free()
	await process_frame
