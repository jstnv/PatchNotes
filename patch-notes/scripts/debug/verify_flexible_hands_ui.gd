extends SceneTree
const CardScene = preload("res://scenes/cards/card_view.tscn")
const SCENES = [preload("res://scenes/phases/design_phase.tscn"), preload("res://scenes/phases/alpha_phase.tscn"), preload("res://scenes/phases/beta_phase.tscn")]
var checks := 0
var failures := 0
var db: Node
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func _initialize() -> void:
	await process_frame
	db = root.get_node("CardDatabase")
	for size in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = size
		for index in 3:
			var project := ProjectState.new(30)
			if index > 0: project.finalize_design_bugs(false, 5, [], [])
			if index == 2:
				project.initialize_snapshots(&"fast_follower", &"market_surge")
				project.finalize_alpha(0, [], [])
			var run := RunState.new()
			run.initialize_cash(5000)
			var phase = SCENES[index].instantiate()
			root.add_child(phase)
			phase.size = root.get_visible_rect().size
			await process_frame
			if index == 2:
				var snapshots := PrimitiveSnapshotDatabase.new()
				snapshots.load_ledgers()
				check(phase.setup(project,run,snapshots), "Beta UI setup")
			else: phase.setup(project, run)
			phase.set("_phase_state", 1)
			var fan = phase.get_node("%HandContainer")
			var cards: Array[CardData] = []
			var views: Array[CardView] = []
			for n in 7:
				var card: CardData = db.get_card(&"search_for_bugs" if index == 2 else &"graphics_pass")
				var view: CardView = CardScene.instantiate()
				view.set_card(card)
				view.card_pressed.connect(Callable(phase, "_on_card_pressed"))
				fan.add_child(view)
				cards.append(card)
				views.append(view)
			phase.set("_candidate_cards",cards)
			if index < 2: phase.set("_pass_definitions", db.get_cards_by_phase_and_types(CardData.PHASE_DESIGN,[&"pass"] as Array[StringName]))
			else: phase.set("_candidate_views",views)
			await create_timer(0.8).timeout
			phase.call("_on_card_pressed", views[0])
			var can_play: StringName = &"_can_play_selected_hand" if index == 0 else (&"_can_play_selected_instances" if index == 1 else &"_can_attempt_play")
			check(phase.call(can_play), "One selected live card enables play in phase%d" % index)
			if index > 0:
				if index == 2:
					phase.force_card_view_preparation_failure_for_verification()
					check(not phase.host_playtest() and run.get_completed_run_cycles() == 0 and phase.get("_candidate_cards").size() == 7, "Failed Playtest view preparation is atomic")
					phase.set("_force_card_view_failure",false)
				check(phase.host_playtest(), "Live Playtest commits")
				check(fan.card_views().size() == 9 and phase.get("_candidate_cards").size() == 9, "All nine cards are present in the live fan")
				check(phase.get_selected_candidate_views() == [views[0]], "Playtest retains selected view identity")
				check(phase.call(can_play), "Overflow still allows a one-card hand")
				if index == 2:
					check(phase.play_selected_hand(), "Beta live one-card commit")
				else: phase.call("_on_play_alpha_hand_pressed")
				check(fan.card_views().size() == 8 and phase.get("_candidate_cards").size() == 8, "Live overflow retains eight and adds no random replacements")
				check(project.get_current_cycle() == 2 and run.get_completed_run_cycles() == 2, "Playtest and partial hand each cost one cycle")
				if not DisplayServer.get_name() == "headless":
					await process_frame
					await create_timer(0.8).timeout
					await RenderingServer.frame_post_draw
					var out := OS.get_environment("PN_AWARDS_REPORT_OUTPUT").get_base_dir()
					root.get_texture().get_image().save_png(out.path_join("phase%d-%d.png" % [index,size.x]))
			else:
				phase.call("_on_play_card_pressed")
				check(project.get_current_cycle() == 1 and project.get_core_score(0) == 2, "Design one-card live play applies once without synergy")
			phase.queue_free()
			await process_frame
	print("FLEXIBLE_HANDS_UI checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
