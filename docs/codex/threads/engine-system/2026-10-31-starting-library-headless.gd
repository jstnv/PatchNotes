## Research-only headless library screen using current CardDatabase, phase commands,
## weighted deals, Pass Budget, production, bug finalization and Review source.
extends SceneTree

const CardDB = preload("res://scripts/cards/card_database.gd")
const Design = preload("res://scripts/simulation/design_hand_command.gd")
const Alpha = preload("res://scripts/simulation/alpha_hand_command.gd")
const Production = preload("res://scripts/simulation/production_hand.gd")
const Finalization = preload("res://scripts/simulation/development_finalization.gd")
const Review = preload("res://scripts/review/primitive_review_calculator.gd")
var database: Node
var failures: Array[String] = []

func _initialize() -> void:
	print("LIBRARY_HEADLESS_INIT")
	call_deferred("run")

func run() -> void:
	database=CardDB.new()
	root.add_child(database)
	await process_frame
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_LIBRARY_MANIFEST")))
	if not parsed is Dictionary or not parsed.has("libraries"):
		push_error("Library manifest unavailable")
		quit(2);return
	var rows: Array[Dictionary]=[]
	var n:=int(OS.get_environment("PN_LIBRARY_SEEDS")) if OS.get_environment("PN_LIBRARY_SEEDS").is_valid_int() else 3
	for engine: String in parsed.libraries:
		var ids: Array[StringName]=[]
		for raw_id: String in parsed.libraries[engine].ids: ids.append(StringName(raw_id))
		for genre in [&"action",&"puzzle",&"adventure"]:
			for strategy in [&"competent",&"optimized"]:
				for seed in range(n):
					var outcome:=simulate(engine,ids,genre,strategy,4417+seed*7919)
					if outcome.is_empty():failures.append("%s/%s/%s/%d" % [engine,genre,strategy,seed])
					else:rows.append(outcome)
	print("LIBRARY_RESULT_JSON:",JSON.stringify({"schema":1,"cases":rows,"failures":failures,"seeds_per_cell":n}))
	database.queue_free()
	await process_frame
	quit(1 if not failures.is_empty() else 0)

func _cards(ids: Array[StringName], phase: StringName) -> Array[CardData]:
	var result: Array[CardData]=[]
	for id in ids:
		var card: CardData=database.get_card(id)
		if card==null:push_error("Missing card "+str(id));continue
		if card.phase==phase:result.append(card)
	return result

func _priorities(genre: StringName,strategy: StringName) -> Dictionary:
	if strategy==&"competent":return {0:25,1:25,2:25,3:25}
	if genre==&"action":return {0:30,1:20,2:30,3:20}
	if genre==&"puzzle":return {0:15,1:20,2:25,3:40}
	return {0:25,1:25,2:15,3:35}

func _engine_bonus(engine: String) -> Dictionary:
	if engine.begins_with("puzzle") or engine=="rival_puzzle":return {2:1000,3:1000}
	if engine.begins_with("adventure") or engine=="rival_adventure":return {0:1000,3:1000}
	return {}

func _rating(scores: Array[int],scope: int,genre: StringName) -> float:
	var targets: Array=Review.GENRE_TARGETS[genre]
	var ratios: Array[float]=[];var mean:=0.0
	for i in range(4):
		var ratio:=minf(1.25,float(scores[i])/float(targets[i]));ratios.append(ratio);mean+=ratio/4.0
	var variance:=0.0
	for ratio in ratios:variance+=pow(ratio-mean,2.0)/4.0
	return maxf(0.0,minf(10.0,(mean-0.5*sqrt(variance))*8.0))*minf(1.0,float(scope)/30.0)

func _choose(hand: RefCounted,project: ProjectState,genre: StringName,strategy: StringName,engine: String) -> Array[int]:
	var cards: Array[CardData]=hand._candidate_cards
	if cards.size()<4:return []
	var old: Array[int]=[]
	for i in range(4):old.append(project.get_core_score(ProjectState.CoreScore.values()[i]))
	var old_rating:=_rating(old,project.get_current_scope(),genre)
	var best: Array[int]=[];var best_value: float=-INF
	for a in range(cards.size()-3):
		for b in range(a+1,cards.size()-2):
			for c in range(b+1,cards.size()-1):
				for d in range(c+1,cards.size()):
					var selected: Array[CardData]=[cards[a],cards[b],cards[c],cards[d]]
					if not hand.can_play_pass_budget(selected):continue
					var base: Dictionary=hand.calculate_base(selected)
					if not base.get("valid",false):continue
					var additions: Dictionary=Production.calculate(selected.map(func(x: CardData):return {&"primary_stat":x.primary_stat}),base.score_additions,selected.any(func(x: CardData):return x.card_type==&"feature"),_engine_bonus(engine)).score_additions
					var scores:=old.duplicate()
					for i in range(4):scores[i]+=int(additions.get(i,0))
					var value:=(_rating(scores,project.get_current_scope()+int(base.scope),genre)-old_rating)*10.0
					var features:=selected.filter(func(x: CardData):return x.card_type==&"feature").size()
					if strategy==&"competent":value+=float(base.scope)*0.45+float(features)*0.15
					else:value+=float(base.scope)*0.35+float(features)*0.08
					value-=float(base.get("bug_pressure",base.get("alpha_bug_pressure",0.0)))*0.03
					if value>best_value:best_value=value;best=[hand.candidate_ids[a],hand.candidate_ids[b],hand.candidate_ids[c],hand.candidate_ids[d]]
	return best

func _phase(project: ProjectState,ids: Array[StringName],genre: StringName,strategy: StringName,phase_name: StringName,seed: int,engine: String) -> Dictionary:
	var hand: RefCounted=Design.new() if phase_name==&"design" else Alpha.new()
	hand._project_state=project;hand._deal_rng=RandomNumberGenerator.new();hand._deal_rng.seed=seed
	hand._available_features=_cards(ids,phase_name)
	var pass_cards: Array[CardData]=[]
	for id in [&"graphics_pass",&"sound_pass",&"technology_pass",&"design_pass"]:pass_cards.append(database.get_card(id))
	hand._pass_definitions=pass_cards
	hand.priorities=_priorities(genre,strategy);hand.active=true
	var deal: Dictionary=hand._build_weighted_candidate_definitions(hand.priorities)
	if not deal.get("valid",false):return {"error":str(deal.get("error","initial deal"))}
	hand._candidate_cards.assign(deal.cards)
	if phase_name==&"design":
		for card in deal.selected_features:hand._available_features.erase(card)
	for card in deal.cards:
		hand.candidate_ids.append(hand.next_candidate_id)
		hand.next_candidate_id+=1
	var short:=int(deal.cards.size()<7);var hands:=0;var passes:=0;var features:=0;var depleted:=false
	var max_hands:=5 if strategy==&"competent" else 7
	while hands<max_hands:
		var chosen:=_choose(hand,project,genre,strategy,engine)
		if chosen.size()!=4:depleted=true;break
		var selected: Array[CardData]=[]
		for token in chosen:selected.append(hand._candidate_cards[hand.candidate_ids.find(token)])
		var result: Dictionary=hand.execute(hand.command(chosen))
		if not result.get("ok",false):return {"error":str(result.get("error","hand"))}
		# The new engine IDs are not live. Apply the licensed +0.1 delta from
		# current ProductionHand after the accepted canonical hand, per category.
		var with_bonus: Dictionary=Production.calculate(selected.map(func(x: CardData):return {&"primary_stat":x.primary_stat}),result.base_hand.score_additions,selected.any(func(x: CardData):return x.card_type==&"feature"),_engine_bonus(engine)).score_additions
		for category in range(4):
			var delta:=int(with_bonus.get(category,0))-int(result.final_action.score_additions.get(category,0))
			if delta>0 and not project.add_core_score(ProjectState.CoreScore.values()[category],delta):return {"error":"bonus overlay"}
		hands+=1
		for card in selected:
			if card.card_type==&"pass":passes+=1
			else:features+=1
		if hand._candidate_cards.size()<7:short+=1
		if hand._candidate_cards.size()<4:depleted=true;break
	var played: Array[StringName]=[];var unplayed: Array[StringName]=[]
	for card in _cards(ids,phase_name):
		if (hand._exhausted_card_ids if phase_name==&"design" else hand._exhausted_feature_ids).has(card.id):played.append(card.id)
		else:unplayed.append(card.id)
	var finalizer:=Finalization.new();finalizer._project_state=project
	var bug_rng:=RandomNumberGenerator.new();bug_rng.seed=seed+899999
	var bug_result: Dictionary=finalizer._calculate_design_finalization(bug_rng.randf(),bug_rng.randf()) if phase_name==&"design" else finalizer._calculate_alpha_finalization(bug_rng.randf(),bug_rng.randf())
	if not bug_result.get("valid",false):return {"error":"finalization calculation"}
	var accepted:=project.finalize_design_bugs(bug_result.perfect_production,bug_result.hidden_bugs,played,unplayed) if phase_name==&"design" else project.finalize_alpha(bug_result.generated,played,unplayed)
	if not accepted:return {"error":"project finalization"}
	return {"hands":hands,"passes":passes,"features":features,"short":short,"depleted":depleted,"printed":hand._budget_printed,"generated":2+hand._budget_printed/8,"unused_budget":hand.pass_budget_available(),"hidden_bugs_added":int(bug_result.get("hidden_bugs",bug_result.get("generated",0)))}

func simulate(engine: String,ids: Array[StringName],genre: StringName,strategy: StringName,seed: int) -> Dictionary:
	var project:=ProjectState.new(30)
	project.set("_release_id",StringName("library_screen"))
	if not project.configure_predevelopment("Library Screen",genre,&"fantasy",ids):return {}
	var design:=_phase(project,ids,genre,strategy,&"design",seed,engine)
	if design.has("error"):push_error(str(design.error));return {}
	var alpha:=_phase(project,ids,genre,strategy,&"alpha",seed+31001,engine)
	if alpha.has("error"):push_error(str(alpha.error));return {}
	var raw_bugs:=project.get_remaining_bugs()
	var qa:=4 if strategy==&"competent" else 8
	project.discover_bugs(qa);project.fix_known_bugs(qa)
	project.set("_has_beta_finalization",true)
	var review: ReviewResult=Review.calculate(project,50)
	if review==null:push_error("Review unavailable");return {}
	return {"engine":engine,"genre":str(genre),"strategy":str(strategy),"seed":seed,"scope":project.get_current_scope(),"core":[project.get_core_score(0),project.get_core_score(1),project.get_core_score(2),project.get_core_score(3)],"review":review.get_final_review(),"raw_bugs":raw_bugs,"remaining_bugs":project.get_remaining_bugs(),"design":design,"alpha":alpha}
