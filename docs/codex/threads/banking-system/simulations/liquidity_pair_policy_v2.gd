## Exact quote request, then at most two affordable visible FIFO Research actions.
extends RefCounted

const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
var _delegate: Callable
var _borrow_amount := 0
var _borrow_attempted := false
var _research_count := 0
var _departed := false

static func factory(config: Dictionary) -> Callable:
	var amount: Variant = config.get("borrow_amount")
	if not Fixture.valid_config(config) or not (amount is int or amount is float) or not is_finite(float(amount)) or amount != int(amount) or int(amount) not in [0,50000,100000]: return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._delegate = Fixture.factory(config)
	policy._borrow_amount = int(amount)
	if not policy._delegate.is_valid(): return Callable()
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"studio" and not _departed:
		if _borrow_amount > 0 and not _borrow_attempted:
			_borrow_attempted = true
			var key := "bank_quote_500_12" if _borrow_amount == 50000 else "bank_quote_1000_12"
			return {"type":&"bank_borrow","payload":{"quote":view.get(key,{})}}
		if _research_count < 2:
			var queue: Array = view.get("research_queue",[])
			if not queue.is_empty():
				var head_id := str(queue[0].get("feature_id",""))
				for quote: Dictionary in view.research_quotes:
					if str(quote.get("feature_id","")) == head_id and quote.get("can_research",false):
						_research_count += 1
						return {"type":&"research","payload":{"quote":quote}}
		_departed = true
	return _delegate.call(view)
