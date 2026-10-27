## Contracts-owned legal Game5 SideStreet support/control and Game6 observation.
## Only the detached visible CampaignSession observation informs choices.
extends RefCounted
const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
var _long: Callable
var _short: Callable
var _support := false
var _reported := false

static func factory(config: Dictionary) -> Callable:
	if typeof(config.get("support")) != TYPE_BOOL or not config.get("development_long") is Dictionary or not config.get("development_short") is Dictionary: return Callable()
	var long_policy := Development.factory(config.development_long)
	var short_policy := Development.factory(config.development_short)
	if not long_policy.is_valid() or not short_policy.is_valid(): return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._long = long_policy
	policy._short = short_policy
	policy._support = config.support
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	var releases: int = view.releases.size()
	if releases not in [4,5]: return _stop(view,"Expected post-commission Game5/Game6 route")
	if view.phase == &"studio" and releases == 4 and not _reported:
		_reported = true
		print("PN_SUPPORT_PAIR_START " + JSON.stringify({"support":_support,"cycle":view.run_cycle,"cash_cents":view.cash_cents,"investment_bp":view.publisher_investment_capacity_bp,"fans":view.fans,"quote":view.get("support_quote",{})}))
	var choice: Dictionary = (_long if releases == 4 else _short).call(view)
	if view.phase == &"studio" and choice.get("type") == &"begin_development" and releases == 4:
		if _support:
			var quote: Dictionary = view.get("support_quote",{})
			if quote.is_empty() or quote.get("publisher_id") != &"sidestreet" or quote.get("support_budget_cents") != 87500 or quote.get("funding_cents") != 70000 or quote.get("marketing_points") != 5:
				return _stop(view,"Visible I15 support quote missing or changed")
			choice.payload.support_quote = quote.duplicate(true)
			print("PN_SUPPORT_PAIR_BIND " + JSON.stringify({"quote_id":str(quote.quote_id),"project_id":str(quote.project_id),"cycle":view.run_cycle}))
		else:
			print("PN_SUPPORT_PAIR_SELF_PUBLISH " + JSON.stringify({"cycle":view.run_cycle}))
	if view.phase == &"studio" and choice.get("type") == &"begin_development" and releases == 5:
		print("PN_SUPPORT_PAIR_GAME6 " + JSON.stringify({"cycle":view.run_cycle,"cash_cents":view.cash_cents,"supported_title":view.releases[4].get("support_rights",{})}))
	return choice

func _stop(view: Dictionary, reason: String) -> Dictionary:
	print("PN_SUPPORT_PAIR_STOP " + JSON.stringify({"reason":reason,"phase":str(view.phase),"cycle":view.run_cycle,"cash_cents":view.cash_cents,"releases":view.releases.size()}))
	return {"type":&"publisher_support_pair_unmet"}
