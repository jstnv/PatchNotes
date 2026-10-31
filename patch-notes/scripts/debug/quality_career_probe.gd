extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Policy:=preload("res://scripts/market/rival_career_policy.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const Historical:=preload("res://scripts/market/historical_standard_trial.gd")
const Market:=preload("res://scripts/market/market_transaction_trial.gd")
var trial: RunState
func arg(prefix: String,default_value: String="") -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return default_value
func market(_owner: StringName,cycle: int) -> Dictionary:
	var source:=Historical.source_from_run(trial)
	if not source.is_empty() and cycle>=Historical.effective_cycle(source):return Historical.snapshot(source,cycle)
	return Market.neutral()
func _initialize() -> void:
	await process_frame
	var genre:=arg("--genre=","action");var seed:=arg("--seed=","5607");var output:=arg("--output=")
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"career-"+genre+"-"+seed,"studio_name":"Career "+genre,"specialty":genre,"traits":["family_funding","cult_following"],"seed":seed,"rival_founder_profile":"rival-founder-active-1977-v2"},catalog)
	if session==null:push_error("No ordinary founder");quit(2);return
	trial=session.run;trial._market_provider=market
	var policy:=Policy.new(StringName(genre));var tape:=Replay.begin(session);var actions: Array=[];var issue:=""
	for i in range(600):
		if trial.get_completed_run_cycles()>=72:break
		var view: Dictionary=session.observation();var choice:=policy.choose(session,view)
		if choice.get("type")==&"blocked":issue=str(choice.payload.reason);break
		var before_cycle:=trial.get_completed_run_cycles()
		var result:=Replay.record(session,tape,session.command(StringName(choice.type),choice.get("payload",{})))
		policy.observe_result(view,choice,result)
		actions.append({"type":str(choice.type),"phase":str(view.phase),"cycle":trial.get_completed_run_cycles(),"cash":trial.get_cash_cents(),"ok":result.get("ok",false),"error":result.get("error",""),"events":result.get("events",[]),"discovered":result.get("discovered",-1),"fixed":result.get("fixed",-1)})
		if not result.ok:issue=str(result.get("error","Rejected"));break
	var releases: Array=[]
	for id in trial.get_released_game_ids():releases.append({"id":str(id),"metadata":trial.get_release_metadata(id),"sales":trial.get_released_game_sales(id)})
	var report:={"source":Replay.source_identity(),"genre":genre,"seed":seed,"issue":issue,"cycle":trial.get_completed_run_cycles(),"phase":str(session.phase()),"cash":trial.get_cash_cents(),"scope":policy.scope(trial),"releases":releases,"actions":actions,"policy_state":policy.state,"finance":trial._studio_finance,"rng":trial.random_streams.snapshot()}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));Replay.save_tape(output+".tape.json",tape)
	print("QUALITY_CAREER "+JSON.stringify({"issue":issue,"cycle":report.cycle,"cash":report.cash,"scope":report.scope,"reviews":releases.map(func(r):return r.sales.review_tenths)}));quit(0 if issue.is_empty() and report.cycle==72 else 1)
