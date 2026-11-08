## Engine royalties on cumulative post-platform studio revenue. The default
## preserves legacy20%; Public Action passes3000bp. Quotient/remainder avoids
## overflowing cents*rate, and cumulative deltas retain fractional cents.
extends RefCounted

static func cumulative(net_cents: int, basis_points: int=2000) -> int:
	if net_cents < 0 or basis_points < 0 or basis_points > 10000: return -1
	# Preserve exact cents and overflow-safe quotient/remainder rounding.
	@warning_ignore("integer_division")
	return (net_cents / 10000) * basis_points + ((net_cents % 10000) * basis_points) / 10000

static func increment(before_net_cents: int, after_net_cents: int, basis_points: int=2000) -> int:
	if before_net_cents < 0 or after_net_cents < before_net_cents: return -1
	if basis_points < 0 or basis_points > 10000: return -1
	return cumulative(after_net_cents,basis_points) - cumulative(before_net_cents,basis_points)

## Pure validation projection. Billing remains cumulative()/increment() above.
## Input series are per-title Studio entitlement AFTER any publisher recoup.
## Earned and settled retain independent cumulative rounding histories.
static func retained_series(earned: Variant, settled: Variant, basis_points: Variant) -> Dictionary:
	if not earned is Dictionary or not settled is Dictionary or not basis_points is int or basis_points<0 or basis_points>10000:return {}
	var cycles: Array[int]=[]
	for series: Dictionary in [earned,settled]:
		for cycle: Variant in series:
			if not cycle is int or cycle<1 or not series[cycle] is int or series[cycle]<0:return {}
			if cycle not in cycles:cycles.append(cycle)
	cycles.sort()
	var earned_total:=0;var settled_total:=0
	var retained_earned: Dictionary={};var retained_settled: Dictionary={}
	for cycle: int in cycles:
		var gain: int=earned.get(cycle,0);var paid: int=settled.get(cycle,0)
		if gain>9223372036854775807-earned_total or paid>9223372036854775807-settled_total:return {}
		var earned_after: int=earned_total+gain;var settled_after: int=settled_total+paid
		if settled_after>earned_after:return {}
		var earned_cut:=increment(earned_total,earned_after,basis_points)
		var settled_cut:=increment(settled_total,settled_after,basis_points)
		if earned_cut<0 or earned_cut>gain or settled_cut<0 or settled_cut>paid:return {}
		retained_earned[cycle]=gain-earned_cut;retained_settled[cycle]=paid-settled_cut
		earned_total=earned_after;settled_total=settled_after
	return {"earned":retained_earned,"settled":retained_settled}
