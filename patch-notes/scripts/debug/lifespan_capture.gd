extends RefCounted

## Editor-only, user-triggered local capture. Excluded with scripts/debug at export.
static func save_capture(run: RunState) -> String:
	if not OS.has_feature("editor"): return "Unavailable outside the editor build."
	var titles: Array = []
	for id in run.get_released_game_ids():
		titles.append({"metadata": run.get_release_metadata(id), "ledger": run.get_released_game_sales(id), "monthly_report": run.get_released_game_monthly_report(id)})
	var source := {}
	for path in ["res://scripts/run_state.gd", "res://scripts/studio_traits.gd", "res://scripts/finance/feature_spending_guidance.gd", "res://scripts/finance/studio_finance_ledger.gd", "res://scripts/finance/outstanding_expenses.gd", "res://scripts/sales/released_game_sales.gd", "res://scripts/sales/later_month_sales_calculator.gd", "res://scripts/sales/released_game_monthly_report.gd"]:
		source[path] = FileAccess.get_sha256(path)
	var capture := {"format": "patch_notes_lifespan_capture_v1", "label": "Actual current state; no future time simulated", "utc": Time.get_datetime_string_from_system(true),
		"studio_creation": run.get_studio_creation_snapshot(), "engine": Engine.get_version_info(), "source_sha256": source, "run_cycle": run.get_completed_run_cycles(), "cash_cents": run.get_cash_cents(), "redraws": run.get_available_redraws(), "titles": titles, "studio_finance": run.get_studio_finance_snapshot(), "studio_finance_report": run.get_studio_finance_report()}
	capture["development_pacing"] = run.get_development_pacing()
	capture["feature_spending_advice"] = run.get_feature_spending_advice()
	var folder := "user://lifespan-captures"
	if DirAccess.make_dir_recursive_absolute(folder) != OK: return "Could not create local capture folder."
	var path := "%s/capture-%d-%d.json" % [folder, run.get_completed_run_cycles(), Time.get_ticks_usec()]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return "Could not save local capture."
	file.store_string(JSON.stringify(capture, "\t"))
	return "Saved locally: " + ProjectSettings.globalize_path(path)
