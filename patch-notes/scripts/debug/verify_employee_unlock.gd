extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	verify.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func studio(run: RunState, snapshots: PrimitiveSnapshotDatabase) -> StudioPhase:
	var view: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	expect(view.setup(null, run, snapshots, true), "Studio prevalidation succeeds")
	root.add_child(view)
	return view

func verify() -> void:
	root.size = Vector2i(1152,648)
	root.content_scale_size = root.size
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var session = preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"employee_unlock","studio_name":"Employee Unlock","specialty":"action","traits":[],"seed":"4417","employee_trial":false},catalog)
	expect(session != null, "Normal player recipe starts without private employee opt-in")
	if session == null: quit(1); return
	# Current Insider hold removes this fixed route's incidental income; fund
	# only the isolated mechanics fixture, preserving all ordinary game rules.
	expect(session.run.add_cash(20000), "Explicit employee mechanics fixture funding")
	var snapshots := PrimitiveSnapshotDatabase.new()
	expect(snapshots.load_ledgers(), "Publisher and market ledgers load")
	var choose = preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Unlock Check","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	for release_count in range(3):
		for step in range(100):
			if session.in_studio and session.run.get_released_game_ids().size() == release_count: break
			var choice: Dictionary = choose.call(session.observation())
			var result: Dictionary = session.execute(session.command(choice.type,choice.get("payload",{})))
			expect(result.ok, "Legal campaign command succeeds: " + str(choice.type))
			if not result.ok: quit(1); return
		expect(session.in_studio and session.run.get_released_game_ids().size() == release_count, "Reached genuine release boundary %d" % release_count)
		var view := studio(session.run, snapshots)
		await process_frame
		var button: Button = view.get_node("%Employees")
		if release_count < 2:
			expect(button.disabled and button.tooltip_text.contains("2"), "Employees stays locked with clear requirement after %d releases" % release_count)
			view._open_employees()
			expect(view._employees_panel == null and not session.run.uses_employee_trial(), "Locked action cannot open or activate employee rules")
			view.queue_free(); await process_frame
			continue
		expect(not button.disabled, "Second release enables the real Studio Employees button")
		var run: RunState = session.run
		var cash := run.get_cash_cents()
		var cycle := run.get_completed_run_cycles()
		var rng := run.random_streams.snapshot()
		var signals := [0,0]
		run.employees_changed.connect(func(): signals[0] += 1)
		run.finance_changed.connect(func(): signals[1] += 1)
		# A pre-activation save must hydrate without requiring a private recipe flag.
		var adapter := StudioCheckpoint.new()
		var prior := adapter.capture(run)
		var restored := adapter.hydrate(prior)
		expect(restored != null and not restored.uses_employee_trial(), "Existing two-release save restores without silently changing its employee rules")
		button.pressed.emit()
		expect(view._employees_panel != null and view._employees_panel.visible, "Ordinary Studio button opens the shared employee folder")
		expect(run.uses_employee_trial(), "Opening after Game 2 enables the existing employee package once")
		if view._employees_panel == null:
			view.queue_free(); await process_frame
			continue
		expect(signals == [1,1], "Activation notifies checkpoint observers of roster and prospective payroll")
		expect(run.get_cash_cents() == cash and run.get_completed_run_cycles() == cycle and run.random_streams.snapshot() == rng, "Unlocking spends no cash, cycles or RNG")
		expect(not view._employees_panel._hire_buttons[&"qa"].disabled and not view._employees_panel._hire_buttons[&"production"].disabled, "Both implemented role offers are usable after Game 2")
		var activated := adapter.capture(run)
		view._employees_panel.close(); button.pressed.emit()
		expect(adapter.capture(run) == activated and signals == [1,1], "Reopening neither repeats activation nor mutates saved state")
		var quote := run.get_employee_hire_quote(&"qa")
		view._employees_panel.request_purchase(&"hire",quote)
		expect(view._employees_panel.confirmation.visible, "Hiring still requires the existing price/payroll confirmation")
		view._employees_panel.confirmation.hide(); view._employees_panel.confirmation.canceled.emit()
		expect(adapter.capture(run) == activated, "Canceling hire changes no saved state")
		view._employees_panel.request_purchase(&"hire",quote)
		view._employees_panel.confirmation.hide(); view._employees_panel.confirmation.confirmed.emit()
		expect(run.get_employees().employees.size() == 1 and run.get_cash_cents() == cash - 10000 and run.get_completed_run_cycles() == cycle, "Confirmed QA hire charges the existing $100 once, with no cycle")
		expect(run.get_studio_finance_report().monthly_payroll_cents == 100000, "Existing $1,000 monthly payroll is retained")
		var saved := adapter.capture(run)
		var cold := adapter.hydrate(saved)
		expect(cold != null and adapter.capture(cold) == saved, "Unlocked roster and payroll survive exact cold hydration")
		view.queue_free(); await process_frame
		var continued := studio(cold,snapshots)
		await process_frame
		expect(not continued.get_node("%Employees").disabled, "Cold Continue keeps Employees unlocked")
		continued.queue_free(); await process_frame
	print("Employee unlock: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
