class_name StudioTraits
extends RefCounted

## Selection contract v1. No background or secondary effect is wired yet.
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


static func cash_for_points(points: int) -> int:
	if points < 0: return -1
	return mini(points, CASH_CAP_CENTS / CASH_PER_POINT_CENTS) * CASH_PER_POINT_CENTS


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
	if selection.is_empty(): return "Background not recorded (earlier run)."
	var names: PackedStringArray = []
	for id: StringName in selection.secondary_ids: names.append(SECONDARIES[id].name)
	return "%s · Selection only; effects inactive%s" % [BACKGROUNDS[selection.background_id],
		"\nPreview traits: " + ", ".join(names) if not names.is_empty() else ""]
