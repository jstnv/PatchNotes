extends SceneTree

## Presentation regression: isolated Hub; no player saves or game actions.
const Hub := preload("res://scripts/ui/studio_hub.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const KEYS: Array[StringName] = [&"studio_info", &"management", &"market", &"production"]
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	print("PASS: " if condition else "FAIL: ", message)
	if not condition: failures += 1

func wait_motion(hub: Control) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while hub.transitioning and Time.get_ticks_msec() < deadline: await process_frame
	for i in 3: await process_frame

func key_accept(button: Button) -> void:
	button.grab_focus()
	for down in [true,false]:
		var event := InputEventAction.new()
		event.action = &"ui_accept"
		event.pressed = down
		root.push_input(event,true)
	await process_frame

func pointer_move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event,true)

func pointer_click(point: Vector2) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event,true)
	await process_frame

func capture(name: String) -> void:
	var folder := OS.get_environment("PN_STUDIO_PANEL_CAPTURE")
	if folder.is_empty() or DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(folder)
	var result := root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
	check(result == OK,"Native screenshot captured: " + name)

func button_edges(button: Control) -> Vector2:
	var transform := button.get_global_transform()
	return Vector2((transform * Vector2.ZERO).x,(transform * Vector2(button.size.x,0)).x)

func panel_inner_edges(panel: PanelContainer) -> Vector2:
	var transform := panel.get_global_transform()
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	return Vector2((transform * Vector2(style.border_width_left,0)).x,(transform * Vector2(panel.size.x-style.border_width_right,0)).x)

func check_button_wave(hub: Control) -> void:
	var wave: Node = hub.get("_wave")
	if wave == null:
		check(false,"Studio buttons use the menu button motion")
		return
	var buttons: Array = wave.get("_buttons")
	var phases: PackedFloat64Array = wave.get("_phases")
	var weights: PackedFloat32Array = wave.get("_hover_weights")
	var inner := panel_inner_edges(hub._root_panel)
	for id: StringName in KEYS:
		var button: Button = hub.root_buttons[id]
		var index := buttons.find(button)
		if index < 0:
			check(false,"Root participates in the motion: " + str(id))
			continue
		weights[index] = 0.0
		wave.set("_hover_weights",weights)
		phases[index] = 0.0
		wave.set("_phases",phases)
		wave.call("_apply_poses")
		var left := button_edges(button)
		phases[index] = PI
		wave.set("_phases",phases)
		wave.call("_apply_poses")
		var right := button_edges(button)
		check(absf(left.x-inner.x-1.0) < 0.8 and absf(inner.y-right.y-1.0) < 0.8,"Normal wave endpoints stay one pixel inside the visible border: " + str(id))
		weights[index] = 1.0
		wave.set("_hover_weights",weights)
		wave.call("_apply_poses")
		var hovered := button_edges(button)
		check(absf(hovered.x-inner.x-2.0) < 0.8 and absf(inner.y-hovered.y-2.0) < 0.8,"Fully hovered button stays two pixels inside both visible borders: " + str(id))
		weights[index] = 0.0
	wave.set("_hover_weights",weights)
	wave.call("_apply_poses")

func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1152,648)
	root.content_scale_size = root.size
	var run_state: RunState = Factory.create_fresh_session({"schema_version":1,"studio_id":"panelmotion","studio_name":"Panel Motion","specialty":"action","traits":[],"seed":"9871"},root.get_node("CardDatabase").get_development_catalog()).run
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
	for id: StringName in KEYS:
		var group: VBoxContainer = hub.add_group(id,str(id).capitalize())
		var destination := Button.new()
		destination.text = "Destination"
		group.add_child(destination)
	for i in 4: await process_frame
	var idle_x: float = hub._root_panel.position.x
	check(hub.get_node_or_null("CompanionClip/StudioOverview") == null,"No summary dashboard exists with no selected menu")
	check(not hub._companion.is_visible_in_tree(),"No companion menu is visible with no selection")
	check(idle_x > 0.0,"The Studio panel sits to the right in its idle position")
	check(hub._root_panel.size.x >= 334.0,"The Studio panel includes the four-pixel width increase")
	check_button_wave(hub)
	capture("idle-1152")
	# Inspect the transition while it runs, rather than only its end state.
	hub.root_buttons[&"studio_info"].pressed.emit()
	var transition_root_positions := []
	var clipped_companion := false
	var limit := Time.get_ticks_msec() + 4000
	while hub.transitioning and Time.get_ticks_msec() < limit:
		transition_root_positions.append(hub._root_panel.position.x)
		if hub._companion.visible and hub._companion.position.x < -0.5: clipped_companion = true
		await process_frame
	await wait_motion(hub)
	check(transition_root_positions.any(func(x):return x > 0.5 and x < idle_x - 0.5),"Studio panel visibly slides between idle and selected positions")
	check(clipped_companion,"Companion menu emerges through its clipped opening")
	capture("selected-1152")
	hub.root_buttons[&"studio_info"].pressed.emit()
	await wait_motion(hub)
	for id: StringName in KEYS:
		hub.root_buttons[id].pressed.emit()
		await wait_motion(hub)
		check(hub.selected == id and hub.groups[id].is_visible_in_tree(),"Selecting opens the correct companion: " + str(id))
		check(absf(hub._root_panel.position.x) < 0.5,"Selected Studio panel returns to its original left position: " + str(id))
		hub.root_buttons[id].pressed.emit()
		await wait_motion(hub)
		check(hub.selected.is_empty() and hub.requested.is_empty() and not hub._companion.is_visible_in_tree(),"Selecting the active root closes the companion: " + str(id))
		check(absf(hub._root_panel.position.x-idle_x) < 0.5,"Closing restores the idle Studio position: " + str(id))
	await key_accept(hub.root_buttons[&"studio_info"])
	await wait_motion(hub)
	check(hub.selected == &"studio_info","Keyboard activation opens its group")
	await key_accept(hub.root_buttons[&"studio_info"])
	await wait_motion(hub)
	check(hub.selected.is_empty() and hub.root_buttons[&"studio_info"].has_focus(),"Keyboard activation closes the group without losing focus")
	hub.root_buttons[&"market"].pressed.emit()
	hub.root_buttons[&"market"].pressed.emit()
	await wait_motion(hub)
	check(hub.selected.is_empty() and hub.requested.is_empty(),"Rapid double activation returns to idle")
	var pointer_button: Button = hub.root_buttons[&"market"]
	var pointer_point := pointer_button.get_global_rect().get_center()
	pointer_move(pointer_point)
	await create_timer(0.25).timeout
	var wave: Node = hub.get("_wave")
	var index: int = wave.get("_buttons").find(pointer_button)
	var hover_weights: PackedFloat32Array = wave.get("_hover_weights")
	check(pointer_button.is_hovered() and hover_weights[index] > 0.95,"Pointer hover animates the shifted Studio button")
	var pointer_edges := button_edges(pointer_button)
	var inner := panel_inner_edges(hub._root_panel)
	check(absf(pointer_edges.x-inner.x-2.0) < 1.0 and absf(inner.y-pointer_edges.y-2.0) < 1.0,"Pointer hover reaches the intended two-pixel border clearance")
	await pointer_click(pointer_button.get_global_rect().get_center())
	await wait_motion(hub)
	check(hub.selected == &"market","Pointer clicks the shifted, expanded button and opens its group")
	await pointer_click(pointer_button.get_global_rect().get_center())
	await wait_motion(hub)
	check(hub.selected.is_empty(),"Pointer clicks the selected button to close its group")
	pointer_move(Vector2(2,2))
	await create_timer(0.25).timeout
	root.size = Vector2i(1600,900)
	root.content_scale_size = root.size
	for i in 5: await process_frame
	check(hub._root_panel.position.x > 0.0 and hub._root_panel.get_global_rect().end.x <= 1600.0,"Resized idle Studio panel stays visible and offset")
	check_button_wave(hub)
	capture("idle-1600")
	hub.root_buttons[&"production"].pressed.emit()
	await wait_motion(hub)
	check(absf(hub._root_panel.position.x) < 0.5 and hub.groups[&"production"].is_visible_in_tree(),"Resized selection restores the left position and companion")
	capture("selected-1600")
	hub.root_buttons[&"production"].pressed.emit()
	await wait_motion(hub)
	check(Replay.digest([run_state.get_cash_cents(),run_state.get_completed_run_cycles(),run_state.get_owned_feature_ids(),run_state.get_studio_finance_snapshot(),run_state.random_streams.snapshot()]) == before,"Studio navigation preserves finance, calendar, ownership and RNG")
	print("STUDIO_PANEL_MOTION checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
