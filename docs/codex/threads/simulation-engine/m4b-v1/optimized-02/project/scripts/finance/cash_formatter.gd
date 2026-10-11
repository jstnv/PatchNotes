class_name CashFormatter
extends RefCounted

const CENTS_PER_DOLLAR := 100
const THOUSAND_CENTS := 100000
const MILLION_CENTS := 100000000
const BILLION_CENTS := 100000000000
const TRILLION_CENTS := 100000000000000
const QUADRILLION_CENTS := 100000000000000000


static func format_cents(cents: Variant) -> String:
	if typeof(cents) != TYPE_INT or cents < 0:
		return ""
	if cents < THOUSAND_CENTS:
		return "$%d.%02d" % [cents / CENTS_PER_DOLLAR, cents % CENTS_PER_DOLLAR]
	if cents >= QUADRILLION_CENTS:
		return _format_abbreviated(cents, QUADRILLION_CENTS, "Q")
	if cents >= TRILLION_CENTS:
		return _format_abbreviated(cents, TRILLION_CENTS, "T")
	if cents >= BILLION_CENTS:
		return _format_abbreviated(cents, BILLION_CENTS, "B")
	if cents >= MILLION_CENTS:
		return _format_abbreviated(cents, MILLION_CENTS, "M")
	return _format_abbreviated(cents, THOUSAND_CENTS, "K")


static func format_exact_cents(cents: Variant) -> String:
	if typeof(cents) != TYPE_INT or cents < 0:
		return ""
	return "$%d.%02d" % [cents / CENTS_PER_DOLLAR, cents % CENTS_PER_DOLLAR]


static func _format_abbreviated(cents: int, unit_cents: int, suffix: String) -> String:
	var whole_units := cents / unit_cents
	var remainder := cents % unit_cents
	var truncated_tenths := whole_units * 10 + (remainder * 10) / unit_cents
	return "$%d.%d%s" % [truncated_tenths / 10, truncated_tenths % 10, suffix]
