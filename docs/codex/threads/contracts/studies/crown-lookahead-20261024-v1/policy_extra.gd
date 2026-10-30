
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
