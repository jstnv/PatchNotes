extends RefCounted
const Base = preload("res://scripts/debug/cb2_access.gd")
const STATS = {"graphics":0,"sound":1,"technology":2,"design":3}
var config: Dictionary
var legacy: Callable
var brief_active := false
var briefs := 0
var earned := 0
var offers: Array = []
var prediction: Dictionary = {}
var reached := false
static func factory(cfg: Dictionary) -> Callable:
	var p = new()
	p.config=cfg.duplicate(true)
	p.earned=int(cfg.get("starting_reputation",0))
	p.legacy=Base.factory({"arm":"acquire","specialty":"action","label":cfg.label,"extra_hand":true})
	return func(view: Dictionary) -> Dictionary: return p.choose(view)
func note(kind: String,data: Dictionary) -> void:
	data.case=config.label
	print("PN_CB_"+kind+" "+JSON.stringify(data))
func fail(message: String) -> Dictionary:
	note("FAIL",{"reason":message})
	return {"type":&"crown_study_invalid"}
func choose(view: Dictionary) -> Dictionary:
	var rep: int=int(view.publisher_relationships.get(&"crown_quill",{}).get("reputation_bp",0))
	note("VIEW",{"sequence":view.sequence,"cycle":view.run_cycle,"phase":view.phase,"release_count":view.releases.size(),"cash":view.cash_cents,"reputation":rep,"view_hash":JSON.stringify(view).sha256_text()})
	if view.phase==&"contract" and brief_active: return brief(view)
	if view.phase==&"studio" and config.arm!="skip" and briefs<3 and rep<2000:
		for offer: Dictionary in view.studio_actions.contract_offers:
			if str(offer.kind)!="crown_brief": continue
			if offer.offer_id in offers: return fail("reused Brief")
			offers.append(offer.offer_id)
			brief_active=true
			note("ACCEPT",{"offer":offer.offer_id,"source":offer.quote.source_release_id,"cycle":view.run_cycle,"cash":view.cash_cents,"prior_reputation":rep,"view_hash":JSON.stringify(view).sha256_text()})
			return {"type":&"accept_contract","payload":offer}
	return legacy.call(view)
func brief(view: Dictionary) -> Dictionary:
	var state: Dictionary = view.contract
	if not prediction.is_empty():
		if int(state.scope) != int(prediction.scope): return fail("Scope projection mismatch")
		for i in range(4):
			if int(state.core_half_units[i]) != int(prediction.cores[i]): return fail("Core projection mismatch")
		prediction = {}
	if state.completed:
		var cores: Array = []
		for i in range(4): cores.append(int(state.core_half_units[i]))
		var score := grade(state.scope,cores)
		var award: int = int(score.grade)/10
		earned += award
		if int(view.publisher_relationships[&"crown_quill"].reputation_bp) != earned: return fail("P1 award mismatch")
		if int(view.publisher_relationships[&"sidestreet"].reputation_bp) != 0: return fail("SideStreet standing leak")
		briefs += 1
		note("RESULT",{"offer":state.offer_id,"ordinal":briefs,"scope":state.scope,"cores":cores,"grade":score.grade,"completion":score.completion,"promise":score.promise,"award":award,"total":earned,"cycle":view.run_cycle,"cash":view.cash_cents,"redraws":state.successful_redraws,"remaining_redraws":state.available_redraws})
		if earned>=2000 and not reached:
			reached = true
			note("R20",{"briefs":briefs,"cycle":view.run_cycle,"releases":view.releases.size()})
		brief_active = false
		return {"type":&"dismiss_contract"}
	var cards: Array = state.candidates
	if cards.is_empty(): return command(view,&"begin")
	if cards.size()!=7: return fail("expected seven visible cards")
	var chosen := [cards[0],cards[1],cards[2],cards[3]]
	var best: int = -9223372036854775807
	var full_options := 0
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand := [cards[a],cards[b],cards[c],cards[d]]
					var projected := project(state,hand)
					var score := grade(projected.scope,projected.cores)
					if score.grade==10000: full_options += 1
					var spread: int = projected.cores.max()-projected.cores.min()
					var deficits := 0
					for h: int in projected.cores: deficits += maxi(0,4-h)
					var rank: int = int(score.grade)*1000000 + int(score.completion)*100 - spread
					if config.arm=="completion": rank=int(score.completion)*1000000+int(score.promise)*100-spread
					if config.arm=="passes_then_balance" and int(state.hand_count)==0:
						var passes := 0
						for card: Dictionary in hand:
							if card.renewable: passes += 1
						rank=passes*100000000000+int(score.grade)*1000000+int(score.completion)*100-spread
					if not (config.arm=="naive_then_balance" and int(state.hand_count)==0) and rank>best:
						best=rank
						chosen=hand
	prediction = project(state,chosen)
	var tokens: Array[int] = []
	for card: Dictionary in chosen: tokens.append(int(card.token))
	note("HAND",{"offer":state.offer_id,"hand":state.hand_count,"full_options":full_options,"visible":cards,"chosen":tokens,"projected":prediction,"view_hash":JSON.stringify(view).sha256_text()})
	return command(view,&"play",{"candidate_ids":tokens})

static func grade(scope: int, cores: Array) -> Dictionary:
	var n: int = 2*mini(scope,9)+2*mini(int(cores.min()),8)
	for h: int in cores: n += mini(h,8)
	var completion: int = 10000*n/66
	var spread: int = cores.max()-cores.min()
	var promise := clampi(10000-1250*maxi(0,spread-4),0,10000)
	return {"grade":mini(completion,promise),"completion":completion,"promise":promise}

static func project(state: Dictionary, hand: Array) -> Dictionary:
	var cores: Array[int] = []
	for i in range(4): cores.append(int(state.core_half_units[i]))
	var scope := int(state.scope)
	var shared := str(hand[0].primary_stat)
	for card: Dictionary in hand:
		if str(card.primary_stat)!=shared: shared=""
	var multiplier := 3 if not shared.is_empty() else 2
	for card: Dictionary in hand:
		scope += int(card.scope)
		cores[STATS[str(card.primary_stat)]] += multiplier*int(card.primary_value)
		if not str(card.secondary_stat).is_empty(): cores[STATS[str(card.secondary_stat)]] += multiplier*int(card.secondary_value)
	return {"scope":scope,"cores":cores}

static func command(view: Dictionary, kind: StringName, payload: Dictionary = {}) -> Dictionary:
	var state: Dictionary = view.contract
	return {"type":&"contract","payload":{"request":{"schema_version":1,"type":kind,"offer_id":state.offer_id,"hand_count":state.hand_count,"sequence":state.sequence,"run_cycle":state.run_cycle,"payload":payload}}}

