class_name ContractResult
extends RefCounted

var _scope: int
var _core_half_units: Dictionary
var _completion_numerator: int
var _payout_cents: int
var _remainder_cents: int
var _upfront_cents: int
var _denominator: int
var _promotion: int
var _challenge_grade_bp := 0
var _bonus_cash_cents := 0
var _bonus_promotion := 0


func _init(scope: int, core_half_units: Dictionary, completion_numerator: int, payout_cents: int, remainder_cents: int, upfront_cents: int = ContractState.GUARANTEED_UPFRONT_CENTS, denominator: int = 96, promotion: int = 0, challenge_grade_bp: int = 0, bonus_cash_cents: int = 0, bonus_promotion: int = 0) -> void:
	_scope = scope
	_core_half_units = core_half_units.duplicate()
	_completion_numerator = completion_numerator
	_payout_cents = payout_cents
	_remainder_cents = remainder_cents
	_upfront_cents = upfront_cents
	_denominator = denominator
	_promotion = promotion
	_challenge_grade_bp = challenge_grade_bp
	_bonus_cash_cents = bonus_cash_cents
	_bonus_promotion = bonus_promotion


func get_scope() -> int:
	return _scope


func get_core_score_half_units(category: ProjectState.CoreScore) -> int:
	return _core_half_units.get(category, 0)


func get_completion_numerator() -> int:
	return _completion_numerator


func get_payout_cents() -> int:
	return _payout_cents


func get_upfront_cents() -> int:
	return _upfront_cents


func get_completion_payment_cents() -> int:
	return _remainder_cents


func get_completion_percent() -> float:
	return float(_completion_numerator) * 100.0 / float(_denominator)

func get_promotion() -> int: return _promotion
func get_challenge_grade_bp() -> int: return _challenge_grade_bp
func get_bonus_cash_cents() -> int: return _bonus_cash_cents
func get_bonus_promotion() -> int: return _bonus_promotion
