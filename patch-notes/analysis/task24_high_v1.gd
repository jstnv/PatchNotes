## Separate high-effort Task21 continuation, not a normal-policy observation.
extends "res://analysis/task21_route_v1.gd"
var visits: Array[Dictionary]=[]
func _run() -> void:
	random_inputs.seed=290929000
	live_cycles=[]
	var row:=await _one("synergy",0)
	var file:=FileAccess.open("res://design-logs/task24-v1/high_task21_1104.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":[row],"failures":0 if row.valid else 1},"  "))
	quit(0 if row.valid else 1)
func _visit_high(game: Control,reason: String) -> void:
	if not game.get("_active_phase") is StudioPhase:return
	var run: RunState=game.run_state
	var s:=_state(game)
	s["reason"]=reason
	s["owned_ids"]=run.get_owned_feature_ids()
	s["year"]=run.get_current_year()
	s["qualifying_count"]=0
	s["familiarity"]={}
	for id: StringName in run.get_owned_feature_ids():s.familiarity[str(id)]=run.get_feature_familiarity(id)
	for id: StringName in run.get_released_game_ids():
		var review: Dictionary=run.get_release_metadata(id).review
		if int(review.scope)>=int(review.required_scope):s.qualifying_count+=1
	visits.append(s)
func _begin_game(game: Control,title: String,genre: StringName,out: Dictionary) -> bool:
	_visit_high(game,"before_development")
	return super._begin_game(game,title,genre,out)
func _contract(game: Control,policy: String,seed_value: int,out: Dictionary,label: String) -> bool:
	_visit_high(game,"release")
	var success:=await super._contract(game,policy,seed_value,out,label)
	_visit_high(game,"contract_return")
	return success
func _cleanup(game: Control,out: Dictionary) -> Dictionary:
	out.errors.erase("starwave_gate")
	out["releases"]=[]
	out["purchases"]=out.starter_purchases.duplicate(true)
	for key in ["store_purchase","reserve_purchase"]:
		if out.has(key):out.purchases.append(out[key])
	if game!=null and out.errors.is_empty():
		var run: RunState=game.run_state
		for number in range(3,30):
			if run.get_completed_run_cycles()>=1104:break
			if not _begin_game(game,"High Game %d"%number,&"adventure",out) or not await _develop_game(game,"synergy","mixed","qa",int(out.seed)+(number-1)*500000,number,out):out.errors.append("high_continuation");break
			_visit_high(game,"release")
			if run.get_completed_run_cycles()>=1104:break
			if run.is_sidestreet_offer_available():
				if not await _contract(game,"synergy",int(out.seed)+number*17,out,"sidestreet_%d"%number):out.errors.append("high_contract");break
		for id: StringName in run.get_released_game_ids():
			var metadata:=run.get_release_metadata(id)
			var r: Dictionary=metadata.review.duplicate(true)
			r["release_id"]=str(id);r["cycle"]=metadata.release_cycle;r["qualifies"]=int(r.scope)>=int(r.required_scope)
			out.releases.append(r)
		_visit_high(game,"final")
		out["final"]=visits[-1]
		out["studio_visits"]=visits
		out["policy"]="high_task21"
		out["store_gate"]=0
		out["cap"]=1104
		out["stop"]="cycle_cap" if run.get_completed_run_cycles()>=1104 else "blocked"
		for a: Dictionary in out.actions:
			if a.phase in ["exact_historical_reserve","additional_reserve","later_store"]:out.purchases.append(a)
	out.valid=out.errors.is_empty()
	return await super._cleanup(game,out)
