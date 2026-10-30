extends RefCounted
const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
var cfg: Dictionary
var play: Callable
static func factory(config: Dictionary) -> Callable:
	var p: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	p.cfg=config.duplicate(true)
	p.play=Development.factory(config.development)
	return func(view: Dictionary) -> Dictionary: return p.choose(view)
func choose(view: Dictionary) -> Dictionary:
	if view.phase != &"studio": return play.call(view)
	for feature in cfg.research:
		if StringName(feature) in view.owned_features: continue
		for quote: Dictionary in view.research_quotes:
			if quote.feature_id != StringName(feature): continue
			print("PN_GATE_RESEARCH "+JSON.stringify({"case":cfg.label,"cycle":view.run_cycle,"cash":view.cash_cents,"quote":quote}))
			if quote.get("can_admit",false): return {"type":&"admit_research","payload":{"quote":quote}}
			if quote.get("can_research",false): return {"type":&"research","payload":{"quote":quote}}
		print("PN_GATE_BLOCKED "+str(feature))
		return {"type":&"full_delivery_study_blocked"}
	var choice: Dictionary = play.call(view)
	if cfg.commission and choice.type == &"begin_development":
		if view.commission_quote.is_empty(): return {"type":&"quote_commission","payload":choice.payload.duplicate(true)}
		choice.payload.commission_quote=view.commission_quote.duplicate(true)
		print("PN_GATE_BIND "+JSON.stringify({"quote":view.commission_quote,"standing":view.publisher_relationships,"owned":view.owned_features,"cash":view.cash_cents}))
	return choice
