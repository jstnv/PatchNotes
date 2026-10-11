## Test-only example: explicit decisions from public observation fields.
## This file is copied to the experiment's frozen project, never the live source.
extends RefCounted

static func factory(config: Dictionary) -> Callable:
	# Reuse the finite policy as a small example of dependency handling. res://
	# dependencies refer only to files in the frozen project. No ../ imports.
	var fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
	var delegate: Callable = fixture.factory(config)
	if not delegate.is_valid(): return Callable()
	return func(observation: Dictionary) -> Dictionary:
		# Returning a legal command does not execute it. CampaignSession owns
		# validation, RNG, effects and ordered events exactly once.
		return delegate.call(observation)
