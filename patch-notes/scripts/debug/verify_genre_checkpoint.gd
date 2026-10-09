extends "res://scripts/debug/verify_studio_checkpoint.gd"

## Constructed historical fixture, not a claim of a legal playthrough. The old
## equal-33 Action formula gave production 8, Genre Fit .96 and final Review 7.7.
func _legacy_release(run: RunState) -> ProjectState:
	var project := PrimitivePredevelopment.prepare_project("Historical Action", &"action", &"fantasy", run)
	var scores: Dictionary[ProjectState.CoreScore, int] = {0:33, 1:33, 2:33, 3:33}
	project.add_core_scores_and_scope(scores, 30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	var ratios: Dictionary[ProjectState.CoreScore, float] = {0:1.0, 1:1.0, 2:1.0, 3:1.0}
	var review := ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), ratios, 1.0, 0.0, 1.0, 8.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.68, 7.7, 10.0, 0.96, 8.0)
	expect(project.commit_review_result(review), "Commit frozen pre-change Review fixture")
	_finish_launch(project)
	return project


func _finish_launch(project: ProjectState) -> void:
	var snapshots := PrimitiveSnapshotDatabase.new()
	expect(snapshots.load_ledgers(), "Load launch ledgers")
	expect(project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project)), "Freeze Awareness")
	expect(project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots)), "Freeze market context")
	expect(project.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(project)), "Freeze units")
	expect(project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project)), "Freeze launch revenue")


func _run() -> void:
	var run := RunState.new()
	run.initialize_cash(0)
	expect(run.create_studio_with_traits("Genre compatibility", &"action", []), "Create current Studio fixture")
	expect(run.finalize_starter_selection(), "Close starter selection")
	var historical := _legacy_release(run)
	expect(run.register_release(historical), "Register historical release once")
	var id := historical.get_release_id()
	var history := run.get_release_metadata(id)
	var sales := run.get_released_game_sales(id)
	var adapter := StudioCheckpoint.new()
	var current := adapter.capture(run)
	expect(not current.is_empty(), "Capture historical fixture under current schema: " + adapter.error)
	if current.is_empty(): quit(1); return
	var previous := current.duplicate(true)
	previous.content_revision = adapter.previous_revision()
	expect(previous.content_revision != current.content_revision, "Review revision is explicit")
	expect(adapter.validate(previous).is_empty(), "Exact immediately previous content revision remains compatible")
	var restored := adapter.hydrate(previous)
	expect(restored != null, "Hydrate prior revision without recalculation: " + adapter.error)
	if restored == null: quit(1); return
	var recaptured := adapter.capture(restored)
	var expected_current := previous.duplicate(true)
	expected_current.content_revision = adapter.revision()
	expect(recaptured == expected_current, "Recapture differs only in content revision")
	expect(restored.get_release_metadata(id) == history and restored.get_released_game_sales(id) == sales, "Historical Review, targets and sales are byte-equivalent typed values")
	expect(history.review.standards == [33,33,33,33] and history.review.final_review == 7.7 and history.review.production_rating == 8.0, "Historical equal-33 standards and old final Review remain frozen")
	var malformed := previous.duplicate(true)
	malformed.run.cash_cents = str(run.get_cash_cents() + 1)
	expect(adapter.hydrate(malformed) == null, "Previous revision still enforces all finance provenance validation")
	var unknown := previous.duplicate(true)
	unknown.content_revision = "unrelated-review-revision"
	expect(adapter.hydrate(unknown) == null and adapter.error == "INCOMPATIBLE_CONTENT_OR_RNG", "Unknown revision remains incompatible")
	var wrong_rng := previous.duplicate(true)
	wrong_rng.rng_algorithm = "unknown-rng"
	expect(adapter.hydrate(wrong_rng) == null, "Previous revision cannot bypass RNG compatibility")

	# A separate hydrated fixture supplies the new project; it does not mutate
	# the coordinator's historical save fixture or disguise an unsaved project.
	var comparison := adapter.hydrate(previous)
	var next := PrimitivePredevelopment.prepare_project("New Action", &"action", &"fantasy", comparison)
	var targets: Dictionary[ProjectState.CoreScore, int] = {0:40, 1:26, 2:40, 3:26}
	next.add_core_scores_and_scope(targets, 30)
	next.initialize_snapshots(&"fast_follower", &"stable_market")
	next.finalize_design_bugs(false, 0, [&"text"], [])
	next.finalize_alpha(0, [], [])
	next.finalize_beta()
	var next_review := PrimitiveReviewCalculator.calculate(next, 50)
	expect(next_review != null and next_review.get_standards() == targets and next_review.get_final_review() == 8.0, "Next project uses new Genre targets and neutral target-completion anchor")
	if next_review == null: quit(1); return
	expect(next.commit_review_result(next_review), "Commit new Genre Review")
	_finish_launch(next)
	var view: PostGameReview = load("res://scenes/phases/post_game_review.tscn").instantiate()
	root.add_child(view)
	await process_frame
	expect(view.setup_release_snapshot(history, sales), "Historical detailed Review accepts frozen metadata")
	expect(view.get_node("%GraphicsLabel").text.split("/")[1].strip_edges().begins_with("33 ") and view.get_node("%ReviewLabel").text.contains("7.7"), "Historical detailed Review displays old standard and score")
	expect(view.setup(next, comparison), "New detailed Review accepts current result")
	expect(view.get_node("%GraphicsLabel").text.split("/")[1].strip_edges().begins_with("40 ") and view.get_node("%SoundLabel").text.split("/")[1].strip_edges().begins_with("26 ") and view.get_node("%ReviewLabel").text.contains("8.0"), "New detailed Review displays Genre targets and score")
	expect(comparison.get_release_metadata(id) == history, "Viewing a new project never rewrites historical release metadata")
	view.queue_free()
	await process_frame

	# Use the real store and coordinator in a uniquely named isolated directory.
	# No ordinary player slot, persistent writer port or existing generation is used.
	var directory := "user://genre-checkpoint-" + Crypto.new().generate_random_bytes(8).hex_encode()
	var coordinator := CheckpointCoordinator.new()
	coordinator.store = StudioCheckpointStore.new(directory, coordinator.adapter.validate)
	coordinator.store._writer = TCPServer.new()
	var test_port := 47439
	if not OS.get_environment("PN_CHECKPOINT_TEST_PORT").is_empty(): test_port = int(OS.get_environment("PN_CHECKPOINT_TEST_PORT"))
	if coordinator.store._writer.listen(test_port, "127.0.0.1") != OK:
		expect(false, "Acquire dedicated verifier writer port")
		quit(1)
		return
	root.add_child(coordinator)
	var saved := coordinator.store.save(previous)
	expect(saved.status == &"saved", "Real store writes valid previous-revision generation")
	if saved.status != &"saved": coordinator.store.release_writer(); quit(1); return
	var path: String = saved.path
	var old_hash := FileAccess.get_sha256(path)
	var old_files := DirAccess.get_files_at(coordinator.store.directory)
	expect(coordinator.store.inspect().payload == previous, "Store inspection returns exact previous payload")
	var continued := coordinator.load_current()
	expect(continued != null, "Real coordinator Continues prior revision")
	if continued == null: coordinator.store.release_writer(); quit(1); return
	coordinator.entered_studio(true)
	await process_frame
	expect(FileAccess.get_sha256(path) == old_hash and DirAccess.get_files_at(coordinator.store.directory) == old_files, "Continue and passive Studio entry leave all saved bytes and generations unchanged")
	expect(continued.get_release_metadata(id) == history and continued.get_released_game_sales(id) == sales, "Continue preserves historical metadata and sales")
	var old_cash := continued.get_cash_cents()
	expect(continued.add_cash_cents(123), "Commit ordinary Studio cash action")
	await process_frame
	expect(coordinator.flush() and coordinator.failure.is_empty(), "Next committed action saves successfully")
	var upgraded := coordinator.store.inspect()
	expect(upgraded.status == &"valid" and upgraded.payload.content_revision == adapter.revision() and upgraded.sequence == 2, "Next action writes current revision at next generation")
	expect(FileAccess.get_sha256(path) == old_hash, "Upgrade preserves previous generation bytes")
	var upgraded_run := coordinator.adapter.hydrate(upgraded.payload)
	expect(upgraded_run != null and upgraded_run.get_cash_cents() == old_cash + 123 and upgraded_run.get_release_metadata(id) == history and upgraded_run.get_released_game_sales(id) == sales, "Upgrade contains one action and identical frozen history")
	coordinator.store.release_writer()
	coordinator.queue_free()
	await process_frame

	# An unrelated revision remains preserved on disk and is never silently loaded.
	var incompatible_directory := directory + "-incompatible"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(incompatible_directory))
	var incompatible_path := incompatible_directory.path_join("checkpoint.1.json")
	var file := FileAccess.open(incompatible_path, FileAccess.WRITE)
	file.store_string(CheckpointCodec.new().envelope(unknown))
	file.close()
	var incompatible_hash := FileAccess.get_sha256(incompatible_path)
	var incompatible_store := StudioCheckpointStore.new(incompatible_directory, adapter.validate)
	expect(incompatible_store.inspect().status == &"incompatible", "Real store identifies unrelated revision")
	expect(FileAccess.get_sha256(incompatible_path) == incompatible_hash, "Incompatible revision bytes remain preserved")
	print("Genre checkpoint verification: %d failures" % failures)
	quit(0 if failures == 0 else 1)
