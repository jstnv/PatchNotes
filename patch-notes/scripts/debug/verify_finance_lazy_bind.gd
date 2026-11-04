## UI-only regression; run in an isolated profile with synthetic RunStates.
extends SceneTree

class CountingRun extends RunState:
	var report_calls := 0
	func get_studio_finance_report() -> Dictionary:
		report_calls += 1
		return super.get_studio_finance_report()

var checks := 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _initialize() -> void:
	go.call_deferred()

func go() -> void:
	await process_frame
	var panel := StudioFinances.new()
	root.add_child(panel)
	var first := CountingRun.new()
	check(first.initialize_cash_cents(550000), "First fixture has finance")
	panel.bind_run(first)
	check(not panel.visible and first.report_calls == 0, "Hidden binding does not calculate a report")
	check(panel.report.is_empty(), "Hidden binding does not expose a stale report")
	check(panel.open(), "Finance panel opens")
	check(first.report_calls > 0 and panel.report == first.get_studio_finance_report(), "Opening reads the exact current report")
	check(first.add_cash_cents(1234), "First run records cash")
	check(panel.report == first.get_studio_finance_report(), "Visible finance updates after a change")
	panel.close()
	var second := CountingRun.new()
	check(second.initialize_cash_cents(120000), "Replacement fixture has finance")
	panel.bind_run(second)
	check(not panel.visible and second.report_calls == 0 and panel.report.is_empty(), "Hidden rebind discards the old report")
	check(panel.open() and panel.report == second.get_studio_finance_report(), "Reopening shows the replacement run")
	var current := panel.report.duplicate(true)
	first.finance_changed.emit()
	check(panel.report == current, "Old run notifications do not change the replacement report")
	panel.queue_free()
	await process_frame
	print("FINANCE_LAZY_BIND ", JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
