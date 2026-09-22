class_name LaunchPhase
extends Control

var _project_state: ProjectState
var _run_state: RunState
var _snapshot_database: PrimitiveSnapshotDatabase


func setup(project_state: ProjectState, run_state: RunState, snapshot_database: PrimitiveSnapshotDatabase) -> bool:
	if project_state == null or run_state == null or snapshot_database == null or not project_state.has_beta_finalization() or not project_state.is_launch_ready() or not project_state.has_review_result() or not project_state.has_awareness_result() or not project_state.has_launch_market_context_result() or not run_state.is_cash_initialized():
		return false
	_project_state = project_state
	_run_state = run_state
	_snapshot_database = snapshot_database
	_refresh_review()
	return true


func _refresh_review() -> void:
	var result := _project_state.get_review_result()
	%ReviewLabel.text = "Review: %.1f / 10.0" % result.get_final_review()
	%ProductionRatingLabel.text = "Production Rating: %.2f" % result.get_production_rating()
	%ScopeCompletionLabel.text = "Scope Completion: %.1f%%" % (result.get_scope_completion() * 100.0)
	%BugMultiplierLabel.text = "Bug Multiplier: %.1f%%" % (result.get_bug_multiplier() * 100.0)
	%VarianceLabel.text = "Review Variance: %+.2f" % result.get_variance_modifier()
	var awareness := _project_state.get_awareness_result()
	%AwarenessLabel.text = "Awareness: %d" % awareness.get_total_awareness()
	%LaunchMarketingLabel.text = "Launch Marketing: %d" % awareness.get_launch_marketing()
	var context := _project_state.get_launch_market_context_result()
	%MarketContextLabel.visible = context.was_forecast_revealed_at_launch()
	if %MarketContextLabel.visible:
		var forecast := _snapshot_database.get_forecast(context.get_forecast_id_for_authority())
		if forecast == null:
			return
		%MarketContextLabel.text = "Market: %s — Launch Demand ×%s" % [forecast.get_display_name(), context.get_forecast_multiplier_text()]
	%CompetitorContextLabel.visible = context.was_competitor_revealed_at_launch()
	if %CompetitorContextLabel.visible:
		var competitor := _snapshot_database.get_competitor(context.get_competitor_id_for_authority())
		if competitor == null:
			return
		%CompetitorContextLabel.text = "Rival: %s — Target Release: Cycle %d" % [competitor.get_display_name(), context.get_competitor_target_cycle()]


func get_project_state() -> ProjectState:
	return _project_state


func get_run_state() -> RunState:
	return _run_state
