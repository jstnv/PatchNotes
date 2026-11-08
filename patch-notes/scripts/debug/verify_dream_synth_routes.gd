extends SceneTree

const Field := preload("res://scripts/ui/circuit_pulse_field.gd")
const Geometry := preload("res://scripts/ui/circuit_geometry.gd")
const Tuning := preload("res://scripts/ui/circuit_flow_settings.gd")
const Background := preload("res://scripts/ui/menu_circuit_background.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func run() -> void:
	var graph := Geometry.new()
	graph.rebuild(Vector2(1280, 720))
	var config := Tuning.new()
	config.branching_probability = 1.0
	var field := Field.new()
	field.bind(graph, config)
	var bass_routes := {}
	var chord_routes := {}
	for pitch in 128:
		field.reset()
		var first_bass = field.spawn_note(&"bass", pitch)
		var first_chord = field.spawn_note(&"chord", pitch)
		bass_routes[first_bass.route] = true
		chord_routes[first_chord.route] = true
	var disjoint := true
	for route in bass_routes:
		if chord_routes.has(route): disjoint = false
	check(disjoint and bass_routes.size() > 1 and chord_routes.size() > 1, "Bass and chord notes start from distinct route sets")
	check(graph.routes[2].get_closest_point(graph.routes[3].sample_baked(graph.routes[3].get_baked_length() * 0.8)).distance_to(graph.routes[3].sample_baked(graph.routes[3].get_baked_length() * 0.8)) < 3.0, "Different starting paths may merge or intersect")
	field.reset()
	var chord = field.spawn_note(&"chord", 60)
	var fork_route := -1
	for pitch in 128:
		field.reset()
		chord = field.spawn_note(&"chord", pitch)
		if graph.forks.has(chord.route):
			fork_route = chord.route
			break
	check(fork_route >= 0, "A chord can use a route with a junction")
	if fork_route >= 0:
		chord.distance = float(graph.forks[fork_route].distance) - 1.0
		field.step(0.1, Vector3.ONE, true, [])
		check(field.count() == 1 and field.total_splits == 0, "A chord note never creates a second thread at a junction")
	field.reset()
	var bass = field.spawn_note(&"bass", 51)
	check(graph.forks.has(bass.route), "A bass note can use a route with a junction")
	if graph.forks.has(bass.route):
		bass.distance = float(graph.forks[bass.route].distance) - 1.0
		field.step(0.1, Vector3.ONE, true, [])
		check(field.total_splits == 1, "Bass threads retain their existing junction behavior")
	var background := Background.new()
	background._note_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/boot/sequence_v1/menu_visual_notes.json"))
	var all_tracks: Dictionary = background._note_data.tracks
	for id in all_tracks:
		var raw: Array = all_tracks[id].chords
		var unique := {}
		for row: Array in raw:
			var key := "%d:%d" % [int(row[0]), int(row[1])]
			unique[key] = maxi(int(row[2]), int(unique.get(key, 0)))
		var events: Array = background._note_events(id)
		var seen := {}
		var correct := true
		for event: Dictionary in events:
			if event.kind != &"chord": continue
			var key := "%d:%d" % [roundi(float(event.time) * 48000.0), int(event.pitch)]
			if seen.has(key) or not unique.has(key) or int(event.velocity) != int(unique[key]): correct = false
			seen[key] = true
		check(correct and seen.size() == unique.size(), str(id) + " emits one chord thread per simultaneous pitch with strongest velocity")
	background._note_data = {"sample_rate":48000, "tracks":{"fixture":{"bass":[[0,36,90]], "chords":[[0,60,10],[0,60,100],[20,60,80],[0,64,50]]}}}
	var fixture: Array = background._note_events("fixture",1.0)
	check(fixture.size() == 4, "Distinct simultaneous pitches and later repeated notes remain separate")
	check(fixture[1].pitch == 60 and fixture[1].velocity == 100 and is_equal_approx(fixture[1].time,1.0), "Duplicate note keeps strongest velocity and playback offset")
	field.reset()
	field.step(0.1,Vector3.ONE,true,null)
	var only_neutral := field.count() > 0
	for pulse in field.pulses:
		if pulse.active and pulse.color_index != 2: only_neutral = false
	check(only_neutral,"Unknown audio falls back to neutral threads rather than inventing bass or chord notes")
	field.reset()
	field.step(0.1,Vector3.ZERO,false,null)
	only_neutral = field.count() > 0
	for pulse in field.pulses:
		if pulse.active and pulse.color_index != 2: only_neutral = false
	check(only_neutral and field.fallback and field.luminosity < 0.2,"Muted fallback stays subdued and neutral")
	field.reset()
	field.step(0.1,Vector3.ZERO,false,[])
	check(field.count() == 0,"A muted known track does not invent synth notes")
	background.free()
	print("NOTE_ROUTES checks=%d failures=%d" % [checks, failures])
	quit(failures)
