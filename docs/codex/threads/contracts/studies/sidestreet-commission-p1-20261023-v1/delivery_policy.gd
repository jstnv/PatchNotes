extends RefCounted
const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
var cfg: Dictionary
var play: Callable
var started := false
static func factory(config: Dictionary) -> Callable:
	var p: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	p.cfg = config.duplicate(true)
	p.play = Development.factory(config.development)
	return func(view: Dictionary) -> Dictionary: return p.choose(view)
func choose(view: Dictionary) -> Dictionary:
	if view.phase != &"studio": return play.call(view)
	if not started:
		started = true
		print("PN_COMMISSION_START "+JSON.stringify({"case":cfg.label,"cycle":view.run_cycle,"cash":view.cash_cents,"standing":view.publisher_relationships,"owned":view.owned_features,"fans":view.fans}))
	if cfg.get("maps",false) and &"maps" not in view.owned_features:
		for quote: Dictionary in view.research_quotes:
			if quote.feature_id != &"maps": continue
			if quote.get("can_admit",false): return {"type":&"admit_research","payload":{"quote":quote}}
			if quote.get("can_research",false): return {"type":&"research","payload":{"quote":quote}}
		print("PN_COMMISSION_BLOCKED Maps unavailable or unaffordable")
		return {"type":&"commission_study_blocked"}
	var choice: Dictionary = play.call(view)
	if cfg.get("commission",false) and choice.type == &"begin_development":
		if view.commission_quote.is_empty(): return {"type":&"quote_commission","payload":choice.payload.duplicate(true)}
		choice.payload.commission_quote = view.commission_quote.duplicate(true)
		print("PN_COMMISSION_BIND "+JSON.stringify(view.commission_quote))
	return choice
