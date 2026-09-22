class_name MarketForecastDefinition
extends RefCounted

const BASIS_POINTS_PER_ONE := 10000

var _id: StringName
var _display_name: String
var _launch_demand_basis_points: int
var _selection_weight: int


func _init(id: StringName, display_name: String, launch_demand_basis_points: int, selection_weight: int) -> void:
	_id = id
	_display_name = display_name
	_launch_demand_basis_points = launch_demand_basis_points
	_selection_weight = selection_weight


func get_id() -> StringName:
	return _id


func get_display_name() -> String:
	return _display_name


func get_launch_demand_basis_points() -> int:
	return _launch_demand_basis_points


func get_selection_weight() -> int:
	return _selection_weight


func get_launch_demand_multiplier_text() -> String:
	return "%d.%02d" % [_launch_demand_basis_points / BASIS_POINTS_PER_ONE, (_launch_demand_basis_points % BASIS_POINTS_PER_ONE) / 100]
