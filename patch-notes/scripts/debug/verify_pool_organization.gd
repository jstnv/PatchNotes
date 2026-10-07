extends "res://scripts/debug/verify_game_lifespan_trial.gd"

## Presentation fixtures use real transactions; these are not human play traces.
const OUT := "res://design-logs/campaign-pool-ui-v1"
var traces: Array = []

func settle() -> void:
	await create_timer(0.70).timeout

func shot(name: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + name + ".png")

func ids(cards: Array) -> Array:
	return cards.map(func(card): return str(card.card_data.id))

func state(phase: Control, project: ProjectState, run: RunState) -> Array:
	return [HandPresentation.project_snapshot(project, run), run.get_cash_cents(),
		phase.get("_candidate_cards").duplicate(), phase.get("_deal_rng").state,
		project.get_exhausted_beta_card_ids(), run.get_owned_feature_ids()]

func install(phase: Control, names: Array[StringName]) -> void:
	var fan: CardFan = phase.get_node("%HandContainer")
	for view in fan.ordered_cards():
		fan.remove_child(view)
		view.queue_free()
	var cards: Array[CardData] = []
	var views: Array[CardView] = []
	for id in names:
		var card: CardData = root.get_node("CardDatabase").get_card(id)
		var view: CardView = load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(card)
		view.card_pressed.connect(Callable(phase, "_on_card_pressed"))
		fan.add_child(view)
		cards.append(card)
		views.append(view)
	phase.set("_candidate_cards", cards)
	phase.set("_selected_card_views", [] as Array[CardView])
	if phase is BetaPhase: phase.set("_candidate_views", views)
	phase.refresh_workspace()

func sorted_correctly(fan: CardFan, by_scope: bool) -> bool:
	var previous := -1000000
	for view in fan.ordered_cards():
		var card := view.card_data
		var key: int
		if by_scope: key = -card.scope
		elif fan.beta_sort_only:
			key = [&"qa", &"marketing", &"insider"].find(card.beta_category)
			if key < 0: key = 3 + [&"graphics", &"sound", &"technology", &"design"].find(card.primary_stat)
		else: key = [&"graphics", &"sound", &"technology", &"design"].find(card.primary_stat)
		if key < previous: return false
		previous = key
	return true

func exercise_action(phase: Control, project: ProjectState, run: RunState, kind: String, by_scope: bool) -> void:
	var fan: CardFan = phase.get_node("%HandContainer")
	var workspace: PhaseWorkspace = phase.get_workspace()
	var before_views := fan.ordered_cards()
	var before_ids := ids(before_views)
	var selected: Array = before_views.slice(0, 1 if kind == "redraw" else 4)
	for view in selected: view.input_button.pressed.emit()
	var retained := before_views.filter(func(card): return card not in selected)
	var before := state(phase, project, run)
	var button: Button = phase.get_node("%RedrawButton" if kind == "redraw" else ("%PlayHandButton" if phase is BetaPhase else ("%PlayAlphaHandButton" if phase is AlphaPhase else "%PlayCardButton")))
	button.pressed.emit()
	var motion := workspace.hand_motion
	check(motion.busy, phase.name + " " + kind + " begins real presentation")
	if not motion.busy: return
	var committed := state(phase, project, run)
	check(run.get_completed_run_cycles() == int(before[0]["_cycle"]) + (0 if kind == "redraw" else 1), "Correct transaction cost before animation")
	check(retained.all(func(card): return card in fan.ordered_cards()), "Exact reserved instances survive visual sorting")
	check(fan.ordered_cards().filter(func(card): return card not in before_views).size() == selected.size(), "Only selected slots receive new instances")
	button.pressed.emit()
	workspace.organize_button.pressed.emit()
	check(workspace.organize_button.disabled and state(phase, project, run) == committed, "Repeated action/sort callbacks during presentation are passive")
	await motion.finished
	var events: Array = motion.trace.map(func(event): return event.event)
	check(events.count("deal") == selected.size() and events.count("return_from_bottom") == retained.size(), "Reserved bottom fan returns and each replacement deals from above")
	check(events.rfind("deal") < events.find("fan_restored") and events.find("fan_restored") < events.find("sort_started") and events[-1] == "sorted", "All entrance animations finish before the active sort starts")
	check(sorted_correctly(fan, by_scope) and state(phase, project, run) == committed, "Automatic sorting preserves committed cash, clocks, redraws, RNG and cards")
	check(fan.get_children().map(func(card): return card.card_data) == phase.get("_candidate_cards"), "Visual sort never remaps authoritative candidate slots")
	traces.append({"phase": phase.name, "action": kind, "scope_sort": by_scope, "before": before_ids, "after": ids(fan.ordered_cards()), "events": motion.trace.duplicate(true)})
	await shot(phase.name + "-" + kind + ("-scope" if by_scope else "-category"))

func production(title: String) -> void:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	if title != "design": project.finalize_design_bugs(false, 20, [], [])
	if title == "beta": project.finalize_alpha(0, [], [])
	var run := RunState.new()
	run.initialize_cash(50000)
	var phase: Control = load("res://scenes/phases/%s_phase.tscn" % title).instantiate()
	root.add_child(phase)
	if title == "beta": phase.setup(project, run, snapshots)
	else: phase.setup(project, run)
	phase.get("_deal_rng").seed = 261006
	phase.get_workspace().overlay.cancel()
	check(phase.call("begin_" + title), title + " native phase start")
	var names: Array[StringName] = [&"sound_pass", &"design_pass", &"text", &"technology_pass", &"graphics_pass", &"sound_pass", &"scrolling"]
	if title == "alpha": names = [&"sound_pass", &"design_pass", &"maps", &"technology_pass", &"graphics_pass", &"sound_pass", &"music"]
	if title == "beta": names = [&"sign_flippers", &"study_competition", &"debug", &"sign_flippers", &"search_for_bugs", &"posters", &"predict_market_trends"]
	install(phase, names)
	await settle()
	var fan: CardFan = phase.get_node("%HandContainer")
	var button: Button = phase.get_workspace().organize_button
	var before := state(phase, project, run)
	var old_visual := fan.ordered_cards()
	button.pressed.emit()
	await settle()
	check(sorted_correctly(fan, false) and old_visual != fan.ordered_cards(), title + " sort visibly groups its own categories")
	check(state(phase, project, run) == before, "Manual sort changes no authoritative state")
	if title == "beta":
		button.pressed.emit()
		check(button.text == "Sort" and sorted_correctly(fan, false), "Beta repeats type sort without a Scope toggle")
	await exercise_action(phase, project, run, "redraw", false)
	if title != "beta":
		button.pressed.emit()
		await settle()
		check(button.text == "Sort by Category" and sorted_correctly(fan, true), "Production still toggles to descending Scope")
		await exercise_action(phase, project, run, "redraw", true)
	await exercise_action(phase, project, run, "play", title != "beta")
	# Resize/skip cancellation restores the chosen grouping without replaying work.
	fan.ordered_cards()[0].input_button.pressed.emit()
	phase.get_node("%RedrawButton").pressed.emit()
	var committed := state(phase, project, run)
	phase.get_workspace().hand_motion.cancel()
	check(sorted_correctly(fan, title != "beta") and state(phase, project, run) == committed, "Cancelled presentation preserves current sort and committed transaction")
	if title == "beta":
		install(phase, [&"design_pass", &"sign_flippers", &"graphics_pass", &"debug", &"study_competition", &"sign_flippers", &"search_for_bugs"])
		button.pressed.emit()
		check(sorted_correctly(fan, false) and fan.ordered_cards().size() == 7 and ids(fan.ordered_cards()).slice(5) == ["graphics_pass", "design_pass"], "Corrective Passes follow QA/Marketing/Insider without disappearing")
	phase.queue_free()
	await process_frame

func summary() -> void:
	var run := RunState.new()
	run.initialize_cash_cents(200001)
	var first := _released_project(7.0, 751)
	run.register_release(first)
	var second := _released_project(6.0, 301)
	run.register_release(second)
	run.complete_productive_action()
	run.complete_productive_action()
	var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	root.add_child(studio)
	studio.setup(second, run, snapshots)
	studio.open_summary()
	studio.get_node("%GameList").select(0)
	studio.get_node("%GameList").item_selected.emit(0)
	var selected: StringName = studio.get("_selected_release_id")
	check(selected == first.get_release_id(), "Summary selects the actual older release ID")
	var campaign: Button = studio.get_node("%CampaignButton")
	var before := _snapshot(run, selected)
	for dimensions in [Vector2i(1152, 648), Vector2i(1280, 720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		var header: Control = studio.get_node("SummaryPanel/Margin/Layout/Header")
		var buttons: Array[Control] = [studio.get_node("%DetailedReviewButton"), studio.get_node("%MonthlySalesButton"), campaign, studio.get_node("%CloseSummaryButton")]
		check(buttons.all(func(button): return button.get_parent() == header and header.get_global_rect().encloses(button.get_global_rect()) and studio.get_global_rect().encloses(button.get_global_rect())), "All four summary actions fit the top bar at %d" % dimensions.x)
		studio.get_node("SummaryPanel/Margin/Layout/Scroll").scroll_vertical = 900
		await settle()
		check(campaign.is_visible_in_tree() and not campaign.disabled and campaign.get_global_rect().position.y == buttons[0].get_global_rect().position.y, "Campaign stays beside other actions while statistics scroll")
		await shot("summary-header-%d" % dimensions.x)
	check(_snapshot(run, selected) == before, "Resizing, selecting and scrolling stay passive")
	campaign.pressed.emit()
	check(run.get_completed_run_cycles() == 3 and run.get_cash_cents() == int(before[0]) - 10000 and run.get_released_game_sales(selected).campaign_count == 1 and run.get_released_game_sales(second.get_release_id()).campaign_count == 0, "Moved button runs existing $100/one-cycle campaign only on selected title")
	var committed := _snapshot(run, selected)
	campaign.pressed.emit()
	check(campaign.disabled and _snapshot(run, selected) == committed, "Campaign repeat callback still rejects atomically")
	studio.queue_free()
	await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	snapshots.load_ledgers()
	root.size = Vector2i(1152, 648)
	root.content_scale_size = root.size
	for title in ["design", "alpha", "beta"]: await production(title)
	await summary()
	FileAccess.open(OUT + "/sort-traces.json", FileAccess.WRITE).store_string(JSON.stringify(traces, "\t"))
	print("Pool organization / campaign header: %d failures" % failures)
	quit(failures)
