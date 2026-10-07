## UI fixtures use authoritative RunState transactions; they are not played routes.
## godot --headless --path . --script res://scripts/debug/verify_studio_finances.gd
## Omit --headless and append -- --capture for viewport evidence.
extends SceneTree

const OUTPUT := "res://design-logs/task33-v1/rendered/"
var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func expect(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1


func _settle() -> void:
	await create_timer(0.28).timeout
	await process_frame


func _snapshot(run: RunState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids(), run.get_released_game_ids(), run.get_studio_finance_report().duplicate(true)]


func _named_run(name: String) -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(0)
	expect(run.set_studio_name(name, &"action"), "Named studio initializes actual finance history")
	return run


func _run() -> void:
	RenderingServer.set_default_clear_color(Color("#100608"))
	if "--capture" in OS.get_cmdline_user_args(): DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	expect(StudioFinances._money(-12345) == "-$123.45" and StudioFinances._money(0) == "$0.00" and StudioFinances._money(10001) == "$100.01", "UI formats negative profit and positive cash in exact cents")
	for resolution in [Vector2i(1152, 648), Vector2i(1280, 720)]:
		root.size = resolution
		root.content_scale_size = resolution
		await _verify_resolution(resolution)
	await _verify_main_menu()
	print("Studio finance UI verification: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _verify_resolution(resolution: Vector2i) -> void:
	var run := _named_run("Finance UI fixture")
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	root.add_child(game)
	await _settle()
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	var menu: StudioFinances = hud.studio_finances
	expect(game.get("_active_phase") is StudioPhase, "Named studio starts in actual Studio")
	var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
	expect(hud.cash_button.is_visible_in_tree() and not hud.cash_button.disabled and viewport.encloses(hud.cash_button.get_global_rect()), "Cash button is visible and reachable")
	expect(hud.cash_button.get_global_rect().position.x > hud.tutorial_button.get_global_rect().position.x, "Cash button is on the right of the footer")
	expect(hud.cash_button.text == "Cash: $5500.00" and hud.footer.text.contains("$500.00") and hud.footer.text.contains("M1 end"), "HUD shows actual cash and first month rent")
	var before := _snapshot(run)
	hud.cash_button.pressed.emit()
	await _settle()
	expect(menu.visible and menu.page == &"finances", "Cash opens Studio Finances")
	_check_bounds(menu, resolution)
	expect(menu.report == run.get_studio_finance_report(), "Finance view reads exact authoritative report")
	menu.bank_button.pressed.emit()
	await _settle()
	expect(menu.page == &"bank" and menu.bank_history.text.contains("Neutral starting history") and menu.bank_history.text.contains("No completed months"), "Bank starts with neutral empty history")
	expect(menu.back_button.text == "Back to Finances", "Bank has an explicit Back path")
	await _capture("bank-neutral", resolution)
	_escape(menu)
	expect(menu.visible and menu.page == &"finances", "Escape returns Bank to Finances")
	_escape(menu)
	expect(not menu.visible and _snapshot(run) == before, "Second Escape closes without altering finance or gameplay")
	for visit in range(3):
		hud.cash_button.pressed.emit()
		await _settle()
		menu.bank_button.pressed.emit()
		menu.back_button.pressed.emit()
		menu.back_button.pressed.emit()
	expect(_snapshot(run) == before, "Repeated open, Bank, Back and close remain passive")
	# Calendar-only transactions below are isolated accounting/UI fixtures.
	expect(run.complete_productive_action() and run.complete_productive_action() and run.complete_productive_action(), "Fixture reaches completed Month1 and partial Month2")
	hud.cash_button.pressed.emit()
	await _settle()
	expect(menu.month_table.get_root().get_child_count() == menu.report.rows.size(), "Table exposes all current authoritative month rows")
	var first := menu.month_table.get_root().get_first_child()
	expect(first != null and first.get_text(0).contains("complete"), "First month is marked completed")
	if first != null:
		first.select(0)
		menu.call("_show_month")
		expect(menu.month_detail.text.contains("Run Month 1") and menu.month_detail.text.contains("Rent due: $500.00") and menu.month_detail.text.contains("Paid this month: $500.00"), "Selecting older month shows its exact rent obligation/payment")
	var last := menu.month_table.get_root().get_child(menu.month_table.get_root().get_child_count() - 1)
	expect(last.get_text(0).contains("partial"), "Current month is honestly marked partial")
	expect(first.get_text(3) == "-$500.00", "Negative operating profit remains visible in the table")
	_check_bounds(menu, resolution)
	await _capture("finances", resolution)
	menu.open_bank()
	expect(menu.bank_history.text.contains("Completed months: 1") and not menu.bank_history.text.contains("Neutral starting history"), "Bank completed history updates from ledger inputs")
	await _capture("bank-history", resolution)
	menu.close()
	# A small-cash arrears fixture proves the displayed blocked state and exact cents.
	expect(run.spend_cash_cents(run.get_cash_cents() - 12345), "Fixture leaves exact-cent partial rent funding")
	expect(run.complete_productive_action(), "Boundary records an unpaid rent fixture")
	expect(hud.footer.text.begins_with("Unpaid rent $376.55") and hud.footer.text.contains("Cash → Finances"), "Overdue rent is immediately visible in HUD with a finance entry direction")
	var footer_font := hud.footer.get_theme_font("font")
	expect(footer_font.get_string_size("Unpaid rent $376.55 · Cash → Finances", HORIZONTAL_ALIGNMENT_LEFT, -1, hud.footer.get_theme_font_size("font_size")).x <= hud.footer.size.x, "HUD arrears amount and finance direction fit before ellipsis")
	await _capture("overdue-hud", resolution)
	hud.cash_button.pressed.emit()
	await _settle()
	expect(menu.report.financially_blocked and menu.block_label.visible and menu.totals_label.text.contains("$376.55"), "Unpaid obligations and first-version financial block are explicit")
	expect(menu.block_label.text.contains("launch") and menu.block_label.text.contains("income action"), "Blocked finance view preserves allowed navigation and recovery explanation")
	_check_bounds(menu, resolution)
	await _capture("unpaid-rent", resolution)
	menu.finance_tabs.current_tab = 1
	await _settle()
	expect(menu.expense_details.text.contains("rent:2") and menu.expense_details.text.contains("Remaining $376.55") and menu.expense_details.text.contains("Overdue 0 cycles"), "Outstanding tab shows stable bill, exact remaining balance and newly missed age")
	await _capture("outstanding-bills", resolution)
	menu.open_bank()
	await _settle()
	expect(menu.bank_history.text.contains("Credit score: 595") and menu.bank_history.text.contains("rent:2"), "Bank displays real score and identified monthly reason")
	await _capture("credit-missed-rent", resolution)
	menu.back()
	menu.finance_tabs.current_tab = 0
	before = _snapshot(run)
	var focus := InputEventAction.new()
	focus.action = "ui_focus_next"
	focus.pressed = true
	for attempt in range(8):
		menu._input(focus)
		expect(menu.dialog.is_ancestor_of(root.gui_get_focus_owner()), "Keyboard focus remains in finance dialog")
	menu.close()
	expect(_snapshot(run) == before, "Blocked-state finance navigation does not forgive rent or advance time")
	# Isolated receipt classification and late-payment UI fixtures, not played income actions.
	expect(run.add_cash_cents(40000, &"publisher_receipt", &"ui_fixture_publisher") and run.add_cash_cents(1234, &"beta_income", &"ui_fixture_beta") and run.add_cash_cents(77, &"other_income", &"ui_fixture_misc"), "Fixture records distinct exact-cent non-sales receipts and clears arrears")
	hud.show_finances()
	await _settle()
	var prior_due := menu.month_table.get_root().get_child(1)
	prior_due.select(0)
	menu.call("_show_month")
	expect(menu.month_detail.text.contains("Rent due: $500.00") and menu.month_detail.text.contains("Paid this month: $123.45") and menu.month_detail.text.contains("Still unpaid from this month: $0.00"), "Original due month distinguishes its own payments from later arrears recovery")
	var receipt_month := menu.month_table.get_root().get_child(2)
	receipt_month.select(0)
	menu.call("_show_month")
	expect(menu.month_detail.text.contains("Publisher receipts: $400.00") and menu.month_detail.text.contains("Beta income: $12.34") and menu.month_detail.text.contains("Miscellaneous income: $0.77") and menu.month_detail.text.contains("Non-sales income total: $413.11"), "Month detail separates publisher, Beta and miscellaneous receipts without adding them twice")
	expect(menu.month_detail.text.contains("Rent due: $0.00") and menu.month_detail.text.contains("Paid this month: $376.55") and menu.month_detail.text.contains("Still unpaid from this month: $0.00"), "Payment month clearly shows rent paid toward an earlier month's obligation")
	expect(not hud.footer.text.begins_with("Unpaid rent") and not menu.block_label.visible, "Rent recovery clears the visible blocked warning")
	await _capture("income-and-rent-recovery", resolution)
	menu.close()
	# Binding is independent from old run notifications and unknown legacy history.
	var replacement := _named_run("Second finance fixture")
	hud.setup(null, replacement)
	expect(not run.finance_changed.is_connected(hud.refresh) and not run.finance_changed.is_connected(menu._on_finance_changed), "HUD and report detach old run finance signals")
	expect(replacement.finance_changed.is_connected(hud.refresh) and replacement.finance_changed.is_connected(menu._on_finance_changed), "HUD and report bind the replacement run")
	hud.show_finances()
	await _settle()
	var fresh_report := menu.report.duplicate(true)
	run.finance_changed.emit()
	expect(menu.report == fresh_report and menu.report.cash_cents == 550000, "Old run notification cannot replace visible new-run finance data")
	var legacy := RunState.new()
	legacy.initialize_cash_cents(12345)
	hud.setup(null, legacy)
	hud.show_finances()
	await _settle()
	expect(not menu.report.get("available", false) and menu.month_detail.text.contains("history unavailable") and menu.month_table.get_root().get_child_count() == 0, "Unknown legacy history shows unavailable, without invented rows")
	menu.open_bank()
	expect(menu.bank_history.text.contains("history unavailable"), "Unknown legacy Bank history remains unavailable")
	hud.set_phase(game.get("_active_phase"))
	expect(not menu.visible, "Changing phase closes finance navigation safely")
	hud.setup(null, null)
	expect(hud.cash_button.disabled and not hud.show_finances(), "Missing RunState disables finance entry")
	game.queue_free()
	await _settle()


func _verify_main_menu() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await _settle()
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	expect(game.get("_active_phase") is MainMenu and hud.cash_button.disabled and not hud.show_finances(), "Main Menu cannot open studio finance history")
	game.queue_free()
	await _settle()


func _check_bounds(menu: StudioFinances, resolution: Vector2i) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
	expect(viewport.encloses(menu.dialog.get_global_rect()), "Finance dialog fits %s" % resolution)
	expect(menu.back_button.is_visible_in_tree() and menu.dialog.get_global_rect().encloses(menu.back_button.get_global_rect()), "Finance Back stays visible inside its dialog")
	expect(menu.dialog.get_global_rect().encloses(menu.month_table.get_global_rect()) and menu.dialog.get_global_rect().encloses(menu.month_detail.get_global_rect()), "Monthly table and details fit inside the finance dialog")


func _escape(menu: StudioFinances) -> void:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	menu._input(event)


func _capture(label: String, resolution: Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(OUTPUT + "%s-%dx%d.png" % [label, resolution.x, resolution.y]) == OK, "Saved rendered finance evidence")
