## Activated new-game trial cohort. Design/Alpha exhaust legal affordable
## visible Features; Beta retains its provisional hand count.
extends RefCounted

const Factory := preload("res://scripts/simulation/run_factory.gd")
const SynergyChoice := preload("res://scripts/market/rival_synergy_choice.gd")
const BetaChoice := preload("res://scripts/market/rival_beta_synergy_choice.gd")
const StartingPool := preload("res://scripts/market/rival_starting_pool.gd")
const ZERO_STEPS := 12
const BETA_HANDS := 2

## This stock policy reads only the current hand, identities and release count.
## Building every unused campaign/Bank/Store offer on every zero-cycle choice
## used to re-plan the entire sales history repeatedly during player Research.
## Generic Callables still receive the complete public observation.
class TrialPolicy extends "res://scripts/simulation/decision_policy.gd":
	var decision: Callable
	func observation(current: RefCounted) -> Dictionary:
		return {"run_id":current.run._bank_run_id,"project_id":current.project_id(),"phase":current.phase(),
			"releases":current.run.get_released_game_ids(),
			"development":{} if current.in_studio or current.contract!=null else current.development.observation(false)}
	func choose(view: Dictionary, _lifetime: RefCounted) -> Dictionary:
		return decision.call(view)

static func create_world(player: RunState,catalog: RefCounted) -> RivalWorld:
	return preload("res://scripts/market/rival_opening_loader.gd").new().create(player,catalog)

## Explicit predecessor fixture/recovery utility; existing worlds restore their
## original two owners and policy. New-save creation never silently falls back.
static func create_legacy_world(player: RunState, catalog: RefCounted) -> RivalWorld:
	if player == null or catalog == null or player.get_completed_run_cycles()!=0 or player.get_studio_name().is_empty(): return null
	var definitions := [
		{"id":&"incumbent-arcade-foundry","name":"Arcade Foundry","specialty":&"action","archive":[
			{"id":&"arcade-history-1977","title":"Circuit Clash","year":1977,"genre":&"action","theme":&"science_fiction","review_tenths":72},
			{"id":&"arcade-history-1979","title":"Skyline Siege","year":1979,"genre":&"action","theme":&"war","review_tenths":78}]},
		{"id":&"incumbent-wayfinder-works","name":"Wayfinder Works","specialty":&"adventure","archive":[
			{"id":&"wayfinder-history-1976","title":"The Lantern Road","year":1976,"genre":&"adventure","theme":&"fantasy","review_tenths":71},
			{"id":&"wayfinder-history-1979","title":"Atlas of Ash","year":1979,"genre":&"adventure","theme":&"mystery","review_tenths":76}]}
	]
	var sessions := {}
	var archive := {}
	for item: Dictionary in definitions:
		var seed_text := (str(player._bank_run_id)+":"+str(item.id)).sha256_text().substr(0,12)
		var recipe := {"schema_version":1,"studio_id":str(item.id),"studio_name":item.name,"specialty":str(item.specialty),"traits":["family_funding","cult_following"],"seed":str(seed_text.hex_to_int())}
		var session: RefCounted = Factory.create_fresh_session(recipe,catalog)
		if session == null: return null
		if not StartingPool.apply_to_new_rival(session.run): return null
		if not session.run._feature_research.is_empty() or not session.run._familiarity.is_empty(): return null
		sessions[item.id] = session
		archive[item.id] = item.archive
	var world := RivalWorld.new()
	if not world.initialize(player,sessions): return null
	world.historical_archive = archive
	return world

static func policies(world: RivalWorld) -> Dictionary:
	var result := {}
	for id: StringName in world.studios:
		var session: RefCounted = world.studios[id]
		if session.run._rival_founder_profile=="rival-founder-active-1977-v2":
			if not world.policy_states.has(id):world.policy_states[id]={}
			var career:=preload("res://scripts/market/rival_career_decision.gd").new(session,world.policy_states[id])
			result[id]=career.choose.bind(career)
			continue
		var policy := TrialPolicy.new()
		policy.decision=_feature_maximal_choice.bind(session,String(session.run.get_studio_specialty()),session.run.get_studio_name(),uses_synergy_trial(id,session.run))
		# A method Callable alone does not retain its RefCounted target. The bound
		# argument owns it for exactly the lifetime of this returned decision.
		result[id] = policy.choose.bind(policy)
	return result

static func _feature_maximal_choice(view: Dictionary, session: RefCounted, genre: String, label: String, enabled: bool) -> Dictionary:
	if view.phase not in [&"design",&"alpha"]: return choose(view,genre,label,enabled,enabled,session)
	var current: Dictionary = view.development
	if current.finalized or current.confirmation_pending or not current.active: return choose(view,genre,label,enabled,enabled,session)
	var tokens := _legal_visible_feature_hand(current,session,enabled)
	if not tokens.is_empty(): return _development(view,&"play",{"candidate_ids":tokens})
	if _can_exit(current,session): return _development(view,&"request_exit")
	return {"type":&"blocked","payload":{"reason":"No legal affordable visible Feature hand; phase exit unavailable"}}

## The authoritative phase hand validates each combination; the current
## RunState supplies its exact fee. Only current visible instances are searched.
static func _legal_visible_feature_hand(current: Dictionary, session: RefCounted, enabled: bool) -> Array[int]:
	var hand: RefCounted = session.development.hand
	var cards: Array = current.candidates
	var best_tokens: Array[int] = []
	var best_features := 0
	var best_value := -INF
	for a in range(cards.size()-3):
		for b in range(a+1,cards.size()-2):
			for c in range(b+1,cards.size()-1):
				for d in range(c+1,cards.size()):
					var offered: Array = [cards[a],cards[b],cards[c],cards[d]]
					var selected: Array[CardData] = []
					var tokens: Array[int] = []
					var features := 0
					for card: Dictionary in offered:
						var token := int(card.token)
						var index: int = hand.candidate_ids.find(token)
						if index < 0: break
						selected.append(hand._candidate_cards[index])
						tokens.append(token)
						if card.type == "feature": features += 1
					if selected.size() != 4 or features == 0: continue
					var base: Dictionary = hand.calculate_base(selected)
					if not base.get("valid",false): continue
					var cost: int = session.run.primitive_feature_hand_cost_cents(selected,session.development.project.get_release_id())
					if cost < 0 or cost > int(current.cash_cents): continue
					var value := 0.0
					if enabled:
						var assessed: Dictionary = SynergyChoice._assess(current,offered)
						var shortfall: int = maxi(0,int(current.required_scope)-int(current.scope))
						value = float(assessed.get("proxy",0.0))+float(mini(int(base.get("scope",0)),shortfall))*0.03
					tokens.sort()
					if features > best_features or (features == best_features and value > best_value) or (features == best_features and value == best_value and _tokens_less(tokens,best_tokens)):
						best_features = features
						best_value = value
						best_tokens = tokens
	return best_tokens

static func _tokens_less(left: Array[int], right: Array[int]) -> bool:
	if right.is_empty(): return true
	for index in range(mini(left.size(),right.size())):
		if left[index] != right[index]: return left[index] < right[index]
	return left.size() < right.size()

static func uses_synergy_trial(id: StringName, run: RunState) -> bool:
	# Former player Studios and richer Store pools retain the previous policy.
	# The explicitly approved incumbent foundation pools use this screen.
	return id in [&"incumbent-arcade-foundry", &"incumbent-wayfinder-works"] and run.get_owned_feature_ids().all(StartingPool.supports_synergy_feature)

static func _can_exit(current: Dictionary, session: RefCounted) -> bool:
	# Full observations retain their existing public fact. The stock policy
	# asks the same authority lazily, only after it actually needs an exit.
	return bool(current.can_exit) if current.has("can_exit") else session!=null and session.development.actions.can_finalize()


static func choose(view: Dictionary, genre: String, label: String, beta_aware: bool = true, production_aware: bool = true, session: RefCounted = null) -> Dictionary:
	if view.phase == &"studio":
		return {"type":&"begin_development","payload":{"name":"%s %d" % [label,view.releases.size()+1],"genre":genre,"theme":"fantasy"}}
	if view.phase == &"contract": return {}
	var current: Dictionary = view.development
	if current.finalized: return {"type":&"launch"} if current.phase == "beta" else _development(view,&"enter_next_phase")
	if current.confirmation_pending: return _development(view,&"confirm_exit")
	if not current.active: return _development(view,&"begin")
	# This trial never redraws, so revision 1 is the initial deal and each later
	# revision is one real productive hand. No policy counter needs restoration.
	if current.phase == "beta" and current.get("hand_revision",0) >= BETA_HANDS+1 and _can_exit(current,session): return _development(view,&"request_exit")
	var cards: Array = current.candidates.duplicate(true)
	if current.phase == "beta":
		cards = cards.filter(func(card): return card.type != "beta" or BetaPriorityAllocation.category_enabled(StringName(card.beta_category)))
	cards.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if (a.type == "feature") != (b.type == "feature"): return a.type == "feature"
		return int(a.token) < int(b.token))
	if cards.size()<4: return {}
	var tokens: Array[int] = []
	for index in range(4): tokens.append(int(cards[index].token))
	if production_aware and current.phase in ["design","alpha"]:
		tokens = SynergyChoice.pick(current,cards.slice(0,4),StringName(view.run_id))
	elif current.phase == "beta":
		tokens = BetaChoice.pick(current,cards.slice(0,4),StringName(view.run_id),beta_aware)
	return _development(view,&"play",{"candidate_ids":tokens})

static func _development(view: Dictionary,kind: StringName,payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.development
	return {"type":&"development","payload":{"request":{"schema_version":1,"type":kind,"project_id":view.project_id,"phase":current.phase,"sequence":current.sequence,"project_cycle":current.project_cycle,"run_cycle":current.run_cycle,"payload":payload}}}
