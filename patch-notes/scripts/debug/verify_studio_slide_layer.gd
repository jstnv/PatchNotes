extends SceneTree

## Isolated presentation regression against the actual Gameplay/Studio scene.
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", label)
	if not value: failures += 1

func canvas_layer(item: Node) -> int:
	var node: Node = item
	while is_instance_valid(node):
		if node is CanvasLayer: return node.layer
		node = node.get_parent()
	return 0

func canvas_z(item: Node) -> int:
	var node: Node = item
	var value := 0
	while node is CanvasItem:
		value += node.z_index
		if not node.z_as_relative: break
		node = node.get_parent()
	return value

func is_drawn_above(a: Control, b: Control) -> bool:
	if canvas_layer(a) != canvas_layer(b): return canvas_layer(a) > canvas_layer(b)
	if canvas_z(a) != canvas_z(b): return canvas_z(a) > canvas_z(b)
	return a.is_greater_than(b)

func visible_rect(item: Control) -> Rect2:
	var result := item.get_global_rect()
	var node := item.get_parent()
	while is_instance_valid(node):
		if node is Control and node.clip_contents:
			result = result.intersection(node.get_global_rect())
		node = node.get_parent()
	return result

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("user://slide-layer-" + label + ".png")
	check(result == OK, label + ": captured native frame")

func halfway(studio: StudioPhase, view: Control, hud: GameplayHUD, label: String, under: Control = null) -> void:
	var motion: MenuTransitions = studio._hub_motion
	check(motion.busy and motion._navigation_tween != null, label + ": transition is active")
	if not motion.busy or motion._navigation_tween == null: return
	var tween: Tween = motion._navigation_tween
	tween.pause()
	var elapsed := tween.get_total_elapsed_time()
	print("LAYER_MIDPOINT label=%s elapsed=%.6f target=0.100000" % [label, elapsed])
	check(elapsed <= 0.10, label + ": midpoint was not already missed")
	if elapsed > 0.10:
		if tween.is_valid(): tween.play()
		var missed_deadline := Time.get_ticks_msec() + 6000
		while motion.busy and Time.get_ticks_msec() < missed_deadline: await process_frame
		return
	var remaining := maxf(0.0, 0.10 - elapsed)
	if remaining > 0.0: tween.custom_step(remaining)
	await process_frame
	var sidebar: Control = studio._hub._root_panel if under == null else under
	var header: Control = hud.get_node("PersistentHeader")
	var footer: Control = hud.get_node("PersistentFooter")
	check(view.is_visible_in_tree() and sidebar.is_visible_in_tree(), label + ": incoming and Studio panel are simultaneously visible")
	check(view.get_global_rect().intersects(sidebar.get_global_rect()), label + ": destination overlaps the Studio panel during motion")
	check(is_drawn_above(view, sidebar), label + ": moving destination is above Studio panel")
	var visible := visible_rect(view)
	check(not visible.intersects(header.get_global_rect()) or is_drawn_above(header, view), label + ": moving destination cannot cover top HUD")
	check(not visible.intersects(footer.get_global_rect()) or is_drawn_above(footer, view), label + ": moving destination cannot cover bottom HUD")
	await capture(label)
	check(tween.is_valid(), label + ": midpoint tween remains valid before resuming")
	if tween.is_valid(): tween.play()
	var deadline := Time.get_ticks_msec() + 6000
	while motion.busy and Time.get_ticks_msec() < deadline: await process_frame
	check(not motion.busy, label + ": transition finishes")
	for frame in 2: await process_frame

func pointer_click(button: Button, wait_for_frame := true) -> void:
	var point := button.get_global_rect().get_center()
	var mouse := InputEventMouseMotion.new()
	mouse.position = point
	mouse.global_position = point
	root.push_input(mouse,true)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event,true)
	if wait_for_frame: await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var run_state: RunState = Factory.create_fresh_session({"schema_version":1,"studio_id":"slide_layer","studio_name":"Slide Layer","specialty":"action","traits":[],"seed":"4417"},catalog).run
	var engine_id: StringName = preload("res://scripts/debug/ui_test_actions.gd").create_feature_engine(run_state,"Layer Test Engine")
	var before := Replay.digest([run_state.get_cash_cents(), run_state.get_completed_run_cycles(), run_state.random_streams.snapshot(), run_state.get_owned_feature_ids(), run_state.get_studio_finance_snapshot()])
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 3: await process_frame
	game._onboarding.answer(true)
	game.focused_guidance.automatic_enabled = false
	game.run_state = run_state
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	hud.setup(null, run_state)
	check(game._enter_initial_studio(true), "Actual Studio mounts with isolated in-memory run")
	for frame in 4: await process_frame
	var studio: StudioPhase = game._active_phase
	hud.contextual_tip.dismiss()
	studio._show_group(&"management")
	studio._hub.settle_motion()
	for frame in 2: await process_frame
	await pointer_click(hud.cash_button)
	check(hud.studio_finances.visible, "Actual HUD Cash pointer opens Finances with Management selected at 1280x720")
	await create_timer(0.4).timeout
	if hud.studio_finances.visible:
		await pointer_click(hud.studio_finances.back_button)
		check(not hud.studio_finances.visible and studio._hub.selected == &"management", "Finance Back works and preserves Management")
	await pointer_click(hud.settings_button)
	check(hud.settings_menu.is_open(), "Actual HUD Settings pointer opens Settings with Management selected at 1280x720")
	await create_timer(0.4).timeout
	if hud.settings_menu.is_open():
		await pointer_click(hud.settings_menu.back_button)
		await process_frame
		check(not hud.settings_menu.is_open() and studio._hub.selected == &"management", "Settings Back works and preserves Management")
	var engine_button := studio.get_node("%StudioEnginesButton") as Button
	await pointer_click(engine_button)
	var engine: Control = studio._engine_browser
	if engine != null:
		await halfway(studio, engine, hud, "engines-enter")
		studio._engine_browser._inspect(engine_id)
		studio._engine_browser.configure_button.pressed.emit()
		var store: Control = studio._feature_store
		if store != null:
			await halfway(studio, store, hud, "store-enter", engine)
			studio._open_engines(engine_id)
			await halfway(studio, store, hud, "store-back", engine)
		else: check(false, "Nested Feature Implementation was created")
		studio._engine_browser.closed.emit()
		await halfway(studio, engine, hud, "engines-back")
		check(engine_button.has_focus(), "Pointer navigation restores focus to Engines button")
	else: check(false, "Engines destination was created")
	studio._show_group(&"studio_info")
	studio._hub.settle_motion()
	for frame in 2: await process_frame
	var bank_button := studio.get_node("%StudioBankButton") as Button
	await pointer_click(bank_button)
	if hud.studio_finances.visible:
		await halfway(studio, hud.studio_finances.dialog, hud, "bank-enter")
		# Sample the pop before the next frame can advance past its midpoint.
		await pointer_click(hud.studio_finances.back_button, false)
		await halfway(studio, hud.studio_finances.dialog, hud, "bank-back")
		check(bank_button.has_focus(), "Bank pointer navigation restores focus to Bank button")
	else: check(false, "Bank destination was created")
	var after := Replay.digest([run_state.get_cash_cents(), run_state.get_completed_run_cycles(), run_state.random_streams.snapshot(), run_state.get_owned_feature_ids(), run_state.get_studio_finance_snapshot()])
	check(before == after, "Browsing and transitions preserve player cash, calendar, ownership, finance and RNG")
	game.queue_free()
	for frame in 2: await process_frame
	print("STUDIO_SLIDE_LAYER checks=%d failures=%d" % [checks, failures])
	quit(failures)
