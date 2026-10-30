## Founder career metadata. Studio money, debt, IP and employees are never here.
extends RefCounted

static func create(founder_id: String, first_studio_id: String, cycle: int) -> Dictionary:
	if founder_id.is_empty() or first_studio_id.is_empty() or cycle < 0: return {}
	return {"schema_version": 1, "founder_id": founder_id, "active_studio_id": first_studio_id,
		"career_studio_ids": [first_studio_id], "operated_periods": [{"studio_id": first_studio_id, "start_cycle": cycle, "end_cycle": -1, "exit_reason": ""}],
		"milestone_ids": [], "reputation_events": [], "financing_summaries": [], "pending_departure": {}}

static func valid(profile: Dictionary) -> bool:
	if profile.size()!=9: return false # Includes rejection of any personal wallet.
	if profile.get("schema_version") != 1 or typeof(profile.get("founder_id")) != TYPE_STRING or profile.founder_id.is_empty(): return false
	if typeof(profile.get("active_studio_id")) != TYPE_STRING or typeof(profile.get("career_studio_ids")) != TYPE_ARRAY or typeof(profile.get("operated_periods")) != TYPE_ARRAY: return false
	if typeof(profile.get("milestone_ids")) != TYPE_ARRAY or typeof(profile.get("reputation_events")) != TYPE_ARRAY or typeof(profile.get("financing_summaries")) != TYPE_ARRAY or typeof(profile.get("pending_departure")) != TYPE_DICTIONARY: return false
	var open_count := 0
	var prior_end := 0
	for period in profile.operated_periods:
		if not period is Dictionary or typeof(period.get("studio_id")) != TYPE_STRING or period.studio_id.is_empty(): return false
		if typeof(period.get("start_cycle")) != TYPE_INT or typeof(period.get("end_cycle")) != TYPE_INT or typeof(period.get("exit_reason")) != TYPE_STRING: return false
		if period.start_cycle < 0 or period.end_cycle < -1 or (period.end_cycle >= 0 and period.end_cycle < period.start_cycle): return false
		if period.size()!=4 or period.start_cycle<prior_end or not profile.career_studio_ids.has(period.studio_id): return false
		prior_end=period.end_cycle if period.end_cycle>=0 else period.start_cycle
		if period.end_cycle == -1:
			open_count += 1
			if period.studio_id != profile.active_studio_id: return false
	if open_count != (0 if profile.active_studio_id.is_empty() else 1): return false
	var careers := {}
	for studio_id in profile.career_studio_ids:
		if typeof(studio_id) != TYPE_STRING or studio_id.is_empty(): return false
		if careers.has(studio_id): return false
		careers[studio_id]=true
	if not profile.active_studio_id.is_empty() and not profile.career_studio_ids.has(profile.active_studio_id): return false
	var seen := {}
	for milestone in profile.milestone_ids:
		if typeof(milestone) != TYPE_STRING or milestone.is_empty() or seen.has(milestone): return false
		seen[milestone] = true
	if not profile.pending_departure.is_empty():
		if profile.pending_departure.size()!=2 or profile.pending_departure.get("studio_id") != profile.active_studio_id or typeof(profile.pending_departure.get("reason")) != TYPE_STRING or profile.pending_departure.reason.is_empty(): return false
	var packages := {}
	for item: Variant in profile.financing_summaries:
		if not item is Dictionary or item.size()!=5 or not item.get("studio_id") is String or not item.get("package_id") is String or item.package_id.is_empty() or packages.has(item.package_id): return false
		for field in ["cycle","loan_cents","equity_cents"]:
			if typeof(item.get(field))!=TYPE_INT or item[field]<0: return false
		packages[item.package_id]=true
	return true

static func request_departure(profile: Dictionary, studio_id: String, reason: String, at_safe_boundary: bool) -> Dictionary:
	if not valid(profile) or profile.active_studio_id != studio_id or reason.is_empty() or not profile.pending_departure.is_empty(): return {}
	if reason == "voluntary" and not at_safe_boundary: return {}
	var next := profile.duplicate(true)
	next.pending_departure = {"studio_id": studio_id, "reason": reason}
	return next

static func finish_departure(profile: Dictionary, cycle: int, at_safe_boundary: bool) -> Dictionary:
	if not valid(profile) or not at_safe_boundary or cycle < 0 or profile.pending_departure.is_empty(): return {}
	var next := profile.duplicate(true)
	var last: Dictionary = next.operated_periods.back()
	if last.studio_id != next.active_studio_id or last.end_cycle != -1 or cycle < last.start_cycle: return {}
	last.end_cycle = cycle
	last.exit_reason = next.pending_departure.reason
	next.operated_periods[next.operated_periods.size() - 1] = last
	next.active_studio_id = ""
	next.pending_departure = {}
	return next if valid(next) else {}

static func activate(profile: Dictionary, studio_id: String, cycle: int, studio_exists: bool, at_safe_boundary: bool) -> Dictionary:
	if not valid(profile) or not profile.active_studio_id.is_empty() or not profile.pending_departure.is_empty() or not studio_exists or not at_safe_boundary or studio_id.is_empty() or cycle < 0: return {}
	var next := profile.duplicate(true)
	next.active_studio_id = studio_id
	if not next.career_studio_ids.has(studio_id): next.career_studio_ids.append(studio_id)
	next.operated_periods.append({"studio_id": studio_id, "start_cycle": cycle, "end_cycle": -1, "exit_reason": ""})
	return next if valid(next) else {}

static func record_milestone(profile: Dictionary, milestone_id: String) -> Dictionary:
	if not valid(profile) or milestone_id.is_empty() or profile.milestone_ids.has(milestone_id): return {}
	var next := profile.duplicate(true)
	next.milestone_ids.append(milestone_id)
	return next

static func record_financing(profile: Dictionary, studio_id: String, package_id: String, cycle: int, loan_cents: int, equity_cents: int) -> Dictionary:
	if not valid(profile) or studio_id.is_empty() or package_id.is_empty() or cycle < 0 or loan_cents < 0 or equity_cents < 0: return {}
	for item in profile.financing_summaries:
		if item.get("package_id") == package_id: return {}
	var next := profile.duplicate(true)
	next.financing_summaries.append({"studio_id": studio_id, "package_id": package_id, "cycle": cycle,
		"loan_cents": loan_cents, "equity_cents": equity_cents})
	return next
