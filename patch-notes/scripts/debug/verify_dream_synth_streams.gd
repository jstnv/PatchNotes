extends SceneTree

const Background := preload("res://scripts/ui/menu_circuit_background.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures += 1

func increment(counts: Dictionary, key: String) -> void:
	counts[key] = int(counts.get(key,0)) + 1

func key(kind: StringName, sample: int, pitch: int, velocity: int) -> String:
	return "%s:%d:%d:%d" % [kind,sample,pitch,velocity]

func run() -> void:
	var flow := Background.new()
	root.add_child(flow)
	flow.size = Vector2(1280,720)
	flow.set_active(true)
	flow.set_process(false)
	await process_frame
	var data: Dictionary = flow._note_data
	var frames := int(data.loop_frames)
	var expected := {}
	var index := 0
	for id in ["startup","loop_a","loop_b"]:
		var chord_max := {}
		for row: Array in data.tracks[id].bass:
			increment(expected,key(&"bass",index*frames+int(row[0]),int(row[1]),int(row[2])))
		for row: Array in data.tracks[id].chords:
			var note_key := Vector2i(int(row[0]),int(row[1]))
			chord_max[note_key] = maxi(int(row[2]),int(chord_max.get(note_key,0)))
		for note_key: Vector2i in chord_max:
			increment(expected,key(&"chord",index*frames+note_key.x,note_key.y,int(chord_max[note_key])))
		index += 1
	var actual := {}
	var all_routes_ok := true
	var no_chord_splits := true
	var total_events := 0
	var end_time := float(frames*3-1) / 48000.0
	var timeline: RefCounted = flow._make_note_timeline(&"boot", -0.000001)
	for step in range(1,ceili(end_time*30.0)+1):
		var seconds := minf(float(step)/30.0,end_time)
		var events: Array = timeline.advance(&"boot", seconds, true, 12.0)
		for event: Dictionary in events:
			increment(actual,key(StringName(event.kind),roundi(float(event.absolute_time)*48000.0),int(event.pitch),int(event.velocity)))
		total_events += events.size()
		flow.field.step(1.0/30.0,Vector3(0.5,0.5,0.5),true,events)
		for pulse in flow.field.pulses:
			if not pulse.active: continue
			if not pulse.secondary and not pulse.split:
				if pulse.color_index == 0 and pulse.route % 2 != 1: all_routes_ok = false
				if pulse.color_index == 1 and pulse.route % 2 != 0: all_routes_ok = false
			if pulse.color_index == 0 and pulse.allow_split: no_chord_splits = false
	check(actual == expected,"Startup, loop A and loop B retain every distinct note and combine exact duplicate chord onsets")
	check(flow.field.trigger_counts[0] + flow.field.trigger_counts[1] == total_events,"Every scheduled note is admitted to the bounded field")
	check(all_routes_ok,"All note-driven threads use their instrument starting lanes")
	check(no_chord_splits,"Every active blue note remains a single unsplit thread")
	print("NOTE_STREAMS checks=%d failures=%d events=%d" % [checks,failures,total_events])
	flow.free()
	quit(failures)
