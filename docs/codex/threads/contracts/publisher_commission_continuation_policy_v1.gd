## Contracts-owned policy for same-Studio/RNG Game4 commission/control pair.
## Both arms use identical visible Maps research; only project deal differs.
extends RefCounted

const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
var _development: Callable
var _commission := false
var _maps_completed := false
var _start_printed := false

static func factory(config: Dictionary) -> Callable:
	if not config.get("development") is Dictionary or typeof(config.get("commission")) != TYPE_BOOL or config.get("maps") != true: return Callable()
	var callback := Development.factory(config.development)
	if not callback.is_valid(): return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._development = callback
	policy._commission = config.commission
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	if view.phase != &"studio": return _development.call(view)
	if view.releases.size() != 3 or int(view.get("publisher_reputation_bp",{}).get(&"sidestreet",0)) != 2000:
		return _stop(view,"Expected exactly three released games and R20 at Studio")
	if not _start_printed:
		_start_printed = true
		print("PN_COMMISSION_PAIR_START " + JSON.stringify({"commission":_commission,"cycle":view.run_cycle,"cash_cents":view.cash_cents,"releases":view.releases.size(),"reputation_bp":view.publisher_reputation_bp,"fans":view.fans}))
	if &"maps" not in view.owned_features:
		for quote: Dictionary in view.research_quotes:
			if StringName(quote.get("feature_id",&"")) != &"maps": continue
			if bool(quote.get("can_admit",false)):
				print("PN_COMMISSION_MAPS_ADMIT " + JSON.stringify({"due_cents":quote.due_cents,"cycle":view.run_cycle}))
				return {"type":&"admit_research","payload":{"quote":quote}}
			if bool(quote.get("can_research",false)):
				print("PN_COMMISSION_MAPS_RESEARCH " + JSON.stringify({"due_cents":quote.due_cents,"cycle":view.run_cycle}))
				return {"type":&"research","payload":{"quote":quote}}
			return _stop(view,"Maps quote visible but cannot be admitted/researched")
		return _stop(view,"Maps research quote missing")
	if not _maps_completed:
		_maps_completed = true
		print("PN_COMMISSION_MAPS_OWNED " + JSON.stringify({"cycle":view.run_cycle,"cash_cents":view.cash_cents}))
	var choice: Dictionary = _development.call(view)
	if choice.get("type") != &"begin_development": return choice
	if _commission:
		var quote: Dictionary = view.get("commission_quote",{})
		if quote.is_empty() or quote.get("publisher_id") != &"sidestreet" or quote.get("fee_cents") != 600000 or quote.get("required_scope") != 30:
			return _stop(view,"Visible tier-1 commission quote missing or changed")
		choice.payload.commission_quote = quote.duplicate(true)
		print("PN_COMMISSION_PAIR_BIND " + JSON.stringify({"quote_id":str(quote.quote_id),"project_id":str(quote.project_id),"cycle":view.run_cycle}))
	else:
		print("PN_COMMISSION_PAIR_SELF_PUBLISH " + JSON.stringify({"cycle":view.run_cycle}))
	return choice

func _stop(view: Dictionary, reason: String) -> Dictionary:
	print("PN_COMMISSION_PAIR_STOP " + JSON.stringify({"reason":reason,"phase":str(view.phase),"cycle":view.run_cycle,"cash_cents":view.cash_cents,"releases":view.releases.size()}))
	return {"type":&"publisher_commission_pair_unmet"}
