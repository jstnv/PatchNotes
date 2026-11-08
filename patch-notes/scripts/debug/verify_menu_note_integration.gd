extends SceneTree

## Exercise the real circuit node against deterministic presentation clocks.
## No gameplay RNG, player save or real audio device is needed.
const Circuits := preload("res://scripts/ui/menu_circuit_background.gd")
const SoundtrackScript := preload("res://scripts/audio/soundtrack.gd")
const DATA := "res://assets/boot/sequence_v1/menu_visual_notes.json"

class ClockStub extends Node:
	var clocks: Array[Dictionary] = []
	func visual_note_clocks() -> Array[Dictionary]: return clocks.duplicate(true)

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func settle(count: int = 5) -> void:
	for i in count: await process_frame

func clock(timeline: StringName, seconds: float, gain: float = 1.0) -> Dictionary:
	return {"timeline": timeline, "seconds": seconds, "gain": gain}

func expected(track: Dictionary, offset: int) -> Dictionary:
	var result := {}
	for pair in [["bass",&"bass",1],["chords",&"chord",0]]:
		for row: Array in track[pair[0]]:
			var key := "%s/%d/%d/%d" % [pair[1], int(row[0]) + offset, int(row[1]), pair[2]]
			result[key] = int(result.get(key,0)) + 1
	return result

func merge(into: Dictionary, values: Dictionary) -> void:
	for key: String in values: into[key] = int(into.get(key,0)) + int(values[key])

func project_events(events: Array, rate: float) -> Dictionary:
	var result := {}
	for event: Dictionary in events:
		var key := "%s/%d/%d/%d" % [event.kind, roundi(float(event.absolute_time) * rate), int(event.pitch), int(event.color_index)]
		result[key] = int(result.get(key,0)) + 1
	return result

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var old_song := root.get_node_or_null("Soundtrack")
	if old_song != null:
		root.remove_child(old_song)
		old_song.queue_free()
	var song := ClockStub.new()
	song.name = "Soundtrack"
	root.add_child(song)
	var circuit: Control = Circuits.new()
	circuit.size = Vector2(1280,720)
	root.add_child(circuit)
	await settle()
	circuit.set_process(false)
	circuit._quiet = false
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var rate := float(data.sample_rate)
	var loop_frames := int(data.loop_frames)
	var switch_frames := int(data.switch_frames)
	var length := float(loop_frames) / rate
	var switch_length := float(switch_frames) / rate
	check(not circuit._note_data.is_empty() and circuit.geometry.routes.size() > 0, "Actual circuit loads note data and route geometry")

	# Sample an entire startup + A + B cycle at 30 Hz and compare every note
	# as a multiset, including all simultaneous voices and seam note-ons.
	var actual := {}
	song.clocks.assign([clock(&"boot",0.0)])
	merge(actual,project_events(circuit._music_note_events(),rate))
	var end := length * 3.0 - 1.0 / rate
	for frame in range(1, ceili(end * 30.0) + 1):
		var seconds := minf(float(frame) / 30.0,end)
		song.clocks.assign([clock(&"boot",seconds)])
		merge(actual,project_events(circuit._music_note_events(),rate))
	var wanted := expected(data.tracks.startup,0)
	merge(wanted,expected(data.tracks.loop_a,loop_frames))
	merge(wanted,expected(data.tracks.loop_b,loop_frames * 2))
	check(actual == wanted, "Real circuit emits every startup/A/B bass and chord onset at 30 Hz")
	check(actual.size() > 0, "Actual routed notes retain bass orange and chord blue indices")

	# Enter a new switch at zero; then cross its splice into menu music.
	song.clocks.assign([clock(&"switch_menu",0.0)])
	circuit._music_note_events()
	var switch_actual := {}
	var switch_end := switch_length + length - 1.0 / rate
	for frame in range(1,ceili(switch_end * 30.0) + 1):
		song.clocks.assign([clock(&"switch_menu",minf(float(frame) / 30.0,switch_end))])
		merge(switch_actual,project_events(circuit._music_note_events(),rate))
	var switch_wanted := expected(data.tracks.switch,0)
	merge(switch_wanted,expected(data.tracks.menu,switch_frames))
	check(switch_actual == switch_wanted, "Switch and following menu loop preserve every mapped onset across their splice")

	# Muting advances the playback cursor silently; resuming cannot replay it.
	song.clocks.assign([clock(&"menu",0.0)])
	circuit._music_note_events()
	circuit._quiet = true
	song.clocks.assign([clock(&"menu",1.0)])
	check(circuit._music_note_events().is_empty(), "Muted music produces no note-driven threads")
	circuit._quiet = false
	check(circuit._music_note_events().is_empty(), "Unmuting at the same cursor does not replay silent notes")
	song.clocks.assign([clock(&"menu",2.0)])
	var fresh: Array = circuit._music_note_events()
	check(not fresh.is_empty(), "New notes resume after unmuting")
	var colors_ok := true
	for event: Dictionary in fresh:
		colors_ok = colors_ok and int(event.color_index) == (1 if event.kind == &"bass" else 0)
	check(colors_ok, "Real circuit classifies bass as orange and chords as blue")
	circuit.field.reset()
	var initial_count: int = circuit.field.total_spawned
	circuit.field.step(1.0/60.0,Vector3(0.5,0.5,0.2),true,fresh)
	check(circuit.field.total_spawned - initial_count == fresh.size(), "Actual field admits every collected note event")

	# Shared transport projection must suppress menu mapping once its weight is
	# zero, while crossfade exposes both tails with separate clocks.
	var fade := SoundtrackScript._visual_note_clock_projection({"phase":&"switch","switch_seconds":0.09,"tail_active":true,"tail_seconds":4.0})
	check(fade.size() == 2 and fade[0].timeline == &"boot" and fade[1].timeline == &"switch_menu", "Boot-to-switch crossfade retains both note clocks")
	var off := SoundtrackScript._visual_note_clock_projection({"phase":&"","shared_menu":true,"menu_weight":0.0,"studio_weight":0.0,"menu_seconds":0.0})
	var stale_menu := false
	for entry: Dictionary in off:
		if entry.timeline == &"menu": stale_menu = true
	check(not stale_menu, "Fully inaudible menu layer supplies no stale menu note clock")

	# A late first switch frame must still show every note from its beginning.
	circuit._note_timelines.clear()
	song.clocks.assign([clock(&"boot",4.0)])
	circuit._music_note_events()
	song.clocks.assign([clock(&"switch_menu",0.25)])
	var delayed: Array = circuit._music_note_events()
	var delayed_wanted := {}
	for kind in ["bass","chords"]:
		for row: Array in data.tracks.switch[kind]:
			if float(row[0]) / rate > 0.25: continue
			var key := "%s/%d/%d/%d" % ["bass" if kind == "bass" else "chord",int(row[0]),int(row[1]),1 if kind == "bass" else 0]
			delayed_wanted[key] = int(delayed_wanted.get(key,0)) + 1
	check(project_events(delayed,rate) == delayed_wanted and not delayed.is_empty(), "Delayed first switch frame retains newly started notes")

	# Long suspension has bounded catch-up and only returns visible-age notes.
	circuit._note_timelines.clear()
	song.clocks.assign([clock(&"menu",0.0)])
	circuit._music_note_events()
	song.clocks.assign([clock(&"menu",10000.0)])
	var bound_start := Time.get_ticks_usec()
	var recovered: Array = circuit._music_note_events()
	var bound_elapsed := Time.get_ticks_usec() - bound_start
	var age_ok := true
	for event: Dictionary in recovered:
		age_ok = age_ok and float(event.age) <= 12.00001 and float(event.age) >= 0.0
	check(not recovered.is_empty() and age_ok, "Long suspend returns only recent notes within the 12-second history bound")
	print("LONG_PAUSE_RECOVERY elapsed_us=%d notes=%d" % [bound_elapsed,recovered.size()])

	if DisplayServer.get_name() != "headless":
		root.min_size = Vector2i.ZERO
		root.size = Vector2i(1280,720)
		root.content_scale_size = root.size
		circuit.size = Vector2(1280,720)
		circuit.show()
		circuit.readability_right = 0.0
		circuit.field.reset()
		circuit.field.step(1.0/60.0,Vector3(0.7,0.5,0.2),true,[])
		for i in 128:
			var pulse = circuit.field.spawn_note(&"bass" if i % 2 == 0 else &"chord",36 + i % 24,128,0.8)
			if pulse != null: pulse.distance = 150.0 + float(i % 20) * 35.0
		check(circuit.field.count() == 128, "Native render receives a fully populated 128-note pool")
		await settle()
		var start := Time.get_ticks_usec()
		var max_draw := 0
		for i in 60:
			circuit.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			max_draw = maxi(max_draw,circuit.draw_microseconds)
		var elapsed := Time.get_ticks_usec() - start
		check(int(circuit._shader.get_shader_parameter("pulse_slots")) == 128, "Shader receives all active pulse slots")
		var output := OS.get_environment("PN_MENU_NOTE_CAPTURE")
		if not output.is_empty():
			check(root.get_texture().get_image().save_png(output.path_join("dense-notes.png")) == OK, "Dense native shader capture is written")
		print("DENSE_NOTE_RENDER frames=60 elapsed_us=%d max_cpu_draw_us=%d renderer=%s" % [elapsed,max_draw,RenderingServer.get_video_adapter_name()])
	circuit.free()
	song.free()
	print("MENU_NOTE_INTEGRATION checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
