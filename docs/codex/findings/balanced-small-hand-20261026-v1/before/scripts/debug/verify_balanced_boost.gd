extends SceneTree

const Balanced := preload("res://scripts/cards/balanced_production.gd")
const Production := preload("res://scripts/simulation/production_hand.gd")
const RivalChoice := preload("res://scripts/market/rival_synergy_choice.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func _run() -> void:
	# Independent whole-point oracle across every multiplication/split remainder.
	for total in range(257):
		@warning_ignore("integer_division")
		var boosted := total * 5 / 4
		var split := Balanced.redistribute({0: total})
		var sum := 0
		for category in range(4):
			@warning_ignore("integer_division")
			var expected := boosted / 4 + (1 if category < boosted % 4 else 0)
			expect(split[category] == expected, "total %d category %d" % [total, category])
			sum += split[category]
		expect(sum == boosted, "total %d retains exactly floor(total * 1.25)" % total)
	expect(Balanced.redistribute({0: 5, 1: 5, 2: 5, 3: 6}) == {0: 7, 1: 7, 2: 6, 3: 6}, "21 -> 26 -> 7/7/6/6")
	expect(Balanced.redistribute({0: 2, 1: 2, 2: 2, 3: 2}) == {0: 3, 1: 3, 2: 2, 3: 2}, "8 -> 10 -> 3/3/2/2")
	expect(Balanced.qualifies({0: 17, 1: 20, 2: 20, 3: 23}), "Inclusive raw 15% endpoints remain")
	expect(not Balanced.qualifies({0: 16, 1: 20, 2: 20, 3: 24}), "Outside raw endpoints remains ineligible")
	var raw := {0: 5, 1: 5, 2: 5, 3: 6}
	var original := raw.duplicate(true)
	var records: Array[Dictionary] = []
	for stat in [&"graphics", &"sound", &"technology", &"design"]:
		records.append({"primary_stat": stat})
	var final := Production.calculate(records, raw, true)
	expect(final.balanced_production and final.score_additions == {0: 7, 1: 7, 2: 6, 3: 6}, "Shared live/headless final arithmetic boosts Balanced")
	expect(raw == original, "Calculation does not mutate raw hand")
	var cards: Array = []
	for category in range(4):
		cards.append({"token": category, "definition": "boost_fixture_" + str(category),
			"primary_stat": Production.CORE_STATS[category], "primary_value": 6 if category == 3 else 5,
			"secondary_value": 0, "scope": 1, "type": "feature"})
	var current := {"genre": "action", "required_scope": 30, "core": {0: 0, 1: 0, 2: 0, 3: 0}}
	var assessed := RivalChoice._assess(current, cards)
	expect(assessed.synergy == "balanced" and assessed.final_core == final.score_additions, "AI evaluation uses the same boosted split")
	expect(assessed.scope == 4 and is_equal_approx(assessed.bug_pressure, 21.0 / 18.0), "AI keeps raw Scope and Bug Pressure")
	var passes := Production.calculate(records, raw, false)
	expect(not passes.balanced_production and passes.score_additions == raw, "Feature requirement remains")
	for record in records:
		record.primary_stat = &"graphics"
	var specialized := Production.calculate(records, raw, true)
	expect(not specialized.balanced_production and specialized.score_additions == {0: 8, 1: 8, 2: 8, 3: 9}, "Specialization wins without stacking")
	print("BALANCED_BOOST checks=%d failures=%d" % [checks, failures])
	quit(failures)
