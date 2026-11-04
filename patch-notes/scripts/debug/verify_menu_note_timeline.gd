extends SceneTree

const TIMELINE_PATH := "res://scripts/ui/menu_note_timeline.gd"
const Field := preload("res://scripts/ui/circuit_pulse_field.gd")
const Geometry := preload("res://scripts/ui/circuit_geometry.gd")
const Tuning := preload("res://scripts/ui/circuit_flow_settings.gd")
const EVENTS := [
	{"time": 0.66, "pitch": 67, "kind": &"chord"},
	{"time": 0.10, "pitch": 36, "kind": &"bass"},
	{"time": 0.10, "pitch": 60, "kind": &"chord"},
	{"time": 0.10, "pitch": 64, "kind": &"chord"},
	{"time": 0.112, "pitch": 40, "kind": &"bass"},
]

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func _initialize() -> void:
	run.call_deferred()

func event_sequence(events: Array) -> Array:
	var result := []
	for event: Dictionary in events:
		result.append([int(event.get("pitch", -1)), StringName(event.get("kind", &"")), int(event.get("color_index", -1))])
	return result

func run() -> void:
	check(ResourceLoader.exists(TIMELINE_PATH), "Per-note playback timeline exists")
	if not ResourceLoader.exists(TIMELINE_PATH):
		print("MENU_NOTE_TIMELINE checks=%d failures=%d" % [checks, failures])
		quit(1)
		return
	var timeline_script: Script = load(TIMELINE_PATH)
	var timeline: RefCounted = timeline_script.new()
	var expected := [[36,&"bass",1], [60,&"chord",0], [64,&"chord",0], [40,&"bass",1], [67,&"chord",0]]
	for fps: int in [30, 60, 144]:
		timeline.configure(&"menu", EVENTS, 1.0, 0.0)
		var all: Array = []
		for frame in range(1, fps * 3 + 1):
			all.append_array(timeline.advance(&"menu", float(frame) / float(fps), true))
		check(all.size() == 15, "Every simultaneous and close-spaced note emits in three loops at %d Hz" % fps)
		var expected_three := expected + expected + expected
		check(event_sequence(all) == expected_three, "Notes retain chronological order and bass/chord colors at %d Hz" % fps)
		var times_ok := all.size() == 15
		var local_times := [0.10,0.10,0.10,0.112,0.66]
		for index in range(all.size()):
			var event: Dictionary = all[index]
			var expected_time: float = float(floori(float(index) / 5.0)) + local_times[index % 5]
			times_ok = times_ok and event.has("absolute_time") and is_equal_approx(float(event.get("absolute_time", -1)), expected_time)
		check(times_ok, "Each event carries its correct unwrapped absolute playback time at %d Hz" % fps)

	timeline.configure(&"menu", EVENTS, 1.0, 0.0)
	var simultaneous: Array = timeline.advance(&"menu", 0.1, true)
	check(event_sequence(simultaneous) == expected.slice(0,3), "Simultaneous bass and both chord notes all emit on the boundary")
	check(timeline.advance(&"menu", 0.1, true).is_empty(), "The same clock timestamp never emits twice")
	check(event_sequence(timeline.advance(&"menu", 0.12, true)) == [expected[3]], "Close-spaced next note is emitted separately")

	timeline.configure(&"menu", EVENTS, 1.0, 0.0)
	check(timeline.advance(&"menu", 2.75, true).size() == 15, "A long frame spanning multiple loops retains every note")
	timeline.configure(&"menu", EVENTS, 1.0, 0.0)
	timeline.advance(&"menu", 0.09, true)
	check(timeline.advance(&"menu", 0.70, false).is_empty(), "Muted playback emits no notes")
	check(timeline.advance(&"menu", 0.90, true).is_empty(), "Unmuting does not replay notes missed while silent")
	check(timeline.advance(&"menu", 1.12, true).size() == 4, "The next audible loop emits fresh notes")

	timeline.configure(&"menu", EVENTS, 1.0, 0.7)
	check(timeline.advance(&"menu", 0.8, true).is_empty(), "Starting midway does not replay earlier notes")
	check(timeline.advance(&"other_track", 0.9, true).is_empty(), "Mismatched track never emits stale notes")
	timeline.configure(&"other_track", EVENTS, 1.0, 0.7)
	check(timeline.advance(&"other_track", 1.12, true).size() == 4, "A newly configured track uses its own clock")
	timeline.configure(&"menu", EVENTS, 1.0, 2.0)
	check(timeline.advance(&"menu", 0.02, true).is_empty(), "A backward seek resynchronizes without a stale burst")
	check(timeline.advance(&"menu", 0.12, true).size() == 4, "Playback after a backward seek resumes at the new position")
	var zero_notes := [{"time": 0.0, "pitch": 38, "kind": &"bass"}]
	timeline.configure(&"menu", zero_notes, 1.0, -0.000001)
	check(event_sequence(timeline.advance(&"menu", 0.0, true)) == [[38,&"bass",1]], "The first bass note sounds at track time zero")
	check(event_sequence(timeline.advance(&"menu", 1.0, true)) == [[38,&"bass",1]], "A zero-time note repeats at the loop seam")
	var intro_notes := [{"time":0.0,"pitch":38,"kind":&"bass"},{"time":0.25,"pitch":60,"kind":&"chord"}]
	var alternating_notes := [{"time":0.0,"pitch":40,"kind":&"bass"},{"time":0.5,"pitch":62,"kind":&"chord"},{"time":1.0,"pitch":41,"kind":&"bass"},{"time":1.5,"pitch":65,"kind":&"chord"}]
	timeline.configure_intro(&"boot",intro_notes,1.0,alternating_notes,2.0,-0.000001)
	check(event_sequence(timeline.advance(&"boot",1.0,true)) == [[38,&"bass",1],[60,&"chord",0],[40,&"bass",1]], "Intro notes and first loop-seam bass emit once in order")
	check(event_sequence(timeline.advance(&"boot",3.0,true)) == [[62,&"chord",0],[41,&"bass",1],[65,&"chord",0],[40,&"bass",1]], "Alternating loop voices retain order and repeat at the two-loop seam")

	var graph := Geometry.new()
	graph.rebuild(Vector2(1280,720))
	var config := Tuning.new()
	config.max_pulses = 4
	var field := Field.new()
	field.bind(graph, config)
	check(field.has_method("spawn_note"), "Pulse field accepts explicit instrument note-on events")
	if field.has_method("spawn_note"):
		var primary_old = field.spawn(0, 0, false)
		var secondary_old = field.spawn(1, 0, true)
		var primary_new = field.spawn(2, 0, false)
		var secondary_new = field.spawn(3, 0, true)
		seed(991)
		var expected_game_rng := randf()
		seed(991)
		var bass = field.spawn_note(&"bass", 36)
		check(bass != null and bass == secondary_old and bass.color_index == 1 and secondary_new.active, "At cap, bass uses orange and replaces the oldest secondary")
		var chord = field.spawn_note(&"chord", 60)
		check(chord != null and chord == secondary_new and chord.color_index == 0, "At cap, chord uses blue and replaces the remaining secondary")
		var next_bass = field.spawn_note(&"bass", 40)
		check(next_bass != null and next_bass == primary_old and next_bass.color_index == 1 and primary_new.active, "At full primary capacity, the oldest primary is replaced")
		check(field.count() == 4, "Every note is admitted while pulse count remains bounded")
		var burst_admitted := true
		var before_burst: int = field.total_spawned
		for i in 10:
			var voice = field.spawn_note(&"chord", 60 + i)
			burst_admitted = burst_admitted and voice != null and voice.color_index == 0
		check(burst_admitted and field.total_spawned == before_burst + 10 and field.count() == 4, "All ten simultaneous chord voices are admitted at the pulse cap")
		check(is_equal_approx(randf(),expected_game_rng), "Note-driven effects do not consume gameplay RNG")
	print("MENU_NOTE_TIMELINE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
