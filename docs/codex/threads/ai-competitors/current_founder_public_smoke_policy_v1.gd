## Public-observation CLI smoke only. Distinct from the prelude experiment policy.
extends RefCounted
const POLICY_ID := "rival-founder-public-smoke"
const POLICY_VERSION := "1"
const Synergy=preload("res://scripts/market/rival_synergy_choice.gd")
const BetaChoice=preload("res://scripts/market/rival_beta_synergy_choice.gd")
static func factory(config: Dictionary) -> Callable:
	if config.get("genre")!="action":return Callable()
	var policy=load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	return func(view: Dictionary) -> Dictionary:return policy.choose(view)
func choose(view: Dictionary) -> Dictionary:
	if view.phase==&"studio":
		for id: StringName in [&"general_combat",&"character_backstories",&"dialogue"]:
			if id not in view.owned_features:return {"type":&"starter_purchase","payload":{"feature_id":id}}
		return {"type":&"begin_development","payload":{"name":"CLI Rival Smoke","genre":"action","theme":"fantasy"}}
	var current: Dictionary=view.development
	if current.finalized:return {"type":&"launch"} if view.phase==&"beta" else _development(view,&"enter_next_phase")
	if current.confirmation_pending:return _development(view,&"confirm_exit")
	if not current.active:return _development(view,&"begin")
	if view.phase==&"beta":
		if int(current.hand_revision)>=8 and current.can_exit:return _development(view,&"request_exit")
	elif current.can_exit:return _development(view,&"request_exit")
	var cards: Array=current.candidates.duplicate(true)
	if view.phase==&"beta":cards=cards.filter(func(c: Dictionary)->bool:return c.type=="beta" and BetaPriorityAllocation.category_enabled(StringName(c.beta_category)))
	cards.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if (a.type=="feature")!=(b.type=="feature"):return a.type=="feature"
		return int(a.token)<int(b.token))
	if cards.size()<4:return {"type":&"blocked","payload":{"reason":"Public smoke has fewer than four legal candidates"}}
	if view.phase!=&"beta" and cards.all(func(c: Dictionary)->bool:return c.type!="feature") and int(current.redraws)>0:
		return _development(view,&"redraw",{"candidate_ids":[int(cards[0].token)]})
	var tokens: Array[int]=[]
	for c: Dictionary in cards.slice(0,4):tokens.append(int(c.token))
	if view.phase==&"beta":tokens=BetaChoice.pick(current,cards.slice(0,4),StringName(view.run_id),true)
	else:tokens=Synergy.pick(current,cards.slice(0,4),StringName(view.run_id))
	return _development(view,&"play",{"candidate_ids":tokens})
func _development(view: Dictionary,kind: StringName,payload: Dictionary={}) -> Dictionary:
	var d: Dictionary=view.development
	return {"type":&"development","payload":{"request":{"schema_version":1,"type":kind,"project_id":view.project_id,"phase":d.phase,"sequence":d.sequence,"project_cycle":d.project_cycle,"run_cycle":d.run_cycle,"payload":payload}}}
