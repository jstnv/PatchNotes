## Declared Contracts-owned study; decisions use detached public observations.
extends RefCounted
const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
var _policies: Dictionary = {}
var _deal_game := -1
var _deal_kind := ""
var _reported: Dictionary = {}
var _revive_index := -1
var _revived := false
var _observed_ages: Dictionary = {}

static func factory(config: Dictionary) -> Callable:
	if not config.get("schedules") is Dictionary: return Callable()
	var p: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	p._deal_game = int(config.get("deal_game", -1))
	p._revive_index = int(config.get("revive_release_index", -1))
	p._deal_kind = str(config.get("deal_kind", ""))
	for key: String in config.schedules:
		var choice := Development.factory({"genre":"sports","theme":"fantasy","name_prefix":"Publisher overnight","selection":"features_first","hands":config.schedules[key]})
		if not choice.is_valid(): return Callable()
		p._policies[int(key)] = choice
	return func(view: Dictionary) -> Dictionary: return p.choose(view)

func choose(view: Dictionary) -> Dictionary:
	if _revive_index >= 0 and _revive_index < view.releases.size():
		var title: Dictionary = view.releases[_revive_index]
		var age := int(title.sales.total_earned_cycles)
		if not _observed_ages.has(age):
			_observed_ages[age] = true
			print("PN_REVIVAL_RIGHTS " + JSON.stringify({"cycle":view.run_cycle,"age":age,"raw_net":title.sales.entitlement_cents,"units":title.sales.earned_units,"rights":title.support_rights}))
		if view.phase == &"studio" and not _revived:
			_revived = true
			if not title.campaign.get("can_purchase",false): return {"type":&"declared_campaign_unavailable"}
			return {"type":&"campaign","payload":{"release_id":title.id}}
	var game: int = view.releases.size() + 1
	if not _policies.has(game): return {"type":&"outside_declared_schedule"}
	if view.phase == &"studio" and not _reported.has(game):
		_reported[game] = true
		print("PN_OVERNIGHT_STUDIO " + JSON.stringify({"next_game":game,"cycle":view.run_cycle,"cash_cents":view.cash_cents,"reputation":view.get("publisher_reputation_bp",{}),"investment":view.get("publisher_investment_capacity_bp",{}),"support_quote":view.get("support_quote",{}),"commission_quote":view.get("commission_quote",{})}))
	var choice: Dictionary = _policies[game].call(view)
	if view.phase == &"studio" and game == _deal_game and _deal_kind != "" and choice.get("type") == &"begin_development":
		var key := _deal_kind + "_quote"
		var quote: Dictionary = view.get(key,{})
		if quote.is_empty():
			print("PN_OVERNIGHT_QUOTE_UNAVAILABLE " + JSON.stringify({"game":game,"kind":_deal_kind,"cycle":view.run_cycle}))
			return {"type":&"declared_publisher_quote_unavailable"}
		choice.payload[key] = quote.duplicate(true)
	return choice
