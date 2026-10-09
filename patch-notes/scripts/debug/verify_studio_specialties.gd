extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func snapshot(run: RunState) -> Array:
	return [run.get_studio_name(), run.get_studio_specialty(), run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids(), run.needs_starter_selection()]

func _run() -> void:
	var fixtures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/debug/fixtures/studio_specialties_v1.json"))
	for genre: String in fixtures:
		var run := RunState.new()
		run.initialize_cash_cents(0)
		var before := snapshot(run)
		check(not run.set_studio_name("Missing choice") and not run.set_studio_name("Unknown", &"unknown") and not run.set_studio_name(" ", StringName(genre)) and snapshot(run) == before, "Incomplete creation rejects atomically: " + genre)
		var preview := StudioSpecialties.preview(StringName(genre))
		var ids: Array = preview.ids.map(func(id: StringName): return str(id))
		ids.sort()
		check(ids == fixtures[genre].ids and preview.count == fixtures[genre].count and preview.scope == fixtures[genre].scope, "Exact deterministic roster / count / Scope: " + genre)
		check(snapshot(run) == before, "Preview is passive: " + genre)
		check(run.set_studio_name("  Specialty Studio  ", StringName(genre)), "Valid creation: " + genre)
		check(run.get_owned_feature_ids() == preview.ids and run.get_cash_cents() == 550000 and run.get_completed_run_cycles() == 0 and run.get_available_redraws() == 4 and run.get_studio_specialty() == StringName(genre), "Exact free roster and existing funding: " + genre)
		before = snapshot(run)
		check(not run.set_studio_name("Changed", &"racing") and snapshot(run) == before, "Specialty and grant cannot repeat or switch: " + genre)
		for id: StringName in run.get_owned_feature_ids():
			check(run.get_feature_familiarity(id) == 0 and StudioSpecialties.PRIMITIVE_IDS.has(str(id)), "Only Primitive ownership, no familiarity: " + str(id))
		check(not run.owns_feature(&"colored_text") and run.get_feature_store_offer(&"colored_text").unlocked and not ResearchTestActions.acquire(run,&"colored_text"), "Owned parent unlocks branch without free descendant or early branch purchase")
		for chosen: StringName in [StringName(genre), &"puzzle" if genre != "puzzle" else &"action"]:
			var project := PrimitivePredevelopment.prepare_project("Independent Genre", chosen, &"fantasy", run)
			check(project.get_genre_id() == chosen and project.get_feature_supply_ids() == run.get_owned_feature_ids() and project.get_current_scope() == 0 and run.get_studio_specialty() == StringName(genre), "Matching / nonmatching project keeps independent Genre and unplayed Scope")
		var poor_id: StringName = &""
		for entry: Dictionary in FeatureStoreCatalog.starting_features():
			if not run.owns_feature(StringName(entry.id)): poor_id = StringName(entry.id); break
		var price: int = run.get_primitive_reserve_offer(poor_id).price_cents
		run.spend_cash_cents(run.get_cash_cents() - price + 1)
		before = snapshot(run)
		check(not run.purchase_starter_feature(poor_id) and snapshot(run) == before, "One-cent-short optional purchase rejects atomically")
		var rebuilt: Control = load("res://scenes/gameplay.tscn").instantiate()
		rebuilt.run_state = run
		root.add_child(rebuilt)
		await process_frame
		check(rebuilt.get("_active_phase") is StudioPhase and snapshot(run) == before, "Studio reconstruction retains authoritative identity, owned IDs and cash")
		rebuilt.queue_free()
		await process_frame
	await _verify_ui()
	print("Studio specialties verification: %d failures" % failures)
	quit(failures)

func _verify_ui() -> void:
	root.size = Vector2i(1152, 648)
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var run: RunState = game.run_state
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	var setup := menu.get_node("CenterContainer/MenuLayout/StudioSetup")
	var name_input := setup.get_node("StudioName") as LineEdit
	var choice := setup.get_node("FolderContent/genre/Genre/StudioSpecialty") as OptionButton
	name_input.text = "Genre Studio"
	var before := snapshot(run)
	setup.get_node("EnterStudio").pressed.emit()
	check(snapshot(run) == before and not setup.get_node("ErrorLabel").text.is_empty(), "Menu requires explicit specialty")
	for index in range(1, 9):
		choice.select(index)
		choice.item_selected.emit(index)
		var preview := StudioSpecialties.preview(choice.get_item_metadata(index))
		check(menu.get("_emphasis").text.contains(str(preview.scope) + " printed Scope") and menu.get("_preview").text.contains(", ".join(preview.names)), "Menu previews exact full roster and emphasis")
	setup.get_node("Back").pressed.emit()
	check(snapshot(run) == before and choice.selected == 0, "Cancel clears uncommitted choice without granting")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	name_input.text = "Genre Studio"
	choice.select(1)
	choice.item_selected.emit(1)
	await process_frame
	await process_frame
	var enter := setup.get_node("EnterStudio") as Button
	check(enter.get_global_rect().end.y < 602 and setup.get_global_rect().position.y >= 0 and setup.get_global_rect().end.x <= 1152, "Roster preview and confirmation fit 1152x648 above HUD")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/task25-v1/studio-specialty-1152.png")
	enter.pressed.emit()
	menu.call("_open_folder", &"traits")
	menu.call("_show_review")
	menu.call("_confirm_studio")
	check(run.get_studio_specialty() == &"action" and run.get_owned_feature_ids().size() == 18, "Menu commits exactly one specialty")
	before = snapshot(run)
	enter.pressed.emit()
	check(snapshot(run) == before, "Stale confirmation callback does not grant again")
	var studio: StudioPhase = game.get("_active_phase")
	check(not game.call("_begin_next_project", studio, "", &"puzzle", &"fantasy") and snapshot(run) == before and run.needs_starter_selection(), "Failed first start preserves optional zero-cycle purchase window")
	check(game.call("_begin_next_project", studio, "Puzzle Game", &"puzzle", &"fantasy") and game.project_state.get_genre_id() == &"puzzle" and run.get_studio_specialty() == &"action", "Successful nonmatching first game commits independent Genre")
	check(not run.needs_starter_selection() and run.get_completed_run_cycles() == 1 and run.get_cash_cents() == 570000, "First-project boundary closes initial window with usual cost")
	var offer := run.get_primitive_reserve_offer(&"simple_story")
	check(not offer.initial and ResearchTestActions.acquire(run,&"simple_story") and run.get_cash_cents() == 490000 and run.get_completed_run_cycles() == 2, "Unowned Primitive costs one cycle and the boundary pays rent")
	check(not game.project_state.get_feature_supply_ids().has(&"simple_story") and PrimitivePredevelopment.prepare_project("Next", &"racing", &"fantasy", run).get_feature_supply_ids().has(&"simple_story"), "New ownership feeds next supply without changing current frozen supply")
	game.queue_free()
	await process_frame
