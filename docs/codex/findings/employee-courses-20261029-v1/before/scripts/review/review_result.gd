class_name ReviewResult
extends RefCounted

var _profile_id: StringName
var _standards: Dictionary[ProjectState.CoreScore, int]
var _normalized_ratios: Dictionary[ProjectState.CoreScore, float]
var _average_ratio: float
var _core_deviation: float
var _production_quality: float
var _production_rating: float
var _scope_completion: float
var _remaining_bugs: int
var _bug_density: float
var _bug_multiplier: float
var _variance_roll: int
var _variance_modifier: float
var _unrounded_review: float
var _final_review: float
var _genre_deviation: float
var _genre_modifier: float
var _pre_genre_review: float


func _init(profile: ReviewStandardProfile, ratios: Dictionary[ProjectState.CoreScore, float], average_ratio: float, core_deviation: float, production_quality: float, production_rating: float, scope_completion: float, remaining_bugs: int, bug_density: float, bug_multiplier: float, variance_roll: int, variance_modifier: float, unrounded_review: float, final_review: float, genre_deviation: float = 0.0, genre_modifier: float = 1.0, pre_genre_review: float = -1.0) -> void:
	_profile_id = profile.get_id()
	_standards = profile.get_standards()
	_normalized_ratios = ratios.duplicate()
	_average_ratio = average_ratio
	_core_deviation = core_deviation
	_production_quality = production_quality
	_production_rating = production_rating
	_scope_completion = scope_completion
	_remaining_bugs = remaining_bugs
	_bug_density = bug_density
	_bug_multiplier = bug_multiplier
	_variance_roll = variance_roll
	_variance_modifier = variance_modifier
	_unrounded_review = unrounded_review
	_final_review = final_review
	_genre_deviation = genre_deviation
	_genre_modifier = genre_modifier
	_pre_genre_review = pre_genre_review if pre_genre_review >= 0.0 else unrounded_review


func get_profile_id() -> StringName: return _profile_id
func get_standard(category: ProjectState.CoreScore) -> int: return _standards.get(category, 0)
func get_standards() -> Dictionary[ProjectState.CoreScore, int]: return _standards.duplicate()
func get_normalized_ratio(category: ProjectState.CoreScore) -> float: return _normalized_ratios.get(category, 0.0)
func get_normalized_ratios() -> Dictionary[ProjectState.CoreScore, float]: return _normalized_ratios.duplicate()
func get_average_ratio() -> float: return _average_ratio
func get_core_deviation() -> float: return _core_deviation
func get_production_quality() -> float: return _production_quality
func get_production_rating() -> float: return _production_rating
func get_scope_completion() -> float: return _scope_completion
func get_remaining_bugs_for_authority() -> int: return _remaining_bugs
func get_bug_density_for_authority() -> float: return _bug_density
func get_bug_multiplier() -> float: return _bug_multiplier
func get_variance_roll() -> int: return _variance_roll
func get_variance_modifier() -> float: return _variance_modifier
func get_unrounded_review() -> float: return _unrounded_review
func get_final_review() -> float: return _final_review
func get_genre_deviation() -> float: return _genre_deviation
func get_genre_modifier() -> float: return _genre_modifier
func get_pre_genre_review() -> float: return _pre_genre_review
