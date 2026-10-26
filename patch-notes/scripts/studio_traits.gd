class_name StudioTraits
extends RefCounted

## Historical versions retain their effects; new selections use version 9.
## Unapproved prices never participate in the active point/cash calculation.
const VERSION := 1
const STARTING_POINTS := 4
const CASH_PER_POINT_CENTS := 5000
const CASH_CAP_CENTS := 30000
const BACKGROUNDS := {
	&"family_funding": "Family Funding",
	&"cult_following": "Cult Following",
	&"publisher_connections": "Publisher Connections"}
const SECONDARIES := {
	&"resourceful": {"name": "Resourceful", "positive": true, "price": "Price pending", "description": "Proposed Store savings; amount and eligible purchase rule pending."},
	&"lean_production": {"name": "Lean Production", "positive": true, "price": "Price pending", "description": "Proposed Feature-play savings; price and cap pending."},
	&"studio_buzz": {"name": "Studio Buzz", "positive": true, "price": "Price pending", "description": "Proposed launch Awareness; price and bonus pending."},
	&"student_loan": {"name": "Student Loan", "positive": false, "price": "Trial refund +2 (inactive)", "description": "Working plan: $10/month for 96 months. No refund or bills in this pass."},
	&"expensive_lease": {"name": "Expensive Lease", "positive": false, "price": "Refund pending", "description": "Proposed higher rent; refund and extra rent pending."},
	&"unknown_name": {"name": "Unknown Name", "positive": false, "price": "Refund pending", "description": "Proposed early Awareness penalty; refund and duration pending."}}

const TRAITS := {
	&"family_funding": {"name":"Family Funding", "positive":true, "points":2, "active_from_version":3, "active_order":0, "price":"2 points", "description":"Active: $300 separate startup funding."},
	&"cult_following": {"name":"Cult Following", "positive":true, "points":1, "active_from_version":7, "active_order":9, "price":"1 point (trial)", "description":"Trial: 20 starting Fans once. Ordinary gains and losses apply."},
	&"publisher_connections": {"name":"Publisher Connections", "positive":true, "points":1, "active_from_version":5, "active_order":6, "price":"1 point", "description":"Active: first Ironclad advance $550; remaining pool $1,850. Full payout stays $2,400."},
	&"resourceful": {"name":"Resourceful", "positive":true, "points":1, "active_from_version":4, "active_order":5, "price":"1 point", "description":"Active: up to $100 off the first paid Store acquisition per release window. Research saving applies to the final installment; down payment unchanged."},
	&"lean_production": {"name":"Lean Production", "positive":true, "points":2, "active_from_version":3, "active_order":3, "price":"2 points", "description":"Active: 10% off paid Primitive hands; up to $100 per project."},
	&"studio_buzz": {"name":"Studio Buzz", "positive":true, "points":1, "active_from_version":3, "active_order":1, "price":"1 point", "description":"Active: +3 Awareness on every launch."},
	&"college_dropout": {"name":"College Dropout", "positive":false, "points":2, "active_from_version":6, "active_order":7, "price":"Grants 2 points", "description":"$5,000 education debt; no cash deposit. 12 months grace, then 95 × $70.68 and $71.11 final."},
	&"graduate": {"name":"Graduate", "positive":false, "points":6, "active_from_version":6, "active_order":8, "price":"Grants 6 points", "description":"$20,000 education debt; no cash deposit. 12 months grace, then 95 × $282.73 and $283.28 final."},
	&"expensive_lease": {"name":"Expensive Lease", "positive":false, "points":2, "active_from_version":3, "active_order":4, "price":"Grants 2 points", "description":"Active: $515 rent every month from month 1."},
	&"unknown_name": {"name":"Unknown Name", "positive":false, "points":2, "active_from_version":3, "active_order":2, "price":"Grants 2 points", "description":"Active: -10 Awareness on first successful launch, floored at zero."}}

static func evaluate_traits(chosen: Array, version: int = 9) -> Dictionary:
	if version not in [3,4,5,6,7,8,9]: return {"valid":false,"reason":"Unsupported trait version."}
	var seen := {}
	var positive := 0
	var negative := 0
	for id: Variant in chosen:
		if not (id is String or id is StringName) or not TRAITS.has(StringName(id)):
			return {"valid":false, "reason":"Unknown trait."}
		var key := StringName(id)
		if seen.has(key): return {"valid":false, "reason":"Choose each trait only once."}
		seen[key] = true
		if TRAITS[key].positive: positive += 1
		else: negative += 1
	if version < 9 and (positive > 2 or negative > 1):
		return {"valid":false, "reason":"Choose at most two positives and one negative."}
	var ids: Array[StringName] = []
	for id: StringName in TRAITS:
		if seen.has(id): ids.append(id)
	var spent := 0
	var refunded := 0
	var active: Array[StringName] = []
	for id: StringName in TRAITS:
		if not seen.has(id): continue
		var definition: Dictionary = TRAITS[id]
		if version < int(definition.active_from_version): continue
		if definition.positive: spent += int(definition.points)
		else: refunded += int(definition.points)
		active.append(id)
	active.sort_custom(func(left: StringName, right: StringName) -> bool:
		return int(TRAITS[left].active_order) < int(TRAITS[right].active_order))
	var remaining := STARTING_POINTS - spent + refunded
	if version < 9 and remaining < 0: return {"valid":false, "reason":"Not enough build points."}
	var reason := ""
	if remaining < 0: reason = "Negative point balance. Check Traits before playing."
	if version >= 9 and seen.has(&"graduate") and seen.has(&"college_dropout"):
		reason = "Choose one education history: Graduate or College Dropout."
	return {"valid":reason.is_empty(), "reason":reason, "version":version, "trait_ids":ids,
		"effects_mode":&"approved_effects_v1", "active_ids":active, "starting_points":STARTING_POINTS,
		"spent_points":spent, "refunded_points":refunded, "remaining_points":remaining, "point_cash_cents":cash_for_points(maxi(0,remaining)),
		"family_funding_cents":30000 if seen.has(&"family_funding") else 0}


static func cash_for_points(points: int) -> int:
	if points < 0 or points > 9223372036854775807 / CASH_PER_POINT_CENTS: return -1
	return points * CASH_PER_POINT_CENTS


static func evaluate(background: StringName, secondary_ids: Array) -> Dictionary:
	if not BACKGROUNDS.has(background):
		return {"valid": false, "reason": "Choose exactly one background."}
	var seen := {}
	var positive := 0
	var negative := 0
	for id: Variant in secondary_ids:
		if not (id is String or id is StringName) or not SECONDARIES.has(StringName(id)):
			return {"valid": false, "reason": "Unknown secondary trait."}
		var key := StringName(id)
		if seen.has(key): return {"valid": false, "reason": "Choose each trait only once."}
		seen[key] = true
		if SECONDARIES[key].positive: positive += 1
		else: negative += 1
	if positive > 2 or negative > 1:
		return {"valid": false, "reason": "Choose at most two positives and one negative."}
	var ids: Array[StringName] = []
	for id: StringName in SECONDARIES:
		if seen.has(id): ids.append(id)
	return {"valid": true, "reason": "", "version": VERSION, "background_id": background,
		"secondary_ids": ids, "effects_mode": &"selection_only_preview",
		"starting_points": STARTING_POINTS, "spent_points": 0, "refunded_points": 0,
		"remaining_points": STARTING_POINTS, "point_cash_cents": cash_for_points(STARTING_POINTS)}


static func summary(selection: Dictionary) -> String:
	if selection.is_empty(): return "Traits not recorded (earlier run)."
	if selection.get("version", 1) >= 2:
		var selected: PackedStringArray = []
		for id: StringName in selection.trait_ids: selected.append(TRAITS[id].name + (" (active)" if id in selection.get("active_ids", []) else " (preview)"))
		return ("Traits: " + ", ".join(selected) if not selected.is_empty() else "No optional traits")
	var names: PackedStringArray = []
	for id: StringName in selection.secondary_ids: names.append(SECONDARIES[id].name)
	return "%s · Selection only; effects inactive%s" % [BACKGROUNDS[selection.background_id],
		"\nPreview traits: " + ", ".join(names) if not names.is_empty() else ""]


static func is_active(selection: Dictionary, id: StringName) -> bool:
	return selection.get("version", 0) >= 3 and selection.get("effects_mode", &"") == &"approved_effects_v1" and id in selection.get("active_ids", [])

static func launch_awareness(selection: Dictionary, raw: int, first_release: bool) -> int:
	if raw < 0: return -1
	var bonus := 3 if is_active(selection, &"studio_buzz") else 0
	if raw > 9223372036854775807 - bonus: return -1
	return maxi(0, raw + bonus - (10 if first_release and is_active(selection, &"unknown_name") else 0))


static func starting_fans(selection: Dictionary) -> int:
	if not is_active(selection, &"cult_following"): return 0
	match selection.get("version", 0):
		7: return 40
		8,9: return 20
	return 0
