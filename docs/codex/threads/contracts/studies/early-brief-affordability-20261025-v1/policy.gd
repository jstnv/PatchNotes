extends RefCounted
const Base = preload("res://scripts/debug/eca_router.gd")
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
	p.legacy=Base.factory(cfg)
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
	if view.phase==&"studio" and config.arm!="skip" and briefs<3:
		for offer: Dictionary in view.studio_actions.contract_offers:
			if str(offer.kind)!="crown_brief": continue
			if offer.offer_id in offers: return fail("reused Brief")
			offers.append(offer.offer_id)
			brief_active=true
			note("ACCEPT",{"offer":offer.offer_id,"source":offer.quote.source_release_id,"cycle":view.run_cycle,"cash":view.cash_cents,"prior_reputation":rep,"view_hash":JSON.stringify(view).sha256_text()})
			return {"type":&"accept_contract","payload":offer}
		for row: Dictionary in view.studio_actions.contract_search:
			if row.publisher_id==&"crown_quill" and row.work==&"brief" and not row.quote.is_empty():
				note("SEARCH",{"cycle":view.run_cycle,"cash":view.cash_cents,"quote":row.quote})
				return {"type":&"search_contracts","payload":{"quote":row.quote}}
		return fail("Crown search unavailable before3 Briefs")
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
					if config.arm=="passes":
						var passes := 0
						for card: Dictionary in hand:
							if card.renewable: passes += 1
						rank=passes*100000000000+int(score.grade)*1000000+int(score.completion)*100-spread
					if config.arm!="naive" and rank>best:
						best=rank
						chosen=hand
	if int(state.hand_count)==0 and config.arm in ["mean","downside"]:
		var selection := plan_first(state,cards)
		chosen=[]
		for index in selection: chosen.append(cards[index])
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


# Hypothetical public-information model, no runtime RNG or mutable game access.
static func radical(index: int, base: int) -> float:
	var result := 0.0
	var factor := 1.0 / float(base)
	var n := index
	while n > 0:
		result += factor * float(n % base)
		n = n / base
		factor /= float(base)
	return result

static func scenarios(state: Dictionary, visible: Array) -> Array:
	var result: Array = []
	var bases := [2,3,5,7,11,13,17,19]
	for sample in range(1,257):
		var reserved: Dictionary = {}
		for card: Dictionary in visible:
			if not card.renewable: reserved[str(card.definition)] = true
		var refill: Array = []
		for slot in range(4):
			var groups: Array = [[],[],[],[]]
			for card: Dictionary in state.planning_pool:
				if not card.renewable and reserved.has(str(card.definition)): continue
				groups[STATS[str(card.primary_stat)]].append(card)
			var total := 0
			for i in range(4):
				groups[i].sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a.definition)<str(b.definition))
				if not groups[i].is_empty(): total += int(state.priorities[i])
			assert(total>0)
			var target := radical(sample,bases[slot*2])*float(total)
			var cumulative := 0
			var category := -1
			for i in range(4):
				if groups[i].is_empty(): continue
				cumulative += int(state.priorities[i])
				if target < float(cumulative):
					category=i
					break
			assert(category>=0)
			var group: Array = groups[category]
			var card: Dictionary = group[mini(floori(radical(sample,bases[slot*2+1])*float(group.size())),group.size()-1)]
			refill.append(card)
			if not card.renewable: reserved[str(card.definition)]=true
		result.append(refill)
	return result

static func quartets() -> Array:
	var out: Array = []
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7): out.append([a,b,c,d])
	return out

static func values(card: Dictionary) -> Array:
	var out := [int(card.scope),0,0,0,0,STATS[str(card.primary_stat)]]
	out[1+out[5]] += int(card.primary_value)
	if not str(card.secondary_stat).is_empty(): out[1+STATS[str(card.secondary_stat)]] += int(card.secondary_value)
	return out

static func hand_values(cards: Array, combo: Array) -> Array:
	var a: Array=cards[combo[0]]
	var b: Array=cards[combo[1]]
	var c: Array=cards[combo[2]]
	var d: Array=cards[combo[3]]
	var m := 3 if a[5]==b[5] and a[5]==c[5] and a[5]==d[5] else 2
	return [a[0]+b[0]+c[0]+d[0],m*(a[1]+b[1]+c[1]+d[1]),m*(a[2]+b[2]+c[2]+d[2]),m*(a[3]+b[3]+c[3]+d[3]),m*(a[4]+b[4]+c[4]+d[4])]

static func combined_grade(first: Array, second: Array) -> int:
	var s: int=first[0]+second[0]
	var a: int=first[1]+second[1]
	var b: int=first[2]+second[2]
	var c: int=first[3]+second[3]
	var d: int=first[4]+second[4]
	var lo := mini(mini(a,b),mini(c,d))
	var hi := maxi(maxi(a,b),maxi(c,d))
	var n := 2*mini(s,9)+mini(a,8)+mini(b,8)+mini(c,8)+mini(d,8)+2*mini(lo,8)
	var completion: int = 10000*n/66
	return mini(completion,maxi(0,10000-1250*maxi(0,hi-lo-4)))

static func lex_greater(a: Array,b: Array) -> bool:
	if b.is_empty(): return true
	for i in range(a.size()):
		if a[i]!=b[i]: return a[i]>b[i]
	return false

func plan_first(state: Dictionary,cards: Array) -> Array:
	var start := Time.get_ticks_msec()
	var samples := scenarios(state,cards)
	var combos := quartets()
	var packed: Array = []
	for card: Dictionary in cards: packed.append(values(card))
	var packed_samples: Array = []
	var sample_ids: Array = []
	for sample: Array in samples:
		var pack: Array = []
		var ids: Array = []
		for card: Dictionary in sample:
			pack.append(values(card))
			ids.append(str(card.definition))
		packed_samples.append(pack)
		sample_ids.append(ids)
	var rows: Array = []
	var best: Array = []
	var chosen: Array = []
	for combo: Array in combos:
		var first := hand_values(packed,combo)
		first[0] += int(state.scope)
		for i in range(4): first[i+1] += int(state.core_half_units[i])
		var retained: Array = []
		var tokens: Array = []
		for i in range(7):
			if i not in combo: retained.append(packed[i])
			else: tokens.append(cards[i].token)
		var grades: Array[int] = []
		var total := 0
		var full := 0
		var positive := 0
		for refill: Array in packed_samples:
			var available := retained.duplicate()
			available.append_array(refill)
			var high := 0
			for second: Array in combos: high=maxi(high,combined_grade(first,hand_values(available,second)))
			grades.append(high)
			total+=high
			if high==10000: full+=1
			if high>0: positive+=1
		var sorted := grades.duplicate()
		sorted.sort()
		var tail := 0
		for i in range(64): tail+=sorted[i]
		var spread: int=maxi(maxi(first[1],first[2]),maxi(first[3],first[4]))-mini(mini(first[1],first[2]),mini(first[3],first[4]))
		var rank: Array = [total,full,positive,-spread]
		if config.arm=="downside": rank=[total+4*tail,total,full,positive,-spread]
		if lex_greater(rank,best):
			best=rank
			chosen=combo
		rows.append({"tokens":tokens,"total":total,"tail":tail,"full":full,"positive":positive,"spread":spread,"rank":rank,"grades":grades})
	note("PLAN",{"offer":state.offer_id,"arm":config.arm,"visible":cards,"pool":state.planning_pool,"priorities":state.priorities,"scope":state.scope,"cores":state.core_half_units,"sample_ids":sample_ids,"ranking":rows,"chosen_indices":chosen,"elapsed_ms":Time.get_ticks_msec()-start})
	return chosen
