extends SceneTree

## Test-only A/B probe: the same Studio button and actions under the existing
## OS-level synthetic helper and deterministic viewport-local input injection.
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0
var downs := 0
var ups := 0
var presses := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func event_to(point: Vector2, event_type: String, inject: String) -> void:
	var event: InputEventMouse
	if event_type == "move":
		event = InputEventMouseMotion.new()
	else:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = event_type == "down"
		event = click
	event.position = point
	if inject != "global_legacy": event.global_position = point
	if inject.begins_with("global"): Input.parse_input_event(event)
	else: root.push_input(event, true)

func run() -> void:
	root.size = Vector2i(1152,648)
	root.content_scale_size = Vector2i(1152,648)
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var state: RunState = preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
	var before := Replay.digest([state.get_cash_cents(), state.get_completed_run_cycles(), state.random_streams.snapshot(), state.get_studio_finance_snapshot()])
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
	var button: Button = studio.get_node("%StudioInfoMenuButton")
	button.button_down.connect(func(): downs += 1)
	button.button_up.connect(func(): ups += 1)
	button.pressed.connect(func(): presses += 1)
	for injection in ["global_legacy", "global", "viewport"]:
		var start_down := downs
		var start_up := ups
		var start_pressed := presses
		var prior_pressed := presses
		for i in 60:
			var point := button.get_global_rect().get_center()
			if injection.begins_with("global"): point = root.get_final_transform() * point
			event_to(point,"move",injection)
			await process_frame
			event_to(point,"down",injection)
			await process_frame
			event_to(point,"up",injection)
			await process_frame
			if presses != prior_pressed + 1:
				print("POINTER_MISS ", {"injection":injection,"attempt":i,"pressed":presses-start_pressed,"downs":downs-start_down,"ups":ups-start_up,"hover":str(root.gui_get_hovered_control()),"mouse":root.get_mouse_position(),"point":point,"button":button.get_global_rect(),"disabled":root.gui_disable_input,"focus":str(root.gui_get_focus_owner())})
			prior_pressed = presses
		var got := presses - start_pressed
		check(downs - start_down == 60 and ups - start_up == 60 and got == 60, "%s input delivers all 60 real button down/up/press signals" % injection)
	var after := Replay.digest([state.get_cash_cents(), state.get_completed_run_cycles(), state.random_streams.snapshot(), state.get_studio_finance_snapshot()])
	check(before == after,"Repeated navigation preserves gameplay state")
	game.queue_free()
	await process_frame
	print("STUDIO_POINTER_REPEAT checks=%d failures=%d downs=%d ups=%d presses=%d" % [checks,failures,downs,ups,presses])
	quit(failures)
