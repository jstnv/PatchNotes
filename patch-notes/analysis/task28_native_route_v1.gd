## Native current-source scene route; inherited policies use visible choices.
extends "res://analysis/task27_routes_v1.gd"
var report_checks := 0
var report_failures := 0

func _capture_cycle(game: Control) -> void:
	super._capture_cycle(game)
	var reports: Array = []
	var run: RunState = game.run_state
	for id in run.get_released_game_ids():
		var report := run.get_released_game_monthly_report(id)
		report_checks += 1
		if report.is_empty(): report_failures += 1
		reports.append(report)
	live_cycles[-1]["monthly_reports"] = reports

func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	arm = "newer"
	experiment = "task28"
	max_games = 3
	era_cap = 0
	first_store_cycle = 0
	random_inputs.seed = 240930000
	var result := await _current_route(0)
	result["report_checks"] = report_checks
	result["report_failures"] = report_failures
	var file := FileAccess.open("res://design-logs/task28-v1/native-%s.json" % era_policy, FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	print("TASK28 native ", era_policy, " releases=", result.releases.size(), " report checks=", report_checks, " failures=", report_failures)
	quit(0 if result.valid and result.releases.size() == 3 and report_failures == 0 else 1)
