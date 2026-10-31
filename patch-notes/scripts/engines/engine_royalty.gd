## The approved starting royalty is 20% of cumulative studio net sales after
## the platform share. Divide accumulated cents before taking each delta so
## fractional cents carry into later settlements without duplicate payments.
extends RefCounted

static func cumulative(net_cents: int) -> int:
	if net_cents < 0: return -1
	return int(net_cents / 5)

static func increment(before_net_cents: int, after_net_cents: int) -> int:
	if before_net_cents < 0 or after_net_cents < before_net_cents: return -1
	return cumulative(after_net_cents) - cumulative(before_net_cents)
