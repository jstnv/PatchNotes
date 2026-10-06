class_name PostGameReview
extends Control

signal continue_to_studio_requested

var _project_state: ProjectState
var _run_state: RunState
var _reveal_targets: Array[float] = []
var _reveal_tween: Tween
var _bugs_label: Label
var _scope_bar: ProgressBar
var _reveal_labels: Array[Label] = []
var reveal_running := false

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
	_set_reveal_targets(data.scope_completion * 100.0, data.production_rating, data.remaining_bugs, data.awareness, data.final_review)
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
	_set_reveal_targets(review.get_scope_completion() * 100.0, review.get_production_rating(), project_state.get_remaining_bugs(), project_state.get_awareness_result().get_total_awareness(), review.get_final_review())
	return true


func _ready() -> void:
	var rows := %ScopeLabel.get_parent()
	var scope_row := HBoxContainer.new()
	scope_row.add_theme_constant_override("separation", 24)
	rows.add_child(scope_row)
	%ScopeLabel.reparent(scope_row)
	%ScopeLabel.custom_minimum_size.x = 300
	_scope_bar = ProgressBar.new()
	_scope_bar.custom_minimum_size = Vector2(220, 20)
	_scope_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_scope_bar.show_percentage = false
	scope_row.add_child(_scope_bar)
	_bugs_label = Label.new()
	_bugs_label.name = "BugsLabel"
	_bugs_label.add_theme_font_size_override("font_size", 18)
	rows.add_child(_bugs_label)
	var ordered: Array[Control] = [scope_row, %ProductionLabel, _bugs_label, %AwarenessLabel, %ReviewLabel, %UnitsLabel]
	for i in range(ordered.size()): rows.move_child(ordered[i], i + 1)
	%ReviewLabel.add_theme_font_size_override("font_size", 24)
	_reveal_labels = [%ScopeLabel, %ProductionLabel, _bugs_label, %AwarenessLabel, %ReviewLabel]
	finish_reveal()
	%ContinueButton.pressed.connect(func():
		finish_reveal()
		continue_to_studio_requested.emit())


func _set_reveal_targets(scope: float, production: float, bugs: int, awareness: int, review: float) -> void:
	_reveal_targets = [scope, production, float(bugs), float(awareness), review]
	if is_node_ready(): finish_reveal()


func start_launch_reveal() -> void:
	if _reveal_targets.size() != 5: return
	finish_reveal()
	%Categories.current_tab = 0
	reveal_running = true
	for i in range(5): _display_reveal_value(0.0, i)
	_reveal_tween = create_tween().set_parallel()
	for i in range(5):
		# The next value starts 80ms before the preceding count reaches its target.
		_reveal_tween.tween_method(_display_reveal_value.bind(i), 0.0, _reveal_targets[i], 0.9).set_delay(i * 0.82).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.chain().tween_callback(finish_reveal)


func _display_reveal_value(value: float, index: int) -> void:
	var formats := ["Scope Completion: %.1f%%", "Production Rating: %.2f", "Bugs Remaining: %d", "Awareness: %d", "Final Review: %.1f / 10.0"]
	_reveal_labels[index].text = formats[index] % value
	if index == 0: _scope_bar.value = value
	if index == 2:
		# Cosmetic glitch only: never consumes gameplay RNG or changes the bug count.
		var glitch := reveal_running and value > 0.0 and value < _reveal_targets[2]
		_bugs_label.modulate = Color("ff829b") if glitch and int(value * 13.0) % 2 == 0 else Color.WHITE
		_bugs_label.add_theme_constant_override("shadow_offset_x", 3 if glitch else 0)
		_bugs_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.9, 1.0, 0.8) if glitch else Color.TRANSPARENT)


func finish_reveal() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid(): _reveal_tween.kill()
	reveal_running = false
	if _reveal_labels.size() != 5 or _reveal_targets.size() != 5: return
	for i in range(5): _display_reveal_value(_reveal_targets[i], i)


func get_project_state() -> ProjectState: return _project_state
func get_run_state() -> RunState: return _run_state
