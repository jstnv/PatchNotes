extends RefCounted
const Base = preload("res://scripts/debug/crown_development_policy.gd")
const STATS = {"graphics":0,"sound":1,"technology":2,"design":3}
var config: Dictionary
var legacy: Callable
var cash_done := false
var brief_active := false
var briefs := 0
var earned := 0
var offers: Array = []
var prediction: Dictionary = {}
var reached := false
var redraw_expected: Dictionary = {}
var safe_floor := -1

static func factory(cfg: Dictionary) -> Callable:
	var p: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	p.config = cfg.duplicate(true)
	p.legacy = Base.factory({"strategy":"action_game2"})
	return func(view: Dictionary) -> Dictionary: return p.choose(view)

func note(kind: String, data: Dictionary) -> void:
	data.case = config.label
	print("PN_CB_"+kind+" "+JSON.stringify(data))

func fail(message: String) -> Dictionary:
	note("FAIL",{"reason":message})
	return {"type":&"crown_study_invalid"}

func choose(view: Dictionary) -> Dictionary:
	var rep: int = int(view.publisher_relationships.get(&"crown_quill",{}).get("reputation_bp",0))
	note("VIEW",{"sequence":view.sequence,"cycle":view.run_cycle,"phase":view.phase,"release_count":view.releases.size(),"cash":view.cash_cents,"reputation":rep,"view_hash":JSON.stringify(view).sha256_text()})
	if view.phase == &"contract":
		if brief_active: return brief(view)
		if view.contract.completed and str(view.contract.offer_id).ends_with(":crown_quill:first"): cash_done = true
		return legacy.call(view)
	if view.phase != &"studio": return legacy.call(view)
	if cash_done and config.arm != "skip" and briefs < 3 and rep < 2000:
		for offer: Dictionary in view.studio_actions.contract_offers:
			if str(offer.kind) != "crown_brief": continue
			if offer.offer_id in offers: return fail("reused Brief offer")
			offers.append(offer.offer_id)
			brief_active = true
			note("ACCEPT",{"offer":offer.offer_id,"source":offer.quote.source_release_id,"cycle":view.run_cycle,"cash":view.cash_cents,"prior_reputation":rep,"view_hash":JSON.stringify(view).sha256_text()})
			return {"type":&"accept_contract","payload":offer}
	return legacy.call(view)

func brief(view: Dictionary) -> Dictionary:
	var state: Dictionary = view.contract
	if not redraw_expected.is_empty():
		if int(state.available_redraws) != int(redraw_expected.budget)-1 or int(state.successful_redraws) != int(redraw_expected.used)+1: return fail("redraw debit mismatch")
		if int(state.scope) != int(redraw_expected.scope) or state.core_half_units != redraw_expected.cores: return fail("redraw altered scores")
		note("REDRAW_AFTER",{"offer":state.offer_id,"remaining":state.available_redraws,"used":state.successful_redraws,"cycle":view.run_cycle})
		redraw_expected = {}
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
	var planning: Array = []
	if int(state.hand_count)==0 and str(config.arm).begins_with("lookahead"): planning=plan_first(state,cards)
	var planning_index := 0
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
					if int(state.hand_count)==0: rank = int(score.grade)*1000000-deficits*1000-spread
					if int(state.hand_count)==0 and str(config.arm).begins_with("retained"):
						rank = int(forecast(projected,hand,cards)*1000000.0)+int(score.grade)*100-spread
					if not planning.is_empty(): rank=int(planning[planning_index].rank)
					planning_index+=1
					if config.arm=="completion": rank=int(score.completion)*1000000+int(score.promise)*100-spread
					if config.arm!="naive" and rank>best:
						best=rank
						chosen=hand
	var prospective := project(state,chosen)
	var current_grade := int(grade(prospective.scope,prospective.cores).grade)
	if safe_floor>=0:
		if current_grade<safe_floor: return fail("conservative redraw lost best achievable grade")
		note("SAFE_MONOTONE",{"offer":state.offer_id,"before":safe_floor,"after":current_grade})
		safe_floor=-1
	var conservative := str(config.arm).ends_with("_safe")
	if int(state.hand_count)==1 and (str(config.arm).ends_with("_redraw") or conservative) and int(state.available_redraws)>0 and int(state.successful_redraws)<2 and current_grade<10000:
		var token := int(chosen[excess_card(chosen,prospective.cores)].token)
		var decision: Dictionary = {}
		if conservative:
			decision=safe_redraw(state,cards,chosen,current_grade)
			token=int(decision.token)
			note("SAFE_DECISION",{"offer":state.offer_id,"visible":cards,"pool":state.planning_pool,"priorities":state.priorities,"scope":state.scope,"cores":state.core_half_units,"before_grade":current_grade,"decision":decision})
		if token>=0:
			redraw_expected={"budget":state.available_redraws,"used":state.successful_redraws,"scope":state.scope,"cores":state.core_half_units.duplicate(true)}
			if conservative: safe_floor=current_grade
			note("REDRAW",{"offer":state.offer_id,"hand":state.hand_count,"before_grade":current_grade,"token":token,"budget":state.available_redraws,"used":state.successful_redraws,"visible":cards,"best":prospective,"cycle":view.run_cycle,"safe":conservative,"decision":decision})
			return command(view,&"redraw",{"candidate_ids":[token]})
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

static func contribution(card: Dictionary) -> Array[float]:
	var values: Array[float] = [0.0,0.0,0.0,0.0]
	values[STATS[str(card.primary_stat)]] += 2.0*float(card.primary_value)
	if not str(card.secondary_stat).is_empty(): values[STATS[str(card.secondary_stat)]] += 2.0*float(card.secondary_value)
	return values

static func forecast(projected: Dictionary, hand: Array, cards: Array) -> float:
	var mean: Array[float] = [0.0,0.0,0.0,0.0]
	var mean_scope := 0.0
	var retained: Array = []
	for card: Dictionary in cards:
		var values := contribution(card)
		for i in range(4): mean[i] += values[i]/7.0
		mean_scope += float(card.scope)/7.0
		if card not in hand: retained.append(card)
	var best := -1.0
	for mask in range(8):
		var cores: Array[float] = []
		for h: int in projected.cores: cores.append(float(h))
		var scope := float(projected.scope)
		var kept := 0
		for j in range(3):
			if mask & (1 << j):
				kept += 1
				var values := contribution(retained[j])
				for i in range(4): cores[i] += values[i]
				scope += float(retained[j].scope)
		for i in range(4): cores[i] += float(4-kept)*mean[i]
		scope += float(4-kept)*mean_scope
		var n: float = 2.0*minf(scope,9.0)+2.0*minf(float(cores.min()),8.0)
		for h: float in cores: n += minf(h,8.0)
		var completion := 10000.0*n/66.0
		var promise := clampf(10000.0-1250.0*maxf(0.0,float(cores.max())-float(cores.min())-4.0),0.0,10000.0)
		best = maxf(best,minf(completion,promise))
	return best

static func excess_card(hand: Array, cores: Array) -> int:
	var mean := 0.0
	for h: int in cores: mean += float(h)/4.0
	var best := -INF
	var selected := 0
	for j in range(hand.size()):
		var values := contribution(hand[j])
		var rank := 0.0
		for i in range(4): rank += values[i]*(float(cores[i])-mean)
		if rank>best:
			best=rank
			selected=j
	return selected


static func best_quartet(state: Dictionary, cards: Array) -> Dictionary:
	var best := -9223372036854775807
	var result: Dictionary = {}
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand := [cards[a],cards[b],cards[c],cards[d]]
					var projected := project(state,hand)
					var score := grade(projected.scope,projected.cores)
					var rank: int = int(score.grade)*1000000+int(score.completion)*100-int(projected.cores.max())+int(projected.cores.min())
					if rank>best:
						best=rank
						result={"hand":hand,"projected":projected,"grade":score.grade}
	return result

static func legal_groups(pool: Array, cards: Array, type_filter: String = "", excluded: String = "") -> Array:
	var reserved: Dictionary = {}
	for card: Dictionary in cards:
		if not card.renewable: reserved[str(card.definition)]=true
	var groups: Array = [[],[],[],[]]
	for card: Dictionary in pool:
		if str(card.definition)==excluded or (str(card.card_type)=="feature" and reserved.has(str(card.definition))): continue
		if not type_filter.is_empty() and str(card.card_type)!=type_filter: continue
		groups[STATS[str(card.primary_stat)]].append(card)
	for group: Array in groups:
		group.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a.definition)<str(b.definition))
	return groups

static func refill_samples(state: Dictionary, cards: Array) -> Array:
	var samples: Array = []
	var x: int = 20261024
	for scenario in range(32):
		var reserved := cards.duplicate()
		var refill: Array = []
		for slot in range(4):
			x=(16807*x)%2147483647
			var category_roll := float(x)/2147483647.0
			x=(16807*x)%2147483647
			var definition_roll := float(x)/2147483647.0
			var groups := legal_groups(state.planning_pool,reserved)
			var total := 0
			for i in range(4):
				if not groups[i].is_empty(): total+=int(state.priorities[i])
			assert(total>0)
			var target := category_roll*float(total)
			var cumulative := 0
			var chosen := -1
			for i in range(4):
				if groups[i].is_empty(): continue
				cumulative+=int(state.priorities[i])
				if target<float(cumulative):
					chosen=i
					break
			assert(chosen>=0)
			var group: Array = groups[chosen]
			var card: Dictionary = group[mini(floori(definition_roll*float(group.size())),group.size()-1)].duplicate(true)
			card.token=-1-slot
			refill.append(card)
			reserved.append(card)
		samples.append(refill)
	return samples

func plan_first(state: Dictionary, cards: Array) -> Array:
	var started := Time.get_ticks_msec()
	var samples := refill_samples(state,cards)
	var ranking: Array = []
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand := [cards[a],cards[b],cards[c],cards[d]]
					var projected := project(state,hand)
					var retained: Array = []
					for card: Dictionary in cards:
						if card not in hand: retained.append(card)
					var second_state := {"scope":projected.scope,"core_half_units":projected.cores}
					var total := 0
					var full := 0
					var positive := 0
					for refill: Array in samples:
						var second := retained.duplicate()
						second.append_array(refill)
						var outcome := best_quartet(second_state,second)
						total+=int(outcome.grade)
						if int(outcome.grade)==10000: full+=1
						if int(outcome.grade)>0: positive+=1
					var spread: int = int(projected.cores.max())-int(projected.cores.min())
					var tokens: Array = []
					for card: Dictionary in hand: tokens.append(card.token)
					ranking.append({"tokens":tokens,"total":total,"full":full,"positive":positive,"spread":spread,"rank":total*1000000+full*10000+positive*100-spread})
	note("LOOKAHEAD",{"offer":state.offer_id,"pool":state.planning_pool,"priorities":state.priorities,"visible":cards,"scope":state.scope,"cores":state.core_half_units,"samples":samples,"ranking":ranking,"elapsed_ms":Time.get_ticks_msec()-started})
	return ranking

static func safe_redraw(state: Dictionary,cards: Array,chosen: Array,before_grade: int) -> Dictionary:
	var protected: Array = []
	for card: Dictionary in chosen: protected.append(card.token)
	var rows: Array = []
	var best := float(before_grade)
	var selected := -1
	for slot in range(cards.size()):
		var old: Dictionary = cards[slot]
		if old.token in protected: continue
		var type_filter := ""
		for card: Dictionary in state.planning_pool:
			if str(card.definition)==str(old.definition): type_filter=str(card.card_type)
		assert(not type_filter.is_empty())
		var groups := legal_groups(state.planning_pool,cards,type_filter,str(old.definition))
		var total := 0
		for i in range(4):
			if not groups[i].is_empty(): total+=int(state.priorities[i])
		if total<=0: continue
		var expected := 0.0
		var outcomes: Array = []
		for i in range(4):
			var group: Array = groups[i]
			for replacement: Dictionary in group:
				var probability := float(state.priorities[i])/float(total)/float(group.size())
				var hypothetical := cards.duplicate()
				hypothetical[slot]=replacement
				var score := best_quartet(state,hypothetical)
				expected+=probability*float(score.grade)
				outcomes.append({"definition":replacement.definition,"probability":probability,"grade":score.grade})
		rows.append({"token":old.token,"expected":expected,"outcomes":outcomes})
		if expected>best+0.000000001:
			best=expected
			selected=int(old.token)
	return {"token":selected,"expected":best,"protected":protected,"options":rows}
