## Intentional negative fixture, not a game bug or an AI policy recommendation.
extends RefCounted
const Finite := preload("res://scripts/simulation/finite_fixture_policy.gd")

static func factory(config: Dictionary) -> Callable:
	var development: Callable = Finite.factory(config)
	if not development.is_valid(): return Callable()
	return func(view: Dictionary) -> Dictionary:
		if view.phase == &"studio" and view.releases.size() >= 2:
			return {"type":&"intentional_reducer_rejection_fixture"}
		return development.call(view)
