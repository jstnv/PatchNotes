extends Node

const Grid := preload("res://scripts/audio/music_grid.gd")
const A := "res://assets/audio/crunch_time_70/crunch_time_A_jazz.wav"
const B := "res://assets/audio/crunch_time_70/crunch_time_B_techno.wav"
var player: AudioStreamPlayer
var grid := Grid.new()
var output_latency := 0.0
var manually_paused := false
var last_sample_usec := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100
	DemoSettingsStore.apply_audio(DemoSettingsStore.read_settings().values)
	player = AudioStreamPlayer.new()
	player.bus = &"Music"
	add_child(player)
	var path := B if ProjectSettings.get_setting("audio/soundtrack/prototype_variant", "A") == "B" else A
	var stream := load(path).duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	player.stream = stream
	output_latency = AudioServer.get_output_latency()
	player.play()
	AudioServer.bus_layout_changed.connect(func(): output_latency = AudioServer.get_output_latency())

func _process(_delta: float) -> void:
	var should_pause := manually_paused or get_tree().paused
	if should_pause != player.stream_paused:
		if should_pause: presentation_seconds()
		player.stream_paused = should_pause
	presentation_seconds()

func set_paused(value: bool) -> void:
	if value: presentation_seconds()
	manually_paused = value
	player.stream_paused = value or get_tree().paused

func _exit_tree() -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream = null

func presentation_seconds() -> float:
	if not is_instance_valid(player) or not player.has_stream_playback(): return grid.seconds
	var ticks := Time.get_ticks_usec()
	var elapsed := (ticks - last_sample_usec) / 1000000.0 if last_sample_usec > 0 else 0.0
	last_sample_usec = ticks
	var position := player.get_playback_position()
	var loops: int = grid.unwrap(position, player.stream.get_length(), elapsed, player.stream_paused)
	return grid.sample(position, loops,
		player.stream.get_length(), AudioServer.get_time_since_last_mix(), output_latency, player.stream_paused)
