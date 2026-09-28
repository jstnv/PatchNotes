class_name PostGameReview
extends Control

signal continue_to_studio_requested

var _project_state: ProjectState
var _run_state: RunState

func setup_release_snapshot(metadata: Dictionary, sales: Dictionary) -> bool:
	var data: Dictionary = metadata.get("review", {})
	if data.is_empty() or sales.is_empty(): return false
	%Subtitle.text = "%s · Released %d" % [metadata.get("release_title", "Game"), metadata.get("release_year", 0)]
	%ReviewLabel.text = "Final Review: %.1f / 10.0" % data.final_review
	%ProductionLabel.text = "Production Rating: %.2f" % data.production_rating
	%ScopeLabel.text = "Scope Completion: %.1f%%" % (data.scope_completion * 100.0)
	%AwarenessLabel.text = "Awareness: %d" % data.awareness
	%UnitsLabel.text = "Projected Month 1 Units: %d" % data.projected_units
	%CoreDescription.text = "Final production compared with this release's review standards."
	var labels: Array[Label] = [%GraphicsLabel, %SoundLabel, %TechnologyLabel, %DesignLabel]
	var names := ["Graphics", "Sound", "Technology", "Design"]
	for index in range(4):
		var standard: int = data.standards[index]
		labels[index].text = "%s     %d points  /  %d standard     %.0f%% of standard" % [names[index], data.cores[index], standard, 100.0 * data.cores[index] / standard if standard > 0 else 0.0]
	%ScopeDetailLabel.text = "Delivered Scope: %d / %d\nScope Completion: %.1f%%" % [data.scope, data.required_scope, data.scope_completion * 100.0]
	%CyclesLabel.text = "Development Time: %d cycles · Remaining Bugs: %d" % [data.development_cycles, data.remaining_bugs]
	%MarketingDetailLabel.text = %AwarenessLabel.text
	%LaunchMarketingLabel.text = "Launch Marketing: %d" % data.launch_marketing
	%SalesUnitsLabel.text = "Projected Month 1 Units: %d · Lifetime earned: %d" % [data.projected_units, sales.earned_units]
	%SalesNetLabel.text = "Projected Gross: %s · Projected Net: %s\nEarned Gross: %s · Earned Net: %s · Paid: %s" % [CashFormatter.format_exact_cents(data.projected_gross_cents), CashFormatter.format_exact_cents(data.projected_net_cents), CashFormatter.format_exact_cents(sales.earned_units * PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS), CashFormatter.format_exact_cents(sales.entitlement_cents), CashFormatter.format_exact_cents(sales.settled_cents)]
	%SalesNoteLabel.text = "Month 1 gross is before the platform share. Later sales continue by release age; earned net settles at calendar-month boundaries."
	return true


func setup(project_state: ProjectState, run_state: RunState) -> bool:
	if project_state == null or run_state == null or not project_state.has_review_result() or not project_state.has_awareness_result() or not project_state.has_units_sold_result() or not project_state.has_month_one_sales_revenue_result():
		return false
	_project_state = project_state
	_run_state = run_state
	if project_state.has_predevelopment_identity():
		%Subtitle.text = run_state.get_project_display_name(project_state) + " • Your game has been released. Explore its performance by category."
	%ReviewLabel.text = "Final Review: %.1f / 10.0" % project_state.get_review_result().get_final_review()
	%ProductionLabel.text = "Production Rating: %.2f" % project_state.get_review_result().get_production_rating()
	%ScopeLabel.text = "Scope Completion: %.1f%%" % (project_state.get_review_result().get_scope_completion() * 100.0)
	%AwarenessLabel.text = "Awareness: %d" % project_state.get_awareness_result().get_total_awareness()
	%UnitsLabel.text = "Projected Month 1 Units: %d" % project_state.get_units_sold_result().get_final_units_sold()
	var review := project_state.get_review_result()
	var labels: Array[Label] = [%GraphicsLabel, %SoundLabel, %TechnologyLabel, %DesignLabel]
	var names := ["Graphics", "Sound", "Technology", "Design"]
	%CoreDescription.text = "Final production compared with this release's review standards."
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var score := project_state.get_core_score(category)
		var standard := review.get_standard(category)
		labels[category].text = "%s     %d points  /  %d standard     %.0f%% of standard" % [names[category], score, standard, 100.0 * score / standard if standard > 0 else 0.0]
	%ScopeDetailLabel.text = "Delivered Scope: %d / %d\nScope Completion: %.1f%%" % [project_state.get_current_scope(), project_state.get_required_scope(), review.get_scope_completion() * 100.0]
	%CyclesLabel.text = "Development Time: %d cycles" % project_state.get_current_cycle()
	%MarketingDetailLabel.text = %AwarenessLabel.text
	%LaunchMarketingLabel.text = "Launch Marketing: %d" % project_state.get_awareness_result().get_launch_marketing()
	%SalesUnitsLabel.text = %UnitsLabel.text
	%SalesNetLabel.text = "Projected Month 1 Net: %s" % CashFormatter.format_exact_cents(project_state.get_month_one_sales_revenue_result().get_projected_month_one_net_cents())
	%SalesNoteLabel.text = "This is a forecast. Sales are earned as time advances and paid at calendar-month boundaries."
	return true


func _ready() -> void:
	%ContinueButton.pressed.connect(func(): continue_to_studio_requested.emit())


func get_project_state() -> ProjectState: return _project_state
func get_run_state() -> RunState: return _run_state
