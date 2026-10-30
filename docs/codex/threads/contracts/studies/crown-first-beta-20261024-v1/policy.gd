## Experimental detached-observation policy; no runtime state or future RNG reads.
extends RefCounted
const Legacy = preload("res://scripts/debug/crown_access_legacy_v1.gd")
const Production = preload("res://scripts/simulation/production_hand.gd")
const STATS = ["graphics", "sound", "technology", "design"]
const TARGETS = {"action": [40,26,40,26], "puzzle": [20,13,40,59], "simulation": [20,20,59,33]}
const PRIORITIES = {"action": [30,20,30,20], "puzzle": [15,10,30,45], "simulation": [15,15,45,25]}

var cfg: Dictionary
var legacy: Callable
var hands: Dictionary = {}
var redrawn: Dictionary = {}
var cards_by_id: Dictionary = {}
var store_ids: Dictionary = {}
var acquired_windows: Dictionary = {}
var extra_play := false
var qa_extra := false
var reserved_redraw := false
var first_redraw := false
var qa_extensions: Dictionary = {}
var core_done := false
var core_pending := ""
var core_basis: Dictionary = {}

static func factory(config: Dictionary) -> Callable:
	var p = new()
	p.cfg = config
	for path in ["res://data/card_ledger.json","res://data/feature_store_ledger.json"]:
		for card in JSON.parse_string(FileAccess.get_file_as_string(path)):
			p.cards_by_id[card.id] = card
			if path.ends_with("feature_store_ledger.json"): p.store_ids[card.id] = true
	p.legacy = Legacy.factory({"strategy":"action_game2"})
	return func(view: Dictionary) -> Dictionary: return p.choose(view)

func choose(view: Dictionary) -> Dictionary:
	extra_play = false
	qa_extra = false
	reserved_redraw = false
	first_redraw = false
	core_basis = {}
	var command: Dictionary = legacy.call(view) if cfg.arm == "legacy" else route(view)
	print("FOLLOWUP " + JSON.stringify({"case":cfg.label,"cycle":view.run_cycle,"cash":view.cash_cents,"releases":view.releases.size(),"phase":view.phase,"view_hash":hash(view),"development":view.development,"offers":view.studio_actions.contract_offers,"owned":view.owned_features,"research_quotes":view.research_quotes,"monthly_rent_cents":view.studio_actions.finance.get("monthly_rent_cents",50000),"extra_play":extra_play,"qa_extra":qa_extra,"reserved_redraw":reserved_redraw,"first_redraw":first_redraw,"core_basis":core_basis,"command":command}))
	return command

func route(view: Dictionary) -> Dictionary:
	if view.phase == &"contract":
		if view.contract.completed: return {"type":&"dismiss_contract"}
		if view.contract.candidates.is_empty(): return Legacy._contract(view,&"begin")
		var tokens: Array[int] = []
		for i in range(4): tokens.append(int(view.contract.candidates[i].token))
		return Legacy._contract(view,&"play",{"candidate_ids":tokens})
	var rent: int = view.studio_actions.finance.get("monthly_rent_cents",50000)
	if view.phase == &"studio":
		for offer in view.studio_actions.contract_offers:
			if offer.kind == &"ironclad" or (offer.kind == &"sidestreet" and int(view.cash_cents) < 400000):
				return {"type":&"accept_contract","payload":offer}
			if offer.kind == &"publisher" and str(offer.quote.get("publisher_id","")) == "crown_quill":
				return {"type":&"accept_contract","payload":offer}
		if cfg.arm == "acquire" and view.releases.size() >= 1:
			var purchase: Dictionary = acquire(view,rent)
			if not purchase.is_empty(): return purchase
		return {"type":&"begin_development","payload":{"name":"Crown route %d" % (view.releases.size()+1),"genre":cfg.specialty,"theme":"fantasy"}}
	var d: Dictionary = view.development
	if d.finalized: return {"type":&"launch"} if d.phase == "beta" else Legacy._development(view,&"enter_next_phase")
	if d.confirmation_pending: return Legacy._development(view,&"confirm_exit")
	if not d.active:
		var wanted: Dictionary = {&"qa":50,&"marketing":40,&"insider":10} if d.phase == "beta" else {0:PRIORITIES[cfg.specialty][0],1:PRIORITIES[cfg.specialty][1],2:PRIORITIES[cfg.specialty][2],3:PRIORITIES[cfg.specialty][3]}
		if d.priorities != wanted: return Legacy._development(view,&"priorities",{"distribution":wanted})
		return Legacy._development(view,&"begin")
	var key: String = str(view.project_id)+":"+d.phase
	var count: int = hands.get(key,0)
	var target: int = ({"design":3,"alpha":2,"beta":3} if view.releases.is_empty() else {"design":6,"alpha":4,"beta":6})[d.phase]
	if cfg.get("first_search_redraw",false) and d.phase == "beta" and count == 0 and not redrawn.has(key) and int(d.redraws)>0 and int(view.cash_cents)>=4*rent:
		var search := false
		var debug := false
		for card in d.candidates:
			search = search or card.definition == "search_for_bugs"
			debug = debug or card.definition == "debug"
		if not search:
			var keep: Array[int] = best(d,int(view.cash_cents)-4*rent,false,2 if debug else 0)
			if not keep.is_empty():
				for i in range(d.candidates.size()-1,-1,-1):
					if i not in keep:
						redrawn[key] = true
						first_redraw = true
						return Legacy._development(view,&"redraw",{"candidate_ids":[int(d.candidates[i].token)]})
	var extra_selected: Array[int] = []
	if cfg.get("extra_hand",false) and count == target and d.phase in ["design","alpha"] and int(d.scope) < int(d.required_scope):
		extra_selected = best(d,int(view.cash_cents)-4*rent,true)
	if cfg.get("qa_extension",false) and d.phase == "beta" and (qa_extensions.has(key) or count >= target or (count >= 3 and int(d.known_bugs) == 0)):
		return extend_qa(view,d,key,rent)
	if (count >= target and extra_selected.is_empty()) or (count > 0 and int(view.cash_cents) < 3*rent) or (d.phase == "beta" and count >= 3 and int(d.known_bugs) == 0):
		return Legacy._development(view,&"request_exit")
	var selected: Array[int] = extra_selected if not extra_selected.is_empty() else best(d,int(view.cash_cents)-3*rent)
	if selected.is_empty():
		if count > 0: return Legacy._development(view,&"request_exit")
		selected = best(d,int(view.cash_cents))
		if selected.is_empty(): selected = [0,1,2,3] # retain legal-engine rejection if stranded
	if not (d.phase == "beta" and cfg.get("reserve_beta_redraw",false)) and not redrawn.has(key) and int(d.redraws) > 0:
		redrawn[key] = true
		for i in range(d.candidates.size()-1,-1,-1):
			if i not in selected:
				return Legacy._development(view,&"redraw",{"candidate_ids":[int(d.candidates[i].token)]})
	var tokens: Array[int] = []
	for i in selected: tokens.append(int(d.candidates[i].token))
	hands[key] = count+1
	extra_play = not extra_selected.is_empty()
	return Legacy._development(view,&"play",{"candidate_ids":tokens})

func best(d: Dictionary, available: int, require_scope_feature: bool = false, qa_rule: int = 0) -> Array[int]:
	var value := -INF
	var chosen: Array[int] = []
	var cards: Array = d.candidates
	for a in range(cards.size()-3):
		for b in range(a+1,cards.size()-2):
			for c in range(b+1,cards.size()-1):
				for e in range(c+1,cards.size()):
					var indices: Array[int] = [a,b,c,e]
					var cost := 0
					var contains_scope := false
					for i in indices:
						var card: Dictionary = cards[i]
						contains_scope = contains_scope or (card.type == "feature" and int(card.scope) > 0)
						if d.phase != "beta" and card.type == "feature" and not store_ids.has(str(card.definition)): cost += (int(card.primary_value)+int(card.secondary_value)+2*int(card.scope))*1000
					if require_scope_feature and not contains_scope: continue
					if qa_rule > 0:
						var search := false
						var debug := false
						for i in indices:
							search = search or cards[i].definition == "search_for_bugs"
							debug = debug or cards[i].definition == "debug"
						if qa_rule in [1,3] and not search: continue
						if qa_rule in [2,3] and not debug: continue
					if cost > available and d.phase != "beta": continue
					var score: float = quality(cards,indices,d)
					if score > value:
						value=score
						chosen=indices
	return chosen

func quality(cards: Array, indices: Array[int], d: Dictionary) -> float:
	if d.phase == "beta":
		var score := 0.0
		var qa := 0
		for i in indices:
			var card: Dictionary = cards[i]
			if card.beta_category == "qa":
				qa+=1
				if card.definition == "debug": score += 14.0 if int(d.known_bugs)>0 else 2.0
				elif card.definition == "search_for_bugs": score += 10.0
				else: score+=float(card.beta_value)
			elif card.beta_category == "marketing": score+=float(card.beta_value)*(0.5 if int(d.known_bugs)>0 else 2.0)
			else: score+=float(card.beta_value)*0.4
		return score+(8.0 if qa==4 else 0.0)
	var scores: Dictionary = {}
	var records: Array = []
	var scope := 0
	var feature := false
	for i in indices:
		var card: Dictionary = cards[i]
		records.append({"primary_stat":card.primary_stat})
		scope+=int(card.scope)
		feature = feature or card.type == "feature"
		var contributions: Array = card.get("core_contributions",[{"stat":card.primary_stat,"value":card.primary_value},{"stat":card.secondary_stat,"value":card.secondary_value}])
		for entry in contributions:
			var k: int = STATS.find(str(entry.stat))
			if k>=0: scores[k]=int(scores.get(k,0))+int(entry.value)
	var additions: Dictionary = Production.calculate(records,scores,feature).score_additions
	var ratios: Array[float] = []
	var mean := 0.0
	for k in range(4):
		var ratio: float = minf(1.25,float(int(d.core.get(k,0))+int(additions.get(k,0)))/float(TARGETS[cfg.specialty][k]))
		ratios.append(ratio)
		mean+=ratio/4.0
	var variance := 0.0
	for ratio in ratios: variance+=pow(ratio-mean,2)/4.0
	return 800.0*maxf(0.0,mean-0.5*sqrt(variance))+4.0*mini(scope,maxi(0,int(d.required_scope)-int(d.scope)))

func acquire(view: Dictionary, rent: int) -> Dictionary:
	for q in view.research_quotes:
		if q.head:
			if q.can_research:
				acquired_windows[view.releases.size()] = true
				if str(q.feature_id) == core_pending: core_done = true
				return {"type":&"research","payload":{"quote":q}}
			return {}
	if acquired_windows.has(view.releases.size()) or acquired_windows.size() >= 5: return {}
	var supply := 0
	var totals := [0,0,0,0]
	for id in view.owned_features:
		var c: Dictionary = cards_by_id.get(str(id),{})
		if c.get("type","") != "feature" or c.get("phase","") not in ["design","alpha"]: continue
		supply += int(c.scope)
		for part in c.get("core_contributions",[{"stat":c.primary_stat,"value":c.primary_value},{"stat":c.secondary_stat,"value":c.secondary_value}]):
			var k: int = STATS.find(str(part.stat))
			if k >= 0: totals[k] += int(part.value)
	if supply >= 30: return core_acquire(view,rent) if cfg.get("core_target",false) and not core_done else {}
	var winner: Dictionary = {}
	var best_ratio := -1.0
	var best_core := -1.0
	for q in view.research_quotes:
		if not q.can_admit: continue
		var c: Dictionary = cards_by_id.get(str(q.feature_id),{})
		if c.get("type","") != "feature" or c.get("phase","") not in ["design","alpha"] or int(c.get("scope",0)) <= 0: continue
		var expense: int = int(q.down_cents)+int(q.remaining_cents)+rent*int(q.remaining_actions)
		if int(view.cash_cents) < expense+400000: continue
		var ratio: float = float(mini(int(c.scope),30-supply))/float(maxi(1,expense))
		var after: Array = totals.duplicate()
		for part in c.get("core_contributions",[{"stat":c.primary_stat,"value":c.primary_value},{"stat":c.secondary_stat,"value":c.secondary_value}]):
			var k: int = STATS.find(str(part.stat))
			if k >= 0: after[k] += int(part.value)
		var core := INF
		for k in range(4): core=minf(core,float(after[k])/float(TARGETS[cfg.specialty][k]))
		if ratio > best_ratio or (ratio == best_ratio and (core > best_core or (core == best_core and str(q.feature_id) < str(winner.get("feature_id","~"))))):
			winner=q
			best_ratio=ratio
			best_core=core
	if winner.is_empty(): return {}
	return {"type":&"admit_research","payload":{"quote":winner}}


func extend_qa(view: Dictionary, d: Dictionary, key: String, rent: int) -> Dictionary:
	var used: int = qa_extensions.get(key,0)
	qa_extensions[key] = used
	if used >= 2 or int(view.cash_cents) < 4*rent: return Legacy._development(view,&"request_exit")
	var search := false
	var debug := false
	for card in d.candidates:
		search = search or card.definition == "search_for_bugs"
		debug = debug or card.definition == "debug"
	if cfg.get("reserve_beta_redraw",false) and not search and not redrawn.has(key) and int(d.redraws)>0:
		var keep: Array[int] = best(d,int(view.cash_cents)-4*rent,false,2 if debug else 0)
		if not keep.is_empty():
			for i in range(d.candidates.size()-1,-1,-1):
				if i not in keep:
					redrawn[key] = true
					reserved_redraw = true
					return Legacy._development(view,&"redraw",{"candidate_ids":[int(d.candidates[i].token)]})
	var rule := 3 if search and debug else (1 if search else (2 if debug and int(d.known_bugs)>0 else 0))
	if rule == 0: return Legacy._development(view,&"request_exit")
	var selected: Array[int] = best(d,int(view.cash_cents)-4*rent,false,rule)
	if selected.is_empty(): return Legacy._development(view,&"request_exit")
	var tokens: Array[int] = []
	for i in selected: tokens.append(int(d.candidates[i].token))
	qa_extensions[key] = used+1
	hands[key] = int(hands.get(key,0))+1
	qa_extra = true
	return Legacy._development(view,&"play",{"candidate_ids":tokens})

func core_acquire(view: Dictionary, rent: int) -> Dictionary:
	if view.releases.is_empty(): return {}
	var review: Dictionary = view.releases[-1].metadata.review
	if float(review.final_review) >= 7.0: return {}
	var weakest := 0
	var low := INF
	for k in range(4):
		var ratio: float = float(review.cores[k])/float(review.standards[k])
		if ratio < low:
			weakest=k
			low=ratio
	if low >= 1.0: return {}
	var gap: int = int(review.standards[weakest])-int(review.cores[weakest])
	var winner: Dictionary = {}
	var best_ratio := -1.0
	var best_expense := 9223372036854775807
	for q in view.research_quotes:
		if not q.can_admit: continue
		var c: Dictionary = cards_by_id.get(str(q.feature_id),{})
		if c.get("type","") != "feature" or c.get("phase","") not in ["design","alpha"] or int(c.get("scope",0))<=0: continue
		var expense: int = int(q.down_cents)+int(q.remaining_cents)+rent*int(q.remaining_actions)
		if int(view.cash_cents) < expense+400000: continue
		var addition := 0
		for part in c.get("core_contributions",[{"stat":c.primary_stat,"value":c.primary_value},{"stat":c.secondary_stat,"value":c.secondary_value}]):
			if STATS.find(str(part.stat)) == weakest: addition += int(part.value)
		if addition <= 0: continue
		var ratio: float = float(mini(gap,addition))/float(maxi(1,expense))
		if ratio > best_ratio or (ratio == best_ratio and (expense < best_expense or (expense == best_expense and str(q.feature_id)<str(winner.get("feature_id","~"))))):
			winner=q
			best_ratio=ratio
			best_expense=expense
	if winner.is_empty(): return {}
	core_pending=str(winner.feature_id)
	core_basis={"release":view.releases.size(),"review":review,"weakest":weakest,"gap":gap,"feature_id":core_pending,"ratio":best_ratio,"expense":best_expense}
	return {"type":&"admit_research","payload":{"quote":winner}}
