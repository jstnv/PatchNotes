extends RefCounted
const Development = preload("res://scripts/simulation/finite_fixture_policy.gd")
const STAT_INDEX = {"graphics":0,"sound":1,"technology":2,"design":3}
var cfg: Dictionary
var first: Callable
var later: Callable
var iron_done := false
var active_kind := ""
var brief_count := 0
var awarded := 0
var seen_releases := 0
var r20_seen := false
var prior_projection: Dictionary = {}
var offer_ids: Array = []

static func factory(config: Dictionary) -> Callable:
	var p: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	p.cfg = config.duplicate(true)
	p.first = Development.factory(config.development_first)
	p.later = Development.factory(config.development_later)
	return func(view: Dictionary) -> Dictionary: return p.choose(view)

func note(kind: String, data: Dictionary) -> void:
	data["case"] = cfg.label
	print("PN_ACCESS_" + kind + " " + JSON.stringify(data))

func fail(reason: String) -> Dictionary:
	note("FAIL", {"reason":reason})
	return {"type":&"access_study_invalid"}

func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"contract": return contract(view)
	if view.phase != &"studio": return development(view).call(view)
	if view.releases.size() > seen_releases:
		seen_releases = view.releases.size()
		note("RELEASE", {"released":view.releases[-1],"ordinal":seen_releases,"cycle":view.run_cycle,"cash":view.cash_cents,"fans":view.fans,"reputation":view.get("publisher_relationships",{}).get(&"sidestreet",{}).get("reputation_bp",0)})
	if view.releases.is_empty(): return first.call(view)
	if not iron_done:
		for offer: Dictionary in view.studio_actions.contract_offers:
			if str(offer.kind) == "ironclad":
				active_kind = "ironclad"
				return {"type":&"accept_contract","payload":{"kind":&"ironclad"}}
		return fail("Ironclad offer missing")
	if cfg.arm != "skip" and awarded < 2000 and brief_count < view.releases.size():
		for offer: Dictionary in view.studio_actions.contract_offers:
			if str(offer.kind) != "sidestreet_brief": continue
			if offer.offer_id in offer_ids or str(offer.quote.source_release_id) != str(view.releases[-1].id): return fail("Duplicate or stale Brief")
			active_kind = "brief"
			offer_ids.append(offer.offer_id)
			note("ACCEPT", {"ordinal":brief_count+1,"offer":offer.offer_id,"source":offer.quote.source_release_id,"cycle":view.run_cycle,"cash":view.cash_cents,"owned":view.owned_features})
			return {"type":&"accept_contract","payload":{"kind":&"sidestreet_brief","offer_id":offer.offer_id}}
		return fail("Release-paced Brief missing")
	# Completed briefs must not immediately refill before a new release.
	if cfg.arm != "skip" and awarded < 2000:
		for offer: Dictionary in view.studio_actions.contract_offers:
			if str(offer.kind) == "sidestreet_brief": return fail("Same-release refill")
	return later.call(view)

func development(view: Dictionary) -> Callable:
	return first if view.releases.is_empty() else later

func contract(view: Dictionary) -> Dictionary:
	var state: Dictionary = view.contract
	if not prior_projection.is_empty():
		if int(state.scope) != int(prior_projection.scope): return fail("Projected Scope mismatch")
		for i in range(4):
			if int(state.core_half_units.get(i,0)) != int(prior_projection.cores[i]): return fail("Projected Core mismatch")
		prior_projection = {}
	if state.completed:
		if active_kind == "ironclad": iron_done = true
		else:
			if int(state.hand_count) != 2 or int(state.successful_redraws) != 0: return fail("Brief hands/redraw mismatch")
			var cores: Array = []
			for i in range(4): cores.append(int(state.core_half_units.get(i,0)))
			var award: int = grade(int(state.scope),cores,10) / 10
			awarded += award
			if int(view.publisher_relationships.get(&"sidestreet",{}).get("reputation_bp",0)) != awarded: return fail("Runtime award mismatch")
			brief_count += 1
			note("RESULT", {"ordinal":brief_count,"offer":state.offer_id,"scope":state.scope,"cores":cores,"award":award,"total":awarded,"shadow8":grade(int(state.scope),cores,8)/10,"cycle":view.run_cycle,"cash":view.cash_cents})
			if awarded >= 2000 and not r20_seen:
				r20_seen = true
				note("R20", {"cycle":view.run_cycle,"brief":brief_count})
		active_kind = ""
		return {"type":&"dismiss_contract"}
	var cards: Array = state.candidates.duplicate(true)
	if cards.is_empty(): return command(view,&"begin")
	if cards.size() != 7: return fail("Expected seven visible cards")
	var hand: Array = []
	if active_kind == "ironclad":
		cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			if bool(a.renewable) != bool(b.renewable): return not bool(a.renewable)
			return int(a.token) < int(b.token))
		hand = cards.slice(0,4)
	else:
		var best := -9223372036854775807
		var full_options := 0
		for a in range(4):
			for b in range(a+1,5):
				for c in range(b+1,6):
					for d in range(c+1,7):
						var candidate := [cards[a],cards[b],cards[c],cards[d]]
						var projected := project(state,candidate)
						var g := grade(projected.scope,projected.cores,10)
						if g == 10000: full_options += 1
						var excess := 0
						var deficits := 0
						for score: int in projected.cores:
							deficits += maxi(0,6-score)
							excess += maxi(0,score-6)
						var rank: int = g*1000 - excess
						if int(state.hand_count) == 0 and cfg.arm == "balanced":
							rank = -deficits*1000 - absi(projected.scope-5)*100 - mini(excess,99)
							if projected.scope < 3 or projected.scope > 7: rank -= 1000000
						if rank > best:
							best = rank
							hand = candidate
		note("HAND", {"ordinal":brief_count+1,"hand":state.hand_count,"visible":cards,"full_options":full_options,"before_scope":state.scope,"before_cores":state.core_half_units})
		prior_projection = project(state,hand)
	var tokens: Array[int] = []
	for card: Dictionary in hand: tokens.append(int(card.token))
	return command(view,&"play",{"candidate_ids":tokens})

static func grade(scope: int,cores: Array,target: int) -> int:
	var n := 4*mini(scope,target)
	for score: int in cores: n += mini(score,6)
	var completion: int = 10000*n/(4*target+24)
	var promise := 10000 if scope <= 10 else (5000 if scope == 11 else 0)
	return mini(completion,promise)

static func project(state: Dictionary,hand: Array) -> Dictionary:
	var cores: Array[int] = []
	for i in range(4): cores.append(int(state.core_half_units.get(i,0)))
	var scope := int(state.scope)
	var shared := str(hand[0].primary_stat)
	for card: Dictionary in hand:
		if str(card.primary_stat) != shared: shared = ""
	var multiplier := 3 if not shared.is_empty() else 2
	for card: Dictionary in hand:
		scope += int(card.scope)
		cores[int(STAT_INDEX[str(card.primary_stat)])] += multiplier*int(card.primary_value)
		if not str(card.secondary_stat).is_empty(): cores[int(STAT_INDEX[str(card.secondary_stat)])] += multiplier*int(card.secondary_value)
	return {"scope":scope,"cores":cores}

static func command(view: Dictionary,kind: StringName,payload: Dictionary = {}) -> Dictionary:
	var state: Dictionary = view.contract
	return {"type":&"contract","payload":{"request":{"schema_version":1,"type":kind,"offer_id":state.offer_id,"hand_count":state.hand_count,"sequence":state.sequence,"run_cycle":state.run_cycle,"payload":payload}}}
