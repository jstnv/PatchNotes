## Thread-owned, observation-only policy for the predeclared SideStreet comparison.
## It never edits game rules or inspects hidden future state.
extends RefCounted

const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
var _config: Dictionary
var _development: Callable
var _ironclad_started := false
var _sidestreet_started := false
var _publisher_started := false

static func factory(config: Dictionary) -> Callable:
	if config.get("mode") not in ["prefix", "pair"]: return Callable()
	if config.mode == "pair" and config.get("arm") not in ["take", "skip"]: return Callable()
	if not config.get("development") is Dictionary: return Callable()
	var development: Callable = Development.factory(config.development)
	if not development.is_valid(): return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._config = config.duplicate(true)
	policy._development = development
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"contract":
		if view.contract.completed: return {"type": &"dismiss_contract"}
		var cards: Array = view.contract.candidates.duplicate(true)
		if cards.is_empty(): return _contract(view, &"begin")
		cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			if bool(a.renewable) != bool(b.renewable): return not bool(a.renewable)
			return int(a.token) < int(b.token))
		var tokens: Array[int] = []
		for index in range(mini(4,cards.size())): tokens.append(int(cards[index].token))
		return _contract(view, &"play", {"candidate_ids":tokens})
	if view.phase != &"studio": return _development.call(view)
	var offers: Array = view.studio_actions.contract_offers
	if _config.mode == "prefix":
		if view.releases.size() >= 1 and not _ironclad_started:
			for offer: Dictionary in offers:
				if offer.kind == &"ironclad":
					_ironclad_started = true
					return {"type": &"accept_contract", "payload":offer}
	else:
		if _config.arm == "take" and not _sidestreet_started:
			for offer: Dictionary in offers:
				if offer.kind == &"sidestreet":
					_sidestreet_started = true
					return {"type": &"accept_contract", "payload":offer}
			return {"type": &"accept_contract", "payload":{"kind":"sidestreet","offer_id":""}}
		if not _publisher_started:
			for offer: Dictionary in offers:
				if offer.kind == &"publisher" and String(offer.quote.get("publisher_id", "")) in ["crown_quill", "neon_circuit"]:
					_publisher_started = true
					return {"type": &"accept_contract", "payload":offer}
			return {"type": &"accept_contract", "payload":{"kind":"publisher","quote":{}}}
	return _development.call(view)

static func _contract(view: Dictionary, kind: StringName, payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.contract
	return {"type": &"contract", "payload":{"request":{"schema_version":1,"type":kind,"offer_id":current.offer_id,"hand_count":current.hand_count,"sequence":current.sequence,"run_cycle":current.run_cycle,"payload":payload}}}
