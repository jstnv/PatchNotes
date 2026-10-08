## READ-ONLY era capture. All actions use current phase/RunState APIs.
extends "res://analysis/task21_route_v1.gd"
var era_policy := "ordinary"
var era_cap := 240
var first_store_cycle := 0
var current_route: Dictionary

func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	era_cap = int(_arg("--cap=", "240"))
	first_store_cycle = int(_arg("--store-gate=", "0"))
	for index in range(int(_arg("--start=", "0")), int(_arg("--start=", "0")) + int(_arg("--count=", "6"))):
		random_inputs.seed = 240929000 + index
		live_cycles = []
		var out := await _era_route(index)
		rows.append(out)
		if not out.valid: failures += 1
		print("ERA ", era_policy, " ", index, " cycle=", out.final.cycle, " releases=", out.releases.size(), " qualified=", out.final.qualifying_count, " stop=", out.stop)
	var file := FileAccess.open("res://design-logs/task24-v1/normal_%s_%d_%d%s.json" % [era_policy, first_store_cycle, era_cap, _arg("--tag=", "")], FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":rows,"failures":failures,"command":OS.get_cmdline_args()},"  "))
	quit(0 if failures == 0 else 1)

func _era_route(index: int) -> Dictionary:
	var seed_value := 270927000 + index * 97
	var target := 20 + index % 4
	var roster: Array = ROSTERS[target][index % 3]
	var focus := "sound" if index % 2 == 0 else "mixed"
	var mode := "qa" if index % 2 == 0 else "marketing"
	var out := {"policy":era_policy,"case":index,"seed":seed_value,"environment_seed":240929000+index,"store_gate":first_store_cycle,"cap":era_cap,"starter_target":target,"starter_roster":roster,"production_focus":focus,"beta_mode":mode,"actions":[],"purchases":[],"releases":[],"studio_visits":[],"errors":[],"blockers":[],"valid":false,"stop":"cycle_cap"}
	current_route = out
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	(menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName") as LineEdit).text = "Calendar Trial %d" % index
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var run: RunState = game.run_state
	run.calendar_changed.connect(_capture_cycle.bind(game))
	_visit(game,out,"initial")
	for raw: String in roster:
		var before := _state(game)
		var quote := run.get_primitive_reserve_offer(StringName(raw))
		var success := run.purchase_starter_feature(StringName(raw))
		out.purchases.append({"id":raw,"kind":"starter","quote":quote,"success":success,"before":before,"after":_state(game)})
		if not success: out.errors.append("starter_purchase")
		_visit(game,out,"starter_purchase")
	out["starter_summary"] = run.get_starter_pool_summary()
	if int(out.starter_summary.scope)!=target or int(out.starter_summary.spent_cents)>400000: out.errors.append("starter_limits")
	for number in range(1,151):
		if not out.errors.is_empty(): break
		if run.get_completed_run_cycles()>=era_cap: break
		if not _begin_game(game,"Era Game %d"%number,GENRES[(index+number-1)%3],out):
			out.errors.append("begin_game"); break
		if not await _develop_game(game,era_policy,focus,mode,seed_value+(number-1)*500000,number,out):
			out.stop="policy_action_blocked"
			break
		var release := _release(game.project_state,run)
		release["required_scope"] = game.project_state.get_required_scope()
		release["qualifies"] = int(release.scope)>=int(release.required_scope)
		release["owned_ids"] = run.get_owned_feature_ids()
		out.releases.append(release)
		_visit(game,out,"release")
		if run.get_completed_run_cycles()>=era_cap: break
		if number==1:
			if not await _contract(game,era_policy,seed_value,out,"ironclad"):
				out.errors.append("ironclad"); break
			_visit(game,out,"contract_return")
		if run.is_sidestreet_offer_available():
			if not await _contract(game,era_policy,seed_value+number*17,out,"sidestreet_%d"%number):
				out.errors.append("sidestreet"); break
			_visit(game,out,"contract_return")
		_shop(game,out)
	out["final"]=_studio_state(game)
	out["live_cycles"]=live_cycles.duplicate(true)
	out["frozen_sales_records"]=[]
	for id: StringName in run.get_released_game_ids(): out.frozen_sales_records.append(run.get_released_game_sales(id))
	out.valid=out.errors.is_empty()
	game.queue_free()
	await process_frame
	return out

func _studio_state(game: Control) -> Dictionary:
	var run: RunState=game.run_state
	var result:=_state(game)
	result["year"]=run.get_current_year()
	result["owned_ids"]=run.get_owned_feature_ids()
	result["qualifying_count"]=0
	result["familiarity"]={}
	for id: StringName in run.get_owned_feature_ids(): result.familiarity[str(id)]=run.get_feature_familiarity(id)
	for id: StringName in run.get_released_game_ids():
		var review: Dictionary=run.get_release_metadata(id).review
		if int(review.scope)>=int(review.required_scope): result.qualifying_count+=1
	result["in_studio"]=game.get("_active_phase") is StudioPhase
	return result

func _visit(game: Control,out: Dictionary,reason: String) -> void:
	var before:=_studio_state(game)
	var studio: StudioPhase=game.get("_active_phase")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	(studio.get("_feature_store") as FeatureStore).hide()
	if before!=_studio_state(game): out.errors.append("passive_store_changed_state")
	before["reason"]=reason
	out.studio_visits.append(before)

func _shop(game: Control,out: Dictionary) -> void:
	var run: RunState=game.run_state
	var reserve:=200000 if era_policy=="cautious" else 180000
	# Actual Primitive ownership first, aiming at enough finite printed Scope.
	var ids: Array=run.get("_feature_definitions").keys()
	ids.sort()
	for id: StringName in ids:
		if int(run.get_starter_pool_summary().scope)>=33: break
		var offer:=run.get_primitive_reserve_offer(id)
		if offer.is_empty() or offer.owned: continue
		if int(offer.price_cents)+reserve>run.get_cash_cents(): continue
		var before:=_state(game)
		var success:=run.purchase_primitive_reserve_feature(id)
		out.purchases.append({"id":str(id),"kind":"reserve","quote":offer,"success":success,"before":before,"after":_state(game)})
		if not success: out.errors.append("reserve_purchase")
		_visit(game,out,"reserve_purchase")
	if run.get_completed_run_cycles()<first_store_cycle: return
	var offers: Array[Dictionary]=[]
	for entry: Dictionary in FeatureStoreCatalog.entries():
		var offer:=run.get_feature_store_offer(entry.id)
		if not offer.owned and offer.unlocked and int(offer.price_cents)+reserve<=run.get_cash_cents(): offers.append(offer)
	offers.sort_custom(func(a:Dictionary,b:Dictionary):return int(a.price_cents)<int(b.price_cents) if a.price_cents!=b.price_cents else str(a.id)<str(b.id))
	if offers.is_empty(): return
	var quote:=offers[0]
	var before:=_state(game)
	var success:=run.purchase_feature(quote.id)
	out.purchases.append({"id":quote.id,"kind":"store","quote":quote,"success":success,"before":before,"after":_state(game)})
	if not success: out.errors.append("store_purchase")
	_visit(game,out,"store_purchase")

func _develop_game(game: Control,policy: String,focus: String,mode: String,seed_value: int,number: int,out: Dictionary) -> bool:
	await process_frame
	var project: ProjectState=game.project_state
	var run: RunState=game.run_state
	active_project=project
	var design: DesignPhase=game.get("_active_phase")
	design.get("_deal_rng").seed=seed_value+1
	design.get("_finalization_rng").seed=seed_value+2
	if focus=="sound": design.set_priority_distribution(_core_priorities(true))
	if not design.get_workspace().overlay.commit_draft(): return false
	var dh:=2 if policy=="cautious" else 4 if policy=="ordinary" else 6
	var ah:=3 if policy=="cautious" else 6 if policy=="ordinary" else 8
	var bh:=2 if policy=="cautious" else 4 if policy=="ordinary" else 6
	for hand in range(dh):
		if not _production_hand(design,project,run,policy,focus,"design",number,out):
			out.blockers.append({"phase":"design","game":number,"hand":hand+1,"state":_state(game)}); return false
		if hand==1 and policy!="cautious":
			var before:=_state(game)
			var success:=design.commit_priority_distribution(_core_priorities(false) if focus=="sound" else _core_adjustment())
			out.actions.append({"phase":"design_priority","success":success,"before":before,"after":_state(game)})
	design.call("_on_proceed_to_alpha_pressed")
	if not game.get("_active_phase") is AlphaPhase: out.errors.append("alpha_transition");return false
	var alpha: AlphaPhase=game.get("_active_phase")
	alpha.get("_deal_rng").seed=seed_value+3
	alpha.get("_finalization_rng").seed=seed_value+4
	if focus=="sound": alpha.set_priority_distribution(_core_priorities(true))
	if not alpha.get_workspace().overlay.commit_draft(): return false
	for hand in range(ah):
		if not _production_hand(alpha,project,run,policy,focus,"alpha",number,out):
			out.blockers.append({"phase":"alpha","game":number,"hand":hand+1,"state":_state(game)});return false
	alpha.request_proceed_to_beta()
	if game.get("_active_phase") is AlphaPhase and alpha.get_node("%UnderScopeDialog").visible: alpha.get_node("%UnderScopeDialog").confirmed.emit()
	if not game.get("_active_phase") is BetaPhase:out.errors.append("beta_transition");return false
	var beta: BetaPhase=game.get("_active_phase")
	beta.get("_deal_rng").seed=seed_value+5
	beta.get("_insight_rng").seed=seed_value+6
	beta.set_priority_distribution(_beta_priorities(mode))
	if not beta.get_workspace().overlay.commit_draft(): return false
	for hand in range(bh):
		if not _beta_hand(beta,project,run,policy,mode,number,out):out.errors.append("beta_hand");return false
	game.set("_controlled_review_roll",-1)
	game.get("_review_rng").seed=seed_value+7
	var before:=_state(game)
	var success:=beta.request_launch()
	if not success:success=beta.confirm_launch_for_verification()
	out.actions.append({"phase":"launch","game":number,"success":success,"before":before,"after":_state(game)})
	return success and game.get("_active_phase") is StudioPhase

func _choose_production(cards: Array[CardData],project: ProjectState,run: RunState,policy: String,focus: String) -> Array[int]:
	var best:=-INF
	var selected: Array[int]=[]
	var stats: Array[StringName]=[&"graphics",&"sound",&"technology",&"design"]
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand: Array[CardData]=[cards[a],cards[b],cards[c],cards[d]]
					if run.primitive_feature_hand_cost_cents(hand)>run.get_cash_cents():continue
					var same:=hand.all(func(x:CardData):return x.primary_stat==hand[0].primary_stat)
					if policy=="cautious" and guided_target.is_empty():return [a,b,c,d]
					var scope:=0
					var core:=0.0
					for x: CardData in hand:
						scope+=x.scope
						var weight:=float(project.get_genre_ratios()[stats.find(x.primary_stat)])/25.0 if era_policy=="synergy" else 1.0
						core+=x.primary_value*weight
						if x.secondary_value>0:core+=x.secondary_value*(float(project.get_genre_ratios()[stats.find(x.secondary_stat)])/25.0 if era_policy=="synergy" else 1.0)
					var value:=mini(scope,maxi(0,project.get_required_scope()-project.get_current_scope()))*4.0+core*(1.5 if same and era_policy=="synergy" else 1.0)
					if same:value+=10.0 if era_policy=="synergy" else 2.0
					if same and hand[0].primary_stat==guided_target:value+=100000
					if value>best:best=value;selected=[a,b,c,d]
	return selected

func _choose_beta(cards: Array[CardData],project: ProjectState,mode: String,policy: String) -> Array[int]:
	if policy=="cautious":return [0,1,2,3]
	if mode=="qa":return super._choose_beta(cards,project,mode,policy)
	var best:=-INF
	var result: Array[int]=[]
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var value:=0.0
					var marketing:=0
					for i in [a,b,c,d]:
						var card:=cards[i]
						if card.beta_category==&"marketing":value+=card.beta_value*3;marketing+=1
						elif card.id==&"debug" and project.get_known_bugs()>0:value+=12
						elif card.id==&"search_for_bugs":value+=5
					if marketing==4:value+=8
					if value>best:best=value;result=[a,b,c,d]
	return result
