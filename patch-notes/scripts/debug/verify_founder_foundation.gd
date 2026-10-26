extends SceneTree

const Ownership := preload("res://scripts/legacy/ownership_book.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")
const Codec := preload("res://scripts/legacy/legacy_codec.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_verify_ownership()
	_verify_founder()
	print("Founder foundation verification: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func _verify_ownership() -> void:
	var initial := Ownership.create("old", {"founder:person": 600000, "outside:pool": 400000})
	var books := {"old": initial}
	check(Ownership.valid_world(books) and Ownership.controller(initial) == "founder:person", "Initial cap table and majority")
	var offer := {"studio_id":"old", "tx_id":"sale-1", "expected_revision":0, "seller":"founder:person", "buyer":"studio:buyer", "units":100000, "price_cents":250000, "seller_consented":true}
	check(Ownership.plan_secondary(books, offer).is_empty(), "Missing corporate buyer cannot enter ownership graph")
	books["buyer"] = Ownership.create("buyer", {"founder:rival":1000000})
	var before := books.duplicate(true)
	check(Ownership.plan_secondary(books, offer.merged({"seller_consented":false}, true)).is_empty(), "Founder refusal transfers nothing")
	var result := Ownership.plan_secondary(books, offer)
	check(not result.is_empty() and result.controller_after == "" and result.issued_units == 1000000, "Exact 50 percent has no controller")
	check(books == before and result.cash_legs == [{"holder":"studio:buyer", "delta_cents":-250000}, {"holder":"founder:person", "delta_cents":250000}], "Planning leaves input intact and identifies external settlement")
	var sold: Dictionary = result.books
	check(Ownership.plan_secondary(sold, offer).is_empty(), "Duplicate or stale sale rejected")
	var other := {"studio_id":"old", "tx_id":"sale-2", "expected_revision":0, "seller":"outside:pool", "buyer":"studio:buyer", "units":400000, "price_cents":500000, "seller_consented":true}
	var other_result := Ownership.plan_secondary(books, other)
	check(other_result.controller_after == "founder:person" and other_result.books.old.holders["founder:person"] == 600000, "Other shareholder sale preserves founder majority")
	var primary := {"studio_id":"old", "tx_id":"issue-1", "expected_revision":0, "buyer":"studio:buyer", "investment_cents":250000, "pre_money_cents":1000000, "affirmative_units":600000}
	var issued := Ownership.plan_primary(books, primary)
	check(not issued.is_empty() and issued.new_units == 250000 and issued.post_money_cents == 1250000 and issued.controller_after == "", "Paid primary issuance dilutes majority with correct post money")
	check(issued.cash_legs[1] == {"holder":"studio:old", "delta_cents":250000} and books == before, "Primary proceeds belong to target Studio and planning is pure")
	check(Ownership.plan_primary(books, primary.merged({"affirmative_units":500000}, true)).is_empty(), "Exactly half cannot authorize issuance")
	check(Ownership.plan_primary(books, primary.merged({"pre_money_cents":0}, true)).is_empty(), "Zero pre money cannot use ordinary issue formula")
	var cycle_request := {"studio_id":"buyer", "tx_id":"cycle-1", "expected_revision":0, "seller":"founder:rival", "buyer":"studio:old", "units":1, "price_cents":1, "seller_consented":true}
	check(Ownership.plan_secondary(other_result.books, cycle_request).is_empty(), "Corporate ownership cycles rejected")
	check(Ownership.create("bad", {"studio:bad":1}).is_empty(), "Self ownership rejected")
	var one_unit := Ownership.create("small", {"founder:person": 500001, "outside:pool": 499999})
	check(Ownership.controller(one_unit) == "founder:person", "One unit above half controls")
	var one_cent := {"studio_id":"old", "tx_id":"rounding", "expected_revision":0, "buyer":"outside:new", "investment_cents":1, "pre_money_cents":2000000, "affirmative_units":600000}
	check(Ownership.plan_primary(books, one_cent).is_empty(), "Half-unit banker rounding cannot issue zero shares")
	var restored_book: Dictionary = Codec.decode_book(JSON.parse_string(JSON.stringify(Codec.encode_book(initial))))
	check(Ownership.valid(restored_book) and Ownership.controller(restored_book) == "founder:person", "Cap table survives exact JSON checkpoint round trip")
	var corrupted := Codec.encode_book(initial)
	corrupted.holders["founder:person"] = "600000.0"
	check(Codec.decode_book(corrupted).is_empty(), "Inexact share encoding rejected")

func _verify_founder() -> void:
	var profile := Founder.create("person", "old", 0)
	check(Founder.valid(profile) and profile.active_studio_id == "old", "Founder initially operates one Studio")
	check(Founder.request_departure(profile, "old", "voluntary", false).is_empty(), "Voluntary departure waits for safe boundary")
	var pending := Founder.request_departure(profile, "old", "voluntary", true)
	check(not pending.is_empty() and Founder.finish_departure(pending, 4, false).is_empty(), "Pending role cannot hand off in active phase")
	var departed := Founder.finish_departure(pending, 4, true)
	check(Founder.valid(departed) and departed.active_studio_id.is_empty() and departed.operated_periods[0].exit_reason == "voluntary", "Career records departure without a wallet")
	check(Founder.activate(profile, "new", 4, true, true).is_empty(), "Second manual Studio rejected")
	var migrated := Founder.activate(departed, "new", 4, true, true)
	check(Founder.valid(migrated) and migrated.active_studio_id == "new" and migrated.career_studio_ids == ["old", "new"], "Funded existing Studio can become sole manual operator")
	check(Founder.activate(departed, "free", 4, false, true).is_empty(), "Nonexistent free Studio cannot be activated")
	var achieved := Founder.record_milestone(migrated, "first-acquisition")
	check(achieved.milestone_ids == ["first-acquisition"] and Founder.record_milestone(achieved, "first-acquisition").is_empty(), "Milestones are once only")
	var financed := Founder.record_financing(achieved, "new", "package-1", 4, 10000, 5000)
	check(financed.financing_summaries.size() == 1 and not financed.has("cash_cents") and Founder.record_financing(financed, "new", "package-1", 4, 10000, 5000).is_empty(), "Financing history is nonspendable and idempotent")
	var restored_profile: Dictionary = Codec.decode_founder(JSON.parse_string(JSON.stringify(Codec.encode_founder(financed))))
	check(Founder.valid(restored_profile) and restored_profile.active_studio_id == "new", "Founder career survives exact JSON checkpoint round trip")
