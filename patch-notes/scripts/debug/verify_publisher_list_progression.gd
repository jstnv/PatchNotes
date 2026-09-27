extends SceneTree

var failures := 0
var snapshots := PrimitiveSnapshotDatabase.new()


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func make_release(review_score: float, marketing: int) -> ProjectState:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.add_scope(30)
	project.add_marketing_output(marketing)
	project.finalize_design_bugs(false, 0, [], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, review_score, 1.0, 0, 0.0, 1.0, 50, 0.0, review_score, review_score))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(project))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project


func new_run() -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(0)
	return run


func snapshot(run: RunState, project: ProjectState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_released_game_sales(project.get_release_id()), project.get_review_result(), project.get_awareness_result()]


func select_first(phase: ContractPhase) -> void:
	for child in phase.get("_candidate_row").get_children():
		if phase.get_selected_candidate_views().size() >= 4:
			break
		if child is CardView and not child.is_selected():
			child.input_button.pressed.emit()


func _run() -> void:
	snapshots.load_ledgers()
	root.size = Vector2i(1152, 648)
	await _verify_browser_and_release_thresholds()
	await _verify_contract_completion()
	print("Publisher List and progression verification: %d failures" % failures)
	quit(failures)


func _verify_browser_and_release_thresholds() -> void:
	var run := new_run()
	var project := make_release(6.9, 24)
	check(run.get_unlocked_publisher_ids().is_empty() and run.get_pending_publisher_notifications().is_empty(), "No publisher unlocks before first release")
	check(not run.register_release(ProjectState.new(30)) and run.get_unlocked_publisher_ids().is_empty(), "Failed registration cannot advance progression")
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	check(studio.setup(project, run, snapshots), "First release enters Studio")
	root.add_child(studio)
	await process_frame
	check(run.get_unlocked_publisher_ids() == [&"ironclad"] and run.get_pending_publisher_notifications().is_empty(), "Only Ironclad unlocks at first release, and Studio presents its notification once")
	var notice := studio.get_node("Dashboard/Layout/PublisherUnlockNotice") as PanelContainer
	check(notice.visible and (notice.find_child("PublisherUnlockMessage", true, false) as Label).text.contains("Ironclad Interactive"), "One-time unlock banner names Ironclad")
	var before := snapshot(run, project)
	studio.get_node("%PublisherList").pressed.emit()
	var browser: PublisherBrowser = studio.get_node("PublisherBrowser")
	var list := browser.find_child("PublisherEntries", true, false) as ItemList
	var details := browser.find_child("PublisherDetails", true, false) as RichTextLabel
	check(browser.visible and list.item_count == 5 and not studio.get_node("%Dashboard").visible, "Studio browser shows all five publishers")
	for size in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = size
		await process_frame
		await process_frame
		await process_frame
		var browser_rect := browser.get_global_rect()
		var list_rect := list.get_global_rect()
		var details_rect := details.get_global_rect()
		var studio_rect := studio.get_global_rect()
		check(browser_rect.position.x >= studio_rect.position.x and browser_rect.end.x <= studio_rect.end.x and list_rect.end.x <= studio_rect.end.x and details_rect.position.x >= list_rect.end.x and details_rect.end.x <= studio_rect.end.x, "Publisher browser fits the Studio viewport at %s" % size)
	root.size = Vector2i(1152, 648)
	for index in range(5):
		list.select(index)
		list.item_selected.emit(index)
		check(details.text.contains(PublisherCatalog.entries()[index].name) and details.text.contains("Prerequisite:") and details.text.contains(PublisherCatalog.entries()[index].personality), "Publisher %d displays identity, condition and personality" % index)
	check(list.get_item_text(0).contains("Unlocked") and list.get_item_text(4).contains("Locked") and details.text.contains("3)."), "Locked Starwave states the unattainable three-contract condition")
	(browser.find_child("ClosePublisherBrowser", true, false) as Button).pressed.emit()
	check(before == snapshot(run, project) and studio.get_node("%Dashboard").visible, "Browser navigation costs zero cash and cycles and preserves frozen results")
	studio.get_node("%Contracts").pressed.emit()
	var contract_detail := studio.get_node("ContractDetail") as PanelContainer
	check((contract_detail.find_child("AcceptContractButton", true, false) as Button).visible and _panel_text(contract_detail).contains("Publisher: Ironclad Interactive"), "Existing cash-only Primitive Contract is explicitly assigned to Ironclad")
	(contract_detail.find_child("CloseContractDetailButton", true, false) as Button).pressed.emit()
	check(before == snapshot(run, project), "Contract details remain passive beside publisher browsing")
	var reconstructed := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	check(reconstructed.setup(project, run, snapshots), "Studio reconstruction accepts same release")
	root.add_child(reconstructed)
	await process_frame
	check(reconstructed.get_node_or_null("Dashboard/Layout/PublisherUnlockNotice") == null and run.get_unlocked_publisher_ids() == [&"ironclad"] and before == snapshot(run, project), "Reconstruction neither repeats notification nor mutates release state")
	studio.queue_free()
	reconstructed.queue_free()
	await process_frame
	var second := make_release(7.0, 25)
	var below := make_release(6.9, 24)
	check(run.register_release(below) and not run.get_unlocked_publisher_ids().has(PublisherCatalog.CROWN_QUILL) and not run.get_unlocked_publisher_ids().has(PublisherCatalog.NEON_CIRCUIT), "Review 6.9 and Awareness 124 do not unlock threshold publishers")
	check(run.register_release(second) and run.get_unlocked_publisher_ids().has(PublisherCatalog.CROWN_QUILL) and run.get_unlocked_publisher_ids().has(PublisherCatalog.NEON_CIRCUIT), "Review 7.0 and Awareness 125 unlock exact thresholds from committed release history")
	check(run.get_release_metadata(second.get_release_id()).review.final_review == 7.0 and run.get_release_metadata(second.get_release_id()).review.awareness == 125, "Publisher thresholds use frozen historical results")
	var pending := run.get_pending_publisher_notifications()
	check(pending.size() == 2 and pending.has(PublisherCatalog.CROWN_QUILL) and pending.has(PublisherCatalog.NEON_CIRCUIT), "New publisher notifications queue once")
	check(run.register_release(second) and run.get_pending_publisher_notifications() == pending and not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE), "Duplicate release registration cannot repeat notifications or unlock Starwave")
	check(run.get_publisher_status(PublisherCatalog.STARWAVE).requirement.contains("3)."), "Two releases alone cannot meet Starwave's contract requirement")
	check(run.take_pending_publisher_notifications() == pending and run.take_pending_publisher_notifications().is_empty(), "Notification acknowledgment is one-shot")


func _verify_contract_completion() -> void:
	var run := new_run()
	var project := make_release(6.9, 24)
	check(run.register_release(project), "Contract progression fixture has first release")
	var state := run.accept_primitive_contract()
	check(state != null and not run.get_unlocked_publisher_ids().has(PublisherCatalog.SIDESTREET) and run.get_completed_contract_count() == 0, "Accepting a contract does not unlock SideStreet")
	var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	check(phase.setup(state, run), "Contract phase reuses authoritative state")
	root.add_child(phase)
	await process_frame
	var database := root.get_node("CardDatabase")
	var cards: Array[CardData] = [database.get_card(&"text"), database.get_card(&"graphics_pass"), database.get_card(&"sound_pass"), database.get_card(&"technology_pass"), database.get_card(&"design_pass"), database.get_card(&"sprites"), database.get_card(&"scrolling")]
	phase.call("_publish_candidate_pool", cards)
	select_first(phase)
	check(phase.call("_play_selected_hand"), "First contract hand commits")
	check(state.get_successful_hand_count() == 1 and run.get_completed_contract_count() == 0 and not run.get_unlocked_publisher_ids().has(PublisherCatalog.SIDESTREET), "Partial contract never unlocks SideStreet")
	select_first(phase)
	check(phase.call("_play_selected_hand"), "Second contract hand completes")
	check(state.is_completed() and state.is_payout_committed() and run.get_completed_contract_count() == 1 and run.get_unlocked_publisher_ids().has(PublisherCatalog.SIDESTREET), "Only committed completion unlocks SideStreet")
	var pending := run.get_pending_publisher_notifications()
	check(pending.count(PublisherCatalog.SIDESTREET) == 1, "SideStreet notification is queued once")
	var after := snapshot(run, project)
	check(not phase.call("_play_selected_hand") and snapshot(run, project) == after and run.get_pending_publisher_notifications() == pending, "Repeated completion cannot pay, advance, or notify again")
	check(not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE) and run.get_completed_contract_count() == 1, "Fixed one-shot contract cannot meet Starwave's three-completion requirement")
	phase.queue_free()
	await process_frame


func _panel_text(panel: Control) -> String:
	var result := ""
	for child in panel.find_children("*", "Label", true, false):
		result += (child as Label).text
	return result
