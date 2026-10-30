class_name GuidedProductionModel
extends RefCounted

## A disposable teaching scenario, never attached to a checkpoint or rival world.
## Scripted supply is practice-only; arithmetic comes from live production code.
const Design := preload("res://scripts/simulation/design_hand_command.gd")
const Alpha := preload("res://scripts/simulation/alpha_hand_command.gd")
const Beta := preload("res://scripts/simulation/beta_hand_command.gd")
const Production := preload("res://scripts/simulation/production_hand.gd")
enum Lesson { CORE, BALANCED, SPECIALIZATION, REDRAW, REDRAW_HAND, ALPHA, MARKETING, SEARCH, DEBUG, COMPLETE }
const POOLS := [
	[&"text",&"sound_pass",&"technology_pass",&"graphics_pass"],
	[&"4_color_palette",&"sound_pass",&"technology_pass",&"design_pass"],
	[&"sprites",&"graphics_pass",&"graphics_pass",&"graphics_pass"],
	[&"graphics_pass",&"graphics_pass",&"graphics_pass",&"sound_pass",&"technology_pass",&"design_pass",&"score_system"],
	[],
	[&"levels",&"sound_effects",&"controls",&"simple_story"],
	[&"sign_flippers",&"posters",&"press_release",&"sign_flippers",&"search_for_bugs",&"debug",&"posters"],
	[&"search_for_bugs",&"search_for_bugs",&"search_for_bugs",&"search_for_bugs",&"debug",&"posters",&"sign_flippers"],
	[&"debug",&"debug",&"debug",&"debug",&"search_for_bugs",&"posters",&"sign_flippers"],
]
var project: ProjectState
var run: RunState
var pool: Array[CardData] = []
var lesson := Lesson.CORE
var resolved := false
var complete := false
var result: Dictionary = {}
var catalog: RefCounted
var snapshots: PrimitiveSnapshotDatabase
var exhausted_design: Array[StringName] = []
var exhausted_alpha: Array[StringName] = []

func start(definitions: RefCounted) -> bool:
	if project != null or definitions == null: return false
	for ids: Array in POOLS:
		for id: StringName in ids:
			if not definitions.cards.has(id): return false
	catalog = definitions
	run = RunState.new()
	if not run.initialize_cash(0) or not run.create_studio_with_traits("Practice Studio",&"action",[]): return false
	for index in RunRandom.STREAMS.size(): run.random_streams.stream(RunRandom.STREAMS[index]).seed = 8400+index
	project = ProjectState.new(30)
	project._release_id = &"guided-practice-project"
	var feature_ids: Array[StringName] = []
	for ids: Array in POOLS:
		for id: StringName in ids:
			if catalog.cards[id].card_type == &"feature" and id not in feature_ids: feature_ids.append(id)
	if not project.configure_predevelopment("Practice Project",&"action",&"fantasy",feature_ids): return false
	snapshots = PrimitiveSnapshotDatabase.new()
	if not snapshots.load_ledgers() or not project.initialize_snapshots(&"fast_follower",&"stable_market"): return false
	_deal()
	return true

func snapshot() -> Dictionary:
	return {"lesson":lesson,"resolved":resolved,"complete":complete,"scores":HandPresentation.project_snapshot(project,run),
		"pool":pool.map(func(card: CardData): return String(card.id)),"rng":run.random_streams.snapshot(),
		"cash":run.get_cash_cents(),"cycle":run.get_completed_run_cycles(),"design":exhausted_design.duplicate(),"alpha":exhausted_alpha.duplicate()}

func phase_name() -> String:
	return "Beta" if lesson >= Lesson.MARKETING else "Alpha" if lesson == Lesson.ALPHA else "Design"

func can_play(slots: Array) -> bool:
	if project == null or resolved or complete or lesson == Lesson.REDRAW or slots.size()!=4: return false
	for slot in slots:
		if not slot is int: return false
	var ordered := slots.duplicate()
	ordered.sort()
	return ordered == [0,1,2,3]

func can_redraw(slots: Array) -> bool:
	return lesson == Lesson.REDRAW and not resolved and slots.size()==1 and slots[0] is int and slots[0]==3 and run.can_consume_redraw(1)

func redraw(slots: Array) -> Dictionary:
	if not can_redraw(slots): return {"ok":false}
	pool[3] = catalog.cards[&"graphics_pass"]
	run.consume_redraw(1)
	lesson = Lesson.REDRAW_HAND
	return {"ok":true}

func play(slots: Array) -> Dictionary:
	if not can_play(slots): return {"ok":false}
	var cards: Array[CardData] = []
	for index in [0,1,2,3]: cards.append(pool[index])
	if lesson >= Lesson.MARKETING:
		var command := Beta.new()
		command._project_state = project
		command._run_state = run
		command._snapshot_database = snapshots
		command._deal_rng = run.random_streams.stream(&"beta_deal")
		command._insight_rng = run.random_streams.stream(&"beta_insight")
		command.priorities = BetaPriorityAllocation.new().get_distribution()
		for id: StringName in catalog.cards:
			var card: CardData = catalog.cards[id]
			command._definitions_by_id[id] = card
			if card.phase == CardData.PHASE_BETA: command._beta_definitions.append(card)
		command._candidate_cards.assign(pool)
		command.candidate_ids.assign([0,1,2,3,4,5,6])
		command.next_candidate_id = 7
		command.active = true
		var committed: Dictionary = command.execute(command.command([0,1,2,3]))
		if not committed.ok: return committed
		pool.assign(command._candidate_cards)
		result = {"ok":true,"scores":{},"scope":0,"specialization_stat":&"", "balanced_production":false,"events":committed.events}
		if committed.preflight.marketing_specialization: result.specialization_stat = &"marketing"
		elif committed.preflight.qa_specialization: result.specialization_stat = &"qa"
	else:
		var base: Dictionary
		if lesson == Lesson.ALPHA:
			var calculator := Alpha.new()
			calculator._candidate_cards.assign(pool)
			calculator._available_features.assign(pool)
			base = calculator.calculate_base(cards)
		else:
			base = Design.new().calculate_base(cards)
		if not base.valid: return {"ok":false}
		var records: Array = cards.map(func(card: CardData): return {"primary_stat":card.primary_stat})
		var production: Dictionary = Production.calculate(records,base.score_additions,base.get("has_feature",true))
		var commit := func() -> bool:
			var applied := project.add_alpha_production(production.score_additions,base.scope,base.alpha_bug_pressure) if lesson == Lesson.ALPHA else project.add_core_scores_and_scope(production.score_additions,base.scope,base.bug_pressure)
			if not applied: return false
			project.advance_cycle()
			return true
		if not run.complete_productive_action(commit): return {"ok":false}
		for card: CardData in cards:
			if not card.renewable:
				if lesson == Lesson.ALPHA: exhausted_alpha.append(card.id)
				else: exhausted_design.append(card.id)
		for index in [3,2,1,0]: pool.remove_at(index)
		result = {"ok":true,"scores":production.score_additions,"scope":base.scope,
			"specialization_stat":production.specialization_stat,"balanced_production":production.balanced_production}
	resolved = true
	return result.duplicate(true)

func next_lesson() -> bool:
	if not resolved or complete: return false
	if lesson == Lesson.REDRAW_HAND and not project.finalize_design_bugs(false,6,exhausted_design,[]): return false
	if lesson == Lesson.ALPHA and not project.finalize_alpha(2,exhausted_alpha,[]): return false
	lesson = (lesson+1) as Lesson
	resolved = false
	result = {}
	if lesson == Lesson.COMPLETE:
		complete = true
		pool.clear()
	else: _deal()
	return true

func _deal() -> void:
	pool.clear()
	for id: StringName in POOLS[lesson]: pool.append(catalog.cards[id])
