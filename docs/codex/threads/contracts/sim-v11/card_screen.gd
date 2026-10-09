extends SceneTree

var failures: Array = []
var checks := 0
var db: Node
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures.append(text)
func _initialize() -> void: call_deferred("_run")
func ids(cards: Array) -> Array:
	return cards.map(func(c): return str(c.id))
func score(cards: Array) -> Dictionary:
	var scope := 0
	var cores := [0,0,0,0]
	var same: bool = cards.all(func(c): return c.primary_stat == cards[0].primary_stat)
	for card: CardData in cards:
		scope += card.scope
		cores[ContractState.CORE_BY_STAT[card.primary_stat]] += card.primary_value * (3 if same else 2)
		if not card.secondary_stat.is_empty(): cores[ContractState.CORE_BY_STAT[card.secondary_stat]] += card.secondary_value * (3 if same else 2)
	return {"scope":scope,"cores":cores}
func value(scope: int, cores: Array, target: int = 14) -> int:
	var total := 4 * mini(scope,target)
	for c in cores: total += mini(c,target)
	return total
func choose(cards: Array, policy: String, scope: int, cores: Array) -> Array:
	var best := []
	var best_value := -1
	var best_tie := -1
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var slots := [a,b,c,d]
					var picked := slots.map(func(i): return cards[i])
					var points := score(picked)
					var combined := cores.duplicate()
					for i in range(4): combined[i] += points.cores[i]
					var amount: int = points.scope if policy == "scope" else value(scope+points.scope,combined)-value(scope,cores)
					var tie: int = points.scope + points.cores.reduce(func(x,y): return x+y,0)
					if amount > best_value or (amount == best_value and tie > best_tie):
						best = slots; best_value = amount; best_tie = tie
	return best
func draw(pool: Array, exhausted: Dictionary, reserved: Dictionary, rng: RandomNumberGenerator, count: int) -> Array:
	var result := []
	for slot in range(count):
		var category_roll := rng.randf()
		var definition_roll := rng.randf()
		var categories := [[],[],[],[]]
		for raw in pool:
			var id := StringName(raw)
			if exhausted.has(id) or reserved.has(id): continue
			var card: CardData = db.get_card(id)
			categories[ContractState.CORE_BY_STAT[card.primary_stat]].append(card)
		for id: StringName in ContractState.PASS_IDS:
			var card: CardData = db.get_card(id)
			categories[ContractState.CORE_BY_STAT[card.primary_stat]].append(card)
		var category := mini(int(category_roll*4),3)
		categories[category].sort_custom(func(a,b): return str(a.id)<str(b.id))
		if categories[category].is_empty(): return []
		var card: CardData = categories[category][mini(int(definition_roll*categories[category].size()),categories[category].size()-1)]
		result.append(card)
		if not card.renewable: reserved[card.id] = true
	return result
func _run() -> void:
	db = root.get_node("CardDatabase")
	var args := OS.get_cmdline_user_args()
	var foundation: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	check(foundation.valid,"Legal foundation passed")
	var results := []
	for policy in ["balanced","scope"]:
		for seed_value in [-1,1104,4417,2027,61001,61002]:
			var run := StudioCheckpoint.new().hydrate(foundation.starwave_checkpoint)
			check(run != null,"Hydrate legal foundation")
			if run == null: continue
			var pool: Array[StringName] = run._primitive_contract_eligible_ids()
			check(JSON.parse_string(JSON.stringify(pool)) == foundation.frozen_eligible,"Exact frozen pool")
			if seed_value >= 0: run.random_streams.stream(&"contract_deal").seed = seed_value
			var rng := RandomNumberGenerator.new()
			rng.state = run.random_streams.stream(&"contract_deal").state
			var initial_rng := str(rng.state)
			# Native two-hand mechanics fixture only. Never a legal Starwave offer.
			var state := ContractState.new(pool)
			state._upfront_committed = true
			run._primitive_contract = state
			run._ironclad_completion_committed = false
			var phase: ContractPhase = load("res://scenes/phases/contract_phase.tscn").instantiate()
			check(phase.setup(state,run),"Native parity fixture setup")
			root.add_child(phase)
			await process_frame
			var exhausted := {}
			var cards := draw(pool,exhausted,{},rng,7)
			var scope := 0
			var cores := [0,0,0,0]
			var trace := []
			var blocked := false
			for hand in range(3):
				if cards.size()!=7: blocked=true; break
				if hand<2:
					check(ids(cards)==ids(phase._candidate_cards),"Exact native draw/retention parity")
					check(rng.state==run.random_streams.stream(&"contract_deal").state,"Native deal RNG parity")
				var slots := choose(cards,policy,scope,cores)
				var selected := slots.map(func(i): return cards[i])
				var retained := []
				for i in range(7):
					if i not in slots: retained.append(cards[i])
				var points := score(selected)
				scope += points.scope
				for i in range(4): cores[i] += points.cores[i]
				for card: CardData in selected:
					if not card.renewable:
						check(not exhausted.has(card.id),"Finite Feature never reused")
						exhausted[card.id]=true
				trace.append({"hand":hand+1,"draw":ids(cards),"selected":ids(selected),"retained":ids(retained),"scope":scope,"cores":cores.duplicate(),"exhausted":exhausted.keys(),"redraws":0,"analysis_only_third_hand":hand==2})
				if hand<2:
					for i in slots: (phase._candidate_row.get_children()[i] as CardView).input_button.pressed.emit()
					check(phase._play_selected_hand(),"Native parity hand accepted")
					check(state.get_scope()==scope,"Native Scope parity")
					for i in range(4): check(state.get_core_score_half_units(i)==cores[i],"Native half-unit Core parity")
				if hand<2:
					var reserved := {}
					for card: CardData in retained:
						if not card.renewable: reserved[card.id]=true
					cards = retained + draw(pool,exhausted,reserved,rng,4)
			var completions := {}
			for target in [12,14,16]: completions[str(target)]={"numerator":value(scope,cores,target),"denominator":target*8}
			results.append({"seed":seed_value,"initial_rng":initial_rng,"policy":policy,"pool":pool,"trace":trace,"scope":scope,"cores":cores,"blocked":blocked,"completions":completions})
			phase.queue_free()
			await process_frame
	var out := {"checks":checks,"failures":failures,"results":results,"valid":failures.is_empty(),"parity_fixture_only":true}
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(out))
	print("SW1 CARDS ",checks," checks; ",failures)
	quit(0 if failures.is_empty() else 1)
