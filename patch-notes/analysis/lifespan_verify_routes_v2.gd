## Bounded current-source legal routes; automation is not human evidence.
extends "res://analysis/task27_routes_v1.gd"
var action_limit := 0
var route_case := 0
var project_number := 0
var ledger_checks := 0
var row_checks := 0
var discrepancies: Array = []
var observed_previous := {}
var final_captures: Array = []

func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	arm = "newer"
	experiment = _arg("--experiment=", "lifespan_v2")
	if experiment=="repeat": arm="older"
	route_case = int(_arg("--case=", "0"))
	max_games = int(_arg("--games=", "3"))
	action_limit = int(_arg("--limit=", "0"))
	era_cap = 0
	first_store_cycle = 0
	random_inputs.seed = 240930000 + route_case
	var result := await _current_route(route_case)
	result["ledger_checks"] = ledger_checks
	result["row_checks"] = row_checks
	result["discrepancies"] = discrepancies
	result["captures"] = final_captures
	result["limit"] = action_limit
	var path := "res://design-logs/lifespan-verification-v2/route_%s_%d_%d.json" % [era_policy,route_case,max_games]
	if experiment=="repeat": path=path.replace(".json","_repeat.json")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(result))
	print("LIFESPAN route ",path," releases=",result.releases.size()," checks=",ledger_checks," discrepancies=",discrepancies.size())
	quit(0 if result.valid and discrepancies.is_empty() and (result.releases.size()==max_games or (action_limit>0 and result.final.cycle==action_limit)) else 1)

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	project_number += 1
	var seed_value := 240930100 + route_case*97 + (project_number-1)*500000
	var seed_ready := func(child: Node):
		if child is DesignPhase:
			child.ready.connect(func():
				child.get("_deal_rng").seed = seed_value+1
				child.get("_finalization_rng").seed = seed_value+2,CONNECT_ONE_SHOT)
	game.get_node("%PhaseRoot").child_entered_tree.connect(seed_ready)
	var rolls: Array[int] = [random_inputs.randi_range(0,99),random_inputs.randi_range(0,99)]
	game.set("_controlled_snapshot_rolls",rolls)
	var studio: StudioPhase = game.get("_active_phase")
	studio.close_summary()
	studio.get_node("%StartNextGame").pressed.emit()
	if studio.get_node("%LowScopeWarning").visible: studio.get_node("%LowScopeWarning").confirmed.emit()
	var setup: PredevelopmentOverlay = studio.get("_predevelopment")
	setup.name_input.text = title
	for i in range(setup.genre_input.item_count):
		if setup.genre_input.get_item_metadata(i)==genre: setup.genre_input.select(i)
	var priorities := {0:25,1:25,2:25,3:25}
	if era_policy=="synergy":
		var ratios: Array = []
		for entry: Dictionary in PrimitivePredevelopment.catalog().genres:
			if entry.id==genre: ratios=entry.ratios
		var ranked: Array[int]=[0,1,2,3]
		ranked.sort_custom(func(a,b):return clampf(42.0*float(ratios[a])/25.0,33.0,58.0)>clampf(42.0*float(ratios[b])/25.0,33.0,58.0))
		priorities={ranked[0]:50,ranked[1]:30,ranked[2]:15,ranked[3]:5}
	elif route_case%2==0: priorities=_core_priorities(true)
	for i in range(4): setup.priority_sliders[i].value=priorities[i]
	var before:=_state(game)
	setup.begin_button.pressed.emit()
	game.get_node("%PhaseRoot").child_entered_tree.disconnect(seed_ready)
	var success: bool = game.get("_active_phase") is DesignPhase and not game.get("_active_phase").is_initial_priority_planning()
	out.actions.append({"phase":"predevelopment","game":project_number,"title":title,"genre":genre,"rolls":rolls,"priorities":priorities,"before":before,"after":_state(game),"success":success})
	return success

func _capture_cycle(game: Control) -> void:
	super._capture_cycle(game)
	var run: RunState=game.run_state
	var reports: Array=[]
	for id in run.get_released_game_ids():
		var rec:=run.get_released_game_sales(id)
		var report:=run.get_released_game_monthly_report(id)
		ledger_checks+=1
		if report.is_empty(): discrepancies.append({"kind":"empty_report","id":id,"cycle":run.get_completed_run_cycles()});continue
		var sums: Array[int]=[0,0,0,0,0]
		for row: Dictionary in report.rows:
			row_checks+=1
			sums[0]+=row.units; sums[1]+=row.gross_cents; sums[2]+=row.net_cents; sums[3]+=row.settled_cents; sums[4]+=row.unpaid_cents
			if row.net_cents != row.settled_cents+row.unpaid_cents: discrepancies.append({"kind":"row_conservation","id":id})
		if sums != [rec.earned_units,rec.earned_units*999,rec.entitlement_cents,rec.settled_cents,rec.entitlement_cents-rec.settled_cents]: discrepancies.append({"kind":"totals","id":id})
		var previous: Dictionary=observed_previous.get(id,ReleasedGameSales.create(id,rec.total_units,rec.review_tenths,rec.launch_awareness,rec.market_bp))
		var expected:=ReleasedGameSales.next_cycle(previous,run.get_completed_run_cycles(),run.get_completed_run_cycles()%2==0,rec.campaign_count>previous.campaign_count)
		for key in expected:
			if expected[key]!=rec[key]: discrepancies.append({"kind":"per_cycle_ledger","id":id,"key":key})
		observed_previous[id]=rec
		reports.append(report)
	live_cycles[-1]["monthly_reports"]=reports

func _capture_final(game: Control,out: Dictionary) -> void:
	var run: RunState=game.run_state
	var before:=_state(game)
	var exporter=load("res://scripts/debug/lifespan_capture.gd")
	var saved: String=exporter.save_capture(run)
	if not saved.begins_with("Saved locally: "): discrepancies.append({"kind":"capture_write"});return
	var cap: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(saved.trim_prefix("Saved locally: ")))
	if int(cap.cash_cents)!=run.get_cash_cents() or int(cap.run_cycle)!=run.get_completed_run_cycles() or cap.titles.size()!=run.get_released_game_ids().size(): discrepancies.append({"kind":"capture_header"})
	for i in range(cap.titles.size()):
		var id: StringName=run.get_released_game_ids()[i]
		var expected:={"metadata":run.get_release_metadata(id),"ledger":run.get_released_game_sales(id),"monthly_report":run.get_released_game_monthly_report(id)}
		if JSON.parse_string(JSON.stringify(expected))!=cap.titles[i]: discrepancies.append({"kind":"capture_title","index":i})
	if _state(game)!=before: discrepancies.append({"kind":"capture_not_passive"})
	final_captures.append(cap)

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
		if action_limit > 0 and run.get_completed_run_cycles() >= action_limit: break
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
		if action_limit > 0 and run.get_completed_run_cycles() + 3 > action_limit: break
		if number==1:
			if not await _contract(game,era_policy,seed_value,out,"ironclad"):out.errors.append("ironclad");break
			_visit(game,out,"Ironclad return")
		if action_limit > 0 and run.get_completed_run_cycles() + 3 > action_limit: break
		if run.is_sidestreet_offer_available():
			if not await _contract(game,era_policy,seed_value+number*17,out,"sidestreet_current_%d"%number):out.errors.append("sidestreet");break
			_visit(game,out,"SideStreet return")
		_shop(game,out)
		out["after_game_%d"%number] = _studio_state(game)
		await process_frame
	_capture_final(game, out)
	out["final"] = _studio_state(game)
	out["live_cycles"] = live_cycles.duplicate(true)
	out["sales_records"] = []
	for id: StringName in run.get_released_game_ids():out.sales_records.append(run.get_released_game_sales(id))
	out.valid=out.errors.is_empty()
	game.queue_free()
	await process_frame
	return out


func _develop_game(game: Control,policy: String,focus: String,_mode: String,seed_value: int,number: int,out: Dictionary) -> bool:
	await process_frame
	var project: ProjectState=game.project_state
	var run: RunState=game.run_state
	active_project=project
	for label: String in ["design","alpha"]:
		var phase: Control=game.get("_active_phase")
		if phase.is_initial_priority_planning():
			phase.get("_deal_rng").seed=seed_value+(1 if label=="design" else 3)
			phase.get("_finalization_rng").seed=seed_value+(2 if label=="design" else 4)
			if policy in ["synergy","high","repeat"]:phase.set_priority_distribution(_priorities(project))
			elif focus=="sound":phase.set_priority_distribution(_core_priorities(true))
			if not phase.get_workspace().overlay.commit_draft():return false
		var limit := (3 if label=="design" else 4) if policy=="cautious" else (4 if label=="design" else 5) if policy=="ordinary" else (10 if label=="design" else 14) if policy!="high" else (22 if label=="design" else 24)
		if _arg("--budget=", "normal") == "fixed": limit = 10 if label == "design" else 14
		for hand in range(limit):
			if action_limit > 0 and run.get_completed_run_cycles() >= action_limit: return false
			if _arg("--budget=", "normal") != "fixed" and policy in ["synergy","high","repeat"] and hand>=3:
				var scores_ready:=true
				for i in range(4):
					if project.get_core_score(i)<_core_target(project,i)*(0.55 if label=="design" else 1.0):scores_ready=false
				if (scores_ready or policy=="repeat") and (label=="design" or project.get_current_scope()>=project.get_required_scope()):break
			if policy in ["synergy","high","repeat"] and hand>0 and hand%3==0:
				var before:=_state(game)
				var changed:bool=phase.commit_priority_distribution(_priorities(project))
				out.actions.append({"phase":label+" priorities","game":number,"distribution":phase.get_priority_distribution(),"success":changed,"before":before,"after":_state(game)})
			if action_limit > 0 and run.get_completed_run_cycles() >= action_limit: return false
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
		if action_limit > 0 and run.get_completed_run_cycles() >= action_limit: return false
		# Never inspect hidden Bugs to stop; budget and public known Bugs only.
		if not _beta_hand(beta,project,run,policy,"qa",number,out):return false
	game.set("_controlled_review_roll",-1)
	game.get("_review_rng").seed=seed_value+7
	var before:=_state(game)
	var launched:=beta.request_launch()
	if not launched:launched=beta.confirm_launch_for_verification()
	out.actions.append({"phase":"launch","game":number,"success":launched,"before":before,"after":_state(game)})
	return launched and game.get("_active_phase") is StudioPhase


func _shop(game: Control,out: Dictionary) -> void:
	if action_limit>0 and game.run_state.get_completed_run_cycles()+5>action_limit: return
	super._shop(game,out)

func _campaign_action(game: Control,id: StringName) -> Dictionary:
	var result:=super._campaign_action(game,id)
	var before:=_state(game)
	var rejected:bool=not game.run_state.purchase_post_launch_campaign(id,int(result.before.cycle))
	result["repeated_callback_rejected"]=rejected and before==_state(game)
	if not result.repeated_callback_rejected:discrepancies.append({"kind":"campaign_retry"})
	return result
