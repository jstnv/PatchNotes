## Read-only current scene routes. No gameplay edits or invented money/time.
extends "res://analysis/task24_current_v2.gd"
var arm := "next"
var experiment := "main"
func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	arm = _arg("--arm=", "next")
	experiment = _arg("--experiment=", "main")
	max_games = 3
	era_cap = 0
	first_store_cycle = 0
	var index := int(_arg("--case=", "0"))
	random_inputs.seed = 240930000 + index
	live_cycles = []
	var result := await _current_route(index)
	result["arm"] = arm
	result["experiment"] = experiment
	result["budget"] = _arg("--budget=", "normal")
	var path := "res://design-logs/task27-v1/route_%s_%s_%s_%d.json" % [experiment,era_policy,arm,index]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	print("TASK27 route ",path," valid=",result.valid," releases=",result.releases.size())
	quit(0 if result.valid and result.releases.size()==3 else 1)

func _shop(game: Control, out: Dictionary) -> void:
	var run: RunState = game.run_state
	var number: int = out.releases.size()
	if number == 1:
		if experiment == "repeat":
			out["repeat_alignment"] = _align_campaign(game,run.get_released_game_ids()[0])
			out["repeat_preparation"] = _campaign_action(game,run.get_released_game_ids()[0])
		super._shop(game,out)
		return
	if number != 2: return
	out["common_alignment"] = _align_campaign(game,run.get_released_game_ids()[0 if experiment=="repeat" else 1])
	var before := _state(game)
	var records: Array = []
	for id: StringName in run.get_released_game_ids(): records.append(run.get_released_game_sales(id))
	var decision := {"before":before,"records":records,"arm":arm,"success":true}
	if arm in ["newer","older"]:
		decision["action"] = _campaign_action(game,run.get_released_game_ids()[1 if arm=="newer" else 0])
	elif arm == "store":
		var offers: Array[Dictionary] = []
		for entry: Dictionary in FeatureStoreCatalog.entries():
			var quote := run.get_feature_store_offer(entry.id)
			if not quote.owned and quote.unlocked and int(quote.price_cents)+180000<=run.get_cash_cents(): offers.append(quote)
		offers.sort_custom(func(a,b):return int(a.price_cents)<int(b.price_cents) if a.price_cents!=b.price_cents else str(a.id)<str(b.id))
		if offers.is_empty(): decision["action"]={"success":false,"reason":"no unlocked Store offer affordable with 180000-cent production reserve"}
		else:
			decision["action"]={"quote":offers[0],"success":run.purchase_feature(offers[0].id)}
	else: decision["action"]={"success":true,"reason":"begin Game 3 immediately; no free waiting"}
	decision["after"] = _state(game)
	out["opportunity"] = decision
	out.actions.append({"phase":"task27_studio_choice","decision":decision})

func _align_campaign(game: Control,id: StringName) -> Array:
	var steps: Array = []
	var run: RunState = game.run_state
	for i in range(2):
		if run.get_post_launch_campaign_offer(id).eligible: break
		var offers: Array[Dictionary] = []
		for entry: Dictionary in FeatureStoreCatalog.entries():
			var quote := run.get_feature_store_offer(entry.id)
			if not quote.owned and quote.unlocked and int(quote.price_cents)+180000<=run.get_cash_cents(): offers.append(quote)
		offers.sort_custom(func(a,b):return int(a.price_cents)<int(b.price_cents) if a.price_cents!=b.price_cents else str(a.id)<str(b.id))
		if offers.is_empty():
			steps.append({"success":false,"reason":"no affordable real Store action to reach campaign window"})
			break
		var before := _state(game)
		var success := run.purchase_feature(offers[0].id)
		steps.append({"quote":offers[0],"success":success,"before":before,"after":_state(game)})
		if not success: break
	return steps

func _campaign_action(game: Control,id: StringName) -> Dictionary:
	var run: RunState = game.run_state
	var quote := run.get_post_launch_campaign_offer(id)
	var before := _state(game)
	var success := run.purchase_post_launch_campaign(id,run.get_completed_run_cycles())
	return {"id":id,"quote":quote,"success":success,"before":before,"after":_state(game),"record_after":run.get_released_game_sales(id)}

func _choose_production(cards: Array[CardData],project: ProjectState,run: RunState,policy: String,focus: String) -> Array[int]:
	if _arg("--choice=", "native") != "ordinary": return super._choose_production(cards,project,run,policy,focus)
	var saved := era_policy
	era_policy = "ordinary"
	var choice := super._choose_production(cards,project,run,"ordinary",focus)
	era_policy = saved
	return choice

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
		if _arg("--budget=", "normal") == "fixed": limit = 10 if label == "design" else 14
		for hand in range(limit):
			if _arg("--budget=", "normal") != "fixed" and policy in ["synergy","high","repeat"] and hand>=3:
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

