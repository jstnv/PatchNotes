## Synchronous code-owned authority fence. Services/transaction scratch fields
## are not saved state. Never retain this projection across a successful action.
extends RefCounted

const Replay := preload("res://scripts/simulation/development_replay.gd")
const SCRATCH := ["_productive_cycle_in_progress","_committing_cycle_cash","_publishing_cycle","_cycle_plan","_pending_relationship_plan","_preparing_project"]

static func authority(value: Object) -> Dictionary:
	var result := {}
	for property in value.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name not in SCRATCH:
			result[property.name] = Replay.freeze(value.get(property.name))
	return result

static func copy_fields(source: Object, destination: Object) -> void:
	for property in source.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = source.get(property.name)
			destination.set(property.name,value.duplicate(true) if value is Array or value is Dictionary else value)
