## Analysis-only legal starter purchases and matched shared-roster controls.
extends "res://analysis/genre_targets_v1.gd"

func _core_target(project: ProjectState, index: int) -> float:
	if _arg("--arm=", "buy") != "buy": return 33.0
	return super._core_target(project,index)

func _starter_buy(run: RunState, out: Dictionary) -> void:
	var offers: Array = []
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		var quote := run.get_primitive_reserve_offer(entry.id)
		if not quote.owned: offers.append(quote)
	offers.sort_custom(func(a: Dictionary,b: Dictionary):
		var left := int(a.scope)*int(b.price_cents)
		var right := int(b.scope)*int(a.price_cents)
		return left>right if left!=right else str(a.id)<str(b.id))
	var spent := 0
	for offer: Dictionary in offers:
		if int(run.get_starter_pool_summary().scope)>=33: break
		if spent+int(offer.price_cents)>150000: continue
		var before := run.get_cash_cents()
		var ok := run.purchase_starter_feature(offer.id)
		out.purchases.append({"id":offer.id,"quote":offer,"success":ok,"cash_before":before,"cash_after":run.get_cash_cents(),"cycle":run.get_completed_run_cycles()})
		if not ok: out.errors.append("starter purchase rejected"); break
		spent += int(offer.price_cents)
	out["spent"] = spent

func _run() -> void:
	var arm := _arg("--arm=", "buy")
	var results: Array = []
	var genres: Array = PrimitivePredevelopment.catalog().genres
	for genre: Dictionary in genres:
		for policy: String in ["ordinary", "synergy"]:
			if arm!="buy" and policy!="ordinary": continue
			for pace: String in ["early", "slow"]:
				for seed_value: int in [1104,2208,3312]:
					era_policy=policy
					release_band=pace
					declared_seed=seed_value
					project_number=0
					random_inputs.seed=seed_value
					var specialty := StringName(genre.id) if arm=="buy" else StringName(arm)
					var out := {"arm":arm,"genre":genre.id,"specialty":specialty,"policy":policy,"pace":pace,"seed":seed_value,"actions":[],"purchases":[],"errors":[],"blockers":[],"stop":"","spent":0}
					var game: Control=load("res://scenes/gameplay.tscn").instantiate()
					var run:=RunState.new()
					run.initialize_cash(0)
					for i in range(RunRandom.STREAMS.size()): run.random_streams.stream(RunRandom.STREAMS[i]).seed=seed_value+i*100
					if not run.create_studio_with_traits("Genre controls",specialty,[]): out.errors.append("creation failed")
					game.run_state=run
					root.add_child(game)
					await process_frame
					out["initial"]=_state(game)
					out["initial_owned"]=run.get_owned_feature_ids()
					if arm=="buy": _starter_buy(run,out)
					out["owned"]=run.get_owned_feature_ids()
					out["starter_summary"]=run.get_starter_pool_summary()
					out["before_project"]=_state(game)
					var ok: bool=out.errors.is_empty() and _begin_game(game,"Genre controls",StringName(genre.id),out)
					if ok: ok=await _develop_game(game,policy,"mixed","qa",seed_value,1,out)
					out["launched"]=ok
					out["ledger_valid"]=StudioFinanceLedger._is_valid(run._studio_finance)
					out["final"]=_state(game)
					if ok:
						var project: ProjectState=game.project_state
						var review:=project.get_review_result()
						var scores: Array=[]
						for i in range(4): scores.append(project.get_core_score(i))
						out["scores"]=scores
						out["production"]=review.get_production_rating()
						out["review"]=review.get_final_review()
						out["scope_factor"]=review.get_scope_completion()
						out["bug_factor"]=review.get_bug_multiplier()
						out["variance"]=review.get_variance_modifier()
						out["cycles"]=project.get_current_cycle()
					results.append(out)
					print("GENRE2 ",arm," ",genre.id," ",policy," ",pace," ",seed_value," launched=",ok)
					game.queue_free()
					await process_frame
	FileAccess.open("res://../docs/codex/findings/genre-targets-v2/%s.json" % arm,FileAccess.WRITE).store_string(JSON.stringify(results))
	quit(0 if results.all(func(row: Dictionary):return row.launched and row.ledger_valid and row.errors.is_empty()) else 1)
