extends SceneTree

## Audio-note observer regression. Uses an isolated profile and never loads a save.
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
		"studio_weight": 0.0, "studio_index": 0, "menu_seconds": 7.25,
		"main_variant": "a"}
	for variant in ["a", "b"]:
		state.main_variant = variant
		var projected: Array = Song._visual_note_clock_projection(state)
		var found := false
		for entry: Dictionary in projected:
			if entry.timeline == StringName("production_" + variant) and is_equal_approx(float(entry.seconds), 7.25) and is_equal_approx(float(entry.gain), 1.0): found = true
		check(found, "Production %s uses its audible transport at full gain" % variant)
	state.main_variant = "a"
	state.menu_weight = 0.2
	state.studio_weight = 0.5
	var fading: Array = Song._visual_note_clock_projection(state)
	var production_gain := -1.0
	var studio_gain := -1.0
	var menu_gain := -1.0
	for entry: Dictionary in fading:
		if entry.timeline == &"production_a": production_gain = float(entry.gain)
		if entry.timeline == &"studio_0": studio_gain = float(entry.gain)
		if entry.timeline == &"menu": menu_gain = float(entry.gain)
	check(is_equal_approx(production_gain, 0.4) and is_equal_approx(studio_gain, 0.4) and is_equal_approx(menu_gain, 0.2), "Crossfade exposes each arrangement with its actual gain")
	state.menu_weight = 0.0
	state.studio_weight = 1.0
	var studio_only: Array = Song._visual_note_clock_projection(state)
	var production_present := false
	for entry: Dictionary in studio_only:
		if String(entry.timeline).begins_with("production_"): production_present = true
	check(not production_present, "An inaudible production arrangement has no active note clock")
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
	for variant in ["a", "b"]:
		var id := StringName("production_" + variant)
		circuit._note_timelines.clear()
		var bass := 0
		var hook := 0
		var repeated := 0
		for tick in range(0,ceili(Map.LENGTH * 12.0) + 1):
			var seconds := minf(float(tick) / 12.0, Map.LENGTH - 1.0 / Map.SAMPLE_RATE)
			song.clocks.assign([clock(id,seconds)])
			var events: Variant = circuit._music_note_events()
			if events is Array:
				for event: Dictionary in events:
					if StringName(event.get("kind", &"")) == &"bass" and int(event.get("color_index", -1)) == 1: bass += 1
					if StringName(event.get("kind", &"")) in [&"hook", &"chord"] and int(event.get("color_index", -1)) == 0: hook += 1
			var duplicate: Variant = circuit._music_note_events()
			if duplicate is Array: repeated += duplicate.size()
		check(bass > 0 and hook > 0, "Production %s produces orange bass and blue hook notes" % variant)
		check(repeated == 0, "Production %s does not replay notes at the same cursor" % variant)
		circuit._quiet = true
		song.clocks.assign([clock(id,Map.LENGTH + 5.0)])
		var muted: Variant = circuit._music_note_events()
		check(muted is Array and muted.is_empty(), "Production %s advances silently while muted" % variant)
		circuit._quiet = false
		var resumed: Variant = circuit._music_note_events()
		check(resumed is Array and resumed.is_empty(), "Production %s does not replay muted notes" % variant)
		circuit._note_timelines.clear()
		song.clocks.assign([clock(id,Map.LENGTH + 8.0)])
		var attached: Variant = circuit._music_note_events()
		check(attached is Array and attached.is_empty(), "Production %s mid-loop attachment skips prior notes" % variant)
	circuit.free()
	song.free()
	print("PRODUCTION_VISUALIZER_NOTES checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
