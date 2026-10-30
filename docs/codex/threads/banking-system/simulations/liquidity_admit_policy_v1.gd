## Fixed legal Studio Research admissions; no productive cycles or hidden state.
extends RefCounted

var _ids: Array = []
var _step := 0

static func factory(config: Dictionary) -> Callable:
	if not config.get("feature_ids") is Array or config.feature_ids.is_empty(): return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._ids = config.feature_ids.duplicate()
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	if view.phase != &"studio" or _step >= _ids.size(): return {}
	var target: String = str(_ids[_step])
	var quote: Dictionary = {}
	for candidate: Dictionary in view.research_quotes:
		if str(candidate.get("feature_id", "")) == target:
			quote = candidate
			break
	_step += 1
	return {"type":&"admit_research","payload":{"quote":quote}}
