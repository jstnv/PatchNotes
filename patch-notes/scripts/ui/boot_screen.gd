extends Control

const INTRO_LENGTH := 11.8
const START_FADE_END := 7.5
const BLANK_SECONDS := 0.18
const FRAME_RATE := 30.0
const FIRST_VISIBLE_FRAME := 2
const FINAL_LOGO_FRAME := 202
const FRAMES_PER_SHEET := 24
const REFERENCE_SIZE := Vector2(1600, 900)
const JOOCE_DURATION := 6.0
const INTRO_DELAY := 1.0
const Circuits := preload("res://scripts/ui/menu_circuit_background.gd")
const Wave := preload("res://scripts/ui/title_button_wave.gd")

var elapsed := 0.0
var music_started := false
var leaving := false
var interactive := false
var circuits: Control
var picture: TextureRect
var atlas := AtlasTexture.new()
var sheets: Array[Texture2D] = []
var reveal_odd_sheets: Array[Texture2D] = []
var button_box: VBoxContainer
var start_button: Button
var wave: Node
var exit_progress := 0.0
var exit_start_x := 0.0
var jooce_atlas := AtlasTexture.new()
var jooce_picture: TextureRect
var jooce_sheets: Array[Texture2D] = []
var jooce_odd_sheets: Array[Texture2D] = []
var disappear_sheets: Array[Texture2D] = []
var switch_started := false
var handed_off := false
var background: ColorRect
var prepared_game: Control
var boot_ready := false
var _boot_first_frame := true
var _background_fade_started := false
var jooce_sound: AudioStreamPlayer
var _prewarm_process_modes: Dictionary = {}

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree():
		get_tree().quit()

func _exit_tree() -> void:
	if is_instance_valid(jooce_sound):
		jooce_sound.stop()
		jooce_sound.stream = null

func _ready() -> void:
	# Restore the saved display choice before drawing the opening animation.
	DemoSettingsStore.apply_display(DemoSettingsStore.read_settings().values, get_window())
	theme = preload("res://resources/ui/onyx_theme.tres")
	FolderUI.enable_menu_gamepad()
	background = ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var soundtrack := get_node("/root/Soundtrack")
	soundtrack.boot_switch_started.connect(_on_switch_started)
	jooce_sound = AudioStreamPlayer.new()
	jooce_sound.bus = &"SFX"
	jooce_sound.stream = load("res://assets/boot/sequence_v1/jooce_audio.wav")
	add_child(jooce_sound)
	jooce_sound.finished.connect(func(): jooce_sound.stream = null)
	for i in range(1, 9):
		jooce_sheets.append(load("res://assets/boot/sequence_v1/jooce-%02d.png" % i))
		ResourceLoader.load_threaded_request("res://assets/boot/sixty-fps-v1/jooce-odd-%02d.png" % i, "Texture2D")
	for i in range(1, 8):
		disappear_sheets.append(load("res://assets/boot/sequence_v1/disappear-%02d.png" % i))
	jooce_atlas.atlas = jooce_sheets[0]
	jooce_atlas.region = Rect2(0, 0, 458, 458)
	jooce_picture = TextureRect.new()
	jooce_picture.texture = jooce_atlas
	jooce_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	jooce_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	jooce_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(jooce_picture)
	circuits = Circuits.new()
	circuits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	circuits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(circuits)
	circuits.hide()
	# The clean reveal stops on frame 202, so later atlases are never used.
	for i in range(1, 10):
		sheets.append(load("res://assets/boot/start-v10/reveal-%02d.png" % i))
	for i in range(1, 10):
		ResourceLoader.load_threaded_request("res://assets/boot/sixty-fps-v1/reveal-odd-%02d.png" % i, "Texture2D")
	atlas.atlas = sheets[0]
	atlas.region = Rect2(0, 0, 510, 250)
	picture = TextureRect.new()
	picture.texture = atlas
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.hide()
	add_child(picture)
	button_box = VBoxContainer.new()
	add_child(button_box)
	start_button = Button.new()
	start_button.text = "Start"
	start_button.theme_type_variation = &"ArcadePrimary"
	start_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	start_button.icon = load("res://assets/ui/arcade/arrows.svg")
	start_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	start_button.add_theme_constant_override("icon_max_width", 26)
	start_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.modulate.a = 0.0
	button_box.add_child(start_button)
	start_button.pressed.connect(_start_pressed)
	wave = Wave.new()
	add_child(wave)
	var buttons: Array[Button] = [start_button]
	wave.bind_buttons(button_box, buttons)
	resized.connect(_layout)
	_layout()
	# Construct the destination before the opening audio starts. This prevents
	# loading the full gameplay scene from consuming the two-second reveal.
	_prepare_destination.call_deferred()

func _prepare_destination() -> void:
	var window := get_tree().root
	window.set_meta("boot_menu_transition", true)
	prepared_game = load("res://scenes/gameplay.tscn").instantiate()
	prepared_game.process_mode = Node.PROCESS_MODE_DISABLED
	prepared_game.hide()
	window.add_child(prepared_game)
	# Some overlays intentionally process while paused. They must not receive
	# input while this destination exists invisibly behind the boot screen.
	for node: Node in prepared_game.find_children("*", "", true, false):
		if node.process_mode == Node.PROCESS_MODE_ALWAYS:
			_prewarm_process_modes[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_DISABLED
	# Extra opening frames load alongside the prewarmed destination so their
	# import/decode cost does not delay the first audio and picture unnecessarily.
	for i in range(1, 9):
		jooce_odd_sheets.append(_finish_extra_texture("res://assets/boot/sixty-fps-v1/jooce-odd-%02d.png" % i))
	for i in range(1, 10):
		reveal_odd_sheets.append(_finish_extra_texture("res://assets/boot/sixty-fps-v1/reveal-odd-%02d.png" % i))
	get_node("/root/Soundtrack").begin_boot_audio()
	jooce_sound.play()
	boot_ready = true

func _finish_extra_texture(path: String) -> Texture2D:
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		return load(path)
	var texture := ResourceLoader.load_threaded_get(path) as Texture2D
	return texture if texture != null else load(path)

func _layout() -> void:
	var factor := minf(size.x / REFERENCE_SIZE.x, size.y / REFERENCE_SIZE.y)
	var origin := (size - REFERENCE_SIZE * factor) * 0.5
	var side := minf(size.x, size.y)
	jooce_picture.position = (size - Vector2(side, side)) * 0.5
	jooce_picture.size = Vector2(side, side)
	picture.position = origin + Vector2(300, 100) * factor
	picture.size = Vector2(1020, 500) * factor
	button_box.position = origin + Vector2(546, 680) * factor
	button_box.size = Vector2(508, 80) * factor
	start_button.custom_minimum_size = Vector2(0, 80 * factor)
	circuits.readability_right = 0.0

func _process(delta: float) -> void:
	if not boot_ready: return
	if _boot_first_frame:
		_boot_first_frame = false
		return
	if leaving:
		_exit_step(delta)
		return
	elapsed += delta
	if elapsed < JOOCE_DURATION:
		var jooce_frame_60 := mini(int(elapsed * FRAME_RATE * 2.0), 359)
		var jooce_frame := jooce_frame_60 / 2
		var jooce_set := jooce_odd_sheets if jooce_frame_60 % 2 == 1 else jooce_sheets
		jooce_atlas.atlas = jooce_set[jooce_frame / FRAMES_PER_SHEET]
		var cell := jooce_frame % FRAMES_PER_SHEET
		jooce_atlas.region = Rect2((cell % 4) * 458, (cell / 4) * 458, 458, 458)
		return
	if jooce_picture.visible:
		jooce_picture.hide()
		jooce_atlas.atlas = null
		jooce_sheets.clear()
		jooce_odd_sheets.clear()
	# Use the existing one-second pause for the entire background to fade in.
	var fade := smoothstep(0.0, INTRO_DELAY, elapsed - JOOCE_DURATION)
	background.color = Color.BLACK.lerp(Color("101116"), fade)
	if not _background_fade_started:
		_background_fade_started = true
		circuits.modulate.a = 0.0
		circuits.set_active(true)
	circuits.modulate.a = fade
	if elapsed < JOOCE_DURATION + INTRO_DELAY + BLANK_SECONDS:
		return
	var intro_time := minf(elapsed - JOOCE_DURATION - INTRO_DELAY - BLANK_SECONDS, INTRO_LENGTH)
	# Later source frames contain a cropped, noninteractive Start-button
	# fragment. Hold the completed clean logo while the real button fades in.
	var frame_60 := mini(int(intro_time * FRAME_RATE * 2.0), FINAL_LOGO_FRAME * 2)
	var frame := frame_60 / 2
	var reveal_set := reveal_odd_sheets if frame_60 % 2 == 1 else sheets
	atlas.atlas = reveal_set[frame / FRAMES_PER_SHEET]
	var sheet_frame := frame % FRAMES_PER_SHEET
	atlas.region = Rect2((sheet_frame % 4) * 510, (sheet_frame / 4) * 250, 510, 250)
	if not music_started and frame >= FIRST_VISIBLE_FRAME:
		music_started = true
		picture.show()
	start_button.modulate.a = smoothstep(7.0, START_FADE_END, intro_time)
	if intro_time >= START_FADE_END and not interactive:
		interactive = true
		reveal_odd_sheets.clear()
		start_button.mouse_filter = Control.MOUSE_FILTER_STOP
		start_button.focus_mode = Control.FOCUS_ALL
		start_button.grab_focus()
	wave.advance(delta, interactive)

func _start_pressed() -> void:
	if not interactive or leaving:
		return
	if not get_node("/root/Soundtrack").request_boot_switch(): return
	leaving = true
	wave.advance(0.0, false)
	exit_start_x = start_button.position.x
	start_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_button.focus_mode = Control.FOCUS_NONE

func _on_switch_started() -> void:
	switch_started = true

func _exit_step(delta: float) -> void:
	exit_progress = minf(exit_progress + delta / 0.55, 1.0)
	var distance := maxf(0.0, size.x - button_box.global_position.x - start_button.size.x * start_button.scale.x - 24.0)
	start_button.position.x = lerpf(exit_start_x, distance, smoothstep(0.0, 1.0, exit_progress))
	start_button.modulate.a = 1.0 - exit_progress
	if switch_started:
		var soundtrack := get_node("/root/Soundtrack")
		var switch_time: float = soundtrack.boot_switch_seconds()
		if switch_time < 4.25:
			var frame := mini(int(switch_time * FRAME_RATE), 127)
			atlas.atlas = disappear_sheets[frame / FRAMES_PER_SHEET]
			var cell := frame % FRAMES_PER_SHEET
			atlas.region = Rect2((cell % 4) * 510, (cell / 4) * 250, 510, 250)
		else:
			picture.hide()
		if switch_time < soundtrack._boot_clock.logo_reveal_at() or handed_off: return
		handed_off = true
		var menu: MainMenu = prepared_game._active_phase as MainMenu
		if menu != null:
			# The prewarmed replacement is freed during adoption, so it must not
			# remain in the later list of process modes to restore.
			_prewarm_process_modes.erase(menu._visualizer)
			prepared_game.adopt_boot_circuits(circuits)
			menu._boot_resume_modes = _prewarm_process_modes.duplicate()
		else:
			for node: Node in _prewarm_process_modes:
				if is_instance_valid(node): node.process_mode = _prewarm_process_modes[node]
		_prewarm_process_modes.clear()
		prepared_game.process_mode = Node.PROCESS_MODE_INHERIT
		prepared_game.show()
		get_tree().current_scene = prepared_game
		queue_free()
