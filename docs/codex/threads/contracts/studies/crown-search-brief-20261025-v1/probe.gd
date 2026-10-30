extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Session=preload("res://scripts/simulation/campaign_session.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func _initialize() -> void:go.call_deferred()
func go() -> void:
	var input:="";var output:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--checkpoint="):input=arg.trim_prefix("--checkpoint=")
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var fresh=Factory.create_fresh_session({"schema_version":1,"studio_id":"crown-probe-fresh","studio_name":"Probe","specialty":"action","traits":[],"seed":"4417"},catalog)
	check(fresh.run.get_contract_search_quote(&"crown_quill",&"brief").is_empty(),"Review7 required in fresh Studio")
	var s=Session.new()
	check(s.restore_checkpoint(JSON.parse_string(FileAccess.get_file_as_string(input)),catalog,fresh.snapshots),"Legal earned prefix restores")
	if s.run==null:quit(1);return
	var before=Replay.state(s)
	var rep: int=s.run.get_publisher_relationships()[&"crown_quill"].reputation_bp
	check(s.run.get_crown_brief_offer().is_empty(),"Qualifying releases do not issue free Crown Briefs")
	var start_cycle: int=s.run.get_completed_run_cycles()
	var q: Dictionary=s.run.get_contract_search_quote(&"crown_quill",&"brief")
	check(not q.is_empty() and q.terms.cash_cents==0 and q.terms.required_hands==2,"Frozen zero-cash two-hand terms")
	var bad=q.duplicate(true);bad.terms.scope=8
	check(not s.run.search_contracts(bad) and Replay.state(s)==before,"Changed terms rejected atomically")
	check(s.run.get_contract_search_quote(&"crown_quill",&"commission").is_empty(),"No Crown commission activation")
	check(s.execute(s.command(&"search_contracts",{"quote":q})).ok,"Paid Crown Search")
	check(s.run.get_completed_run_cycles()==start_cycle+1 and s.run.get_publisher_relationships()[&"crown_quill"].reputation_bp==rep,"Search costs one cycle and zero standing")
	var found: Dictionary=s.run.get_crown_brief_offer()
	check(not found.is_empty() and found.source_release_id.is_empty(),"Search source is not a release")
	check(not RunState.ContractSearch.source(s.run,found.offer_id,&"brief",&"crown_quill").is_empty(),"Trusted Crown receipt")
	check(RunState.ContractSearch.source(s.run,found.offer_id,&"brief").is_empty(),"Publisher isolation")
	before=Replay.state(s)
	check(s.run.get_contract_search_quote(&"crown_quill",&"brief").is_empty() and not s.run.search_contracts(q) and Replay.state(s)==before,"Pending/stale rejection atomic")
	var d=RunState.ContractSearch.data(s.run).duplicate(true)
	check(RunState.ContractSearch.valid(d),"Search finance provenance valid")
	d.contract_search.receipts[-1].terms.scope=8
	check(not RunState.ContractSearch.valid(d),"Tampered receipt rejected")
	var pending=s.export_checkpoint();var restored=Session.new()
	check(not pending.is_empty() and restored.restore_checkpoint(pending,catalog,fresh.snapshots) and Replay.state(restored)==before,"Pending Search exact Studio restore")
	check(s.execute(s.command(&"accept_contract",{"kind":&"crown_brief","offer_id":found.offer_id,"quote":found})).ok,"Accept exact Crown Brief")
	check(s.run.get_completed_run_cycles()==start_cycle+1,"Acceptance free")
	check(s.execute(s.command(&"contract",{"request":s.contract.command(&"begin")})).ok,"Begin Brief")
	var last: Dictionary={}
	for hand in range(2):
		var ids: Array[int]=[]
		for i in range(4):ids.append(int(s.contract.candidate_ids[i]))
		last=s.command(&"contract",{"request":s.contract.command(&"play",{"candidate_ids":ids})})
		check(s.execute(last).ok,"Legal hand %d"%hand)
		if hand==0:check(s.run.get_publisher_relationships()[&"crown_quill"].reputation_bp==rep,"No first-hand award")
	var state: ContractState=s.contract._state
	check(state.is_completed(),"Two hands complete")
	if not state.is_completed():quit(1);return
	var result=state.get_result()
	var requested: int=1000*mini(10000*result.get_completion_numerator()/66,result.get_challenge_grade_bp())/10000
	var actual: int=s.run.get_publisher_relationships()[&"crown_quill"].reputation_bp
	check(actual==mini(10000,rep+requested),"Unchanged formula and capped actual credit")
	check(result.get_payout_cents()==0 and result.get_promotion()==0 and s.run.get_publisher_relationships()[&"crown_quill"].investment_bp==0,"Zero cash Promotion Investment")
	check(s.run.get_completed_run_cycles()==start_cycle+3,"Search plus Brief exactly3cycles")
	var hand_actions:=0
	for action: Dictionary in s.run._studio_finance.actions:
		if action.source_id==found.offer_id and action.kind==&"contract_hand":
			hand_actions+=1;check(action.direct_delta==0 and action.productive,"Brief hand has no direct currency reward")
	check(hand_actions==2,"Two and only two productive Brief receipts")
	before=Replay.state(s)
	check(not s.execute(last).ok and Replay.state(s)==before,"Duplicate hand cannot settle twice")
	check(s.execute(s.command(&"dismiss_contract")).ok and s.run.get_publisher_relationships()[&"crown_quill"].reputation_bp==actual,"Dismissal no award")
	check(not s.run.get_contract_search_quote(&"crown_quill",&"brief").is_empty(),"Completion permits next paid Search")
	var completed=s.export_checkpoint();var cold=Session.new()
	check(not completed.is_empty() and cold.restore_checkpoint(completed,catalog,fresh.snapshots) and Replay.state(cold)==Replay.state(s),"Completed Brief exact Studio restore")
	if not output.is_empty():FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity(),"requested_bp":requested,"credited_bp":actual-rep},"\t"))
	print("CROWN_SEARCH_PROBE checks=%d failures=%d"%[checks,failures]);quit(failures)
