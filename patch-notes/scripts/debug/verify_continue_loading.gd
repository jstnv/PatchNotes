extends "res://scripts/debug/verify_rival_gameplay_activation.gd"
const AudioMap := preload("res://scripts/audio/theme_map.gd")

var game: Control
var stages: Array[String] = []
var music: Node
var captures: Array[String] = []
var audio_trace: Array[Dictionary] = []
var load_timings: Array[Dictionary] = []
var audio_samples: Array[Dictionary] = []
var viewports: Array[Dictionary] = []
var _capture: AudioEffectCapture
var _capture_bus := -1
const STUDIO := "North Star — A Studio With A Long Name For Loading Layout Verification"

func _initialize() -> void:
	await process_frame
	create_timer(135).timeout.connect(func(): push_error("Continue loading timeout"); quit(2))
	node_added.connect(_replace_store)
	music = root.get_node("Soundtrack")
	if AudioServer.get_driver_name() != "Dummy":
		_capture = AudioEffectCapture.new()
		_capture.buffer_length = 6.0
		_capture_bus = AudioServer.get_bus_index(&"Music")
		AudioServer.add_bus_effect(_capture_bus, _capture)
	await open_game()
	game._on_studio_created(STUDIO, &"action", [], game._active_phase)
	expect(game.run_state.complete_productive_action(Callable(), 0, 0), "Fixture legally reaches second half-month")
	await process_frame
	expect(await game.checkpoints.wait_saved(), "Fixture reaches a durable second half-month before recording disk bytes")
	var saved: Dictionary = game.checkpoints.store.inspect()
	expect(saved.status == &"valid", "Fixture is a real validated Studio/world checkpoint")
	var bytes := FileAccess.get_file_as_bytes(saved.path)
	var expected_run: Dictionary = game.checkpoints.adapter.capture(game.run_state)
	await close_game()
	for size in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = size
		await open_game()
		# Settings applies its saved/default window size when HUD enters tree.
		# Apply the acceptance size afterwards, rather than capturing1280 twice.
		root.size = size
		await process_frame
		expect(root.size == size, "Actual window uses the requested supported size")
		var pixels := root.get_texture().get_size()
		viewports.append({"requested":[size.x,size.y],"window":[root.size.x,root.size.y],"initial_render_pixels":[pixels.x,pixels.y]})
		var menu: MainMenu = game._active_phase
		var transport: AudioStreamPlayer = music.player
		var stream: AudioStream = transport.stream
		var playback_id := transport.get_stream_playback().get_instance_id()
		var before: float = music.presentation_seconds()
		menu.continue_requested.emit()
		var overlay := game.get_node_or_null("ContinueLoading")
		expect(overlay != null, "Continue immediately displays a modal loading overlay")
		if overlay == null:
			await close_game()
			finish()
			return
		expect(game._loading_checkpoint and overlay.visible, "Loading guard remains active while overlay is visible")
		expect(overlay.studio_label.text == STUDIO, "Loading identifies saved Studio including Unicode")
		expect(overlay.date_label.text == "1980 · Month 1, Second Half", "Loading shows the saved year/month/half, not wall-clock date")
		menu.continue_requested.emit()
		expect(game.get_children().filter(func(n): return n.name == &"ContinueLoading").size() == 1, "Repeated Continue cannot create another loader")
		var event := InputEventKey.new()
		event.pressed = true
		event.keycode = KEY_ESCAPE
		Input.parse_input_event(event)
		game._on_studio_created("Must not replace save", &"action", [], menu)
		var rendered := false
		var last_stage := ""
		while game._loading_checkpoint:
			if overlay.visible:
				var stage: String = overlay.stage_label.text
				if not stages.has(stage): stages.append(stage)
				if stage != last_stage:
					expect(music.requested_theme == &"menu", "Menu theme remains requested through this real Continue stage")
					audio_trace.append({"stage":stage,"heard_seconds":music.presentation_seconds(),"raw_seconds":transport.get_playback_position(),"loops":music.grid.loops,"playing":transport.playing,"size":[size.x,size.y]})
					if _capture != null and _capture.get_frames_available() > 1000:
						var buffer := _capture.get_buffer(_capture.get_frames_available())
						var energy := 0.0
						for sample: Vector2 in buffer: energy += sample.length_squared()
						audio_samples.append({"stage":stage,"frames":buffer.size(),"energy":energy})
						expect(energy > 0.001, "Real audio continues producing nonzero samples between loading stages")
					last_stage = stage
				expect(music.player == transport and transport.stream == stream and transport.playing and not transport.stream_paused, "Original audio transport stays running at each loading stage")
				if not rendered and overlay._surface.modulate.a >= 0.99:
					await process_frame
					var label: Label = overlay.studio_label
					expect(label.get_line_count() >= 1 and label.get_visible_line_count() == label.get_line_count(), "Long Studio name remains fully visible")
					expect(Rect2(Vector2.ZERO,Vector2(size)).encloses(label.get_global_rect()), "Studio name fits supported viewport")
					await capture("loading-%dx%d" % [size.x,size.y])
					rendered = true
			await process_frame
		expect(game._active_phase is StudioPhase and game.project_state == null and game.active_contract_state == null, "Completed Continue reveals only the saved Studio boundary")
		expect(music.requested_theme == &"studio" and is_equal_approx(music.blend.pending_duration, AudioMap.STEP), "Studio cue begins only after Continue loading reveals Studio")
		expect(not paused and not game.pause_menu.is_open(), "Esc during loading cannot pause or open another menu")
		expect(game.run_state.get_studio_name() == STUDIO, "New Run cannot replace the restore while loading")
		expect(game.checkpoints.adapter.capture(game.run_state) == expected_run, "Presentation restores every saved player field and RNG exactly")
		expect(game.checkpoints.store.inspect().payload == saved.payload and FileAccess.get_file_as_bytes(saved.path) == bytes, "Continue does not rewrite generation bytes or repeat settlements")
		expect(music.presentation_seconds() > before and music.player == transport and transport.stream == stream, "Music clock advances across Continue without seeking/restarting")
		expect(transport.get_stream_playback().get_instance_id() == playback_id, "Continue retains actual synchronized audio playback instance")
		expect(game.get_node_or_null("ContinueLoading") == null, "Loading surface is removed after Studio is ready")
		await capture("studio-%dx%d" % [size.x,size.y])
		await close_game()
	if OS.get_environment("PN_LOADING_AUDIO_ONLY") == "1":
		finish()
		return
	await check_calendar_boundaries()
	await check_stale_preview_and_failure(saved, bytes)
	await check_teardown(saved, bytes)
	await check_new_run_after_cancel(saved)
	finish()

func open_game() -> void:
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame

func close_game() -> void:
	game.queue_free()
	await process_frame
	await process_frame

func capture(label: String) -> void:
	var output := OS.get_environment("PN_LOADING_CAPTURE_DIR")
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var path := output.path_join(label + ".png")
	expect(root.get_texture().get_image().save_png(path) == OK, "Rendered capture saved")
	captures.append(path)

func wait_loading() -> void:
	while game._loading_checkpoint: await process_frame
	await process_frame

func check_calendar_boundaries() -> void:
	var overlay: CanvasLayer = load("res://scripts/ui/continue_loading.gd").new()
	root.add_child(overlay)
	for row in [[0,"1980 · Month 1, First Half"],[23,"1980 · Month 12, Second Half"],[24,"1981 · Month 13, First Half"]]:
		overlay.show_checkpoint({"run":{"studio_name":STUDIO,"completed_run_cycles":str(row[0])}})
		expect(overlay.date_label.text == row[1], "Loading calendar agrees with game's global month/year boundary")
	overlay.free()

func check_stale_preview_and_failure(saved: Dictionary, bytes: PackedByteArray) -> void:
	await open_game()
	# The menu previously inspected a valid file; a changed disk file must still
	# pass the real loader's validation before any run is attached.
	var untouched: RunState = game.run_state
	FileAccess.open(saved.path,FileAccess.WRITE).store_string("{broken-after-preview")
	game._active_phase.continue_requested.emit()
	await wait_loading()
	expect(game.run_state == untouched and game._active_phase is MainMenu, "Corrupt save after preview never attaches partial restored state")
	expect(game.get_node_or_null("ContinueLoading") == null and game._recovery_dialog.visible, "Failure removes overlay and returns to existing recovery")
	expect(not game._save_failure_dialog.visible, "Recovery has no competing exclusive save-error window")
	expect(FileAccess.get_file_as_string(saved.path) == "{broken-after-preview", "Failure preserves corrupt bytes for explicit recovery")
	game._recovery_dialog.hide()
	FileAccess.open(saved.path,FileAccess.WRITE).store_buffer(bytes)
	# A real competing lease must reject rather than run a second writer.
	game.checkpoints.store.release_writer()
	var owner := TestStore.new(game.checkpoints.store.directory, game.checkpoints.store.validator)
	expect(owner.acquire(), "Independent test writer acquires real lease")
	game._active_phase.continue_requested.emit()
	await wait_loading()
	expect(game.run_state == untouched and game._recovery_dialog.visible and not game._save_failure_dialog.visible, "Writer collision returns one recovery window without restoring")
	owner.release_writer()
	# UI Retry uses the presented route too; it must recover focus and clear busy.
	game._recovery_dialog.get_ok_button().pressed.emit()
	await wait_loading()
	expect(game._active_phase is StudioPhase and game.checkpoints.failure.is_empty(), "Retry after writer release successfully restores Studio")
	expect(FileAccess.get_file_as_bytes(saved.path) == bytes, "Failed load and Retry never rewrite original save")
	await close_game()

func check_teardown(saved: Dictionary, bytes: PackedByteArray) -> void:
	await open_game()
	game._active_phase.continue_requested.emit()
	expect(game._loading_checkpoint, "Scene teardown fixture has an in-flight loader")
	while game.get_node("ContinueLoading").stage_label.text != "Restoring market…": await process_frame
	expect(game.checkpoints.run.get_studio_name().is_empty(), "Teardown occurs after validation/player hydration but before attachment")
	await close_game()
	await open_game()
	expect(game._active_phase is MainMenu and FileAccess.get_file_as_bytes(saved.path) == bytes, "Scene teardown cancels presentation without saving or entering Studio")
	var operation: RefCounted = game.checkpoints.begin_load()
	var original: RunState = game.checkpoints.run
	while not operation.done:
		if operation.stage < 3: expect(game.checkpoints.run == original, "Staged restore publishes no partial player/world")
		var label: String = operation.label()
		var started := Time.get_ticks_usec()
		operation.advance()
		load_timings.append({"stage":label,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0})
	expect(operation.restored != null and operation.restored.get_studio_name() == STUDIO, "Fresh operation can acquire lease after scene teardown")
	var expected: Dictionary = game.checkpoints.adapter.capture(operation.restored)
	var synchronous: RunState = game.checkpoints.load_current()
	expect(synchronous != null and game.checkpoints.adapter.capture(synchronous) == expected, "Synchronous tools and incremental UI use identical restore semantics")
	expect(game.checkpoints.store.inspect().payload == saved.payload, "Both loader entry points preserve original world/save")
	await close_game()

func finish() -> void:
	if _capture != null:
		expect(audio_samples.size() >= 4, "Real audio driver sampled multiple loading stages")
		AudioServer.remove_bus_effect(_capture_bus, AudioServer.get_bus_effect_count(_capture_bus)-1)
	var result := {"checks":checks,"failures":failures,"stages":stages,"captures":captures,"viewports":viewports,"audio_driver":AudioServer.get_driver_name(),"audio_trace":audio_trace,"audio_samples":audio_samples,"load_timings_ms":load_timings}
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("CONTINUE_LOADING " + JSON.stringify(result))
	quit(0 if failures == 0 else 1)

func check_new_run_after_cancel(saved: Dictionary) -> void:
	await open_game()
	FileAccess.open(saved.path,FileAccess.WRITE).store_string("{broken-before-new-run")
	game._active_phase.continue_requested.emit()
	await wait_loading()
	game._recovery_dialog.get_cancel_button().pressed.emit()
	await process_frame
	game._on_studio_created("Explicit replacement Studio", &"action", [], game._active_phase)
	expect(game._active_phase is StudioPhase and game.run_state.get_studio_name() == "Explicit replacement Studio", "Canceling corrupt-save recovery still allows explicitly requested New Run")
	await close_game()
