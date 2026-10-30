## Same finite development policy in both arms; one optional exact Bank request.
extends RefCounted

const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
var _delegate: Callable
var _borrow := false
var _attempted := false

static func factory(config: Dictionary) -> Callable:
	if not Fixture.valid_config(config) or not config.get("borrow") is bool: return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._delegate = Fixture.factory(config)
	policy._borrow = config.borrow
	if not policy._delegate.is_valid(): return Callable()
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)

func choose(view: Dictionary) -> Dictionary:
	if _borrow and not _attempted:
		_attempted = true
		return {"type": &"bank_borrow", "payload": {"quote": view.get("bank_quote_500_12", {})}}
	return _delegate.call(view)
