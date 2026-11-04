extends SceneTree

## Isolated proof for test-input sequencing; this does not alter game input.
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0
var presses := 0
var downs := 0
var ups := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func motion(point: Vector2, mask: int = 0) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = mask
	root.push_input(event, true)

func button_event(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed = down
	root.push_input(event, true)

func click_atomic(point: Vector2) -> void:
	# The two edges are dispatched together, with no frame for unrelated native
	# input to land between them; no live-game button or input behavior changes.
	motion(point)
	button_event(point, true)
	button_event(point, false)

func run() -> void:
	root.size = Vector2i(1152, 648)
	root.content_scale_size = Vector2i(1152, 648)
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var state: RunState = preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
	var before := Replay.digest([state.get_cash_cents(),state.get_completed_run_cycles(),state.random_streams.snapshot(),state.get_studio_finance_snapshot()])
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	game._onboarding.answer(true)
	game.focused_guidance.automatic_enabled = false
	game.focused_guidance.dismiss(true)
	game.run_state = state
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	hud.setup(null,state)
	check(game._enter_initial_studio(true), "Actual two-release Studio mounted")
	for frame in 3: await process_frame
	hud.contextual_tip.dismiss()
	var studio: StudioPhase = game._active_phase
	studio._hub_motion.animate = false
	var target: Button = studio.get_node("%StudioInfoMenuButton")
	target.button_down.connect(func(): downs += 1)
	target.button_up.connect(func(): ups += 1)
	target.pressed.connect(func(): presses += 1)
	var outside := Vector2(root.get_visible_rect().end.x - 8.0, root.get_visible_rect().end.y - 8.0)
	var point := target.get_global_rect().get_center()
	motion(point)
	button_event(point,true)
	motion(outside,MOUSE_BUTTON_MASK_LEFT)
	button_event(outside,false)
	await process_frame
	check(downs == 1 and ups == 1 and presses == 0, "Actual drag out cancels the button press")
	# Reproduce the former split helper's vulnerability: a pointer move can land
	# between down and up, even when the synthetic release repeats the old point.
	motion(point)
	button_event(point,true)
	motion(outside,MOUSE_BUTTON_MASK_LEFT)
	button_event(point,false)
	await process_frame
	check(presses == 0,"Interleaved pointer movement cancels a split synthetic click")
	var first := presses
	var legacy := OS.get_environment("PN_POINTER_LEGACY") == "1"
	for i in 60:
		point = target.get_global_rect().get_center()
		if legacy:
			motion(point)
			button_event(point,true)
			motion(outside,MOUSE_BUTTON_MASK_LEFT)
			button_event(point,false)
		else:
			click_atomic(point)
		# Competing pointer movement may arrive after the atomic pair, but cannot
		# silently split its press/release into separate unrelated gestures.
		motion(outside)
		await process_frame
	check(presses-first == 60,"%s clicks activate 60 times under competing motion" % ("Split" if legacy else "Atomic"))
	var after := Replay.digest([state.get_cash_cents(),state.get_completed_run_cycles(),state.random_streams.snapshot(),state.get_studio_finance_snapshot()])
	check(before == after,"Pointer tests preserve finance, calendar and RNG")
	game.queue_free()
	await process_frame
	print("STUDIO_POINTER_ATOMIC checks=%d failures=%d down=%d up=%d press=%d" % [checks,failures,downs,ups,presses])
	quit(failures)
