## Focused proprietary Feature roots and playable Scope limit regression.
extends SceneTree

const DESIGN_COMMAND := preload("res://scripts/simulation/design_hand_command.gd")
const ALPHA_COMMAND := preload("res://scripts/simulation/alpha_hand_command.gd")
const BEGIN_PROJECT := preload("res://scripts/simulation/begin_project.gd")
const DESIGN_SCENE := preload("res://scenes/phases/design_phase.tscn")
const ALPHA_SCENE := preload("res://scenes/phases/alpha_phase.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")

var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	_verify.call_deferred()

func _snapshot(command: Object, project: ProjectState, run: RunState, exhausted: Dictionary) -> Dictionary:
	return {
		"scope": project.get_current_scope(),
		"scores": [project.get_core_score(ProjectState.CoreScore.GRAPHICS), project.get_core_score(ProjectState.CoreScore.SOUND), project.get_core_score(ProjectState.CoreScore.TECHNOLOGY), project.get_core_score(ProjectState.CoreScore.DESIGN)],
		"project_cycle": project.get_current_cycle(),
		"run_cycle": run.get_completed_run_cycles(),
		"cash": run.get_cash_cents(),
		"rng": command._deal_rng.state,
		"exhausted": exhausted.duplicate(true),
		"candidates": command.candidate_ids.duplicate(),
		"revision": command.revision,
		"budget": [command._budget_printed, command._budget_bonus_centi, command._budget_spent],
		"skill_remainders": project._skill_pass_remainders.duplicate(true),
	}

func _verify() -> void:
	var database := root.get_node("CardDatabase")
	var run := RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Scope roots", &"action", []), "Studio fixture creates")
	var created: Dictionary = run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Scope roots engine"))
	check(created.get("ok", false), "Proprietary engine creates")
	if not created.get("ok", false):
		quit(1)
		return
	var engine_id: StringName = created.engine_id
	check(run.select_engine(engine_id) and run.get_selected_engine_capacity() == 20, "Selected proprietary engine begins at 20 Scope")
	check(run.finalize_starter_selection(), "First-game starter selection finalizes")
	for root_id in [&"text", &"4_color_palette", &"8_bit_sound"]:
		var quote: Dictionary = run.get_feature_research_quote(root_id, engine_id)
		check(quote.get("can_admit", false) and run.admit_feature_research(quote), "Root enters the normal paid implementation queue: %s" % root_id)
	check(run.get_engine_feature_state().engines[engine_id].implemented.is_empty(), "Queued roots are not free implementations")
	for root_id in [&"text", &"4_color_palette", &"8_bit_sound"]:
		var quote: Dictionary = run.get_feature_research_quote(root_id, engine_id)
		check(quote.get("can_research", false) and run.research_feature(quote), "Queued root implementation completes: %s" % root_id)
	check(run.get_feature_research_quote(&"sprites", engine_id).get("unlocked", false), "Descendant unlocks after parent implementation")
	var adapter := StudioCheckpoint.new()
	var payload: Dictionary = adapter.capture(run)
	var restored: RunState = adapter.hydrate(payload) if not payload.is_empty() else null
	check(restored != null and restored.get_selected_engine_id() == engine_id and restored.get_selected_engine_capacity() == 20, "Selected engine and capacity persist through Studio checkpoint")
	if restored == null:
		quit(1)
		return
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var begun: Dictionary = BEGIN_PROJECT.execute(restored, snapshots, "20-Scope game", &"action", &"fantasy")
	check(begun.get("ok", false), "Selected engine begins a project")
	if not begun.get("ok", false):
		quit(1)
		return
	var project: ProjectState = begun.project
	check(project.get_engine_id() == engine_id and project.get_engine_max_scope() == 20 and project.get_required_scope() == 30, "Project freezes selected 20-Scope engine and unchanged 30-Scope requirement")
	check(project.get_feature_supply_ids().has(&"text") and project.get_feature_supply_ids().has(&"4_color_palette"), "Implemented roots enter the selected project's supply")
	check(project.add_scope(19), "Project seeds 19 Scope")

	var text_card: CardData = database.get_card(&"text")
	var palette_card: CardData = database.get_card(&"4_color_palette")
	var sound_card: CardData = database.get_card(&"8_bit_sound")
	var design := DESIGN_COMMAND.new()
	design._project_state = project
	design._run_state = restored
	design._deal_rng = restored.random_streams.stream(&"design_deal")
	design.active = true
	design.priorities = PriorityAllocation.new().get_priority_distribution()
	design._candidate_cards.assign([text_card, palette_card, sound_card, database.get_card(&"graphics_pass"), database.get_card(&"sound_pass"), database.get_card(&"technology_pass"), database.get_card(&"design_pass")])
	design.candidate_ids.assign([0, 1, 2, 3, 4, 5, 6])
	design.next_candidate_id = 7
	design._pass_definitions.assign(database.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
	check(design.calculate_base([text_card, palette_card] as Array[CardData]).get("valid", true) == false, "Design preflight rejects a multi-card hand above 20 Scope")
	var before := _snapshot(design, project, restored, design._exhausted_card_ids)
	var rejected: Dictionary = design.execute(design.command([0, 1] as Array[int]))
	check(not rejected.get("ok", false) and _snapshot(design, project, restored, design._exhausted_card_ids) == before, "Rejected Design hand changes no Scope, Core, cycle, cash, RNG, budget, or Feature exhaustion")
	check(design.calculate_base([text_card] as Array[CardData]).get("valid", false), "Design preflight accepts exact-cap Feature")
	var accepted: Dictionary = design.execute(design.command([0] as Array[int]))
	check(accepted.get("ok", false) and project.get_current_scope() == 20 and design._exhausted_card_ids.has(&"text"), "Feature activation succeeds at exactly 20 Scope")
	check(not project.add_scope(1) and project.get_current_scope() == 20, "Project write guard rejects Scope above capacity")
	check(project.finalize_design_bugs(false, 0, [&"text"], [&"4_color_palette", &"8_bit_sound"]), "A 20-Scope game can finish Design below the 30-Scope requirement")
	check(project.finalize_alpha(0, [], []) and project.finalize_beta(), "A 20-Scope game can finish development")
	var review := PrimitiveReviewCalculator.calculate(project, 50)
	check(review != null and is_equal_approx(review.get_scope_completion(), 20.0 / 30.0), "Existing Review applies the 20-of-30 Scope completion factor")

	var alpha_project := ProjectState.new(30)
	check(alpha_project.set_engine_id(engine_id, 20) and alpha_project.add_scope(19), "Alpha fixture freezes selected 20-Scope engine")
	var dialogue: CardData = database.get_card(&"dialogue")
	var enemies: CardData = database.get_card(&"enemies")
	var alpha := ALPHA_COMMAND.new()
	alpha._project_state = alpha_project
	alpha._run_state = restored
	alpha._deal_rng = restored.random_streams.stream(&"alpha_deal")
	alpha.active = true
	alpha.priorities = PriorityAllocation.new().get_priority_distribution()
	alpha._candidate_cards.assign([dialogue, enemies])
	alpha.candidate_ids.assign([0, 1])
	alpha.next_candidate_id = 2
	alpha._available_features.assign([dialogue, enemies])
	alpha._pass_definitions.assign(database.get_cards_by_phase_and_types(CardData.PHASE_ALPHA, [&"pass"] as Array[StringName]))
	check(not alpha.calculate_base([dialogue, enemies] as Array[CardData]).get("valid", true), "Alpha preflight rejects an aggregate hand above 20 Scope")
	var alpha_before := _snapshot(alpha, alpha_project, restored, alpha._exhausted_feature_ids)
	var alpha_rejected: Dictionary = alpha.execute(alpha.command([0, 1] as Array[int]))
	check(not alpha_rejected.get("ok", false) and _snapshot(alpha, alpha_project, restored, alpha._exhausted_feature_ids) == alpha_before, "Rejected Alpha hand changes no production or Feature exhaustion")

	var ui_project := ProjectState.new(30)
	check(ui_project.set_engine_id(engine_id, 20) and ui_project.add_scope(19), "Card-selection fixture retains 19 of 20 Scope")
	var design_ui := DESIGN_SCENE.instantiate()
	design_ui.setup(ui_project, restored)
	root.add_child(design_ui)
	await process_frame
	design_ui.set("_phase_state", 1)
	design_ui.call("_clear_candidate_pool")
	design_ui.set("_candidate_cards", [text_card, palette_card] as Array[CardData])
	var design_text := CARD_VIEW_SCENE.instantiate() as CardView
	var design_palette := CARD_VIEW_SCENE.instantiate() as CardView
	design_text.set_card(text_card)
	design_palette.set_card(palette_card)
	design_ui.get_node("%HandContainer").add_child(design_text)
	design_ui.get_node("%HandContainer").add_child(design_palette)
	design_ui.set("_selected_card_views", [design_text, design_palette] as Array[CardView])
	check(not design_ui.call("_can_play_selected_hand"), "Design card selection blocks an over-cap multi-card hand")
	design_ui.set("_selected_card_views", [design_text] as Array[CardView])
	check(design_ui.call("_can_play_selected_hand"), "Design card selection allows exact 20-Scope hand")
	design_ui.queue_free()

	var alpha_ui := ALPHA_SCENE.instantiate()
	alpha_ui.setup(ui_project, restored)
	root.add_child(alpha_ui)
	await process_frame
	alpha_ui.set("_phase_state", 1)
	alpha_ui.call("_clear_candidate_pool")
	alpha_ui.set("_candidate_cards", [dialogue, enemies] as Array[CardData])
	var alpha_dialogue := CARD_VIEW_SCENE.instantiate() as CardView
	var alpha_enemies := CARD_VIEW_SCENE.instantiate() as CardView
	alpha_dialogue.set_card(dialogue)
	alpha_enemies.set_card(enemies)
	alpha_ui.get_node("%HandContainer").add_child(alpha_dialogue)
	alpha_ui.get_node("%HandContainer").add_child(alpha_enemies)
	alpha_ui.set("_selected_card_views", [alpha_dialogue, alpha_enemies] as Array[CardView])
	check(not alpha_ui.call("_can_play_selected_instances"), "Alpha card selection blocks an over-cap multi-card hand")
	alpha_ui.set("_selected_card_views", [alpha_dialogue] as Array[CardView])
	check(alpha_ui.call("_can_play_selected_instances"), "Alpha card selection allows exact 20-Scope hand")
	alpha_ui.queue_free()
	print("Proprietary Scope and roots: %d failures" % failures)
	quit(1 if failures else 0)
