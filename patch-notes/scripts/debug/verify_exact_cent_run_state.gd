## Focused exact-cent RunState and shared cash-format verification.
extends SceneTree

var _failures := 0


func _initialize() -> void:
	_verify_exact_cent_authority()
	_verify_dollar_compatibility()
	_verify_overflow_and_atomicity()
	_verify_formatting()
	if _failures == 0:
		print("Exact-cent RunState verification passed.")
	quit(_failures)


func _verify_exact_cent_authority() -> void:
	var state := RunState.new()
	var emissions := [0]
	state.cash_changed.connect(func() -> void: emissions[0] += 1)
	_expect(state.initialize_cash_cents(123456) and state.get_cash_cents() == 123456 and state.get_cash() == 1234 and emissions[0] == 1, "Exact cents initialize once while the legacy getter remains whole-dollar")
	_expect(state.add_cash_cents(81) and state.get_cash_cents() == 123537 and emissions[0] == 2, "Cent income preserves sub-dollar precision")
	_expect(state.spend_cash_cents(38) and state.get_cash_cents() == 123499 and emissions[0] == 3, "Cent spending preserves sub-dollar precision")
	_expect(not state.initialize_cash_cents(0) and state.get_cash_cents() == 123499 and emissions[0] == 3, "Cent authority cannot initialize twice")
	_expect(state.add_cash_cents(0) and state.spend_cash_cents(0) and emissions[0] == 3, "Zero-cent operations are successful signal-free no-ops")


func _verify_dollar_compatibility() -> void:
	var state := RunState.new()
	_expect(state.initialize_cash(0) and state.get_cash_cents() == 0 and state.get_cash() == 0, "Prototype $0 initializes as exactly 0 cents")
	_expect(state.add_cash(1000) and state.get_cash_cents() == 100000 and state.get_cash() == 1000, "Playtest Rival Games remains an exact $1,000.00 addition")
	_expect(state.spend_cash(500) and state.get_cash_cents() == 50000 and state.get_cash() == 500, "Beta Host Playtest remains an exact $500.00 cost")


func _verify_overflow_and_atomicity() -> void:
	for invalid: Variant in [-1, 1.0, NAN, INF, "1", null, true, [], {}]:
		var rejected := RunState.new()
		_expect(not rejected.initialize_cash_cents(invalid) and not rejected.is_cash_initialized(), "Invalid cent initialization rejects: %s" % [invalid])
	var state := RunState.new()
	state.initialize_cash_cents(RunState.MAX_SIGNED_INT)
	_expect(not state.add_cash_cents(1) and state.get_cash_cents() == RunState.MAX_SIGNED_INT, "Cent overflow rejects atomically")
	_expect(state.spend_cash_cents(RunState.MAX_SIGNED_INT) and state.get_cash_cents() == 0, "Exact maximum spending reaches zero without underflow")
	var dollar_overflow := RunState.new()
	_expect(not dollar_overflow.initialize_cash(RunState.MAX_SIGNED_INT), "Whole-dollar compatibility rejects conversion overflow")
	var insufficient := RunState.new()
	insufficient.initialize_cash_cents(99)
	_expect(not insufficient.spend_cash_cents(100) and insufficient.get_cash_cents() == 99, "Unaffordable cent spending rejects atomically")


func _verify_formatting() -> void:
	_expect(CashFormatter.format_cents(0) == "$0.00" and CashFormatter.format_cents(1) == "$0.01" and CashFormatter.format_cents(99999) == "$999.99", "Sub-$1,000 formatting shows exact dollars and cents")
	_expect(CashFormatter.format_cents(100000) == "$1.0K" and CashFormatter.format_cents(199999) == "$1.9K" and CashFormatter.format_cents(99999999) == "$999.9K", "K formatting truncates to one decimal")
	_expect(CashFormatter.format_cents(100000000) == "$1.0M" and CashFormatter.format_cents(199999999) == "$1.9M", "M formatting truncates to one decimal")
	_expect(CashFormatter.format_cents(123456789012) == "$1.2B" and CashFormatter.format_cents(123456789012345) == "$1.2T", "Higher supported magnitudes format without changing cents")
	_expect(CashFormatter.format_cents(-1).is_empty() and CashFormatter.format_cents(1.0).is_empty(), "Formatter rejects invalid authoritative input")


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
