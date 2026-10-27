## Actual Gameplay input path, including a failed-save read-only browse case.
extends "res://scripts/debug/verify_rival_gameplay_activation.gd"

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var game: Control
var output := ""

func _initialize() -> void:
	_run.call_deferred()

func click(control: Control) -> void:
	# Input.parse_input_event takes window pixels; Control rects use the scaled
	# canvas. Settings can restore a larger native window during scene startup.
	var point := root.get_final_transform() * control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	print("CLICK_TARGET ",control.name," at=",point," hovered=",root.gui_get_hovered_control())
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point; event.global_position = point; event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func settle() -> void:
	await create_timer(0.4).timeout

func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func _run() -> void:
	create_timer(60,true).timeout.connect(func(): push_error("Employee click timeout"); quit(2))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	node_added.connect(_replace_store)
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var session = Factory.create_fresh_session({"schema_version":1,"studio_id":"employee_click","studio_name":"Click Studio","specialty":"action","traits":[],"seed":"4417"},catalog)
	# This is a funded mechanics fixture, not an ordinary solvency route.
	expect(session.run.add_cash(20000),"Explicit mechanics fixture funding")
	var choose = preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Click","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	for step in range(100):
		if session.in_studio and session.run.get_released_game_ids().size()==2: break
		var choice: Dictionary = choose.call(session.observation())
		var result: Dictionary = session.execute(session.command(choice.type,choice.get("payload",{})))
		expect(result.ok,"Real campaign command: "+str(choice.type))
		if not result.ok: quit(1); return
	expect(session.run.get_released_game_ids().size()==2,"Two actual releases reached")
	var prior := StudioCheckpoint.new().capture(session.run)
	var fixture_path := OS.get_environment("PN_PAUSE_BASELINE").get_base_dir().path_join("two-release-fixture.json")
	FileAccess.open(fixture_path,FileAccess.WRITE).store_string(JSON.stringify(prior))
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = dimensions; root.content_scale_size = dimensions
		game = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game); current_scene = game
		await process_frame
		game._onboarding.answer(true)
		var run := StudioCheckpoint.new().hydrate(prior)
		expect(run != null,"Funded two-release fixture hydrates normally")
		if run == null: quit(1); return
		game.checkpoints.attach(run)
		expect(game._finish_checkpoint_load(run),"Actual Gameplay mounts restored Studio")
		await settle()
		var studio: StudioPhase = game._active_phase
		var button: Button = studio.get_node("%Employees")
		expect(not button.disabled,"Employees is enabled after two releases")
		print("OPEN_PRECONDITIONS ",{"allowed":run.can_mutate_checkpoint(),"trial":run.uses_employee_trial(),"publishing":run._publishing_cycle,"failure":game.checkpoints.failure,"button_rect":button.get_global_rect(),"studio_size":studio.size})
		await click(button)
		await settle()
		var panel: EmployeePanel = studio._employees_panel
		expect(panel != null and panel.is_visible_in_tree(),"Real pointer click displays Employees")
		if panel == null:
			await capture("no-menu-%d"%dimensions.x)
			game.queue_free(); await process_frame; continue
		expect(root.gui_get_focus_owner()==panel.back_button,"Employees Back receives focus")
		expect(not studio.get_node("%Dashboard").visible,"Employees replaces the dashboard navigation")
		await capture("employees-%d"%dimensions.x)
		await click(panel.back_button); await settle()
		expect(not panel.visible,"Pointer Back closes Employees")
		expect(studio.get_node("%Dashboard").visible and button.has_focus(),"Back restores the dashboard and Employees focus")
		# A failed-save guard may block activation, but it must not silently block
		# inspection of the employee menu or create a roster/payroll mutation.
		panel.free(); studio._employees_panel = null
		run._employees = EmployeeRoster.create(run._bank_run_id)
		run.checkpoint_mutations_allowed = false
		var before := Replay.digest([run.get_employees(),run.get_studio_finance_snapshot(),run.random_streams.snapshot(),run.get_cash_cents(),run.get_completed_run_cycles()])
		await click(button); await settle()
		expect(studio._employees_panel != null and studio._employees_panel.is_visible_in_tree(),"Mutation guard still permits visible employee browsing")
		expect(Replay.digest([run.get_employees(),run.get_studio_finance_snapshot(),run.random_streams.snapshot(),run.get_cash_cents(),run.get_completed_run_cycles()])==before,"Blocked activation changes no roster, money, payroll, time or RNG")
		panel = studio._employees_panel
		if panel != null:
			expect(panel.status.visible and not panel.status.text.is_empty(),"Blocked opening explains read-only availability")
			expect(panel._hire_buttons.values().all(func(hire):return hire.disabled),"Blocked opening cannot dispatch a hire")
			await capture("employees-readonly-%d"%dimensions.x)
			await click(panel.back_button); await settle()
		run.checkpoint_mutations_allowed = true
		await click(button); await settle()
		expect(run.uses_employee_trial() and studio._employees_panel.visible and not studio._employees_panel.status.visible,"Reopening after recovery activates once and clears stale failure")
		game.queue_free(); await process_frame
	print("EMPLOYEE_CLICK checks=%d failures=%d"%[checks,failures])
	quit(failures)
