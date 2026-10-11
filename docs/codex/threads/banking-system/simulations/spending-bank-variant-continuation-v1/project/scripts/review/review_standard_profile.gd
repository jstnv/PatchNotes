class_name ReviewStandardProfile
extends RefCounted

var _id: StringName
var _standards: Dictionary[ProjectState.CoreScore, int]


func _init(id: StringName, standards: Dictionary[ProjectState.CoreScore, int]) -> void:
	_id = id
	_standards = standards.duplicate()


func get_id() -> StringName:
	return _id


func get_standard(category: ProjectState.CoreScore) -> int:
	return _standards.get(category, 0)


func get_standards() -> Dictionary[ProjectState.CoreScore, int]:
	return _standards.duplicate()


func is_valid() -> bool:
	if _id.is_empty() or _standards.size() != ProjectState.CoreScore.size():
		return false
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		if _standards.get(category, 0) <= 0:
			return false
	return true
