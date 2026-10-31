## Run with Godot --headless --path patch-notes --script res://scripts/debug/verify_engine_specialization.gd
extends SceneTree

const Production := preload("res://scripts/simulation/production_hand.gd")
const Marketplace := preload("res://scripts/engines/engine_marketplace.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var matching := [{"primary_stat": &"graphics"}, {"primary_stat": &"graphics"}, {"primary_stat": &"graphics"}, {"primary_stat": &"graphics"}]
	var raw := {0: 10, 1: 10, 2: 10, 3: 10}
	var bonus := {0: 2000, 2: 1000} # +0.1 engine and +0.1 employee on Graphics; +0.1 engine on Technology.
	check(Marketplace.production_bonus(&"action_engine") == {0: 1000, 2: 1000} and Marketplace.production_bonus(&"puzzle_engine") == {2: 1000, 3: 1000}, "Engine bonus map follows dominant Core categories")
	check(Marketplace.production_bonus(&"legacy_engine").is_empty(), "Built-in engine has no production bonus")
	var result: Dictionary = Production.calculate(matching, raw, true, bonus)
	check(result.specialization_stat == &"graphics" and result.score_additions[0] == 17 and result.score_additions[2] == 16, "Engine and employee specialization bonuses add to the base 1.5 multiplier")
	check(result.score_additions[1] == 15 and result.score_additions[3] == 15, "Non-dominant categories retain the base multiplier")
	var passes_only: Dictionary = Production.calculate(matching, raw, false, bonus)
	check(passes_only.score_additions == result.score_additions, "A qualifying Pass-only hand receives the same specialization bonus")
	var mixed := [{"primary_stat": &"graphics"}, {"primary_stat": &"sound"}, {"primary_stat": &"technology"}, {"primary_stat": &"design"}]
	var nonspecial: Dictionary = Production.calculate(mixed, raw, true, bonus)
	check(nonspecial.specialization_stat.is_empty() and nonspecial.score_additions[0] != 17, "Engine bonuses do not activate without Specialization")
	print("Engine specialization: %d failures" % failures)
	quit(1 if failures else 0)
