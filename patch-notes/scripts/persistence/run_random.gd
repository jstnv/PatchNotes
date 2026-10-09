class_name RunRandom
extends RefCounted

const ALGORITHM := "godot-4.7.1-rng-v1"
const STREAMS := [&"snapshot", &"review", &"design_deal", &"design_finalize", &"alpha_deal", &"alpha_finalize", &"beta_deal", &"beta_insight", &"contract_deal"]
var streams: Dictionary = {}

func _init() -> void:
	for id: StringName in STREAMS:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		streams[id] = rng

func stream(id: StringName) -> RandomNumberGenerator:
	return streams[id]

func snapshot() -> Dictionary:
	var result := {}
	for id: StringName in STREAMS:
		result[id] = {"seed":streams[id].seed,"state":streams[id].state}
	return result

func restore(values: Dictionary) -> bool:
	if values.size() != STREAMS.size(): return false
	for id: StringName in STREAMS:
		if not values.get(id) is Dictionary or values[id].size() != 2: return false
		if typeof(values[id].get("seed")) != TYPE_INT or typeof(values[id].get("state")) != TYPE_INT: return false
	for id: StringName in STREAMS:
		streams[id].seed = values[id].seed
		streams[id].state = values[id].state
	return true
