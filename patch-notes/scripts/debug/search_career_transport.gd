## Verifier-local transport only. Every transaction stays in RunState.
extends "res://scripts/simulation/campaign_session.gd"
func _execute(kind: StringName,payload: Dictionary) -> Dictionary:
	if kind not in [&"create_engine",&"purchase_engine_skill"]: return super._execute(kind,payload)
	if not in_studio or contract != null or payload.size()!=1 or not payload.get("quote") is Dictionary: return reject("Exact Studio engine quote required")
	var q: Dictionary=payload.quote
	if kind==&"create_engine":
		if not q.get("name") is String or q!=run.get_proprietary_engine_creation_quote(q.name): return reject("Stale engine creation quote")
		var result: Dictionary=run.create_proprietary_engine(q)
		if not result.get("ok",false): return reject(str(result.get("error","Engine creation rejected")))
		return {"ok":true,"events":[{"type":"engine_created","engine_id":result.engine_id,"cost_cents":q.cost_cents}]}
	if not q.get("engine_id") is StringName or not q.get("branch") is StringName or q!=run.get_engine_skill_quote(q.engine_id,q.branch): return reject("Stale or unavailable earned skill quote")
	var bought: Dictionary=run.purchase_engine_skill(q)
	if not bought.get("ok",false): return reject(str(bought.get("error","Skill purchase rejected")))
	return {"ok":true,"events":[{"type":"engine_skill_purchased","engine_id":q.engine_id,"node_id":bought.node_id,"cost_cents":q.cost_cents,"capacity":bought.capacity}]}
