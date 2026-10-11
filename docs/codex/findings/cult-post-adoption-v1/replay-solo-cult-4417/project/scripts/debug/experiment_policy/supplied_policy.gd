## Read-only policy and detached-observation measurements for the declared study.
extends RefCounted

const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
var _development: Array[Callable] = []
var _first_contract_checked := false
var _cycle_cap := 53
var _observations: Array = []

static func factory(config: Dictionary) -> Callable:
	if not config.get("hands_by_release") is Array or config.hands_by_release.size() != 5 or config.get("cycle_cap") != 53: return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	for hands: Variant in config.hands_by_release:
		if not hands is Dictionary: return Callable()
		var fixture_config := {"genre":"action", "theme":"fantasy", "name_prefix":"Cult post adoption", "selection":"features_first", "hands":hands}
		var delegate: Callable = Fixture.factory(fixture_config)
		if not delegate.is_valid(): return Callable()
		policy._development.append(delegate)
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	_record_observation(view)
	var decision := _choose(view)
	var productive: bool = decision.type == &"begin_development" or (decision.type == &"development" and decision.payload.request.type == &"play") or (decision.type == &"contract" and decision.payload.request.type == &"play")
	if view.run_cycle >= _cycle_cap and productive:
		return {"type":&"declared_study_cycle_bound"}
	return decision

func _choose(view: Dictionary) -> Dictionary:
	if view.phase == &"contract":
		if view.contract.completed: return {"type":&"dismiss_contract"}
		var cards: Array = view.contract.candidates.duplicate(true)
		if cards.is_empty(): return _contract(view,&"begin")
		var tokens: Array[int] = []
		for index in range(mini(4,cards.size())): tokens.append(int(cards[index].token))
		return _contract(view,&"play",{"candidate_ids":tokens})
	var released: int = view.releases.size()
	if view.phase == &"studio" and released == 1 and not _first_contract_checked:
		_first_contract_checked = true
		var offers: Array = view.studio_actions.contract_offers
		if not offers.is_empty(): return {"type":&"accept_contract", "payload":offers[0]}
	return _development[mini(released,4)].call(view)

func _record_observation(view: Dictionary) -> void:
	_observations.append({"run_id":str(view.run_id), "sequence":view.sequence, "run_cycle":view.run_cycle, "cash_cents":view.cash_cents, "fans":view.fans, "phase":str(view.phase), "releases":view.releases.duplicate(true)})
	var file := FileAccess.open("user://cult-post-observations-%s.json" % view.run_id,FileAccess.WRITE)
	if file == null:
		push_error("Cult study measurement output unavailable")
		return
	file.store_string(JSON.stringify({"kind":"detached_public_observations_v1", "observations":_observations},"\t"))

static func _contract(view: Dictionary,kind: StringName,payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.contract
	return {"type":&"contract","payload":{"request":{"schema_version":1,"type":kind,"offer_id":current.offer_id,"hand_count":current.hand_count,"sequence":current.sequence,"run_cycle":current.run_cycle,"payload":payload}}}
