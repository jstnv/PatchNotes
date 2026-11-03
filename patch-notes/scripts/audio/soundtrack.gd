extends Node

signal presentation_resumed(skipped_beats: int)
signal boot_switch_started
signal boot_menu_started

const Grid := preload("res://scripts/audio/music_grid.gd")
const Map := preload("res://scripts/audio/theme_map.gd")
const Blend := preload("res://scripts/audio/theme_blend.gd")
const StudioPool := preload("res://scripts/audio/studio_pool.gd")
const BootClock := preload("res://scripts/audio/boot_sequence_clock.gd")
const BOOT_SEQUENCE := "res://assets/boot/sequence_v1/startup_ab_continuous.wav"
const BOOT_SWITCH_MENU := "res://assets/boot/sequence_v1/switch_menu_continuous.wav"
const STUDIO_STREAM_INDICES := [1, 4, 5, 6, 7, 8]
const A := Map.MAIN_A
const B := Map.MAIN_B
const PAUSE_FADE := 0.9
const PAUSE_REVERB_WET := 0.38
const OPENER_FADE := 0.035
const BOOT_CROSSFADE := 0.18
var player: AudioStreamPlayer
var _boot_tail: AudioStreamPlayer
var themes: AudioStreamSynchronized
var grid := Grid.new()
var blend := Blend.new()
var menu_blend := Blend.new()
var studio_pool := StudioPool.new()
var studio_pool_active := false
var requested_theme: StringName = &"menu"
var output_latency := 0.0
var manually_paused := false
var last_sample_usec := 0
var _applied_weight := -1.0
var _applied_menu_weight := -1.0
var _applied_opener_weight := -1.0
var _applied_studio_index := -1
var opener_retired := false
var pause_reverb: AudioEffectReverb
var pause_weight := 0.0
var _tree_was_paused := false
var _pause_started := 0.0
var _effect_tick_usec := 0
var boot_phase: StringName = &""
var _boot_grid := Grid.new()
var _boot_clock := BootClock.new()
var _boot_last_usec := 0
var _boot_track := -1
var _boot_target := -1.0
var _boot_switch_lateness := 0.0
var _boot_previous_position := -1.0
var _boot_laps := 0
var _boot_switch_stream: AudioStreamWAV

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
	_boot_tail = AudioStreamPlayer.new()
	_boot_tail.process_mode = Node.PROCESS_MODE_ALWAYS
	_boot_tail.bus = &"Music"
	add_child(_boot_tail)
	var path := B if ProjectSettings.get_setting("audio/soundtrack/prototype_variant", "A") == "B" else A
	var main := _loop(path)
	var studio_streams: Array[AudioStreamWAV] = []
	for studio_path: String in Map.STUDIO_POOL:
		var studio_stream := _loop(studio_path)
		if studio_stream == null: return
		studio_streams.append(studio_stream)
	var menu := _loop(Map.MENU)
	var opener := _loop(Map.MENU_OPENER)
	if main == null or menu == null or opener == null: return
	# One audio playback owns all WAVs. Even the inaudible arrangements keep
	# running at the identical sample/bar offset; transitions never seek/restart.
	themes = AudioStreamSynchronized.new()
	themes.stream_count = 9
	themes.set_sync_stream(0, main)
	for i in studio_streams.size():
		themes.set_sync_stream(STUDIO_STREAM_INDICES[i], studio_streams[i])
	themes.set_sync_stream(2, menu)
	themes.set_sync_stream(3, opener)
	menu_blend.requested = 1.0
	menu_blend.weight = 1.0
	menu_blend.fade_from = 1.0
	menu_blend.fade_to = 1.0
	_apply_blend(0.0, 1.0, 1.0)
	player.stream = themes
	player.finished.connect(_boot_audio_finished)
	output_latency = AudioServer.get_output_latency()
	# Wait until the opening scene exists: the boot screen cues the transport
	# at its first visible pixel, while direct gameplay/debug launches still play.
	if get_tree().get_script() != null:
		player.play()
	else:
		_start_for_current_scene.call_deferred()
	AudioServer.bus_layout_changed.connect(func(): output_latency = AudioServer.get_output_latency())

func _start_for_current_scene() -> void:
	if get_tree().root.get_node_or_null("BootScreen") == null and not player.playing:
		player.play()

func begin_boot_audio() -> bool:
	var source := load(BOOT_SEQUENCE) as AudioStreamWAV
	var switch_source := load(BOOT_SWITCH_MENU) as AudioStreamWAV
	if source == null or switch_source == null: return false
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = Map.FRAMES
	stream.loop_end = Map.FRAMES * 3
	_boot_switch_stream = switch_source.duplicate() as AudioStreamWAV
	_boot_switch_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_boot_switch_stream.loop_begin = BootClock.SWITCH_FRAMES
	_boot_switch_stream.loop_end = BootClock.SWITCH_FRAMES + Map.FRAMES
	_boot_track = 0
	_boot_target = -1.0
	_boot_switch_lateness = 0.0
	_boot_last_usec = 0
	_boot_grid = Grid.new()
	_boot_previous_position = -1.0
	_boot_laps = 0
	boot_phase = &"loop"
	player.stream = stream
	player.play()
	return true

func _boot_seconds() -> float:
	if not player.has_stream_playback(): return _boot_grid.mix_seconds
	var tick := Time.get_ticks_usec()
	var elapsed := float(tick - _boot_last_usec) / 1000000.0 if _boot_last_usec > 0 else 0.0
	_boot_last_usec = tick
	var position := player.get_playback_position()
	if _boot_previous_position >= 0.0 and not player.stream_paused:
		_boot_laps += maxi(0, roundi((elapsed - (position - _boot_previous_position)) / (2.0 * Map.LENGTH)))
	_boot_previous_position = position
	_boot_grid.mix_seconds = maxf(_boot_grid.mix_seconds, position + _boot_laps * 2.0 * Map.LENGTH + AudioServer.get_time_since_last_mix())
	return _boot_grid.mix_seconds

func request_boot_switch() -> bool:
	if boot_phase != &"loop" or _boot_target >= 0.0: return false
	_boot_target = _boot_clock.next_beat(_boot_seconds())
	return true

func boot_switch_seconds() -> float:
	if boot_phase == &"menu": return _boot_clock.switch_length()
	if boot_phase != &"switch" or not player.has_stream_playback(): return 0.0
	# Visual milestones follow the audible cursor, not audio already queued in
	# the output device's latency buffer.
	return clampf(player.get_playback_position() + AudioServer.get_time_since_last_mix() - output_latency, 0.0, _boot_clock.switch_length())

func _update_boot_audio() -> void:
	if boot_phase == &"switch":
		if _boot_tail.playing:
			var fade := clampf(boot_switch_seconds() / BOOT_CROSSFADE, 0.0, 1.0)
			_boot_tail.volume_db = linear_to_db(cos(fade * PI * 0.5))
			player.volume_db = linear_to_db(sin(fade * PI * 0.5))
			if fade >= 1.0:
				_boot_tail.stop()
				_boot_tail.stream = null
				player.volume_db = 0.0
		if boot_switch_seconds() >= _boot_clock.switch_length():
			boot_phase = &"menu"
			grid = Grid.new()
			last_sample_usec = 0
			boot_menu_started.emit()
		return
	if boot_phase != &"loop": return
	var now := _boot_seconds()
	_boot_track = _boot_clock.track_for_loop(floori(now / (Map.STEPS_PER_LOOP * Map.STEP)))
	if _boot_target >= 0.0 and now >= _boot_target:
		_boot_switch_lateness = now - _boot_target
		if _boot_switch_stream == null:
			push_error("Cannot load boot switch track")
			return
		_boot_tail.stream = player.stream
		_boot_tail.volume_db = 0.0
		_boot_tail.play(player.get_playback_position())
		player.stop()
		player.stream = _boot_switch_stream
		player.volume_db = -80.0
		boot_phase = &"switch"
		player.play()
		boot_switch_started.emit()

func _boot_audio_finished() -> void:
	# Boot streams loop at explicit sample boundaries; no completion callback
	# should replace the switch/menu stream at its splice point.
	pass

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

func request_theme(theme: StringName, quick_entry: bool = false, pool_active: bool = true) -> bool:
	if theme not in [&"menu", &"main", &"studio"] or themes == null: return false
	if boot_phase in [&"loop", &"switch"]:
		return theme == &"menu"
	if boot_phase == &"menu" and theme != &"menu":
		_handoff_boot_menu()
	presentation_seconds()
	var leaving_menu := requested_theme == &"menu" and theme == &"studio"
	requested_theme = theme
	studio_pool_active = theme == &"studio" and pool_active
	# Schedule against the mix cursor, not the already-heard cursor; output
	# latency must not make the music change one buffer late on purpose.
	blend.request(theme == &"studio", grid.mix_seconds, quick_entry and theme == &"studio")
	menu_blend.request(theme == &"menu", grid.mix_seconds, quick_entry and leaving_menu)
	return true

func _handoff_boot_menu() -> void:
	# The switch and first menu loop are one gapless PCM stream. Move to the
	# synchronized gameplay transport at the same musical offset when leaving.
	presentation_seconds()
	var offset := fposmod(maxf(0.0, player.get_playback_position() - _boot_clock.switch_length()), Map.LENGTH)
	player.stop()
	player.stream = themes
	boot_phase = &""
	last_sample_usec = 0
	grid.previous_position = offset
	player.play(offset)

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
	if themes == null or (weight == _applied_weight and menu_weight == _applied_menu_weight and opener_weight == _applied_opener_weight and studio_pool.selected == _applied_studio_index): return
	_applied_weight = weight
	_applied_menu_weight = menu_weight
	_applied_opener_weight = opener_weight
	_applied_studio_index = studio_pool.selected
	themes.set_sync_stream_volume(0, linear_to_db((1.0 - menu_weight) * (1.0 - weight)))
	var studio_gain := (1.0 - menu_weight) * weight
	for i in STUDIO_STREAM_INDICES.size():
		themes.set_sync_stream_volume(STUDIO_STREAM_INDICES[i], linear_to_db(studio_gain if i == studio_pool.selected else 0.0))
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
	if boot_phase in [&"loop", &"switch"]:
		_update_boot_audio()
		return
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
	var studio_weight: float = blend.sample(grid.mix_seconds)
	var menu_weight: float = menu_blend.sample(grid.mix_seconds)
	studio_pool.on_loop(grid.loops, studio_pool_active and studio_weight == 1.0 and menu_weight == 0.0)
	_apply_blend(studio_weight, menu_weight, _opener_weight())

func set_paused(value: bool) -> void:
	# Sample the stopped state before resuming so time spent with no audio
	# processing is never miscounted as completed music loops.
	if value or manually_paused or player.stream_paused: presentation_seconds()
	manually_paused = value
	player.stream_paused = value

func _exit_tree() -> void:
	if is_instance_valid(_boot_tail):
		_boot_tail.stop()
		_boot_tail.stream = null
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
	var length := player.stream.get_length()
	if boot_phase == &"menu":
		position = maxf(0.0, position - _boot_clock.switch_length())
		length = Map.LENGTH
	var loops: int = grid.unwrap(position, length, elapsed, player.stream_paused)
	return grid.sample(position, loops,
		length, AudioServer.get_time_since_last_mix(), output_latency, player.stream_paused)
