class_name CompetitorDefinition
extends RefCounted

var _id: StringName
var _display_name: String
var _target_release_cycle: int
var _selection_weight: int


func _init(id: StringName, display_name: String, target_release_cycle: int, selection_weight: int) -> void:
	_id = id
	_display_name = display_name
	_target_release_cycle = target_release_cycle
	_selection_weight = selection_weight


func get_id() -> StringName:
	return _id


func get_display_name() -> String:
	return _display_name


func get_target_release_cycle() -> int:
	return _target_release_cycle


func get_selection_weight() -> int:
	return _selection_weight
