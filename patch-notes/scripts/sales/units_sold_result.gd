class_name UnitsSoldResult
extends RefCounted

var _formula_id: StringName
var _sales_period: StringName
var _base_monthly_demand: int
var _final_review_tenths: int
var _quality_baseline_tenths: int
var _total_awareness: int
var _awareness_scale: int
var _awareness_numerator: int
var _launch_decay_basis_points: int
var _market_demand_basis_points: int
var _exact_numerator: int
var _exact_denominator: int
var _pre_rounding_units: float
var _final_units_sold: int


func _init(
	formula_id: StringName,
	sales_period: StringName,
	base_monthly_demand: int,
	final_review_tenths: int,
	quality_baseline_tenths: int,
	total_awareness: int,
	awareness_scale: int,
	awareness_numerator: int,
	launch_decay_basis_points: int,
	market_demand_basis_points: int,
	exact_numerator: int,
	exact_denominator: int,
	pre_rounding_units: float,
	final_units_sold: int
) -> void:
	_formula_id = formula_id
	_sales_period = sales_period
	_base_monthly_demand = base_monthly_demand
	_final_review_tenths = final_review_tenths
	_quality_baseline_tenths = quality_baseline_tenths
	_total_awareness = total_awareness
	_awareness_scale = awareness_scale
	_awareness_numerator = awareness_numerator
	_launch_decay_basis_points = launch_decay_basis_points
	_market_demand_basis_points = market_demand_basis_points
	_exact_numerator = exact_numerator
	_exact_denominator = exact_denominator
	_pre_rounding_units = pre_rounding_units
	_final_units_sold = final_units_sold


func get_formula_id() -> StringName: return _formula_id
func get_sales_period() -> StringName: return _sales_period
func get_base_monthly_demand() -> int: return _base_monthly_demand
func get_final_review_tenths() -> int: return _final_review_tenths
func get_quality_baseline_tenths() -> int: return _quality_baseline_tenths
func get_total_awareness() -> int: return _total_awareness
func get_awareness_scale() -> int: return _awareness_scale
func get_awareness_numerator() -> int: return _awareness_numerator
func get_launch_decay_basis_points() -> int: return _launch_decay_basis_points
func get_market_demand_basis_points() -> int: return _market_demand_basis_points
func get_exact_numerator() -> int: return _exact_numerator
func get_exact_denominator() -> int: return _exact_denominator
func get_pre_rounding_units() -> float: return _pre_rounding_units
func get_final_units_sold() -> int: return _final_units_sold
