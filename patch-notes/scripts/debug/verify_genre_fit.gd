## Genre-target Review regression checks; filename retained for the maintained gate.
extends SceneTree

const EPSILON := 0.000001
# Independent approved G/S/T/D fixtures, including integer scores that reach
# the 125% cap. Do not derive these from the runtime catalog.
const TARGET_CASES := {
	&"action": {"targets": [40, 26, 40, 26], "cap": [50, 33, 50, 33]},
	&"adventure": {"targets": [33, 26, 20, 53], "cap": [42, 33, 25, 67]},
	&"role_playing": {"targets": [20, 26, 40, 46], "cap": [25, 33, 50, 58]},
	&"strategy": {"targets": [20, 13, 53, 46], "cap": [25, 17, 67, 58]},
	&"simulation": {"targets": [20, 20, 59, 33], "cap": [25, 25, 74, 42]},
	&"puzzle": {"targets": [20, 13, 40, 59], "cap": [25, 17, 50, 74]},
	&"sports": {"targets": [33, 33, 40, 26], "cap": [42, 42, 50, 33]},
	&"racing": {"targets": [40, 33, 46, 13], "cap": [50, 42, 58, 17]},
}
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func near(left: float, right: float) -> bool:
	return absf(left - right) <= EPSILON

func make_state(scores: Array, genre: StringName = &"action", theme: StringName = &"fantasy", named: bool = true, scope: int = 30, bugs: int = 0) -> ProjectState:
	var project := ProjectState.new(30)
	if named:
		project.configure_predevelopment("Genre Test", genre, theme, [])
	return finish_state(project, scores, scope, bugs)

func finish_state(project: ProjectState, scores: Array, scope: int = 30, bugs: int = 0) -> ProjectState:
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	for index in range(4): project.add_core_score(index, scores[index])
	project.add_scope(scope)
	project.finalize_design_bugs(false, bugs, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	return project

func _run() -> void:
	for genre: StringName in TARGET_CASES:
		var example: Dictionary = TARGET_CASES[genre]
		var result := PrimitiveReviewCalculator.calculate(make_state(example.targets, genre), 50)
		check(result != null, "Approved Genre calculates: " + str(genre))
		if result == null: continue
		check(result.get_profile_id() == StringName("primitive_genre_targets_v1:" + str(genre)) and result.get_standards().values() == example.targets, "Genre profile freezes the exact approved targets: " + str(genre))
		check(near(result.get_average_ratio(), 1.0) and near(result.get_core_deviation(), 0.0) and near(result.get_production_rating(), 8.0) and near(result.get_final_review(), 8.0), "Uneven raw Genre targets have equal completion and score 8.0: " + str(genre))
		check(near(result.get_genre_deviation(), 0.0) and near(result.get_genre_modifier(), 1.0) and near(result.get_pre_genre_review(), result.get_unrounded_review()), "Compatibility fields remain neutral with no second Genre penalty: " + str(genre))
		var capped := PrimitiveReviewCalculator.calculate(make_state(example.cap, genre), 50)
		check(capped != null and near(capped.get_production_rating(), 10.0) and near(capped.get_final_review(), 10.0), "Ceiling of 125% of each target reaches 10.0: " + str(genre))
		if capped != null:
			for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
				check(near(capped.get_normalized_ratio(category), 1.25), "Genre category %d caps at 1.25: %s" % [category, genre])
		var standards := result.get_standards()
		standards[ProjectState.CoreScore.GRAPHICS] = 999
		check(result.get_standard(ProjectState.CoreScore.GRAPHICS) == example.targets[0], "Returned target copy cannot rewrite the frozen Review: " + str(genre))

	# Ratios [.5, .5, 1, 1] have mean .75 and population deviation .25.
	# 8 * (.75 - .5 * .25) = 5.0, independently of the runtime formula.
	var imbalanced := PrimitiveReviewCalculator.calculate(make_state([20, 13, 40, 26]), 50)
	check(imbalanced != null and near(imbalanced.get_average_ratio(), 0.75) and near(imbalanced.get_core_deviation(), 0.25) and near(imbalanced.get_production_rating(), 5.0), "Imbalance measures target completion, with exact population deviation")
	var even_raw := PrimitiveReviewCalculator.calculate(make_state([33, 33, 33, 33]), 50)
	check(even_raw != null and near(even_raw.get_core_deviation(), 0.2125) and near(even_raw.get_production_rating(), 7.45), "Equal raw scores no longer imply equal completion for Action")
	var action := PrimitiveReviewCalculator.calculate(make_state([40, 26, 40, 26], &"action"), 50)
	var puzzle := PrimitiveReviewCalculator.calculate(make_state([40, 26, 40, 26], &"puzzle"), 50)
	check(action != null and puzzle != null and near(action.get_production_rating(), 8.0) and puzzle.get_production_rating() < action.get_production_rating() and near(puzzle.get_genre_modifier(), 1.0), "Identical scores change base production with project Genre")
	var other_theme := PrimitiveReviewCalculator.calculate(make_state([40, 26, 40, 26], &"action", &"mystery"), 50)
	check(other_theme != null and near(other_theme.get_final_review(), action.get_final_review()), "Theme identity does not affect Genre targets or Review")
	var adjusted := PrimitiveReviewCalculator.calculate(make_state([40, 26, 40, 26], &"action", &"fantasy", true, 24, 6), 70)
	check(adjusted != null and near(adjusted.get_production_rating(), 8.0) and near(adjusted.get_scope_completion(), 0.8) and near(adjusted.get_bug_multiplier(), 0.8) and near(adjusted.get_variance_modifier(), 0.25) and near(adjusted.get_unrounded_review(), 5.37) and near(adjusted.get_final_review(), 5.4), "Scope, Bugs, variance and one-decimal rounding preserve their existing roles")

	var run := RunState.new()
	run.initialize_cash_cents(0)
	check(run.set_studio_name("Action Specialist", &"action"), "Create a real Action specialty for independent-project check")
	var independent := PrimitivePredevelopment.prepare_project("Puzzle Project", &"puzzle", &"fantasy", run)
	check(independent != null, "Action Studio can prepare a Puzzle project")
	if independent != null:
		finish_state(independent, [20, 13, 40, 59])
		var independent_result := PrimitiveReviewCalculator.calculate(independent, 50)
		check(independent_result != null and independent_result.get_profile_id() == &"primitive_genre_targets_v1:puzzle" and near(independent_result.get_production_rating(), 8.0) and run.get_studio_specialty() == &"action", "Project Genre selects scoring targets independently of Studio specialty")

	var legacy := PrimitiveReviewCalculator.calculate(make_state([33, 33, 33, 33], &"action", &"fantasy", false), 50)
	check(legacy != null and legacy.get_profile_id() == &"primitive_b_rebalanced_v2" and legacy.get_standards().values() == [33, 33, 33, 33] and near(legacy.get_final_review(), 8.0), "Identity-free legacy fixture retains equal-33 baseline")
	var zero := PrimitiveReviewCalculator.calculate(make_state([0, 0, 0, 0]), 99)
	check(zero != null and near(zero.get_production_rating(), 0.0) and near(zero.get_final_review(), 0.5) and near(zero.get_genre_modifier(), 1.0), "Zero production still permits bounded positive variance")
	var invalid := make_state([40, 26, 40, 26])
	var wrong_ratios: Array[int] = [25, 25, 25, 25]
	invalid.set("_genre_ratios", wrong_ratios)
	check(PrimitiveReviewCalculator.calculate(invalid, 50) == null and not invalid.has_review_result(), "Malformed saved ratio identity rejects without partial Review commit")
	var invalid_genre := make_state([40, 26, 40, 26])
	invalid_genre.set("_genre_id", &"unknown")
	check(PrimitiveReviewCalculator.calculate(invalid_genre, 50) == null and not invalid_genre.has_review_result(), "Unknown saved Genre rejects without partial Review commit")
	var partial_identity := make_state([33, 33, 33, 33], &"action", &"fantasy", false)
	partial_identity.set("_genre_id", &"action")
	check(PrimitiveReviewCalculator.calculate(partial_identity, 50) == null and not partial_identity.has_review_result(), "Partial identity cannot silently fall back to legacy scoring")

	var stable := make_state([40, 26, 40, 26])
	var once := PrimitiveReviewCalculator.calculate(stable, 70)
	check(stable.commit_review_result(once) and not stable.commit_review_result(PrimitiveReviewCalculator.calculate(stable, 0)) and stable.get_review_result() == once and near(once.get_final_review(), 8.3), "Committed Genre Review cannot be replaced or rerolled")
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = stable
	game.run_state = run
	root.add_child(game)
	await process_frame
	check(game.call("_ensure_review_result") and stable.get_review_result() == once and once.get_profile_id() == &"primitive_genre_targets_v1:action" and near(once.get_genre_modifier(), 1.0), "Gameplay reconstruction reuses the same frozen Genre-target result")
	game.queue_free()
	await process_frame
	print("Genre-target Review verification: %d failures" % failures)
	quit(0 if failures == 0 else 1)
