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
