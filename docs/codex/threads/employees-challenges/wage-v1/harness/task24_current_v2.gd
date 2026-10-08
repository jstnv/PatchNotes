## READ ONLY. Native Task25 starts, visible-choice policies, Task26 release guard.
extends "res://analysis/task24_normal_v1.gd"

const STATS: Array[StringName] = [&"graphics", &"sound", &"technology", &"design"]
var max_games := 2
var phase_for_choice: Control

func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	era_cap = int(_arg("--cap=", "0"))
	max_games = 2 if era_cap == 0 else 100
	first_store_cycle = int(_arg("--store-gate=", "0"))
	var start := int(_arg("--start=", "0"))
	for index in range(start, start + int(_arg("--count=", "16"))):
		live_cycles = []
		random_inputs.seed = 240930000 + index
		var result := await _current_route(index)
		rows.append(result)
		if not result.valid: failures += 1
		_write_rows()
		print("CURRENT24 ", era_policy, " case=", index, " releases=", result.releases.size(), " cycles=", result.final.cycle, " errors=", result.errors)
	quit(0 if failures == 0 else 1)

func _write_rows() -> void:
	var file := FileAccess.open("res://design-logs/task24-current-v2/%s_%s_%s_%s.json" % [era_policy, _arg("--start=", "0"), era_cap, first_store_cycle], FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows": rows, "failures": failures, "command": OS.get_cmdline_args()}, "  "))

func _current_route(index: int) -> Dictionary:
	var genre_list: Array = PrimitivePredevelopment.catalog().genres
	var specialty := StringName(genre_list[index % 8].id)
	var seed_value := 240930100 + index * 97
	var out := {"case":index,"specialty":str(specialty),"seed":seed_value,"environment_seed":240930000+index,"policy":era_policy,"store_gate_trial":first_store_cycle,"actions":[],"purchases":[],"releases":[],"studio_visits":[],"errors":[],"blockers":[],"valid":false,"stop":"requested horizon"}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Current Era Trial"
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(index % 8 + 1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var run: RunState = game.run_state
	run.calendar_changed.connect(_capture_cycle.bind(game))
	# Each matched policy receives exactly the same legal starting purchases.
	if index >= 8:
		var offers: Array[Dictionary] = []
		for entry: Dictionary in FeatureStoreCatalog.starting_features():
			var quote := run.get_primitive_reserve_offer(entry.id)
			if not quote.owned: offers.append(quote)
		offers.sort_custom(func(a: Dictionary,b: Dictionary): return a.scope > b.scope if a.scope != b.scope else str(a.id)<str(b.id))
		for offer: Dictionary in offers:
			if run.get_starter_pool_summary().scope >= 33: break
			if run.get_cash_cents() - int(offer.price_cents) < 180000: continue
			var before := _state(game)
			var success := run.purchase_starter_feature(offer.id)
			out.purchases.append({"id":offer.id,"kind":"initial","quote":offer,"success":success,"before":before,"after":_state(game)})
			if not success: out.errors.append("initial purchase")
	out["starter_summary"] = run.get_starter_pool_summary()
	_visit(game,out,"initial Studio")
	for number in range(1,max_games+1):
		if era_cap>0 and run.get_completed_run_cycles()>=era_cap: break
		var genre := StringName(genre_list[(index+number-1)%8].id)
		if not _begin_game(game,"Current %d"%number,genre,out):out.errors.append("begin");break
		if not await _develop_game(game,era_policy,"sound" if index%2==0 else "mixed","qa",seed_value+(number-1)*500000,number,out):
			out.stop="route stalled";out.blockers.append({"game":number,"state":_state(game)});break
		var release := _release(game.project_state,run)
		release["required_scope"] = game.project_state.get_required_scope()
		release["qualifies"] = int(release.scope)>=int(release.required_scope)
		release["publishers"] = _publishers(run)
		out.releases.append(release)
		_visit(game,out,"committed release")
		if number==1:
			if not await _contract(game,era_policy,seed_value,out,"ironclad"):out.errors.append("ironclad");break
			_visit(game,out,"Ironclad return")
		if run.is_sidestreet_offer_available():
			if not await _contract(game,era_policy,seed_value+number*17,out,"sidestreet_current_%d"%number):out.errors.append("sidestreet");break
			_visit(game,out,"SideStreet return")
		_shop(game,out)
		out["after_game_%d"%number] = _studio_state(game)
		await process_frame
	out["final"] = _studio_state(game)
	out["live_cycles"] = live_cycles.duplicate(true)
	out["sales_records"] = []
	for id: StringName in run.get_released_game_ids():out.sales_records.append(run.get_released_game_sales(id))
	out.valid=out.errors.is_empty()
	game.queue_free()
	await process_frame
	return out

func _core_target(project: ProjectState, index: int) -> float:
	return clampf(42.0*float(project.get_genre_ratios()[index])/25.0,33.0,58.0)

func _priorities(project: ProjectState) -> Dictionary:
	var ranked: Array[int] = [0,1,2,3]
	ranked.sort_custom(func(a:int,b:int):return _core_target(project,a)-project.get_core_score(a)>_core_target(project,b)-project.get_core_score(b))
	return {ranked[0]:50,ranked[1]:30,ranked[2]:15,ranked[3]:5}

func _develop_game(game: Control,policy: String,focus: String,_mode: String,seed_value: int,number: int,out: Dictionary) -> bool:
	await process_frame
	var project: ProjectState=game.project_state
	var run: RunState=game.run_state
	active_project=project
	for label: String in ["design","alpha"]:
		var phase: Control=game.get("_active_phase")
		phase.get("_deal_rng").seed=seed_value+(1 if label=="design" else 3)
		phase.get("_finalization_rng").seed=seed_value+(2 if label=="design" else 4)
		if policy in ["synergy","high","repeat"]:phase.set_priority_distribution(_priorities(project))
		elif focus=="sound":phase.set_priority_distribution(_core_priorities(true))
		if not phase.get_workspace().overlay.commit_draft():return false
		var limit := (3 if label=="design" else 4) if policy=="cautious" else (4 if label=="design" else 5) if policy=="ordinary" else (10 if label=="design" else 14) if policy!="high" else (22 if label=="design" else 24)
		for hand in range(limit):
			if policy in ["synergy","high","repeat"] and hand>=3:
				var scores_ready:=true
				for i in range(4):
					if project.get_core_score(i)<_core_target(project,i)*(0.55 if label=="design" else 1.0):scores_ready=false
				if (scores_ready or policy=="repeat") and (label=="design" or project.get_current_scope()>=project.get_required_scope()):break
			if policy in ["synergy","high","repeat"] and hand>0 and hand%3==0:
				var before:=_state(game)
				var changed:bool=phase.commit_priority_distribution(_priorities(project))
				out.actions.append({"phase":label+" priorities","game":number,"distribution":phase.get_priority_distribution(),"success":changed,"before":before,"after":_state(game)})
			phase_for_choice=phase
			if not _production_hand(phase,project,run,policy,focus,label,number,out):
				out.blockers.append({"game":number,"phase":label,"hand":hand,"reason":"no legal affordable production","state":_state(game)})
				break
		if label=="design":phase.call("_on_proceed_to_alpha_pressed")
		else:
			phase.request_proceed_to_beta()
			if phase.get_node("%UnderScopeDialog").visible:phase.get_node("%UnderScopeDialog").confirmed.emit()
		if label=="design" and not game.get("_active_phase") is AlphaPhase:return false
		if label=="alpha" and not game.get("_active_phase") is BetaPhase:return false
	var beta: BetaPhase=game.get("_active_phase")
	beta.get("_deal_rng").seed=seed_value+5
	beta.get("_insight_rng").seed=seed_value+6
	beta.set_priority_distribution(_beta_priorities("qa"))
	if not beta.get_workspace().overlay.commit_draft():return false
	for hand in range(4 if policy=="cautious" else 6 if policy=="ordinary" else 12):
		# Never inspect hidden Bugs to stop; budget and public known Bugs only.
		if not _beta_hand(beta,project,run,policy,"qa",number,out):return false
	game.set("_controlled_review_roll",-1)
	game.get("_review_rng").seed=seed_value+7
	var before:=_state(game)
	var launched:=beta.request_launch()
	if not launched:launched=beta.confirm_launch_for_verification()
	out.actions.append({"phase":"launch","game":number,"success":launched,"before":before,"after":_state(game)})
	return launched and game.get("_active_phase") is StudioPhase

func _choose_production(cards: Array[CardData],project: ProjectState,run: RunState,policy: String,focus: String) -> Array[int]:
	if era_policy in ["cautious","ordinary"]:return super._choose_production(cards,project,run,policy,focus)
	var best:=-INF
	var choice: Array[int]=[]
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand: Array[CardData]=[cards[a],cards[b],cards[c],cards[d]]
					var cost:=run.primitive_feature_hand_cost_cents(hand)
					if cost<0 or cost>run.get_cash_cents():continue
					var same:=hand.all(func(card:CardData):return card.primary_stat==hand[0].primary_stat)
					var value:=0.0
					var scope:=0
					for card:CardData in hand:scope+=card.scope
					value+=mini(scope,maxi(0,project.get_required_scope()-project.get_current_scope()))*(30.0 if era_policy=="repeat" else 10.0)
					for i in range(4):
						var gain:=0.0
						for card:CardData in hand:
							if card.primary_stat==STATS[i]:gain+=card.primary_value
							if card.secondary_stat==STATS[i]:gain+=card.secondary_value
						if same:gain*=1.5
						value+=minf(gain,maxf(0,_core_target(project,i)-project.get_core_score(i)))*4.0
					if same:value+=8.0
					if same and hand[0].primary_stat==guided_target:value+=100000.0
					value-=cost/100000.0
					if value>best:best=value;choice=[a,b,c,d]
	return choice

func _weakest(cards: Array[CardData],focus: String) -> int:
	# The inherited native redraw path reads only these visible candidates.
	var counts:={}
	for card:CardData in cards:counts[card.primary_stat]=int(counts.get(card.primary_stat,0))+1
	var target:=guided_target
	if target.is_empty():
		var best:=-INF
		for stat:StringName in counts:
			var value:=float(counts[stat])*10.0+maxf(0,_core_target(active_project,STATS.find(stat))-active_project.get_core_score(STATS.find(stat)))
			if value>best:best=value;target=stat
	for i in range(cards.size()):
		if cards[i].primary_stat!=target:return i
	return super._weakest(cards,focus)
