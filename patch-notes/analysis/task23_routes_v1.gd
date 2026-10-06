## Five native releases; hypothetical publishers are never installed.
extends "res://analysis/lifespan_verify_routes_v2.gd"
var neon_trial:=false
var marketing_policy:=false
var beta_calls:=0
func _run() -> void:
	era_policy="synergy"
	# No campaign arm: inserted hypothetical Contract cycles must not move a
	# recorded campaign out of its legal first-half window.
	arm="next"
	experiment="task23"
	route_case=0
	max_games=5
	action_limit=300
	era_cap=0
	first_store_cycle=0
	neon_trial=_arg("--neon=","0")=="1"
	random_inputs.seed=240930000
	var result:=await _current_route(0)
	result["ledger_checks"]=ledger_checks
	result["row_checks"]=row_checks
	result["discrepancies"]=discrepancies
	result["captures"]=final_captures
	FileAccess.open("res://design-logs/task23-v1/route_%s.json"%("neon" if neon_trial else "crown"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print("TASK23 native releases ",result.releases.size()," failures ",discrepancies.size())
	quit(0 if result.valid and result.releases.size()==5 and discrepancies.is_empty() else 1)

func _beta_hand(phase:BetaPhase,project:ProjectState,run:RunState,policy:String,mode:String,number:int,out:Dictionary)->bool:
	if neon_trial and number==2:
		beta_calls+=1
		if beta_calls==7:
			var before:=_state_for(project,run)
			var changed:=phase.commit_priority_distribution({&"qa":25,&"marketing":50,&"insider":25})
			out.actions.append({"phase":"neon_marketing_priorities","success":changed,"before":before,"after":_state_for(project,run)})
			marketing_policy=true
		var success:=super._beta_hand(phase,project,run,policy,"marketing" if marketing_policy else mode,number,out)
		if beta_calls==12:
			for extra in range(8):
				if project.get_marketing_output()>=25:break
				if not super._beta_hand(phase,project,run,policy,"marketing",number,out):return false
			marketing_policy=false
		return success
	return super._beta_hand(phase,project,run,policy,mode,number,out)

func _choose_beta(cards:Array[CardData],project:ProjectState,mode:String,policy:String)->Array[int]:
	if not marketing_policy:return super._choose_beta(cards,project,mode,policy)
	var best:=-INF
	var chosen:Array[int]=[]
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand:Array[CardData]=[cards[a],cards[b],cards[c],cards[d]]
					var value:=0.0
					var marketing:=0
					for card:CardData in hand:
						if card.beta_category==&"marketing":value+=card.beta_value*10;marketing+=1
						elif card.id==&"debug" and project.get_known_bugs()>0:value+=3
						elif card.id==&"search_for_bugs":value+=1
					if marketing==4:value+=100
					if value>best:best=value;chosen=[a,b,c,d]
	return chosen
