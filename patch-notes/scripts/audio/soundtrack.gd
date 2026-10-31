extends Node

signal presentation_resumed(skipped_beats: int)

const Grid := preload("res://scripts/audio/music_grid.gd")
const Map := preload("res://scripts/audio/theme_map.gd")
const Blend := preload("res://scripts/audio/theme_blend.gd")
const A := Map.MAIN_A
const B := Map.MAIN_B
const PAUSE_FADE := 0.9
const PAUSE_REVERB_WET := 0.38
const OPENER_FADE := 0.035
var player: AudioStreamPlayer
var themes: AudioStreamSynchronized
var grid := Grid.new()
var blend := Blend.new()
var menu_blend := Blend.new()
var requested_theme: StringName = &"menu"
var output_latency := 0.0
var manually_paused := false
var last_sample_usec := 0
var _applied_weight := -1.0
var _applied_menu_weight := -1.0
var _applied_opener_weight := -1.0
var opener_retired := false
var pause_reverb: AudioEffectReverb
var pause_weight := 0.0
var _tree_was_paused := false
var _pause_started := 0.0
var _effect_tick_usec := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100
	DemoSettingsStore.apply_audio(DemoSettingsStore.read_settings().values)
	_build_pause_effects()
	player = AudioStreamPlayer.new()
	# The transport owns its pause behavior directly, including under scene
	# pause notifications. Esc changes the Music bus treatment, not playback.
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = &"Music"
	add_child(player)
	var path := B if ProjectSettings.get_setting("audio/soundtrack/prototype_variant", "A") == "B" else A
	var main := _loop(path)
	var studio := _loop(Map.STUDIO)
	var menu := _loop(Map.MENU)
	var opener := _loop(Map.MENU_OPENER)
	if main == null or studio == null or menu == null or opener == null: return
	# One audio playback owns all WAVs. Even the inaudible arrangements keep
	# running at the identical sample/bar offset; transitions never seek/restart.
	themes = AudioStreamSynchronized.new()
	themes.stream_count = 4
	themes.set_sync_stream(0, main)
	themes.set_sync_stream(1, studio)
	themes.set_sync_stream(2, menu)
	themes.set_sync_stream(3, opener)
	menu_blend.requested = 1.0
	menu_blend.weight = 1.0
	menu_blend.fade_from = 1.0
	menu_blend.fade_to = 1.0
	_apply_blend(0.0, 1.0, 1.0)
	player.stream = themes
	output_latency = AudioServer.get_output_latency()
	player.play()
	AudioServer.bus_layout_changed.connect(func(): output_latency = AudioServer.get_output_latency())

func _loop(path: String) -> AudioStreamWAV:
	var source := load(path) as AudioStreamWAV
	if not Map.compatible(source):
		push_error("Soundtrack does not match the shared time map: " + path)
		return null
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = Map.FRAMES
	return stream

func request_theme(theme: StringName, quick_entry: bool = false) -> bool:
	if theme not in [&"menu", &"main", &"studio"] or themes == null: return false
	presentation_seconds()
	var leaving_menu := requested_theme == &"menu" and theme == &"studio"
	requested_theme = theme
	# Schedule against the mix cursor, not the already-heard cursor; output
	# latency must not make the music change one buffer late on purpose.
	blend.request(theme == &"studio", grid.mix_seconds, quick_entry and theme == &"studio")
	menu_blend.request(theme == &"menu", grid.mix_seconds, quick_entry and leaving_menu)
	return true

func _opener_weight() -> float:
	if opener_retired: return 0.0
	var seconds := grid.mix_seconds
	if seconds >= Map.STEPS_PER_LOOP * Map.STEP or (requested_theme != &"menu" and menu_blend.weight <= 0.0):
		opener_retired = true
		return 0.0
	return clampf((Map.STEPS_PER_LOOP * Map.STEP - seconds) / OPENER_FADE, 0.0, 1.0)

func _apply_blend(weight: float, menu_weight: float = -1.0, opener_weight: float = -1.0) -> void:
	if menu_weight < 0.0: menu_weight = menu_blend.weight
	if opener_weight < 0.0: opener_weight = _opener_weight()
	if themes == null or (weight == _applied_weight and menu_weight == _applied_menu_weight and opener_weight == _applied_opener_weight): return
	_applied_weight = weight
	_applied_menu_weight = menu_weight
	_applied_opener_weight = opener_weight
	themes.set_sync_stream_volume(0, linear_to_db((1.0 - menu_weight) * (1.0 - weight)))
	themes.set_sync_stream_volume(1, linear_to_db((1.0 - menu_weight) * weight))
	themes.set_sync_stream_volume(2, linear_to_db(menu_weight * (1.0 - opener_weight)))
	themes.set_sync_stream_volume(3, linear_to_db(menu_weight * opener_weight))

func _build_pause_effects() -> void:
	# Music only: settings continue to own bus volume/mute; SFX stays separate.
	pause_reverb = AudioEffectReverb.new()
	pause_reverb.room_size = 0.65
	pause_reverb.damping = 0.45
	pause_reverb.predelay_msec = 35.0
	pause_reverb.predelay_feedback = 0.2
	pause_reverb.spread = 0.8
	var bus := AudioServer.get_bus_index(&"Music")
	AudioServer.add_bus_effect(bus, pause_reverb)
	_apply_pause_effects()

func _apply_pause_effects() -> void:
	# Keep the full original track; pause changes only the room's wet signal.
	pause_reverb.dry = 1.0
	# Ease the room in/out over real time. Reversing pause reuses the current
	# progress so rapid toggles cannot reset or jump the wet signal.
	pause_reverb.wet = PAUSE_REVERB_WET * smoothstep(0.0, 1.0, pause_weight)
	var bus := AudioServer.get_bus_index(&"Music")
	if bus < 0: return
	for i in range(AudioServer.get_bus_effect_count(bus)):
		if AudioServer.get_bus_effect(bus, i) == pause_reverb:
			AudioServer.set_bus_effect_enabled(bus, i, pause_weight > 0.0)

func begin_gameplay_pause() -> void:
	# Esc is a gameplay-only pause. Clear any latched transport pause now,
	# after SceneTree sends its notifications, without seeking or restarting.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	if not is_instance_valid(player): return
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	set_paused(false)

func _process(_delta: float) -> void:
	# Bus transitions follow real time even if gameplay time_scale is zero.
	var tick := Time.get_ticks_usec()
	var delta := (tick - _effect_tick_usec) / 1000000.0 if _effect_tick_usec > 0 else 0.0
	_effect_tick_usec = tick
	# Esc pauses gameplay, never the shared arrangement transport. The explicit
	# transport-stop seam remains available for backend tests/device suspension.
	var should_pause := manually_paused
	if should_pause != player.stream_paused:
		if should_pause: presentation_seconds()
		player.stream_paused = should_pause
	var now := presentation_seconds()
	var tree_paused := get_tree().paused
	if tree_paused != _tree_was_paused:
		_tree_was_paused = tree_paused
		if tree_paused:
			_pause_started = now
		else:
			# Every visual consumer gets the same whole-subdivision shift. Keep
			# its frozen pose until that phase of the still-running music returns.
			presentation_resumed.emit(ceili(maxf(0.0, now - _pause_started) / Map.STEP))
	var weight := move_toward(pause_weight, 1.0 if tree_paused else 0.0, delta / PAUSE_FADE)
	if weight != pause_weight:
		pause_weight = weight
		_apply_pause_effects()
	_apply_blend(blend.sample(grid.mix_seconds), menu_blend.sample(grid.mix_seconds), _opener_weight())

func set_paused(value: bool) -> void:
	# Sample the stopped state before resuming so time spent with no audio
	# processing is never miscounted as completed music loops.
	if value or manually_paused or player.stream_paused: presentation_seconds()
	manually_paused = value
	player.stream_paused = value

func _exit_tree() -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	var bus := AudioServer.get_bus_index(&"Music")
	if bus >= 0:
		for i in range(AudioServer.get_bus_effect_count(bus) - 1, -1, -1):
			if AudioServer.get_bus_effect(bus, i) == pause_reverb:
				AudioServer.remove_bus_effect(bus, i)

func presentation_seconds() -> float:
	if not is_instance_valid(player) or not player.has_stream_playback(): return grid.seconds
	var ticks := Time.get_ticks_usec()
	var elapsed := (ticks - last_sample_usec) / 1000000.0 if last_sample_usec > 0 else 0.0
	last_sample_usec = ticks
	var position := player.get_playback_position()
	var loops: int = grid.unwrap(position, player.stream.get_length(), elapsed, player.stream_paused)
	return grid.sample(position, loops,
		player.stream.get_length(), AudioServer.get_time_since_last_mix(), output_latency, player.stream_paused)
