## Fixed five-action legal Studio prefix; no hidden state or cash adjustment.
extends RefCounted

var _step := 0

static func factory(_config: Dictionary) -> Callable:
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	var feature_id := "colored_text" if _step < 2 else "8_color_palette"
	var command: Dictionary = {}
	if _step < 4:
		var quote: Dictionary = {}
		for candidate: Dictionary in view.research_quotes:
			if str(candidate.get("feature_id", "")) == feature_id:
				quote = candidate
				break
		command = {"type": &"admit_research" if _step % 2 == 0 else &"research", "payload": {"quote": quote}}
	else:
		var release_id: String = "" if view.releases.is_empty() else str(view.releases[0].id)
		command = {"type": &"campaign", "payload": {"release_id": release_id}}
	_step += 1
	return command
