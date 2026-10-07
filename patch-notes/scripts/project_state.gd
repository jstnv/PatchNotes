class_name ProjectState
extends RefCounted

const MAX_SIGNED_INT: int = 9223372036854775807

# Allocated once per project, retained through phase/release reconstruction.
# Future save files must serialize this identity along with project state.
var _release_id := StringName("release_" + Crypto.new().generate_random_bytes(16).hex_encode())

func get_release_id() -> StringName:
	return _release_id

signal values_changed
signal cycle_changed

enum CoreScore {
	GRAPHICS,
	SOUND,
	TECHNOLOGY,
	DESIGN,
}

var _core_scores: Dictionary[CoreScore, int] = {
	CoreScore.GRAPHICS: 0,
	CoreScore.SOUND: 0,
	CoreScore.TECHNOLOGY: 0,
	CoreScore.DESIGN: 0,
}
var _current_scope: int = 0
var _accumulated_bug_pressure: float = 0.0
var _accumulated_alpha_bug_pressure: float = 0.0
var _has_design_bug_finalization := false
var _was_perfect_production := false
var _hidden_bugs := 0
var _known_bugs := 0
var _fixed_bugs := 0
var _marketing_output: int = 0
var _competitor_snapshot_id: StringName
var _competitor_snapshot_revealed := false
var _market_forecast_snapshot_id: StringName
var _market_forecast_snapshot_revealed := false
var _exhausted_beta_card_ids: Array[StringName] = []
var _implemented_design_feature_ids: Array[StringName] = []
var _unimplemented_design_feature_ids: Array[StringName] = []
var _has_alpha_finalization := false
var _has_beta_finalization := false
var _review_result: ReviewResult
var _awareness_result: AwarenessResult
var _launch_market_context_result: LaunchMarketContextResult
var _units_sold_result: UnitsSoldResult
var _month_one_sales_revenue_result: MonthOneSalesRevenueResult
var _alpha_hidden_bugs_generated := 0
var _implemented_alpha_feature_ids: Array[StringName] = []
var _unimplemented_alpha_feature_ids: Array[StringName] = []
var _required_scope: int
var _current_cycle: int = 0
var _base_name := ""
var _genre_id: StringName
var _theme_id: StringName
var _genre_ratios: Array[int] = []
var _feature_supply_ids: Array[StringName] = []


func configure_predevelopment(base_name: String, genre: StringName, theme: StringName, feature_ids: Array[StringName]) -> bool:
	if has_predevelopment_identity() or _current_cycle != 0 or _current_scope != 0 or _has_design_bug_finalization or not PrimitivePredevelopment.validation_error(base_name, genre, theme).is_empty():
		return false
	_base_name = base_name.strip_edges()
	_genre_id = genre
	_theme_id = theme
	_genre_ratios.assign(PrimitivePredevelopment.find_entry("genres", genre).ratios)
	_feature_supply_ids.assign(feature_ids)
	return true


func has_predevelopment_identity() -> bool: return not _base_name.is_empty()
func get_base_name() -> String: return _base_name
func get_genre_id() -> StringName: return _genre_id
func get_theme_id() -> StringName: return _theme_id
## Graphics / Sound / Technology / Design, saved for Genre Fit at Review.
func get_genre_ratios() -> Array[int]: return _genre_ratios.duplicate()
func get_feature_supply_ids() -> Array[StringName]: return _feature_supply_ids.duplicate()


func _init(required_scope: int) -> void:
	if required_scope < 0:
		push_error("Required Scope cannot be negative.")
		_required_scope = 0
		return

	_required_scope = required_scope


func get_core_score(category: CoreScore) -> int:
	if not _is_valid_core_score(category):
		push_warning("Invalid Core Score category: %s" % category)
		return 0

	return _core_scores[category]


func add_core_score(category: CoreScore, amount: int) -> bool:
	if _has_beta_finalization:
		return false
	if not _is_valid_core_score(category):
		push_warning("Invalid Core Score category: %s" % category)
		return false
	if amount < 0:
		push_warning("Core Score additions cannot be negative.")
		return false
	if amount == 0:
		return true

	_core_scores[category] += amount
	values_changed.emit()
	return true


## Applies one printed Core Score and Scope pair as a single validated update.
func add_core_score_and_scope(category: CoreScore, score_amount: int, scope_amount: int) -> bool:
	var score_additions: Dictionary[CoreScore, int] = {category: score_amount}
	return add_core_scores_and_scope(score_additions, scope_amount)


## Validates and applies Core Scores, Scope, and fractional Bug Pressure together.
## The default preserves existing score-and-Scope-only callers.
func add_core_scores_and_scope(score_additions: Dictionary[CoreScore, int], scope_amount: int, bug_pressure_amount: float = 0.0) -> bool:
	if _has_beta_finalization:
		return false
	if scope_amount < 0:
		push_warning("Scope additions cannot be negative.")
		return false
	if not is_finite(bug_pressure_amount) or bug_pressure_amount < 0.0:
		push_warning("Bug Pressure additions must be finite and nonnegative.")
		return false
	var resulting_bug_pressure := _accumulated_bug_pressure + bug_pressure_amount
	if not is_finite(resulting_bug_pressure) or resulting_bug_pressure < 0.0:
		push_warning("Accumulated Bug Pressure must remain finite and nonnegative.")
		return false

	for category: CoreScore in score_additions:
		if not _is_valid_core_score(category):
			push_warning("Invalid Core Score category: %s" % category)
			return false
		if score_additions[category] < 0:
			push_warning("Core Score additions cannot be negative.")
			return false

	var changed := scope_amount != 0 or bug_pressure_amount != 0.0
	for category: CoreScore in score_additions:
		var amount := score_additions[category]
		_core_scores[category] += amount
		changed = changed or amount != 0
	_current_scope += scope_amount
	_accumulated_bug_pressure = resulting_bug_pressure
	if changed:
		values_changed.emit()
	return true


func get_current_scope() -> int:
	return _current_scope


func get_required_scope() -> int:
	return _required_scope


func get_accumulated_bug_pressure() -> float:
	return _accumulated_bug_pressure


func get_accumulated_alpha_bug_pressure() -> float:
	return _accumulated_alpha_bug_pressure


## Atomically applies base Alpha production without modifying Design Bug Pressure.
func add_alpha_production(score_additions: Dictionary[CoreScore, int], scope_amount: int, alpha_bug_pressure_amount: Variant) -> bool:
	if _has_beta_finalization:
		return false
	if scope_amount < 0:
		push_warning("Alpha Scope additions cannot be negative.")
		return false
	if typeof(alpha_bug_pressure_amount) != TYPE_INT and typeof(alpha_bug_pressure_amount) != TYPE_FLOAT:
		push_warning("Alpha Bug Pressure additions must be numeric.")
		return false
	var pressure_amount := float(alpha_bug_pressure_amount)
	if not is_finite(pressure_amount) or pressure_amount < 0.0:
		push_warning("Alpha Bug Pressure additions must be finite and nonnegative.")
		return false
	var resulting_pressure := _accumulated_alpha_bug_pressure + pressure_amount
	if not is_finite(resulting_pressure) or resulting_pressure < 0.0:
		push_warning("Accumulated Alpha Bug Pressure must remain finite and nonnegative.")
		return false
	for category: CoreScore in score_additions:
		if not _is_valid_core_score(category):
			push_warning("Invalid Core Score category: %s" % category)
			return false
		if score_additions[category] < 0:
			push_warning("Alpha Core Score additions cannot be negative.")
			return false

	var changed := scope_amount != 0 or pressure_amount != 0.0
	for category: CoreScore in score_additions:
		var amount := score_additions[category]
		_core_scores[category] += amount
		changed = changed or amount != 0
	_current_scope += scope_amount
	_accumulated_alpha_bug_pressure = resulting_pressure
	if changed:
		values_changed.emit()
	return true


func has_design_bug_finalization() -> bool:
	return _has_design_bug_finalization


func was_perfect_production() -> bool:
	return _was_perfect_production


func get_hidden_bugs() -> int:
	return _hidden_bugs


func get_known_bugs() -> int:
	return _known_bugs


func get_fixed_bugs() -> int:
	return _fixed_bugs


func get_remaining_bugs() -> int:
	return _hidden_bugs + _known_bugs


## Returns Marketing Output accumulated for this project during Beta.
func get_marketing_output() -> int:
	return _marketing_output


## Adds already-calculated Marketing Output without resolving any card effect.
func add_marketing_output(amount: Variant) -> bool:
	if _has_beta_finalization:
		return false
	if typeof(amount) != TYPE_INT or amount < 0:
		push_warning("Marketing Output additions must be nonnegative integers.")
		return false
	if amount == 0:
		return true
	if amount > MAX_SIGNED_INT - _marketing_output:
		push_warning("Marketing Output overflowed.")
		return false
	var resulting_output: int = _marketing_output + amount
	_marketing_output = resulting_output
	values_changed.emit()
	return true


## Atomically assigns both immutable-ledger identities at new-project creation.
## Assignment does not reveal either snapshot.
func initialize_snapshots(competitor_id: Variant, forecast_id: Variant) -> bool:
	if _has_beta_finalization:
		return false
	var normalized_competitor := _normalize_snapshot_id(competitor_id, "Competitor")
	var normalized_forecast := _normalize_snapshot_id(forecast_id, "Market forecast")
	if normalized_competitor.is_empty() or normalized_forecast.is_empty():
		return false
	if has_competitor_snapshot() or has_market_forecast_snapshot():
		push_warning("Project snapshots can only be initialized together on an empty ProjectState.")
		return false
	_competitor_snapshot_id = normalized_competitor
	_market_forecast_snapshot_id = normalized_forecast
	values_changed.emit()
	return true


func has_competitor_snapshot() -> bool:
	return not _competitor_snapshot_id.is_empty()


func is_competitor_snapshot_revealed() -> bool:
	return _competitor_snapshot_revealed


## Player-facing access remains empty until Study Competition eventually
## reveals the already-assigned snapshot.
func get_revealed_competitor_snapshot_id() -> StringName:
	return _competitor_snapshot_id if _competitor_snapshot_revealed else StringName()


## Narrow authority/verifier query; presentation code should use the revealed
## getter so concealed information cannot leak.
func get_assigned_competitor_snapshot_id_for_authority() -> StringName:
	return _competitor_snapshot_id


## Future competitor generation may assign one stable snapshot identifier.
## Assignment is one-time for this ProjectState and never reveals the payload.
func assign_competitor_snapshot_id(snapshot_id: Variant) -> bool:
	if _has_beta_finalization:
		return false
	var normalized := _normalize_snapshot_id(snapshot_id, "Competitor")
	if normalized.is_empty() or has_competitor_snapshot():
		if has_competitor_snapshot():
			push_warning("The competitor snapshot has already been assigned.")
		return false
	_competitor_snapshot_id = normalized
	values_changed.emit()
	return true


func reveal_competitor_snapshot() -> bool:
	if _has_beta_finalization:
		return false
	if not has_competitor_snapshot():
		push_warning("A competitor snapshot must exist before it can be revealed.")
		return false
	if _competitor_snapshot_revealed:
		return true
	_competitor_snapshot_revealed = true
	values_changed.emit()
	return true


func has_market_forecast_snapshot() -> bool:
	return not _market_forecast_snapshot_id.is_empty()


func is_market_forecast_snapshot_revealed() -> bool:
	return _market_forecast_snapshot_revealed


## Player-facing access remains empty until Predict Market Trends eventually
## reveals the already-assigned snapshot.
func get_revealed_market_forecast_snapshot_id() -> StringName:
	return _market_forecast_snapshot_id if _market_forecast_snapshot_revealed else StringName()


## Narrow authority/verifier query for the future forecast generator.
func get_assigned_market_forecast_snapshot_id_for_authority() -> StringName:
	return _market_forecast_snapshot_id


func assign_market_forecast_snapshot_id(snapshot_id: Variant) -> bool:
	if _has_beta_finalization:
		return false
	var normalized := _normalize_snapshot_id(snapshot_id, "Market forecast")
	if normalized.is_empty() or has_market_forecast_snapshot():
		if has_market_forecast_snapshot():
			push_warning("The market forecast snapshot has already been assigned.")
		return false
	_market_forecast_snapshot_id = normalized
	values_changed.emit()
	return true


func reveal_market_forecast_snapshot() -> bool:
	if _has_beta_finalization:
		return false
	if not has_market_forecast_snapshot():
		push_warning("A market forecast snapshot must exist before it can be revealed.")
		return false
	if _market_forecast_snapshot_revealed:
		return true
	_market_forecast_snapshot_revealed = true
	values_changed.emit()
	return true


func get_exhausted_beta_card_ids() -> Array[StringName]:
	return _exhausted_beta_card_ids.duplicate()


func is_beta_card_exhausted(id: StringName) -> bool:
	return _exhausted_beta_card_ids.has(id)


## Records successfully played finite Beta definitions after complete preflight.
func exhaust_beta_cards(ids: Variant) -> bool:
	if _has_beta_finalization:
		return false
	if not ids is Array:
		push_warning("Beta exhaustion IDs must be provided as an array.")
		return false
	var additions: Array[StringName] = []
	var seen: Dictionary[StringName, bool] = {}
	for raw_id: Variant in ids:
		var id := _normalize_snapshot_id(raw_id, "Beta exhaustion")
		if id.is_empty() or seen.has(id) or _exhausted_beta_card_ids.has(id):
			push_warning("Beta exhaustion IDs must be valid, unique, and previously unexhausted.")
			return false
		seen[id] = true
		additions.append(id)
	if additions.is_empty():
		return true
	_exhausted_beta_card_ids.append_array(additions)
	values_changed.emit()
	return true


func _normalize_snapshot_id(value: Variant, label: String) -> StringName:
	if typeof(value) != TYPE_STRING and typeof(value) != TYPE_STRING_NAME:
		push_warning("%s snapshot IDs must be strings." % label)
		return StringName()
	var text := String(value)
	if text.is_empty() or text != text.strip_edges() or text != text.to_lower() or not text.is_valid_identifier():
		push_warning("%s snapshot IDs must be nonempty lowercase stable identifiers." % label)
		return StringName()
	return StringName(text)


## Transfers up to the requested number of Hidden Bugs into Known Bugs.
## Returns the actual transfer, or -1 when the request is invalid.
func discover_bugs(requested_amount: Variant) -> int:
	if _has_beta_finalization:
		return -1
	if typeof(requested_amount) != TYPE_INT or requested_amount < 0:
		push_warning("Bug discovery requests must be nonnegative integers.")
		return -1
	var actual_discovery := mini(requested_amount, _hidden_bugs)
	if actual_discovery == 0:
		return 0
	_hidden_bugs -= actual_discovery
	_known_bugs += actual_discovery
	values_changed.emit()
	return actual_discovery


## Removes up to the requested number of Known Bugs. Hidden Bugs are protected.
## Returns the actual removal, or -1 when the request is invalid.
func fix_known_bugs(requested_amount: Variant) -> int:
	if _has_beta_finalization:
		return -1
	if typeof(requested_amount) != TYPE_INT or requested_amount < 0:
		push_warning("Bug fixing requests must be nonnegative integers.")
		return -1
	var actual_fixed := mini(requested_amount, _known_bugs)
	if actual_fixed == 0:
		return 0
	if actual_fixed > MAX_SIGNED_INT - _fixed_bugs:
		push_warning("Fixed Bug count overflowed.")
		return -1
	_known_bugs -= actual_fixed
	_fixed_bugs += actual_fixed
	values_changed.emit()
	return actual_fixed


func get_implemented_design_feature_ids() -> Array[StringName]:
	return _implemented_design_feature_ids.duplicate()


func get_unimplemented_design_feature_ids() -> Array[StringName]:
	return _unimplemented_design_feature_ids.duplicate()


func has_alpha_finalization() -> bool:
	return _has_alpha_finalization


func get_alpha_hidden_bugs_generated() -> int:
	return _alpha_hidden_bugs_generated


func get_implemented_alpha_feature_ids() -> Array[StringName]:
	return _implemented_alpha_feature_ids.duplicate()


func get_unimplemented_alpha_feature_ids() -> Array[StringName]:
	return _unimplemented_alpha_feature_ids.duplicate()


## Stores the one-time Design finalization result as one authoritative update.
func finalize_design_bugs(perfect_production: Variant, hidden_bugs: Variant, implemented_ids: Variant, unimplemented_ids: Variant) -> bool:
	if _has_beta_finalization:
		return false
	if _has_design_bug_finalization:
		push_warning("Design Bug finalization has already occurred.")
		return false
	if typeof(perfect_production) != TYPE_BOOL:
		push_warning("Perfect Production finalization value must be boolean.")
		return false
	if typeof(hidden_bugs) != TYPE_INT or hidden_bugs < 0:
		push_warning("Final Hidden Bugs must be a nonnegative integer.")
		return false
	var normalized_implemented := _normalize_feature_history_ids(implemented_ids)
	if not normalized_implemented.valid:
		return false
	var normalized_unimplemented := _normalize_feature_history_ids(unimplemented_ids)
	if not normalized_unimplemented.valid:
		return false
	var implemented_seen: Dictionary[StringName, bool] = {}
	for id: StringName in normalized_implemented.ids:
		implemented_seen[id] = true
	for id: StringName in normalized_unimplemented.ids:
		if implemented_seen.has(id):
			push_warning("Design Feature history collections cannot overlap: %s" % id)
			return false

	_was_perfect_production = perfect_production
	_hidden_bugs = hidden_bugs
	_implemented_design_feature_ids.assign(normalized_implemented.ids)
	_unimplemented_design_feature_ids.assign(normalized_unimplemented.ids)
	_has_design_bug_finalization = true
	values_changed.emit()
	return true


## Adds Alpha's one-time Hidden Bug contribution and Feature-history snapshot as
## one authoritative update. Existing finalized Design Hidden Bugs are retained.
func finalize_alpha(alpha_hidden_bugs: Variant, implemented_ids: Variant, unimplemented_ids: Variant) -> bool:
	if _has_beta_finalization:
		return false
	if _has_alpha_finalization:
		push_warning("Alpha finalization has already occurred.")
		return false
	if not _has_design_bug_finalization:
		push_warning("Alpha cannot finalize before Design finalization.")
		return false
	if typeof(alpha_hidden_bugs) != TYPE_INT or alpha_hidden_bugs < 0:
		push_warning("Alpha Hidden Bugs must be a nonnegative integer.")
		return false
	var normalized_implemented := _normalize_feature_history_ids(implemented_ids, "Alpha")
	if not normalized_implemented.valid:
		return false
	var normalized_unimplemented := _normalize_feature_history_ids(unimplemented_ids, "Alpha")
	if not normalized_unimplemented.valid:
		return false
	var implemented_seen: Dictionary[StringName, bool] = {}
	for id: StringName in normalized_implemented.ids:
		implemented_seen[id] = true
	for id: StringName in normalized_unimplemented.ids:
		if implemented_seen.has(id):
			push_warning("Alpha Feature history collections cannot overlap: %s" % id)
			return false
	var resulting_hidden_bugs: int = _hidden_bugs + alpha_hidden_bugs
	if resulting_hidden_bugs < _hidden_bugs:
		push_warning("Total Hidden Bugs overflowed during Alpha finalization.")
		return false

	_alpha_hidden_bugs_generated = alpha_hidden_bugs
	_hidden_bugs = resulting_hidden_bugs
	_implemented_alpha_feature_ids.assign(normalized_implemented.ids)
	_unimplemented_alpha_feature_ids.assign(normalized_unimplemented.ids)
	_has_alpha_finalization = true
	values_changed.emit()
	return true


func has_beta_finalization() -> bool:
	return _has_beta_finalization


func is_launch_ready() -> bool:
	return _has_beta_finalization and has_launch_feature_work()


## Phase histories contain successfully resolved finite Features, never selections.
## Alpha supplies its committed history before freezing it so an empty project stays playable.
func has_launch_feature_work(pending_alpha_ids: Array[StringName] = []) -> bool:
	var definitions := FeatureStoreCatalog.starting_features()
	definitions.append_array(FeatureStoreCatalog.entries())
	for entry: Dictionary in definitions:
		if entry.get("type") != "feature" or entry.get("renewable", false) or int(entry.get("scope", 0)) <= 0:
			continue
		var id := StringName(entry.get("id", ""))
		if entry.get("phase") == "design" and id in _implemented_design_feature_ids:
			return true
		if entry.get("phase") == "alpha" and (id in _implemented_alpha_feature_ids or id in pending_alpha_ids):
			return true
	return false


func has_review_result() -> bool:
	return _review_result != null


func get_review_result() -> ReviewResult:
	return _review_result


func commit_review_result(result: ReviewResult) -> bool:
	if not _has_beta_finalization or _review_result != null or result == null:
		return false
	if result.get_profile_id().is_empty() or not is_finite(result.get_final_review()) or result.get_final_review() < 0.0 or result.get_final_review() > 10.0:
		return false
	_review_result = result
	values_changed.emit()
	return true


func has_awareness_result() -> bool:
	return _awareness_result != null


func get_awareness_result() -> AwarenessResult:
	return _awareness_result


func commit_awareness_result(result: AwarenessResult) -> bool:
	if not _has_beta_finalization or _review_result == null or _awareness_result != null or result == null:
		return false
	if result.get_formula_id() != &"primitive_awareness_v2" or result.get_marketing_output_used() != _marketing_output or result.get_total_awareness() < 0 or not is_finite(result.get_awareness_multiplier()):
		return false
	_awareness_result = result
	values_changed.emit()
	return true


func has_launch_market_context_result() -> bool:
	return _launch_market_context_result != null


func get_launch_market_context_result() -> LaunchMarketContextResult:
	return _launch_market_context_result


func commit_launch_market_context_result(result: LaunchMarketContextResult) -> bool:
	if not _has_beta_finalization or _review_result == null or _awareness_result == null or _launch_market_context_result != null or result == null:
		return false
	if (
		result.get_profile_id() != &"primitive_launch_market_context_v1"
		or result.get_competitor_id_for_authority() != _competitor_snapshot_id
		or result.get_forecast_id_for_authority() != _market_forecast_snapshot_id
		or result.get_player_launch_cycle() != _current_cycle
		or result.was_competitor_revealed_at_launch() != _competitor_snapshot_revealed
		or result.was_forecast_revealed_at_launch() != _market_forecast_snapshot_revealed
		or result.get_competitor_target_cycle() <= 0
		or result.get_forecast_multiplier_basis_points() <= 0
		or result.get_cycle_delta() != _current_cycle - result.get_competitor_target_cycle()
		or result.has_competitor_consequence()
		or result.has_combined_release_modifier()
	):
		return false
	_launch_market_context_result = result
	values_changed.emit()
	return true


func has_units_sold_result() -> bool:
	return _units_sold_result != null


func get_units_sold_result() -> UnitsSoldResult:
	return _units_sold_result


func commit_units_sold_result(result: UnitsSoldResult) -> bool:
	if not _has_beta_finalization or _review_result == null or _awareness_result == null or _launch_market_context_result == null or _units_sold_result != null or result == null:
		return false
	var expected := PrimitiveUnitsSoldCalculator.calculate(self)
	if expected == null:
		return false
	var review_tenths := int(round(_review_result.get_final_review() * 10.0))
	var expected_awareness_numerator := _awareness_result.get_awareness_scale() + _awareness_result.get_total_awareness()
	if (
		result.get_formula_id() != &"primitive_units_sold_v1"
		or result.get_sales_period() != &"month_1"
		or result.get_base_monthly_demand() != 500
		or result.get_final_review_tenths() != review_tenths
		or result.get_quality_baseline_tenths() != 70
		or result.get_total_awareness() != _awareness_result.get_total_awareness()
		or result.get_awareness_scale() != _awareness_result.get_awareness_scale()
		or result.get_awareness_numerator() != expected_awareness_numerator
		or result.get_launch_decay_basis_points() != 10000
		or result.get_market_demand_basis_points() != _launch_market_context_result.get_forecast_multiplier_basis_points()
		or result.get_exact_numerator() != expected.get_exact_numerator()
		or result.get_exact_denominator() != expected.get_exact_denominator()
		or not is_finite(result.get_pre_rounding_units())
		or result.get_pre_rounding_units() != expected.get_pre_rounding_units()
		or result.get_final_units_sold() != expected.get_final_units_sold()
	):
		return false
	_units_sold_result = result
	values_changed.emit()
	return true


func has_month_one_sales_revenue_result() -> bool:
	return _month_one_sales_revenue_result != null


func get_month_one_sales_revenue_result() -> MonthOneSalesRevenueResult:
	return _month_one_sales_revenue_result


func commit_month_one_sales_revenue_result(result: MonthOneSalesRevenueResult) -> bool:
	if _units_sold_result == null or _month_one_sales_revenue_result != null or result == null:
		return false
	var expected := PrimitiveMonthOneSalesRevenueCalculator.calculate(self)
	if expected == null or not _sales_revenue_results_match(result, expected):
		return false
	_month_one_sales_revenue_result = result
	values_changed.emit()
	return true


func _sales_revenue_results_match(result: MonthOneSalesRevenueResult, expected: MonthOneSalesRevenueResult) -> bool:
	return (
		result.get_formula_id() == expected.get_formula_id()
		and result.get_total_month_one_units() == expected.get_total_month_one_units()
		and result.get_sales_cycle_count() == expected.get_sales_cycle_count()
		and result.get_price_cents() == expected.get_price_cents()
		and result.get_platform_retention_percent() == expected.get_platform_retention_percent()
		and result.get_cycle_units() == expected.get_cycle_units()
		and result.get_cumulative_units() == expected.get_cumulative_units()
		and result.get_cumulative_gross_cents() == expected.get_cumulative_gross_cents()
		and result.get_cumulative_net_entitlement_cents() == expected.get_cumulative_net_entitlement_cents()
		and result.get_projected_month_one_gross_cents() == expected.get_projected_month_one_gross_cents()
		and result.get_projected_month_one_net_cents() == expected.get_projected_month_one_net_cents()
		and result.get_earned_sales_cycle_count() == 0
		and result.get_cumulative_earned_units() == 0
		and result.get_net_cents_previously_settled() == 0
		and result.get_newly_payable_cents() == 0
	)


## Freezes the existing authoritative project fields as future Launch/Review inputs.
func finalize_beta() -> bool:
	if _has_beta_finalization or not _has_alpha_finalization or not has_launch_feature_work():
		return false
	if _required_scope < 0 or _current_scope < 0 or _hidden_bugs < 0 or _known_bugs < 0 or _fixed_bugs < 0 or _marketing_output < 0 or _current_cycle < 0:
		return false
	if not has_competitor_snapshot() or not has_market_forecast_snapshot():
		return false
	_has_beta_finalization = true
	values_changed.emit()
	return true


func _normalize_feature_history_ids(value: Variant, phase_label: String = "Design") -> Dictionary:
	if not value is Array:
		push_warning("%s Feature history must be provided as arrays." % phase_label)
		return {&"valid": false}
	var normalized: Array[StringName] = []
	var seen: Dictionary[StringName, bool] = {}
	for raw_id: Variant in value:
		if typeof(raw_id) != TYPE_STRING and typeof(raw_id) != TYPE_STRING_NAME:
			push_warning("%s Feature history IDs must be strings." % phase_label)
			return {&"valid": false}
		var id := StringName(raw_id)
		if id.is_empty() or seen.has(id):
			push_warning("%s Feature history IDs must be nonempty and unique: %s" % [phase_label, id])
			return {&"valid": false}
		seen[id] = true
		normalized.append(id)
	return {&"valid": true, &"ids": normalized}


func get_current_cycle() -> int:
	return _current_cycle


## One standard successful player action advances exactly one half-month cycle.
func can_advance_cycle() -> bool:
	return not _has_beta_finalization and _current_cycle < MAX_SIGNED_INT


func advance_cycle() -> bool:
	if _has_beta_finalization:
		return false
	if not can_advance_cycle():
		push_warning("Cycle count overflowed.")
		return false
	_current_cycle += 1
	cycle_changed.emit()
	return true


## Scope may exceed Required Scope. The excess is retained so project ambition is
## represented accurately; completion logic belongs to a later milestone.
func add_scope(amount: int) -> bool:
	if _has_beta_finalization:
		return false
	if amount < 0:
		push_warning("Scope additions cannot be negative.")
		return false
	if amount == 0:
		return true

	_current_scope += amount
	values_changed.emit()
	return true


func _is_valid_core_score(category: int) -> bool:
	return _core_scores.has(category)
