## Private bounded access research; public observations, no redraw/RNG/Bank/hire.
extends RefCounted
static func factory(config: Dictionary) -> Callable:
	var state: Dictionary={"hands":{},"cash_searches":0,"contracts":{},"research":[]}
	return func(view: Dictionary) -> Dictionary:return choose(view,state,config)
static func choose(view: Dictionary,state: Dictionary,config: Dictionary) -> Dictionary:
	if view.phase==&"studio":return _studio(view,config)
	if view.phase==&"contract":
		if view.contract.completed:return {"type":&"dismiss_contract"}
		var cards: Array=view.contract.candidates
		if cards.is_empty():return _contract(view,&"begin")
		var best: Array[int]=[];var score: float=-INF
		for a in range(4):
			for b in range(a+1,5):
				for c in range(b+1,6):
					for d in range(c+1,7):
						var ids: Array[int]=[a,b,c,d];var value:=0.0
						for i in ids:value+=4*int(cards[i].scope)+int(cards[i].primary_value)+int(cards[i].secondary_value)
						if value>score:score=value;best.assign(ids.map(func(i):return int(cards[i].token)))
		return _contract(view,&"play",{"candidate_ids":best})
	var current: Dictionary=view.development
	if current.finalized:return {"type":&"launch"} if current.phase=="beta" else _development(view,&"enter_next_phase")
	if current.confirmation_pending:return _development(view,&"confirm_exit")
	if not current.active:
		if current.phase=="beta" and current.priorities!={&"qa":50,&"marketing":50,&"insider":0}:return _development(view,&"priorities",{"distribution":{&"qa":50,&"marketing":50,&"insider":0}})
		return _development(view,&"begin")
	var key: String=str(view.project_id)+":"+str(current.phase)
	var first_target: int=2 if current.phase=="beta" else int(config.first_hands)
	var target: int=first_target if view.releases.is_empty() else ((12 if current.phase=="beta" else 10) if view.releases.size()==1 else 6)
	if int(state.hands.get(key,0))>=target:return _development(view,&"request_exit")
	state.hands[key]=int(state.hands.get(key,0))+1
	var cards: Array=current.candidates
	var indices:=_best_four(cards,current,config.ratios)
	return _development(view,&"play",{"candidate_ids":indices.map(func(i):return int(cards[i].token))})

static func _best_four(cards: Array, current: Dictionary, ratios: Array) -> Array[int]:
	var best := -INF
	var selected: Array[int] = [0, 1, 2, 3]
	var stats: Array[String] = ["graphics", "sound", "technology", "design"]
	for a in range(cards.size() - 3):
		for b in range(a + 1, cards.size() - 2):
			for c in range(b + 1, cards.size() - 1):
				for d in range(c + 1, cards.size()):
					var indices: Array[int] = [a, b, c, d]
					var score := 0.0
					if current.phase == "beta":
						var qa := 0
						for index in indices:
							var card: Dictionary = cards[index]
							if card.beta_category == "qa":
								qa += 1
								if card.definition == "debug": score += 12.0 if int(current.known_bugs) > 0 else 4.0
								elif card.definition == "search_for_bugs": score += 11.0 if int(current.known_bugs) > 0 else 7.0
								else: score += float(card.beta_value)
							elif card.beta_category == "marketing": score += float(card.beta_value) * (0.7 if int(current.known_bugs) > 0 else 3.0)
							else: score += float(card.beta_value) * 0.4
						if int(current.known_bugs) > 0:
							score += float(qa) * 3.0
							if qa == 4: score += 5.0
					else:
						var scope := 0
						var same := true
						var first_stat: String = str(cards[a].primary_stat)
						var printed: Array[float] = [0.0, 0.0, 0.0, 0.0]
						for index in indices:
							var card: Dictionary = cards[index]
							scope += int(card.scope)
							if str(card.primary_stat) != first_stat: same = false
							for entry in card.get("core_contributions",[{"stat":card.primary_stat,"value":card.primary_value},{"stat":card.secondary_stat,"value":card.secondary_value}]):
								var stat_index: int = stats.find(str(entry.stat))
								if stat_index >= 0: printed[stat_index] += float(entry.value)
						var weighted := 0.0
						for stat_index in range(4): weighted += printed[stat_index] * (1.0 if int(current.core.get(stat_index,0)) < 1.32*ratios[stat_index] else 0.1)
						score = float(mini(scope, maxi(0, 30 - int(current.scope)))) * 4.0 + weighted * (1.5 if same else 1.0) + (10.0 if same else 0.0)
					if score > best:
						best = score
						selected = indices
	return selected

static func _development(view: Dictionary, kind: StringName, payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.development
	return {"type": &"development", "payload": {"request": {"schema_version": 1, "type": kind, "project_id": view.project_id, "phase": current.phase, "sequence": current.sequence, "project_cycle": current.project_cycle, "run_cycle": current.run_cycle, "payload": payload}}}

static func _contract(view: Dictionary, kind: StringName, payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.contract
	return {"type": &"contract", "payload": {"request": {"schema_version": 1, "type": kind, "offer_id": current.offer_id, "hand_count": current.hand_count, "sequence": current.sequence, "run_cycle": current.run_cycle, "payload": payload}}}

const PRINTED_SCOPE := {"text": 1, "sprites": 2, "4_color_palette": 1, "8_bit_sound": 2, "8_bit_music": 1, "keyboard_and_mouse": 1, "controller": 1, "scrolling": 2, "menu_system": 2, "local_leaderboards": 1, "split_screen": 3, "score_system": 1, "lives_system": 1, "simple_story": 1, "dialogue": 1, "character_backstories": 1, "multiple_endings": 2, "controls": 1, "enemies": 2, "power_ups": 1, "general_combat": 2, "levels": 2, "maps": 2, "exploration": 1, "secrets": 1, "sound_effects": 1, "music": 2}

static func _cash_work(view:Dictionary) -> Dictionary:
	for offer:Dictionary in view.studio_actions.contract_offers:
		if offer.kind in [&"ironclad",&"sidestreet"]:return {"type":&"accept_contract","payload":offer}
	for row:Dictionary in view.studio_actions.contract_search:
		if row.work==&"cash" and not row.quote.is_empty():return {"type":&"search_contracts","payload":{"quote":row.quote}}
	return {"type":&"unavailable_income"}

static func _studio(view:Dictionary,config:Dictionary) -> Dictionary:
	if not view.releases.is_empty():
		for offer:Dictionary in view.studio_actions.contract_offers:
			if offer.kind in [&"ironclad",&"sidestreet"]:return {"type":&"accept_contract","payload":offer}
		for quote:Dictionary in view.research_quotes:
			if quote.head:
				return {"type":&"research","payload":{"quote":quote}} if quote.can_research else _cash_work(view)
		var printed_scope:=0
		for id in view.owned_features:printed_scope+=int(PRINTED_SCOPE.get(str(id),0))
		var targets:Array=["8_bit_sound","music","8_bit_music","lives_system","enemies","general_combat","scrolling","menu_system","split_screen","power_ups","maps","dialogue","character_backstories","secrets"] if view.releases.size()==1 and printed_scope<30 else []
		if view.releases.size()>=2:targets=["save_files","character_backstories","character_development","player_level_editor","ability_gated_exploration","switchable_protagonists","character_skill_checks"]
		for id in targets:
			if id in view.owned_features:continue
			for quote:Dictionary in view.research_quotes:
				if str(quote.feature_id)==id and quote.can_admit:
					return {"type":&"admit_research","payload":{"quote":quote}} if int(view.cash_cents)>=int(quote.down_cents)+int(quote.due_cents)+200000 else _cash_work(view)
		var complete:bool=printed_scope>=30 if view.releases.size()==1 else ["player_level_editor","ability_gated_exploration","switchable_protagonists","character_skill_checks"].all(func(id):return id in view.owned_features)
		if not complete or int(view.cash_cents)<1500000:return _cash_work(view)
	return {"type":&"begin_development","payload":{"name":"Era game %d"%(view.releases.size()+1),"genre":config.specialty,"theme":"fantasy","priorities":{0:30,1:20,2:30,3:20}}}
