## Explicit bounded TEST strategy. Not approved competitor planning or balance.
## Uses detached public observations and an independent, explicitly seeded RNG.
## The verifier supplements Studio observations with session.quote_bank(50000,24).
## No quote means no borrowing attempt; it never fabricates quote affordability.
extends RefCounted

const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
const POLICY_ID := "bounded-campaign-stress"
const POLICY_VERSION := "1"
var _config: Dictionary
var _rng := RandomNumberGenerator.new()
var _development: Callable
var _contracts: Dictionary = {}
var _campaigns: Dictionary = {}
var _researched := false
var _borrowed := false

static func factory(config: Dictionary) -> Callable:
	if not config.get("policy_seed") is String or not config.policy_seed.is_valid_int() or int(config.policy_seed) < 0: return Callable()
	if not config.get("development") is Dictionary or not Development.valid_config(config.development): return Callable()
	if config.get("card_order") not in ["configured","shuffle"]: return Callable()
	var policy: RefCounted = load("res://scripts/debug/campaign_stress_policy.gd").new()
	policy._config = config.duplicate(true)
	policy._rng.seed = int(config.policy_seed)
	policy._development = Development.factory(config.development)
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func _shuffle(cards: Array) -> void:
	for index in range(cards.size()-1,0,-1):
		var other: int = _rng.randi_range(0,index)
		var held: Variant = cards[index]
		cards[index] = cards[other]
		cards[other] = held

func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"contract":
		if view.contract.completed: return {"type":&"dismiss_contract"}
		var cards: Array = view.contract.candidates.duplicate(true)
		if cards.is_empty(): return _contract(view,&"begin")
		_shuffle(cards)
		var tokens: Array[int] = []
		for index in range(mini(4,cards.size())): tokens.append(int(cards[index].token))
		return _contract(view,&"play",{"candidate_ids":tokens})
	if view.phase != &"studio":
		var decision: Dictionary = _development.call(view)
		if decision.get("type") == &"development" and decision.payload.request.type == &"play" and _config.card_order == "shuffle":
			var cards: Array = view.development.candidates.duplicate(true)
			_shuffle(cards)
			var tokens: Array[int] = []
			for index in range(mini(4,cards.size())): tokens.append(int(cards[index].token))
			decision.payload.request.payload.candidate_ids = tokens
		return decision
	var released: int = view.releases.size()
	if released == 0: return _development.call(view)
	var actions: Dictionary = view.studio_actions
	# At most one available Contract in each inter-release window. Completion is
	# mandatory once accepted; no economic stop is hidden by a skip or restart.
	if not _contracts.has(released) and not actions.contract_offers.is_empty():
		_contracts[released] = true
		var offers: Array = actions.contract_offers.duplicate(true)
		_shuffle(offers)
		return {"type":&"accept_contract","payload":offers[0]}
	if not actions.hire_quote.is_empty(): return {"type":&"hire","payload":{"quote":actions.hire_quote}}
	if not _borrowed and view.get("stress_bank_quote",{}).get("accepted",false):
		_borrowed = true
		return {"type":&"bank_borrow","payload":{"quote":view.stress_bank_quote}}
	if released >= 2:
		for quote: Dictionary in actions.bank_payoff_quotes:
			if view.cash_cents >= int(actions.finance.get("total_overdue_cents",0))+int(quote.total_cents): return {"type":&"bank_payoff","payload":{"quote":quote}}
	# Complete an admitted head before considering further discretionary actions.
	for quote: Dictionary in view.research_quotes:
		if quote.get("head",false): return {"type":&"research","payload":{"quote":quote}}
	if not _researched:
		var eligible: Array = []
		for quote: Dictionary in view.research_quotes:
			if quote.get("can_admit",false): eligible.append(quote)
		if not eligible.is_empty():
			_shuffle(eligible)
			_researched = true
			return {"type":&"admit_research","payload":{"quote":eligible[0]}}
	if not _campaigns.has(released):
		_campaigns[released] = true
		var latest: Dictionary = view.releases[-1]
		if latest.campaign.get("can_purchase",false): return {"type":&"campaign","payload":{"release_id":latest.id}}
	return _development.call(view)

static func _contract(view: Dictionary,kind: StringName,payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.contract
	return {"type":&"contract","payload":{"request":{"schema_version":1,"type":kind,"offer_id":current.offer_id,"hand_count":current.hand_count,"sequence":current.sequence,"run_cycle":current.run_cycle,"payload":payload}}}
