class_name MonthOneSalesRevenueResult
extends RefCounted

var _formula_id: StringName
var _total_month_one_units: int
var _sales_cycles: int
var _price_cents: int
var _platform_retention_percent: int
var _cycle_units: Array[int]
var _cumulative_units: Array[int]
var _cumulative_gross_cents: Array[int]
var _cumulative_net_entitlement_cents: Array[int]
var _projected_month_one_gross_cents: int
var _projected_month_one_net_cents: int


func _init(
	formula_id: StringName,
	total_month_one_units: int,
	sales_cycles: int,
	price_cents: int,
	platform_retention_percent: int,
	cycle_units: Array[int],
	cumulative_units: Array[int],
	cumulative_gross_cents: Array[int],
	cumulative_net_entitlement_cents: Array[int],
	projected_month_one_gross_cents: int,
	projected_month_one_net_cents: int
) -> void:
	_formula_id = formula_id
	_total_month_one_units = total_month_one_units
	_sales_cycles = sales_cycles
	_price_cents = price_cents
	_platform_retention_percent = platform_retention_percent
	_cycle_units = cycle_units.duplicate()
	_cumulative_units = cumulative_units.duplicate()
	_cumulative_gross_cents = cumulative_gross_cents.duplicate()
	_cumulative_net_entitlement_cents = cumulative_net_entitlement_cents.duplicate()
	_projected_month_one_gross_cents = projected_month_one_gross_cents
	_projected_month_one_net_cents = projected_month_one_net_cents


func get_formula_id() -> StringName: return _formula_id
func get_total_month_one_units() -> int: return _total_month_one_units
func get_sales_cycle_count() -> int: return _sales_cycles
func get_price_cents() -> int: return _price_cents
func get_platform_retention_percent() -> int: return _platform_retention_percent
func get_cycle_units() -> Array[int]: return _cycle_units.duplicate()
func get_cumulative_units() -> Array[int]: return _cumulative_units.duplicate()
func get_cumulative_gross_cents() -> Array[int]: return _cumulative_gross_cents.duplicate()
func get_cumulative_net_entitlement_cents() -> Array[int]: return _cumulative_net_entitlement_cents.duplicate()
func get_projected_month_one_gross_cents() -> int: return _projected_month_one_gross_cents
func get_projected_month_one_net_cents() -> int: return _projected_month_one_net_cents


## Legacy projection-only views: a frozen launch projection never earns cash.
## Mutable actual earning/settlement now lives in RunState released-game records.
func get_earned_sales_cycle_count() -> int: return 0
func get_cumulative_earned_units() -> int: return 0
func get_net_cents_previously_settled() -> int: return 0
func get_newly_payable_cents() -> int: return 0
