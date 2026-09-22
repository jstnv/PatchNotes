class_name AwarenessResult
extends RefCounted

var _formula_id: StringName
var _marketing_output: int
var _launch_marketing: int
var _launch_marketing_decay_basis_points: int
var _current_launch_marketing: int
var _organic_awareness: int
var _existing_fans: int
var _fan_visibility_basis_points: int
var _fan_launch_decay_basis_points: int
var _fan_awareness: int
var _total_awareness: int
var _awareness_scale: int
var _awareness_multiplier: float


func _init(formula_id: StringName, marketing_output: int, launch_marketing: int, launch_marketing_decay_basis_points: int, current_launch_marketing: int, organic_awareness: int, existing_fans: int, fan_visibility_basis_points: int, fan_launch_decay_basis_points: int, fan_awareness: int, total_awareness: int, awareness_scale: int, awareness_multiplier: float) -> void:
	_formula_id = formula_id
	_marketing_output = marketing_output
	_launch_marketing = launch_marketing
	_launch_marketing_decay_basis_points = launch_marketing_decay_basis_points
	_current_launch_marketing = current_launch_marketing
	_organic_awareness = organic_awareness
	_existing_fans = existing_fans
	_fan_visibility_basis_points = fan_visibility_basis_points
	_fan_launch_decay_basis_points = fan_launch_decay_basis_points
	_fan_awareness = fan_awareness
	_total_awareness = total_awareness
	_awareness_scale = awareness_scale
	_awareness_multiplier = awareness_multiplier


func get_formula_id() -> StringName: return _formula_id
func get_marketing_output_used() -> int: return _marketing_output
func get_launch_marketing() -> int: return _launch_marketing
func get_launch_marketing_decay_basis_points() -> int: return _launch_marketing_decay_basis_points
func get_current_launch_marketing() -> int: return _current_launch_marketing
func get_organic_awareness() -> int: return _organic_awareness
func get_existing_fans() -> int: return _existing_fans
func get_fan_visibility_basis_points() -> int: return _fan_visibility_basis_points
func get_fan_launch_decay_basis_points() -> int: return _fan_launch_decay_basis_points
func get_fan_awareness() -> int: return _fan_awareness
func get_total_awareness() -> int: return _total_awareness
func get_awareness_scale() -> int: return _awareness_scale
func get_awareness_multiplier() -> float: return _awareness_multiplier
