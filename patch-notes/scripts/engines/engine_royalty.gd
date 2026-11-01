## Engine royalties on cumulative post-platform studio revenue. The default
## preserves legacy20%; Public Action passes3000bp. Quotient/remainder avoids
## overflowing cents*rate, and cumulative deltas retain fractional cents.
extends RefCounted

static func cumulative(net_cents: int, basis_points: int=2000) -> int:
	if net_cents < 0 or basis_points < 0 or basis_points > 10000: return -1
	return (net_cents / 10000) * basis_points + ((net_cents % 10000) * basis_points) / 10000

static func increment(before_net_cents: int, after_net_cents: int, basis_points: int=2000) -> int:
	if before_net_cents < 0 or after_net_cents < before_net_cents: return -1
	if basis_points < 0 or basis_points > 10000: return -1
	return cumulative(after_net_cents,basis_points) - cumulative(before_net_cents,basis_points)
