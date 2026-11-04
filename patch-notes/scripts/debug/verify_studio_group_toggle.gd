extends SceneTree

const Replay := preload("res://scripts/simulation/development_replay.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Hub := preload("res://scripts/ui/studio_hub.gd")
const KEYS: Array[StringName] = [&"studio_info", &"management", &"market", &"production"]
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func wait_motion(hub: Control) -> void:
	var deadline := Time.get_ticks_msec() + 3000
	while hub.transitioning and Time.get_ticks_msec() < deadline:
		await process_frame
	for i in 3: await process_frame

func key_accept(button: Button) -> void:
	button.grab_focus()
	for down in [true, false]:
		var event := InputEventAction.new()
		event.action = &"ui_accept"
		event.pressed = down
		root.push_input(event, true)
	await process_frame

func pointer_activate(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	root.push_input(move, true)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = point
		click.global_position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click, true)
	await process_frame

func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1152,648)
	root.content_scale_size = root.size
	var run_state: RunState = Factory.create_fresh_session({"schema_version":1,"studio_id":"toggle","studio_name":"Toggle Test","specialty":"action","traits":[],"seed":"4417"}, root.get_node("CardDatabase").get_development_catalog()).run
	var before := Replay.digest([run_state.get_cash_cents(),run_state.get_completed_run_cycles(),run_state.get_owned_feature_ids(),run_state.get_studio_finance_snapshot(),run_state.random_streams.snapshot()])
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var motion := MenuTransitions.new()
	motion.automatic_entrances = false
	host.add_child(motion)
	var hub := Hub.new()
	hub.motion = motion
	host.add_child(hub)
	hub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hub.overview.bind_run(run_state)
	var events: Array[StringName] = []
	hub.selection_changed.connect(func(id: StringName): events.append(id))
	for id: StringName in KEYS:
		var group: VBoxContainer = hub.add_group(id,str(id).capitalize())
		var child := Button.new()
		child.text = "Destination"
		group.add_child(child)
	await process_frame
	await process_frame
	for id: StringName in KEYS:
		var button: Button = hub.root_buttons[id]
		button.grab_focus()
		button.pressed.emit()
		await wait_motion(hub)
		check(hub.selected == id and hub.requested == id and hub.groups[id].is_visible_in_tree(),"Root opens " + str(id))
		check(button.button_pressed,"Selected root is pressed " + str(id))
		# Internal re-selection must still be idempotent when restoring navigation.
		hub.select_group(id)
		await wait_motion(hub)
		check(hub.selected == id and hub.requested == id,"Programmatic re-selection stays open " + str(id))
		button.pressed.emit()
		await wait_motion(hub)
		check(hub.selected.is_empty() and hub.requested.is_empty() and hub.overview.visible,"Second root activation returns to dashboard " + str(id))
		check(not button.button_pressed and button.has_focus(),"Closing clears selection and keeps root focus " + str(id))
		check(not events.is_empty() and events[-1].is_empty(),"Closing notifies Studio of empty selection " + str(id))
		if not hub.selected.is_empty() or not hub.requested.is_empty():
			hub.close_group()
			await wait_motion(hub)

	hub.root_buttons[&"studio_info"].pressed.emit()
	await wait_motion(hub)
	hub.root_buttons[&"management"].pressed.emit()
	await wait_motion(hub)
	check(hub.selected == &"management" and hub.groups[&"management"].is_visible_in_tree() and not hub.groups[&"studio_info"].is_visible_in_tree(),"Different root switches directly to its group")
	hub.root_buttons[&"management"].pressed.emit()
	await wait_motion(hub)
	if not hub.selected.is_empty():hub.close_group();await wait_motion(hub)
	hub.root_buttons[&"market"].pressed.emit()
	hub.root_buttons[&"market"].pressed.emit()
	await wait_motion(hub)
	check(hub.selected.is_empty() and hub.requested.is_empty() and hub.overview.visible,"Rapid double activation returns to dashboard")
	if not hub.selected.is_empty():hub.close_group();await wait_motion(hub)
	hub.root_buttons[&"studio_info"].pressed.emit()
	await wait_motion(hub)
	hub.root_buttons[&"studio_info"].pressed.emit()
	hub.root_buttons[&"production"].pressed.emit()
	await wait_motion(hub)
	check(hub.selected == &"production" and hub.requested == &"production" and hub.groups[&"production"].is_visible_in_tree(),"New selection during closing wins")
	hub.close_group()
	await wait_motion(hub)
	var keyboard: Button = hub.root_buttons[&"studio_info"]
	await key_accept(keyboard)
	await wait_motion(hub)
	check(hub.selected == &"studio_info","Keyboard activation opens the group")
	await key_accept(keyboard)
	await wait_motion(hub)
	check(hub.selected.is_empty() and hub.overview.visible and keyboard.has_focus(),"Keyboard activation closes the group and keeps focus")
	await pointer_activate(keyboard)
	await wait_motion(hub)
	check(hub.selected == &"studio_info", "Pointer click opens the group")
	await pointer_activate(keyboard)
	await wait_motion(hub)
	check(hub.selected.is_empty() and hub.overview.visible, "Pointer click closes the selected group")
	host.queue_free()
	for i in 4: await process_frame
	var database := PrimitiveSnapshotDatabase.new()
	check(database.load_ledgers(), "Actual Studio uses the real snapshot ledgers")
	var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	root.add_child(studio)
	check(studio.setup(null,run_state,database), "Actual Studio mounts with an in-memory run")
	for i in 4: await process_frame
	var studio_button: Button = studio._hub.root_buttons[&"studio_info"]
	await pointer_activate(studio_button)
	await wait_motion(studio._hub)
	check(studio._active_menu == &"studio_info" and studio._hub.selected == &"studio_info", "Pointer opens the actual Studio group")
	studio._show_group(&"studio_info")
	await wait_motion(studio._hub)
	check(studio._active_menu == &"studio_info" and studio._hub.selected == &"studio_info", "Programmatic Studio re-selection remains open")
	await pointer_activate(studio_button)
	await wait_motion(studio._hub)
	check(studio._active_menu.is_empty() and studio._hub.selected.is_empty() and studio._hub.overview.visible, "Pointer closes actual Studio group and clears its active menu")
	check(studio_button.has_focus(), "Actual Studio keeps sidebar focus after closing")
	check(Replay.digest([run_state.get_cash_cents(),run_state.get_completed_run_cycles(),run_state.get_owned_feature_ids(),run_state.get_studio_finance_snapshot(),run_state.random_streams.snapshot()]) == before,"Browsing keeps finance, calendar, ownership and RNG unchanged")
	print("STUDIO_GROUP_TOGGLE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
