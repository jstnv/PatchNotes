## Read-only legal first-unlock/late-ownership capture. No proposed offer added.
extends "res://analysis/task21_route_v1.gd"
var marketing_policy := false
var beta_hands := 0
func _run() -> void:
	for index in range(int(_arg("--count=","6"))):
		live_cycles=[]
		marketing_policy=false
		beta_hands=0
		random_inputs.seed=290929000+index
		var row := await _one("synergy",index)
		rows.append(row)
		if not row.valid: failures+=1
	var file := FileAccess.open("res://design-logs/task20-v1/routes_"+_arg("--neon=","0")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"rows":rows},"  "))
	quit(0 if failures==0 else 1)
func _beta_hand(phase: BetaPhase, project: ProjectState, run: RunState, policy: String, mode: String, number: int, out: Dictionary) -> bool:
	if number==2 and _arg("--neon=","0")=="1":
		beta_hands+=1
		if beta_hands==7:
			var before := _state_for(project,run)
			var changed := phase.commit_priority_distribution({&"qa":25,&"marketing":50,&"insider":25})
			out.actions.append({"phase":"neon_marketing_priorities","success":changed,"before":before,"after":_state_for(project,run)})
			marketing_policy=true
		var success := super._beta_hand(phase,project,run,policy,"marketing" if marketing_policy else mode,number,out)
		if beta_hands==12:
			for extra in range(8):
				if project.get_marketing_output()>=25: break
				if not super._beta_hand(phase,project,run,policy,"marketing",number,out): return false
			marketing_policy=false
		return success
	return super._beta_hand(phase,project,run,policy,mode,number,out)
func _choose_beta(cards: Array[CardData], project: ProjectState, mode: String, policy: String) -> Array[int]:
	if not marketing_policy: return super._choose_beta(cards,project,mode,policy)
	var best := -INF
	var chosen: Array[int] = []
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand: Array[CardData]=[cards[a],cards[b],cards[c],cards[d]]
					var value := 0.0
					var marketing := 0
					for card: CardData in hand:
						if card.beta_category==&"marketing": value+=card.beta_value*10; marketing+=1
						elif card.id==&"debug" and project.get_known_bugs()>0: value+=3
						elif card.id==&"search_for_bugs": value+=1
					if marketing==4: value+=100
					if value>best: best=value; chosen=[a,b,c,d]
	return chosen
