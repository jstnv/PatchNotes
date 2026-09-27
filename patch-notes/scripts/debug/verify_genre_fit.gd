extends SceneTree

const EPSILON := 0.000001
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

func make_state(scores: Array, genre: StringName = &"action", theme: StringName = &"fantasy", named: bool = true) -> ProjectState:
	var project := ProjectState.new(30)
	if named:
		project.configure_predevelopment("Genre Test", genre, theme, [])
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	for index in range(4): project.add_core_score(index, scores[index])
	project.add_scope(30)
	project.finalize_design_bugs(false, 0, [], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	return project

func _run() -> void:
	var cases := [
		{"scores": [30, 20, 30, 20], "deviation": 0.0, "modifier": 1.0},
		{"scores": [34, 20, 26, 20], "deviation": 4.0, "modifier": 1.0},
		{"scores": [36, 20, 24, 20], "deviation": 6.0, "modifier": 1.0},
		{"scores": [40, 20, 20, 20], "deviation": 10.0, "modifier": 0.96},
		{"scores": [45, 20, 15, 20], "deviation": 15.0, "modifier": 0.91},
		{"scores": [50, 20, 10, 20], "deviation": 20.0, "modifier": 0.86},
		{"scores": [61, 20, 0, 19], "deviation": 31.0, "modifier": 0.75},
		{"scores": [100, 0, 0, 0], "deviation": 70.0, "modifier": 0.75},
	]
	for example: Dictionary in cases:
		var project := make_state(example.scores)
		var result := PrimitiveReviewCalculator.calculate(project, 50)
		check(result != null and near(result.get_genre_deviation(), example.deviation) and near(result.get_genre_modifier(), example.modifier), "Deviation %.0f uses exact locked modifier %.2f" % [example.deviation, example.modifier])
		check(result != null and near(result.get_unrounded_review(), result.get_pre_genre_review() * example.modifier) and near(result.get_final_review(), PrimitiveReviewCalculator.round_half_up_one_decimal(result.get_unrounded_review())), "Genre Fit applies once after base Review clamp and before final rounding")
	var screenshot := PrimitiveReviewCalculator.calculate(make_state([27, 30, 36, 36]), 50)
	check(screenshot != null and near(screenshot.get_production_rating(), 7.345804325208489) and near(screenshot.get_genre_modifier(), 0.9483720930232559) and near(screenshot.get_final_review(), 7.0), "Screenshot Core scores with clean Bugs, full Scope, Action Genre, and neutral variance now score 7.0")
	var action := make_state([30, 20, 30, 20], &"action")
	var puzzle := make_state([30, 20, 30, 20], &"puzzle")
	var action_result := PrimitiveReviewCalculator.calculate(action, 50)
	var puzzle_result := PrimitiveReviewCalculator.calculate(puzzle, 50)
	check(near(action_result.get_genre_modifier(), 1.0) and puzzle_result.get_genre_modifier() < 1.0, "Saved selected Genre ratios determine fit for identical final scores")
	var other_theme := make_state([30, 20, 30, 20], &"action", &"mystery")
	check(near(PrimitiveReviewCalculator.calculate(other_theme, 50).get_final_review(), action_result.get_final_review()), "Theme identity does not affect Genre Fit")
	var legacy := make_state([0, 0, 0, 0], &"action", &"fantasy", false)
	var legacy_positive := make_state([30, 20, 30, 20], &"action", &"fantasy", false)
	var zero := make_state([0, 0, 0, 0])
	check(near(PrimitiveReviewCalculator.calculate(legacy, 99).get_genre_modifier(), 1.0) and near(PrimitiveReviewCalculator.calculate(zero, 99).get_genre_modifier(), 1.0), "Missing Genre and zero total use approved neutral modifier")
	check(near(PrimitiveReviewCalculator.calculate(legacy_positive, 50).get_genre_modifier(), 1.0), "Missing Genre stays neutral even with positive resolved scores")
	check(near(PrimitiveReviewCalculator.calculate(zero, 99).get_final_review(), 0.5), "Zero-production legacy Review and positive variance remain intact")
	var invalid := make_state([30, 20, 30, 20])
	var wrong_ratios: Array[int] = [25, 25, 25, 25]
	invalid.set("_genre_ratios", wrong_ratios)
	check(PrimitiveReviewCalculator.calculate(invalid, 50) == null and not invalid.has_review_result(), "Malformed saved ratio rejects without partial Review commit")
	var invalid_genre := make_state([30, 20, 30, 20])
	invalid_genre.set("_genre_id", &"unknown")
	check(PrimitiveReviewCalculator.calculate(invalid_genre, 50) == null and not invalid_genre.has_review_result(), "Unknown saved Genre rejects without partial Review commit")
	var stable := make_state([40, 20, 20, 20])
	var once := PrimitiveReviewCalculator.calculate(stable, 70)
	check(stable.commit_review_result(once) and not stable.commit_review_result(PrimitiveReviewCalculator.calculate(stable, 0)) and stable.get_review_result() == once, "Committed result cannot be rerolled or multiplied twice")
	var run := RunState.new()
	run.initialize_cash_cents(0)
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = stable
	game.run_state = run
	root.add_child(game)
	await process_frame
	check(game.call("_ensure_review_result") and stable.get_review_result() == once and near(once.get_genre_modifier(), 0.96), "Gameplay reconstruction reuses the same Genre Fit result")
	game.queue_free()
	await process_frame
	print("Genre Fit verification: %d failures" % failures)
	quit(0 if failures == 0 else 1)
