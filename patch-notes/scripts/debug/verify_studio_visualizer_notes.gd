extends SceneTree

## Presentation-only regression; isolated test profile and no player saves.
const Circuits := preload("res://scripts/ui/menu_circuit_background.gd")
const Song := preload("res://scripts/audio/soundtrack.gd")
const Map := preload("res://scripts/audio/theme_map.gd")

class ClockStub extends Node:
	var clocks: Array[Dictionary] = []
	func visual_note_clocks() -> Array[Dictionary]: return clocks.duplicate(true)

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func clock(id: StringName, seconds: float, gain: float = 1.0) -> Dictionary:
	return {"timeline": id, "seconds": seconds, "gain": gain}

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var state := {"phase": &"", "shared_menu": true, "menu_weight": 0.0,
		"studio_weight": 1.0, "studio_index": 0, "menu_seconds": 7.25}
	for index in 6:
		state.studio_index = index
		var projected: Array = Song._visual_note_clock_projection(state)
		check(projected.size() == 1 and projected[0].timeline == StringName("studio_%d" % index) and is_equal_approx(float(projected[0].seconds),7.25) and is_equal_approx(float(projected[0].gain),1.0), "Studio variation %d exposes its actual selected playback clock" % index)
	state.menu_weight = 0.4
	state.studio_weight = 0.5
	state.studio_index = 2
	var fade: Array = Song._visual_note_clock_projection(state)
	var menu_seen := false
	var studio_seen := false
	for entry: Dictionary in fade:
		if entry.timeline == &"menu": menu_seen = is_equal_approx(float(entry.gain),0.4)
		if entry.timeline == &"studio_2": studio_seen = is_equal_approx(float(entry.gain),0.3)
	check(menu_seen and studio_seen, "Menu and Studio note clocks coexist with the audio mix gains during crossfade")
	state.menu_weight = 0.0
	state.studio_weight = 0.0
	check(Song._visual_note_clock_projection(state).is_empty(), "Inaudible Studio and menu layers expose no note clocks")
	# Pool selection changes on the mix cursor. The listener may still hear the
	# previous arrangement for one output-latency interval after that boundary.
	state.studio_weight = 1.0
	state.studio_index = 2
	state.studio_previous_index = 1
	state.studio_switch_seconds = Map.LENGTH
	state.menu_seconds = Map.LENGTH - 0.01
	var before_switch: Array = Song._visual_note_clock_projection(state)
	check(before_switch.size() == 1 and before_switch[0].timeline == &"studio_1", "Outgoing Studio arrangement remains selected until its switch is audible")
	state.menu_seconds = Map.LENGTH + 0.05
	var after_switch: Array = Song._visual_note_clock_projection(state)
	check(after_switch.size() == 1 and after_switch[0].timeline == &"studio_2" and is_equal_approx(float(after_switch[0].get("start_seconds",-1.0)),Map.LENGTH), "Incoming Studio clock records the actual audible switch boundary")
	var prior := root.get_node_or_null("Soundtrack")
	if prior != null:
		root.remove_child(prior)
		prior.queue_free()
	var song := ClockStub.new()
	song.name = "Soundtrack"
	root.add_child(song)
	var circuit: Control = Circuits.new()
	circuit.size = Vector2(1280,720)
	root.add_child(circuit)
	for frame in 3: await process_frame
	circuit.set_process(false)
	circuit._quiet = false
	for index in 6:
		var id := StringName("studio_%d" % index)
		circuit._note_timelines.clear()
		var bass := 0
		var hook := 0
		var duplicates := 0
		for tick in range(0,ceili(Map.LENGTH * 12.0) + 1):
			var seconds := minf(float(tick) / 12.0, Map.LENGTH - 1.0 / Map.SAMPLE_RATE)
			song.clocks.assign([clock(id,seconds)])
			var events: Variant = circuit._music_note_events()
			if events is Array:
				for event: Dictionary in events:
					if StringName(event.get("kind", &"")) == &"bass" and int(event.get("color_index",-1)) == 1: bass += 1
					if StringName(event.get("kind", &"")) in [&"hook", &"chord"] and int(event.get("color_index",-1)) == 0: hook += 1
			var repeated: Variant = circuit._music_note_events()
			if repeated is Array: duplicates += repeated.size()
		check(bass > 0 and hook > 0, "Studio variation %d supplies both orange bass and blue hook notes" % index)
		check(duplicates == 0, "Studio variation %d does not replay notes at the same playback position" % index)
	circuit._note_timelines.clear()
	song.clocks.assign([clock(&"studio_0",0.0)])
	circuit._music_note_events()
	circuit._quiet = true
	song.clocks.assign([clock(&"studio_0",5.0)])
	var muted: Variant = circuit._music_note_events()
	check(muted is Array and muted.is_empty(), "Muted Studio advances silently without colored notes")
	circuit._quiet = false
	var resumed: Variant = circuit._music_note_events()
	check(resumed is Array and resumed.is_empty(), "Unmuting at the same cursor never replays silent notes")
	song.clocks.clear()
	check(circuit._music_note_events() == null, "An unidentified/stopped track uses neutral fallback")
	# Synthetic frame-zero notes make switch admission test independent of any
	# particular musical arrangement and its first onset.
	circuit._studio_note_data = {"sample_rate":Map.SAMPLE_RATE, "loop_frames":Map.FRAMES,
		"tracks": {"studio_0":{"bass":[[0,36,100]],"hook":[[0,60,100]]},
			"studio_1":{"bass":[[0,40,100]],"hook":[[0,64,100]]}}}
	circuit._note_timelines.clear()
	song.clocks.assign([clock(&"studio_0",Map.LENGTH - 0.01)])
	circuit._music_note_events()
	var incoming := clock(&"studio_1",Map.LENGTH + 0.05)
	incoming["start_seconds"] = Map.LENGTH
	song.clocks.assign([incoming])
	var switched: Variant = circuit._music_note_events()
	var switch_bass := 0
	var switch_hook := 0
	if switched is Array:
		for event: Dictionary in switched:
			if absf(float(event.get("absolute_time",-10.0)) - Map.LENGTH) > 0.0001: continue
			if StringName(event.kind) == &"bass" and int(event.pitch) == 40: switch_bass += 1
			if StringName(event.kind) in [&"hook",&"chord"] and int(event.pitch) == 64: switch_hook += 1
	check(switch_bass == 1 and switch_hook == 1, "New Studio arrangement admits each frame-zero note once after a delayed switch frame")
	var switch_repeat: Variant = circuit._music_note_events()
	check(switch_repeat is Array and switch_repeat.is_empty(), "Studio switch frame-zero notes are never replayed")
	circuit._note_timelines.clear()
	incoming.seconds = Map.LENGTH + 5.0
	song.clocks.assign([incoming])
	var midloop: Variant = circuit._music_note_events()
	check(midloop is Array and midloop.is_empty(), "Attaching mid-loop never replays notes from an earlier scene")
	circuit.free()
	song.free()
	print("STUDIO_VISUALIZER_NOTES checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
