## Explicit paired Store TEST strategy. No approved rival shopping policy.
## Both arms share one legal Studio checkpoint and finite development policy.
## A denied public quote is submitted once and retained as a rejected action.
extends RefCounted

const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
const POLICY_ID := "paired-store-study"
const POLICY_VERSION := "1"
var _arm: String
var _feature: StringName
var _development: Callable

static func factory(config: Dictionary) -> Callable:
	if config.get("arm") not in ["research_now","defer"] or not config.get("feature") is String or config.feature.is_empty(): return Callable()
	if not config.get("development") is Dictionary: return Callable()
	var development: Callable = Development.factory(config.development)
	if not development.is_valid(): return Callable()
	var policy: RefCounted = load("res://scripts/debug/store_study_policy.gd").new()
	policy._arm = config.arm
	policy._feature = StringName(config.feature)
	policy._development = development
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	if _arm == "defer" or view.phase != &"studio" or _feature in view.owned_features:
		return _development.call(view)
	# No can_admit/can_research bypass, invented cash, retry, fallback purchase or
	# free waiting. The authoritative command decides whether this quote commits.
	for quote: Dictionary in view.research_quotes:
		if quote.feature_id == _feature:
			if not quote.queued: return {"type":&"admit_research","payload":{"quote":quote}}
			for head: Dictionary in view.research_quotes:
				if head.head: return {"type":&"research","payload":{"quote":head}}
			return {"type":&"research","payload":{"quote":quote}}
	# Preserve an explicit failed attempt if the configured target has no quote.
	return {"type":&"admit_research","payload":{"quote":{}}}
