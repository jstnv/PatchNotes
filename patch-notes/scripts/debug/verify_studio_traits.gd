extends SceneTree

var failures := 0
const OUT := "res://design-logs/task31-v1/rendered"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func state(run: RunState) -> Array:
	return [run.get_studio_creation_snapshot(), run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids(), run.get_available_redraws(), run.get_studio_finance_snapshot()]

func _run() -> void:
	check(StudioTraits.cash_for_points(-1) == -1 and StudioTraits.cash_for_points(0) == 0 and StudioTraits.cash_for_points(4) == 20000 and StudioTraits.cash_for_points(6) == 30000 and StudioTraits.cash_for_points(RunState.MAX_SIGNED_INT) == 30000, "Point cash rejects negative, handles zero, exact cents and cap without overflow")
	for background: StringName in StudioTraits.BACKGROUNDS:
		for genre: Dictionary in PrimitivePredevelopment.catalog().genres:
			var run := RunState.new()
			run.initialize_cash_cents(0)
			var before := state(run)
			for invalid: Array in [[&"resourceful", &"resourceful"], [&"resourceful", &"lean_production", &"studio_buzz"], [&"student_loan", &"unknown_name"], [&"missing"], [1]]:
				check(not run.create_studio("Test", StringName(genre.id), background, invalid) and state(run) == before, "Invalid selection rejects atomically: " + str(invalid))
			check(not run.create_studio("Test", StringName(genre.id), &"", []) and not run.create_studio("Test", &"missing", background, []) and state(run) == before, "Both manual background and separate Genre required")
			check(run.create_studio("Trait Studio", StringName(genre.id), background, [&"resourceful", &"studio_buzz", &"student_loan"]), "Valid two-positive / one-negative preview: " + genre.id + "/" + String(background))
			var traits := run.get_studio_traits()
			check(traits.spent_points == 0 and traits.refunded_points == 0 and traits.remaining_points == 4 and run.get_cash_cents() == 570000 and run.get_owned_feature_ids() == StudioSpecialties.preview(StringName(genre.id)).ids, "Preview prices inactive, cash conversion exact, Genre roster independent")
			var finance := run.get_studio_finance_snapshot()
			check(finance.transactions.size() == 2 and finance.transactions[1].source_id == &"studio_trait_unspent_points_v1" and finance.transactions[1].amount_cents == 20000 and finance.credit.score == 600 and run.get_studio_finance_report().rows[0].net_profit_cents == 0, "Single startup financing receipt; no fake operating profit or credit")
			before = state(run)
			check(not run.create_studio("Again", &"puzzle", background, []) and not run.set_studio_name("Legacy", &"action") and state(run) == before, "Duplicate/legacy confirmation cannot repeat conversion")
			traits.secondary_ids.clear()
			check(run.get_studio_traits().secondary_ids.size() == 3, "Defensive selection snapshot")
			var checkpoint := run.get_studio_creation_snapshot()
			check(bytes_to_var(var_to_bytes(checkpoint)) == checkpoint, "Stable typed checkpoint roundtrip (not durable save/load)")
			check(run.advance_calendar_cycle() and run.get_cash_cents() == 570000 and run.advance_calendar_cycle() and run.get_cash_cents() == 520000, "First due remains cycle2, exactly $500 rent, no preview Student Loan due")
			check(run.get_studio_finance_snapshot().obligations.size() == 1 and run.get_studio_finance_report().credit.score == 600, "Only real rent producer and paid loss-month credit unchanged")
	for resolution: Vector2i in [Vector2i(1152,648), Vector2i(1280,720)]:
		await verify_ui(resolution)
	var fresh := RunState.new()
	fresh.initialize_cash_cents(0)
	check(fresh.get_studio_traits().is_empty() and fresh.get_studio_specialty().is_empty() and fresh.get_cash_cents() == 0, "Fresh run resets all choices, no inherited automatic background")
	print("Studio traits verification: %d failures" % failures)
	quit(failures)

func capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute(OUT)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + label + "-%dx%d.png" % [root.size.x, root.size.y])

func settle() -> void:
	for i in 5: await process_frame
	if "--capture" in OS.get_cmdline_user_args(): await create_timer(0.4).timeout

func verify_ui(resolution: Vector2i) -> void:
	root.size = resolution
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await settle()
	var run: RunState = game.run_state
	var before := state(run)
	var menu: MainMenu = game.get("_active_phase")
	var layout := menu.get_node("CenterContainer/MenuLayout")
	layout.get_node("StartGame").pressed.emit()
	menu.get("_name_input").text = "Bonita Studio"
	menu.get("_specialty").select(1)
	menu.call("_submit")
	check(menu.get("_background").selected == 0 and not menu.call("_selection").valid and state(run) == before, "Traits step has no default and browsing is free")
	menu.get("_background").select(2)
	menu.get("_trait_checks")[&"resourceful"].button_pressed = true
	menu.get("_trait_checks")[&"studio_buzz"].button_pressed = true
	menu.get("_trait_checks")[&"student_loan"].button_pressed = true
	menu.get("_trait_checks")[&"lean_production"].button_pressed = true
	check(layout.get_node("StudioTraits/ReviewChoices").disabled and menu.get("_trait_error").text.contains("at most"), "Over-cap UI explains and blocks invalid build")
	menu.get("_trait_checks")[&"lean_production"].button_pressed = false
	menu.call("_refresh_traits")
	await settle()
	for path in ["StudioTraits/ReviewChoices", "StudioTraits/Back", "StudioTraits/Points"]:
		var rect: Rect2 = layout.get_node(path).get_global_rect()
		check(rect.position.y >= 0 and rect.end.y <= resolution.y - 45 and rect.end.x <= resolution.x, "Trait footer stays above HUD: " + path)
	await capture("traits")
	menu.call("_show_review")
	await settle()
	check(menu.get("_review").text.contains("Cult Following") and menu.get("_review").text.contains("Action") and menu.get("_review").text.contains("$5,700"), "Confirmation identifies background, Genre and actual cash")
	await capture("confirmation")
	layout.get_node("CreationReview/Back").pressed.emit()
	layout.get_node("StudioTraits/Back").pressed.emit()
	layout.get_node("StudioSetup/Back").pressed.emit()
	check(state(run) == before and menu.get("_background").selected == 0 and menu.call("_secondary_ids").is_empty(), "Cancel resets uncommitted choices and pays nothing")
	layout.get_node("StartGame").pressed.emit()
	menu.get("_specialty").select(1)
	menu.call("_submit")
	menu.get("_background").select(1)
	menu.call("_show_review")
	menu.call("_confirm_studio")
	menu.call("_confirm_studio")
	await settle()
	var studio: StudioPhase = game.get("_active_phase")
	check(run.get_cash_cents() == 570000 and studio.get_node("Dashboard/Layout/StudioIdentity").text.contains("Family Funding") and studio.get_node("Dashboard/Layout/StudioIdentity").text.contains("Action"), "Studio displays committed identity; duplicate callback paid once")
	var identity: Label = studio.get_node("Dashboard/Layout/StudioIdentity")
	check(identity.get_global_rect().position.y >= 0 and identity.get_global_rect().end.y < resolution.y - 45, "Studio identity rendered inside viewport")
	await capture("studio")
	before = state(run)
	var rebuilt: Control = load("res://scenes/gameplay.tscn").instantiate()
	rebuilt.run_state = run
	root.add_child(rebuilt)
	await settle()
	check(rebuilt.get("_active_phase") is StudioPhase and state(run) == before, "Reconstructed game retains choices and never repeats receipt")
	rebuilt.queue_free()
	game.queue_free()
	await process_frame
