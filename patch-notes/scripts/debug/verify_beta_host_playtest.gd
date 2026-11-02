## Separately invoked locked Beta Host Playtest verification.
extends SceneTree

const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")

var _database: Node
var _snapshots: PrimitiveSnapshotDatabase
var _failures := 0
var _checks := 0


func _initialize() -> void:
	await process_frame
	_database = root.get_node("CardDatabase")
	_snapshots = PrimitiveSnapshotDatabase.new()
	_snapshots.load_ledgers()
	_verify_genre_percentage_selection()
	await _verify_planning_and_affordability()
	await _verify_selection_preservation()
	await _verify_pending_and_injection()
	await _verify_corrective_pass_resolution()
	await _verify_single_corrective_pass_resolution()
	if _failures == 0:
		print("Beta Host Playtest verification passed.")
	_finish()

func _finish() -> void:
	print("BETA_PLAYTEST checks=%d failures=%d"%[_checks,_failures])
	quit(_failures)


func _make_state() -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(&"fast_follower", &"market_surge")
	state.finalize_design_bugs(false, 5, [], [])
	state.finalize_alpha(0, [], [])
	return state


func _make_beta(cash: int, begin: bool = true) -> Dictionary:
	var state := _make_state()
	var run := RunState.new()
	run.initialize_cash(cash)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	beta.setup(state, run, _snapshots)
	if begin:
		beta.begin_beta([0.05, 0.15, 0.40, 0.50, 0.80, 0.85, 0.90], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7])
		_install_pool(beta, [&"search_for_bugs", &"debug", &"sign_flippers", &"posters", &"press_release", &"search_for_bugs", &"debug"])
	return {&"beta": beta, &"state": state, &"run": run}


func _install_pool(beta: BetaPhase, ids: Array[StringName]) -> void:
	for old_view: CardView in beta.get("_candidate_views"):
		beta.get_node("%HandContainer").remove_child(old_view)
		old_view.free()
	var cards: Array[CardData] = []
	var views: Array[CardView] = []
	for id: StringName in ids:
		var card: CardData = _database.call(&"get_card", id)
		var view := CARD_VIEW_SCENE.instantiate() as CardView
		view.set_card(card)
		view.card_pressed.connect(Callable(beta, "_on_card_pressed"))
		beta.get_node("%HandContainer").add_child(view)
		cards.append(card)
		views.append(view)
	beta.set("_candidate_cards", cards)
	beta.set("_candidate_views", views)
	beta.set("_selected_card_views", [] as Array[CardView])
	beta.set("_injected_corrective_views", [] as Array[CardView])


func _select_count(beta: BetaPhase, count: int) -> void:
	for index in range(count):
		beta.call("_on_card_pressed", beta.get("_candidate_views")[index])


func _pool_identity(beta: BetaPhase) -> Array:
	var ids: Array[StringName] = []
	var instances: Array[int] = []
	for card: CardData in beta.get("_candidate_cards"):
		ids.append(card.id)
	for view: CardView in beta.get("_candidate_views"):
		instances.append(view.get_instance_id())
	return [ids, instances]


func _selection_identity(beta: BetaPhase) -> Array[int]:
	var result: Array[int] = []
	for view: CardView in beta.get_selected_candidate_views():
		result.append(view.get_instance_id())
	return result


func _verify_planning_and_affordability() -> void:
	var planning := await _make_beta(1000, false)
	_expect(not planning.beta.host_playtest(), "Planning rejects Beta Host Playtest")
	_expect(planning.run.get_cash() == 1000 and planning.state.get_current_cycle() == 0, "Planning rejection spends no cash and advances no cycle")
	planning.beta.queue_free()
	await process_frame

	var poor := await _make_beta(499)
	var pool_before := _pool_identity(poor.beta)
	_expect(not poor.beta.host_playtest(), "Cash below $500 rejects Host Playtest")
	_expect(poor.run.get_cash() == 499 and poor.state.get_current_cycle() == 0 and poor.beta.get_pending_corrective_pass_ids().is_empty() and _pool_identity(poor.beta) == pool_before, "Unaffordable action is fully atomic")
	poor.beta.queue_free()
	await process_frame


func _verify_selection_preservation() -> void:
	for count in range(5):
		var fixture := await _make_beta(1000)
		_select_count(fixture.beta, count)
		var pool_before := _pool_identity(fixture.beta)
		var selection_before := _selection_identity(fixture.beta)
		var priorities: Dictionary = fixture.beta.get_priority_distribution()
		var bugs := [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_remaining_bugs()]
		_expect(fixture.beta.host_playtest(), "Active Host Playtest accepts %d selected cards" % count)
		var pool_after:=_pool_identity(fixture.beta)
		_expect(pool_after[0].size()==9 and pool_after[0].slice(0,7)==pool_before[0] and pool_after[1].slice(0,7)==pool_before[1] and _selection_identity(fixture.beta)==selection_before,"Immediate Host Playtest preserves all original identities/selection and appends two with %d selected"%count)
		_expect(fixture.beta.get("_injected_corrective_views").size()==2 and fixture.beta.get_pending_corrective_pass_ids().is_empty(),"Immediate Passes are protected instances with no deferred pending IDs")
		_expect(fixture.beta.get_priority_distribution() == priorities and [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_remaining_bugs()] == bugs, "Host Playtest preserves priorities and Bugs with %d selections" % count)
		_expect(fixture.run.get_cash() == 500 and fixture.state.get_current_cycle() == 1, "Host Playtest costs exactly $500 and one cycle with %d selections" % count)
		fixture.beta.queue_free()
		await process_frame


func _seed_sound_technology_tie(state: ProjectState) -> void:
	var profile:=PrimitiveReviewCalculator.get_project_profile(state)
	for category in ProjectState.CoreScore.values():
		state.add_core_score(category,profile.get_standard(category)*(1 if category in [ProjectState.CoreScore.SOUND,ProjectState.CoreScore.TECHNOLOGY] else 2))

func _verify_pending_and_injection() -> void:
	var fixture := await _make_beta(1000)
	_seed_sound_technology_tie(fixture.state)
	_select_count(fixture.beta,4)
	var values_before:=[fixture.state.get_hidden_bugs(),fixture.state.get_known_bugs(),fixture.state.get_marketing_output(),fixture.state.is_competitor_snapshot_revealed(),fixture.state.is_market_forecast_snapshot_revealed(),fixture.state.get_exhausted_beta_card_ids()]
	var rng_before: int=fixture.beta.get("_deal_rng").state
	_expect(fixture.beta.host_playtest(),"Valid current Host Playtest immediately appends two")
	var cards: Array[CardData]=fixture.beta.get("_candidate_cards")
	var injected: Array=fixture.beta.get("_injected_corrective_views").duplicate()
	_expect(cards.size()==9 and cards[7].id==&"sound_pass" and cards[8].id==&"technology_pass","Equal normalized percentages use Sound then Technology enum order")
	_expect(fixture.beta.get_pending_corrective_pass_ids().is_empty() and fixture.beta.get("_deal_rng").state==rng_before,"Immediate append has no pending state and consumes no draw RNG")
	_expect([fixture.state.get_hidden_bugs(),fixture.state.get_known_bugs(),fixture.state.get_marketing_output(),fixture.state.is_competitor_snapshot_revealed(),fixture.state.is_market_forecast_snapshot_revealed(),fixture.state.get_exhausted_beta_card_ids()]==values_before,"Playtest changes no Bugs, Marketing, snapshots, or lifecycle")
	_expect(fixture.beta.get_node("%ActionFeedbackLabel").text.contains("Corrective Passes added to the pool"),"Immediate feedback reports current addition")
	var before_invalid:=[fixture.state.get_current_cycle(),fixture.run.get_cash(),fixture.beta.get_priority_distribution()]
	_expect(not fixture.beta.set_priority_distribution({&"qa":75,&"marketing":25,&"insider":0}) and [fixture.state.get_current_cycle(),fixture.run.get_cash(),fixture.beta.get_priority_distribution()]==before_invalid,"Untrained out-of-range priority edit is atomic")
	_expect(fixture.beta.set_priority_distribution({&"qa":60,&"marketing":40,&"insider":0}),"Current legal untrained priorities commit")
	_expect(fixture.state.get_current_cycle()==2,"Host and legal priority commit each consume one cycle")
	fixture.state.add_core_score(ProjectState.CoreScore.SOUND,100)
	fixture.beta.setup(fixture.state,fixture.run,_snapshots)
	_expect(fixture.beta.get("_injected_corrective_views")==injected and cards[7].id==&"sound_pass" and cards[8].id==&"technology_pass","Score/priority changes and UI rebinding preserve existing corrective identities")
	_expect(fixture.beta.host_playtest(),"A second affordable immediate Playtest is a separate legal purchase")
	cards=fixture.beta.get("_candidate_cards")
	_expect(cards.size()==11 and cards[9].id==&"technology_pass" and cards[10].id==&"graphics_pass" and fixture.run.get_cash()==0 and fixture.state.get_current_cycle()==3,"Second Playtest charges $500/one cycle and uses newly weakest normalized categories")
	var before_poor:=[fixture.state.get_current_cycle(),fixture.run.get_cash(),_pool_identity(fixture.beta),_selection_identity(fixture.beta)]
	_expect(not fixture.beta.host_playtest() and [fixture.state.get_current_cycle(),fixture.run.get_cash(),_pool_identity(fixture.beta),_selection_identity(fixture.beta)]==before_poor,"Further unaffordable callback cannot charge, append or advance")
	_expect(fixture.beta.play_selected_hand(),"Ordinary selected hand consumes four slots without an unnecessary refill")
	_expect(fixture.beta.get("_candidate_cards").size()==7 and fixture.state.get_current_cycle()==4 and fixture.beta.get("_injected_corrective_views").size()==4,"Overflow retains all four unplayed protected instances while production advances once")
	_expect(fixture.beta.get("_candidate_views").has(injected[0]) and fixture.beta.get("_candidate_views").has(injected[1]),"Original appended corrective Passes retain exact views after unrelated production")
	fixture.beta.queue_free()
	await process_frame
	await _verify_historical_pending_builder()

## Persisted historical pending-correction component, not a current Host route.
func _verify_historical_pending_builder() -> void:
	var fixture:=await _make_beta(1000)
	var command: RefCounted=fixture.beta.call("_capture_beta_command")
	command._pending_corrective_pass_ids.assign([&"sound_pass",&"technology_pass"])
	var legacy: Dictionary=command._build_replacement_candidate_definitions(command._beta_definitions,command.get_priority_distribution(),[0.05,0.15] as Array[float],[0.1,0.2] as Array[float],[] as Array[StringName],4)
	_expect(legacy.valid and legacy.cards.size()==4 and legacy.cards[0].id==&"sound_pass" and legacy.cards[1].id==&"technology_pass" and legacy.injected_count==2,"Historical pending builder keeps exact corrective prefix/count")
	for index in [2,3]:_expect(legacy.cards[index].phase==CardData.PHASE_BETA and legacy.cards[index].card_type==&"beta","Historical pending ordinary slots retain weighted Beta definitions")
	_expect(legacy.consumed_pending_ids==[&"sound_pass",&"technology_pass"],"Historical pending builder reports exact consumption IDs")
	command._pending_corrective_pass_ids.assign([&"sound_pass",&"sound_pass"])
	_expect(not command._build_replacement_candidate_definitions(command._beta_definitions,command.get_priority_distribution(),[] as Array[float],[] as Array[float],[] as Array[StringName],4).valid,"Malformed duplicate historical pending IDs reject")
	fixture.beta.set("_pending_corrective_pass_ids",[&"graphics_pass",&"design_pass"] as Array[StringName])
	var pending_before: Array[StringName]=fixture.beta.get_pending_corrective_pass_ids()
	_select_count(fixture.beta,4)
	fixture.beta.force_card_view_preparation_failure_for_verification()
	var state_before:=[fixture.state.get_hidden_bugs(),fixture.state.get_known_bugs(),fixture.state.get_current_cycle(),fixture.run.get_cash(),_pool_identity(fixture.beta),_selection_identity(fixture.beta)]
	_expect(not fixture.beta.play_selected_hand(),"Historical pending view-readiness failure rejects production")
	_expect(fixture.beta.get_pending_corrective_pass_ids()==pending_before and [fixture.state.get_hidden_bugs(),fixture.state.get_known_bugs(),fixture.state.get_current_cycle(),fixture.run.get_cash(),_pool_identity(fixture.beta),_selection_identity(fixture.beta)]==state_before,"Failed historical publication preserves pending/state/pool/selection")
	fixture.beta.queue_free()
	await process_frame

func _verify_corrective_pass_resolution() -> void:
	var fixture := await _make_beta(1500)
	_seed_sound_technology_tie(fixture.state)
	_select_count(fixture.beta, 4)
	fixture.beta.host_playtest()
	fixture.beta.play_selected_hand([] as Array[int], [0.05, 0.15] as Array[float], [0.1, 0.2] as Array[float])
	var views: Array[CardView] = fixture.beta.get("_candidate_views").duplicate()
	for index in [3, 4, 5, 6]:
		fixture.beta.call("_on_card_pressed", views[index])
	_expect(fixture.beta.get_workspace().get("_synergy_help_title") == "Corrective Pass selected", "Beta tooltip explains that corrective Passes do not grant synergy")
	var sound_before: int = fixture.state.get_core_score(ProjectState.CoreScore.SOUND)
	var technology_before: int = fixture.state.get_core_score(ProjectState.CoreScore.TECHNOLOGY)
	_expect(fixture.beta.play_selected_hand(), "Two corrective Passes can resolve with two ordinary Beta cards")
	_expect(fixture.state.get_core_score(ProjectState.CoreScore.SOUND) == sound_before + 2 and fixture.state.get_core_score(ProjectState.CoreScore.TECHNOLOGY) == technology_before + 2, "Each selected corrective Pass adds exactly +2 to its matching Core Score")
	var feedback: String = fixture.beta.get_node("%ActionFeedbackLabel").text
	_expect(feedback.contains("Corrective Pass gains: Sound +2, Technology +2") and not feedback.contains("QA Specialization") and not feedback.contains("Balanced Operations"), "Corrective Pass feedback reports gains and cancels both Beta synergies")
	_expect(not fixture.state.is_beta_card_exhausted(&"sound_pass") and not fixture.state.is_beta_card_exhausted(&"technology_pass"), "Corrective Pass definitions never exhaust")
	for card: CardData in fixture.beta.get("_candidate_cards"):
		_expect(card.card_type == &"beta", "Later ordinary pool contains no expired corrective Pass opportunity")
	_expect(fixture.beta.host_playtest(), "A later Host Playtest may queue another correction after consumption")
	fixture.beta.queue_free()
	await process_frame


func _verify_single_corrective_pass_resolution() -> void:
	var fixture := await _make_beta(1000)
	_select_count(fixture.beta, 4)
	_expect(fixture.beta.host_playtest(), "Host Playtest queues a controlled single-Pass fixture")
	_expect(fixture.beta.play_selected_hand([] as Array[int], [0.05, 0.15] as Array[float], [0.1, 0.2] as Array[float]), "Controlled hand publishes corrective Pass opportunities")
	var views: Array[CardView] = fixture.beta.get("_candidate_views").duplicate()
	fixture.beta.call("_on_card_pressed", views[3])
	for index in range(3):
		fixture.beta.call("_on_card_pressed", views[index])
	var graphics_before: int = fixture.state.get_core_score(ProjectState.CoreScore.GRAPHICS)
	var sound_before: int = fixture.state.get_core_score(ProjectState.CoreScore.SOUND)
	_expect(fixture.beta.play_selected_hand(), "One corrective Pass can resolve with three ordinary Beta cards")
	_expect(fixture.state.get_core_score(ProjectState.CoreScore.GRAPHICS) == graphics_before + 2, "Selected corrective Pass applies exactly +2")
	_expect(fixture.state.get_core_score(ProjectState.CoreScore.SOUND) == sound_before, "Unselected corrective Pass applies no effect")
	_expect(views[4] in fixture.beta.get("_candidate_views") and views[4] in fixture.beta.get("_injected_corrective_views"), "Unplayed corrective Pass retains its instance and corrective eligibility")
	var next_views: Array[CardView] = fixture.beta.get("_candidate_views")
	for index in range(4): fixture.beta.call("_on_card_pressed", next_views[index])
	_expect(fixture.beta.play_selected_hand(), "Retained corrective Pass remains playable in the following hand")
	_expect(fixture.state.get_core_score(ProjectState.CoreScore.SOUND) == sound_before + 2 and views[4] not in fixture.beta.get("_candidate_views"), "Retained corrective Pass grants its +2 exactly once when played")
	fixture.beta.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)


func _verify_genre_percentage_selection() -> void:
	var state := ProjectState.new(30)
	_expect(state.configure_predevelopment("Percentage test", &"action", &"fantasy", [] as Array[StringName]), "Percentage fixture configures Action standards")
	var alpha := preload("res://scenes/phases/alpha_phase.tscn").instantiate() as AlphaPhase
	var beta := BETA_SCENE.instantiate() as BetaPhase
	alpha.setup(state)
	beta.set("_project_state", state)
	state.add_alpha_production({ProjectState.CoreScore.GRAPHICS: 20, ProjectState.CoreScore.SOUND: 18, ProjectState.CoreScore.TECHNOLOGY: 24, ProjectState.CoreScore.DESIGN: 19}, 0, 0.0)
	_expect(alpha.call("_select_corrective_categories") == [ProjectState.CoreScore.GRAPHICS, ProjectState.CoreScore.TECHNOLOGY], "Alpha chooses 50% and 60%, not lower raw Sound/Design")
	_expect(beta.call("_select_corrective_pass_ids") == [&"graphics_pass", &"technology_pass"], "Beta chooses the same lowest standard percentages")
	state.add_alpha_production({ProjectState.CoreScore.GRAPHICS: 60, ProjectState.CoreScore.SOUND: 34, ProjectState.CoreScore.TECHNOLOGY: 56, ProjectState.CoreScore.DESIGN: 33}, 0, 0.0)
	alpha.set_priority_distribution({ProjectState.CoreScore.GRAPHICS: 20, ProjectState.CoreScore.SOUND: 20, ProjectState.CoreScore.TECHNOLOGY: 20, ProjectState.CoreScore.DESIGN: 40})
	_expect(alpha.call("_select_corrective_categories")[0] == ProjectState.CoreScore.DESIGN, "Equal 200% ratios preserve Alpha priority tie break")
	_expect(beta.call("_select_corrective_pass_ids") == [&"graphics_pass", &"sound_pass"], "Equal percentages with unequal raw scores preserve Beta Core-order tie break")
	state.add_alpha_production({ProjectState.CoreScore.GRAPHICS: 1, ProjectState.CoreScore.SOUND: 1}, 0, 0.0)
	_expect(beta.call("_select_corrective_pass_ids") == [&"technology_pass", &"design_pass"], "Percentages remain uncapped above the Review cap")
	alpha.free()
	beta.free()
