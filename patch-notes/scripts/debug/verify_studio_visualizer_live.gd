extends SceneTree

## Native audio/renderer acceptance, isolated profile and no gameplay save.
const Circuits := preload("res://scripts/ui/menu_circuit_background.gd")
var failures := 0
var checks := 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func run() -> void:
	var song = root.get_node("Soundtrack")
	var music_bus := AudioServer.get_bus_index(&"Music")
	var previous_mute := AudioServer.is_bus_mute(music_bus)
	AudioServer.set_bus_mute(music_bus,false)
	var player_id: int = song.player.get_instance_id()
	var background := ColorRect.new()
	background.color = Color("101116")
	root.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var circuit: Control = Circuits.new()
	circuit.size = Vector2(1152,648)
	circuit.readability_right = 0.0
	root.add_child(circuit)
	await process_frame
	circuit.set_active(true)
	check(song.request_theme(&"studio",true), "Real Soundtrack accepts Studio theme")
	var deadline := Time.get_ticks_msec() + 10000
	while (song.blend.weight < 0.999 or song.menu_blend.weight > 0.001) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(song.blend.weight >= 0.999 and song.menu_blend.weight <= 0.001, "Studio music becomes the audible synchronized arrangement")
	check(song.player.playing and song.player.get_instance_id() == player_id, "Switch keeps the original playing audio transport")
	circuit.field.reset()
	var peak := 0.0
	var captured := false
	deadline = Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for value in circuit.levels: peak = maxf(peak,float(value))
		var orange := 0
		var blue := 0
		for pulse in circuit.field.pulses:
			if not pulse.active or pulse.distance < 80.0 * circuit.geometry.unit: continue
			if pulse.color_index == 1: orange += 1
			if pulse.color_index == 0: blue += 1
		if orange > 0 and blue > 0 and not captured:
			await RenderingServer.frame_post_draw
			captured = root.get_texture().get_image().save_png("user://studio-visualizer-live.png") == OK
		if captured and circuit.field.trigger_counts[0] > 0 and circuit.field.trigger_counts[1] > 0 and peak > 0.01: break
	check(peak > 0.01, "Real audio produces nonzero observed Music-bus spectrum")
	check(circuit.field.trigger_counts[0] > 0, "Live Studio bass produces orange threads")
	check(circuit.field.trigger_counts[1] > 0, "Live Studio hook produces blue threads")
	check(captured, "Native screenshot captures both active Studio colors")
	var before: PackedInt32Array = circuit.field.trigger_counts.duplicate()
	AudioServer.set_bus_mute(music_bus,true)
	await create_timer(0.8).timeout
	check(circuit.field.trigger_counts == before, "Muting Studio does not produce additional colored note events")
	AudioServer.set_bus_mute(music_bus,previous_mute)
	check(song.player.playing and song.player.get_instance_id() == player_id, "The observer and mute check never replace the music player")
	print("STUDIO_VISUALIZER_LIVE checks=%d failures=%d peak=%.3f bass=%d hook=%d track=%d" % [checks,failures,peak,before[0],before[1],song.studio_pool.selected])
	circuit.free()
	background.free()
	quit(0 if failures == 0 else 1)
