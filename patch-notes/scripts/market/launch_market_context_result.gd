class_name LaunchMarketContextResult
extends RefCounted

enum TimingRelation {
	BEFORE_TARGET,
	ON_TARGET,
	AFTER_TARGET,
}

var _profile_id: StringName
var _forecast_id: StringName
var _forecast_multiplier_basis_points: int
var _forecast_revealed_at_launch: bool
var _competitor_id: StringName
var _competitor_target_cycle: int
var _player_launch_cycle: int
var _cycle_delta: int
var _timing_relation: TimingRelation
var _competitor_revealed_at_launch: bool


func _init(
	profile_id: StringName,
	forecast_id: StringName,
	forecast_multiplier_basis_points: int,
	forecast_revealed_at_launch: bool,
	competitor_id: StringName,
	competitor_target_cycle: int,
	player_launch_cycle: int,
	cycle_delta: int,
	timing_relation: TimingRelation,
	competitor_revealed_at_launch: bool
) -> void:
	_profile_id = profile_id
	_forecast_id = forecast_id
	_forecast_multiplier_basis_points = forecast_multiplier_basis_points
	_forecast_revealed_at_launch = forecast_revealed_at_launch
	_competitor_id = competitor_id
	_competitor_target_cycle = competitor_target_cycle
	_player_launch_cycle = player_launch_cycle
	_cycle_delta = cycle_delta
	_timing_relation = timing_relation
	_competitor_revealed_at_launch = competitor_revealed_at_launch


func get_profile_id() -> StringName: return _profile_id
func get_forecast_id_for_authority() -> StringName: return _forecast_id
func get_forecast_multiplier_basis_points() -> int: return _forecast_multiplier_basis_points
func was_forecast_revealed_at_launch() -> bool: return _forecast_revealed_at_launch
func get_competitor_id_for_authority() -> StringName: return _competitor_id
func get_competitor_target_cycle() -> int: return _competitor_target_cycle
func get_player_launch_cycle() -> int: return _player_launch_cycle
func get_cycle_delta() -> int: return _cycle_delta
func get_timing_relation() -> TimingRelation: return _timing_relation
func was_competitor_revealed_at_launch() -> bool: return _competitor_revealed_at_launch


## Primitive authority defines no competitor gameplay consequence or combined
## release modifier. These explicit queries distinguish absence from neutral 1.00.
func has_competitor_consequence() -> bool: return false
func has_combined_release_modifier() -> bool: return false


func get_forecast_multiplier_text() -> String:
	return "%d.%02d" % [_forecast_multiplier_basis_points / 10000, (_forecast_multiplier_basis_points % 10000) / 100]


func get_timing_relation_text() -> String:
	match _timing_relation:
		TimingRelation.BEFORE_TARGET:
			return "before target"
		TimingRelation.ON_TARGET:
			return "on target"
		TimingRelation.AFTER_TARGET:
			return "after target"
	return ""
