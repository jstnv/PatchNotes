## Banking thread finite test policy. Decisions use only public simulator observations.
## This is not an approved game strategy or AI policy.
extends RefCounted

const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")

var _config: Dictionary
var _delegate: Callable
var _store_admitted := false
var _store_completed := false
var _loan_attempted := false

static func factory(config: Dictionary) -> Callable:
	if not Fixture.valid_config(config): return Callable()
	if config.get("research_feature") != "recorded_sounds" or not config.get("borrow_after_two") is bool: return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._config = config.duplicate(true)
	policy._delegate = Fixture.factory(config)
	if not policy._delegate.is_valid(): return Callable()
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"studio" and view.releases.size() == 1:
		var quote: Dictionary = {}
		for candidate: Dictionary in view.research_quotes:
			if str(candidate.get("feature_id", "")) == _config.research_feature:
				quote = candidate
				break
		if not _store_admitted:
			_store_admitted = true
			return {"type": &"admit_research", "payload": {"quote": quote}}
		if not _store_completed:
			_store_completed = true
			return {"type": &"research", "payload": {"quote": quote}}
	if view.phase == &"studio" and view.releases.size() == 2 and _config.borrow_after_two and not _loan_attempted:
		_loan_attempted = true
		## Private Banking candidate exposes this existing public quote read-only.
		## Empty or ineligible quote is submitted once and retained as a rejection.
		return {"type": &"bank_borrow", "payload": {"quote": view.get("bank_quote_500_12", {})}}
	return _delegate.call(view)
