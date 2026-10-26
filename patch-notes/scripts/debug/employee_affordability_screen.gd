extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
const Session=preload("res://scripts/simulation/campaign_session.gd")
var output: String
var rows: Array=[]
var stronger := false
var contracts: Dictionary={}
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--stronger":stronger=true
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	for hands in [2,3]:
		for seed_value in [4417,61001]:
			for arm in ["none","qa","both"]:
				contracts={}
				var recipe={"schema_version":1,"studio_id":"wage_%d_%d"%[hands,seed_value],"studio_name":"Wage Screen","specialty":"action","traits":[],"seed":str(seed_value),"employee_trial":true}
				var session=Factory.create_fresh_session(recipe,catalog)
				var choose=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Screen","selection":"features_first","hands":{"design":hands,"alpha":hands,"beta":2}})
				var tape=Replay.begin(session)
				var row={"hands":hands,"seed":seed_value,"arm":arm,"minimum_cash":session.run.get_cash_cents(),"hired":false,"course_spend":0,"commands":0,"boundary":{},"blocked":"","releases":[],"payroll":0}
				for n in range(240):
					var view: Dictionary=session.observation()
					var decision: Dictionary
					if session.in_studio and view.releases.size()>=2 and not row.hired:
						if row.boundary.is_empty():row.boundary={"cycle":view.run_cycle,"cash":view.cash_cents,"finance":view.studio_actions.finance}
						var role: StringName=&"qa" if arm!="none" and not session.run.get_employee_hire_quote(&"qa").is_empty() else &"production"
						var quote: Dictionary=session.run.get_employee_hire_quote(role)
						if arm!="none" and not quote.is_empty() and (role==&"qa" or arm=="both"):
							decision={"type":&"hire","payload":{"quote":quote}}
						else:
							row.hired=true
							if arm!="none" and not session.run.get_employees().employees.values().any(func(e):return e.type==&"qa"):row.blocked="No affordable QA hire at Game 2";break
							continue
					elif row.hired and arm!="none" and session.in_studio and not session.run.get_qa_course_quote(&"mixed").is_empty():
						decision={"type":&"course","payload":{"quote":session.run.get_qa_course_quote(&"mixed")}};row.course_spend+=15000
					elif row.hired and arm!="none" and session.in_studio and not session.run.get_qa_course_quote(&"pure").is_empty():
						decision={"type":&"course","payload":{"quote":session.run.get_qa_course_quote(&"pure")}};row.course_spend+=15000
					else:decision=choose_stronger(view,choose) if stronger else choose.call(view)
					var result: Dictionary=Replay.record(session,tape,session.command(decision.type,decision.get("payload",{})))
					row.commands+=1;row.minimum_cash=mini(row.minimum_cash,session.run.get_cash_cents())
					if not result.ok:row.blocked=str(result.get("error","Rejected"));row.failed_action=Replay.freeze(decision);break
					if session.in_studio and session.run.get_released_game_ids().size()>=6:break
				row.end_cycle=session.run.get_completed_run_cycles();row.cash=session.run.get_cash_cents();row.finance=session.run.get_studio_finance_report();row.employees=Replay.freeze(session.run.get_employees())
				row.releases=Replay.freeze(session.observation().releases);row.release_count=row.releases.size()
				row.payroll=row.finance.get("monthly_payroll_cents",0)
				row.tape=Replay.freeze(tape)
				rows.append(row)
				print("WAGE_SCREEN hands=%d seed=%d arm=%s releases=%d cash=%d blocked=%s"%[hands,seed_value,arm,row.release_count,row.cash,row.blocked])
	var report={"source":Replay.source_identity(),"rows":rows,"stronger_policy":stronger,"scope":"Legal fresh starts; paired fixed declared policy. Stronger arm adds visible hand selection, free pre-phase priorities and at most one existing Contract per inter-release window. No loans/rich fixtures; Contract receipts reported separately, not recurring revenue proof. Failed routes retained. Not human balance approval."}
	if not output.is_empty():FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"	"))
	quit(0)

func choose_stronger(view: Dictionary, fallback: Callable) -> Dictionary:
	if view.phase==&"contract":
		if view.contract.completed:return {"type":&"dismiss_contract"}
		var kind:=&"begin" if view.contract.candidates.is_empty() else &"play"
		var payload: Dictionary={}
		if kind==&"play":
			var cards: Array=view.contract.candidates.duplicate(true)
			cards.sort_custom(func(a,b):return a.scope>b.scope if a.scope!=b.scope else a.token<b.token)
			payload.candidate_ids=cards.slice(0,4).map(func(c):return int(c.token))
		return {"type":&"contract","payload":{"request":{"schema_version":1,"type":kind,"offer_id":view.contract.offer_id,"hand_count":view.contract.hand_count,"sequence":view.contract.sequence,"run_cycle":view.contract.run_cycle,"payload":payload}}}
	if view.phase==&"studio" and view.releases.size()>0 and not contracts.has(view.releases.size()) and not view.studio_actions.contract_offers.is_empty():
		contracts[view.releases.size()]=true
		return {"type":&"accept_contract","payload":view.studio_actions.contract_offers[0]}
	var decision: Dictionary=fallback.call(view)
	if view.phase==&"studio":return decision
	var d: Dictionary=view.development
	var distribution: Dictionary={CardData.BETA_CATEGORY_QA:35,CardData.BETA_CATEGORY_MARKETING:50,CardData.BETA_CATEGORY_INSIDER:15} if d.phase=="beta" else {0:30,1:20,2:30,3:20}
	if not d.active and not d.finalized and d.priorities!=distribution:
		return {"type":&"development","payload":{"request":{"schema_version":1,"type":&"priorities","project_id":view.project_id,"phase":d.phase,"sequence":d.sequence,"project_cycle":d.project_cycle,"run_cycle":d.run_cycle,"payload":{"distribution":distribution}}}}
	if decision.get("type")==&"development" and decision.payload.request.type==&"play":
		var cards: Array=d.candidates.duplicate(true)
		if d.phase=="beta":
			cards.sort_custom(func(a,b):
				var av: float=_beta_value(a,d);var bv: float=_beta_value(b,d)
				return av>bv if av!=bv else a.token<b.token)
		else:
			cards.sort_custom(func(a,b):
				var av: int=int(a.primary_value)+int(a.secondary_value)+int(a.scope)*4;var bv: int=int(b.primary_value)+int(b.secondary_value)+int(b.scope)*4
				return av>bv if av!=bv else a.token<b.token)
		decision.payload.request.payload.candidate_ids=cards.slice(0,4).map(func(c):return int(c.token))
	return decision
func _beta_value(c: Dictionary,d: Dictionary) -> float:
	if c.definition=="playtest_rival_games":return 20.0
	if c.beta_category==str(CardData.BETA_CATEGORY_MARKETING):return 8.0+float(c.beta_value)
	if c.definition=="debug":return 7.0 if d.known_bugs>0 else 0.0
	if c.definition=="search_for_bugs":return 6.0 if d.known_bugs==0 and d.fixed_bugs==0 else 1.0
	return 0.5
