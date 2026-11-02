## Retain the canonical fresh recipe bootstrap on both sides of exact replay.
extends RefCounted
const BaseFactory=preload("res://scripts/simulation/run_factory.gd")
const Transport=preload("res://scripts/debug/search_career_transport.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
static func create_fresh_session(recipe: Variant,definitions: RefCounted) -> RefCounted:
	var base: RefCounted=BaseFactory.create_fresh_session(recipe,definitions)
	if base==null:return null
	var expected: Dictionary=Replay.state(base)
	var adapted: RefCounted=Transport.new()
	if not adapted.initialize(base.run,base.catalog,base.snapshots) or Replay.state(adapted)!=expected:return null
	return adapted
