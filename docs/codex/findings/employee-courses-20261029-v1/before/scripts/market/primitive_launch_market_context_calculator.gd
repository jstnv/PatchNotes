class_name PrimitiveLaunchMarketContextCalculator
extends RefCounted

const PROFILE_ID := &"primitive_launch_market_context_v1"


static func calculate(project_state: ProjectState, database: PrimitiveSnapshotDatabase) -> LaunchMarketContextResult:
	if (
		project_state == null
		or database == null
		or not project_state.has_beta_finalization()
		or not project_state.is_launch_ready()
		or not project_state.has_review_result()
		or not project_state.has_awareness_result()
		or project_state.has_launch_market_context_result()
	):
		return null
	var competitor_id := project_state.get_assigned_competitor_snapshot_id_for_authority()
	var forecast_id := project_state.get_assigned_market_forecast_snapshot_id_for_authority()
	if competitor_id.is_empty() or forecast_id.is_empty():
		return null
	var competitor := database.get_competitor(competitor_id)
	var forecast := database.get_forecast(forecast_id)
	if competitor == null or forecast == null:
		return null
	var player_cycle := project_state.get_current_cycle()
	var target_cycle := competitor.get_target_release_cycle()
	var forecast_basis_points := forecast.get_launch_demand_basis_points()
	if player_cycle < 0 or target_cycle <= 0 or forecast_basis_points <= 0:
		return null
	var delta := player_cycle - target_cycle
	var relation := LaunchMarketContextResult.TimingRelation.ON_TARGET
	if delta < 0:
		relation = LaunchMarketContextResult.TimingRelation.BEFORE_TARGET
	elif delta > 0:
		relation = LaunchMarketContextResult.TimingRelation.AFTER_TARGET
	return LaunchMarketContextResult.new(
		PROFILE_ID,
		forecast_id,
		forecast_basis_points,
		project_state.is_market_forecast_snapshot_revealed(),
		competitor_id,
		target_cycle,
		player_cycle,
		delta,
		relation,
		project_state.is_competitor_snapshot_revealed()
	)
