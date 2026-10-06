extends "res://scripts/debug/verify_game_lifespan_trial.gd"

var row_checks := 0
var evidence: Array = []

func _reconcile(run: RunState) -> void:
	for id in run.get_released_game_ids():
		var record := run.get_released_game_sales(id)
		var report := run.get_released_game_monthly_report(id)
		check(not report.is_empty(), "Historical replay agrees with authoritative record")
		if report.is_empty(): continue
		var sums := [0, 0, 0, 0]
		for row: Dictionary in report.rows:
			sums[0] += row.units
			sums[1] += row.net_cents
			sums[2] += row.settled_cents
			sums[3] += row.unpaid_cents
			check(row.gross_cents == row.units * 999 and row.net_cents == row.settled_cents + row.unpaid_cents, "Row gross/net/payment conservation")
			row_checks += 1
		check(sums == [record.earned_units, record.entitlement_cents, record.settled_cents, record.entitlement_cents - record.settled_cents], "Monthly sums reconcile to lifetime units and exact cents")
		evidence.append({"cycle": run.get_completed_run_cycles(), "cash_cents": run.get_cash_cents(), "report": report})

func _run() -> void:
	snapshots.load_ledgers()
	for alignment in [0, 1]:
		var run := RunState.new()
		run.initialize_cash_cents(200000)
		if alignment == 1: run.complete_productive_action()
		var first := _released_project(9.5, 751)
		check(run.register_release(first), "Synthetic strong fixture registers at selected calendar alignment")
		var first_id := first.get_release_id()
		_reconcile(run)
		var revived := false
		for offset in range(81):
			if offset == 5: check(run.register_release(_released_project(2.3, 301)), "Second title starts concurrently at opposite alignment")
			var record := run.get_released_game_sales(first_id)
			var campaign: bool = offset in [2, 4] or (not revived and offset > 10 and offset % 2 == 0 and record.monthly_units == 0)
			if campaign and offset > 10: revived = true
			var cash := run.get_cash_cents()
			var cycle := run.get_completed_run_cycles()
			var paid_before := 0
			for id in run.get_released_game_ids(): paid_before += int(run.get_released_game_sales(id).settled_cents)
			check(run.purchase_post_launch_campaign(first_id, cycle) if campaign else run.complete_productive_action(), "Synthetic central-cycle action succeeds")
			var paid_after := 0
			for id in run.get_released_game_ids(): paid_after += int(run.get_released_game_sales(id).settled_cents)
			check(run.get_cash_cents() == cash + paid_after - paid_before - (10000 if campaign else 0) and run.get_completed_run_cycles() == cycle + 1, "Run cash equals concurrent settlement less exact campaign fee; one cycle")
			_reconcile(run)
			if campaign:
				var before := _snapshot(run, first_id)
				check(not run.purchase_post_launch_campaign(first_id, cycle) and not run.purchase_post_launch_campaign(first_id, cycle + 1) and _snapshot(run, first_id) == before, "Repeat callback and mistimed action roll back")
		check(revived, "A zero-unit month is followed by a real campaign revival fixture")
		var report := run.get_released_game_monthly_report(first_id)
		check(report.rows[0].slices.size() == 2 and report.rows[0].units == 751, "Both Month1 slices preserve odd-unit rounding")
		check(report.rows[-1].earned_halves == 1, "Current partial month contains only one actual half")
		var tampered := run.get_released_game_sales(first_id)
		check(ReleasedGameMonthlyReport.build(tampered, alignment + 1).is_empty(), "Wrong release provenance cannot manufacture a history")
		var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
		root.add_child(studio)
		studio.offset_top = 12.0
		studio.offset_bottom = -52.0
		studio.setup(first, run, snapshots)
		studio.open_summary()
		studio.open_monthly_sales()
		var view: MonthlySalesReport = studio.get("_monthly_report")
		var before := _snapshot(run, first_id)
		view.setup(run, first_id)
		check(view.get("_report").release_id == first_id, "Older release may be selected independently")
		for dimensions in [Vector2i(1152, 648), Vector2i(900, 600)]:
			root.size = dimensions
			root.content_scale_size = dimensions
			await process_frame
			await process_frame
			check(view.get_global_rect().encloses(view.get("_forecast").get_global_rect()), "Monthly report fits supported viewport")
			if "--capture" in OS.get_cmdline_user_args():
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://design-logs/task28-v1/monthly-%d-%d.png" % [alignment, dimensions.x])
		view.closed.emit()
		check(_snapshot(run, first_id) == before, "History navigation and reconstruction are passive")
		if OS.has_feature("editor"):
			var exporter = load("res://scripts/debug/lifespan_capture.gd")
			var saved: String = exporter.save_capture(run)
			check(saved.begins_with("Saved locally: "), "Editor capture writes locally")
			if saved.begins_with("Saved locally: "):
				var captured: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saved.trim_prefix("Saved locally: ")))
				check(int(captured.cash_cents) == run.get_cash_cents() and captured.titles.size() == 2 and int(captured.run_cycle) == run.get_completed_run_cycles(), "Capture preserves exact cash, title inputs and observed cycle")
			check(_snapshot(run, first_id) == before, "Local capture does not advance or alter gameplay")
		studio.queue_free()
		await process_frame
	if DirAccess.dir_exists_absolute("res://design-logs/task28-v1"):
		var file := FileAccess.open("res://design-logs/task28-v1/fixture-rows.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"label": "Synthetic accounting fixtures, not played human time", "rows_checked": row_checks, "captures": evidence}))
	print("Monthly report verification: ", failures, " failures; ", row_checks, " row checks")
	quit(failures)
