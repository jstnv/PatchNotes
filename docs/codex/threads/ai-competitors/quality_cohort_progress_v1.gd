## Offline shared-month certification. No player saves, spawned cash or RNG peeks.
extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const Book:=preload("res://scripts/market/rival_standard_book.gd")
const Decision:=preload("res://scripts/market/rival_career_decision.gd")
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const GENRES:=["action","adventure","role_playing","strategy","simulation","puzzle","sports","racing"]
const NAMES:=["Arcade Foundry","Wayfinder Works","Mythweaver Games","Tactical Circuit","Copperworks Studio","Prism Logic","Victory Lane","Redline Software"]
var sessions: Dictionary={}
var frozen: Dictionary={}
func arg(prefix: String,fallback: String="") -> String:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return fallback
func market(_owner: StringName,_cycle: int) -> Dictionary:return frozen.duplicate(true)
func _initialize() -> void:
	await process_frame
	var generation_source:=Replay.source_identity()
	var output:=arg("--output=");var seed:=arg("--seed=","5607");var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog();var policies: Dictionary={};var tapes: Dictionary={};var memories: Dictionary={};var actions: Array=[];var issues: Array=[]
	for i in range(8):
		var id:=StringName("incumbent-"+GENRES[i].replace("_","-"));var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":str(id),"studio_name":NAMES[i],"specialty":GENRES[i],"traits":["family_funding","cult_following"],"seed":seed,"rival_founder_profile":"rival-founder-active-1977-v2"},catalog)
		if session==null:issues.append("Founder unavailable "+str(id));break
		sessions[id]=session;session.run._market_provider=market;memories[id]={};policies[id]=Decision.new(session,memories[id]);tapes[id]=Replay.begin(session)
	if not arg("--replay=").is_empty():
		_replay_prefix(arg("--replay="),output,policies,tapes,memories)
		return
	var classifier:=RivalWorld.new()
	for tick in range(1,73):
		print("QUALITY_TICK "+str(tick))
		if not issues.is_empty():break
		frozen=Book.snapshot(Book.build(sessions,tick),tick)
		if not Book.valid_snapshot(frozen):issues.append("Invalid dated book "+str(tick));break
		for id: StringName in sessions:
			var session: RefCounted=sessions[id];var policy: RefCounted=policies[id]
			for zero in range(64):
				var view: Dictionary=policy.observation(session);var choice: Dictionary=policy.choose(view,policy)
				var wait_reason: String=""
				if choice.get("type")==&"blocked":
					if session.run.get_completed_run_cycles()==tick:break
					wait_reason=str(choice.payload.reason);choice={"type":&"rival_wait","payload":{}}
				var productive: bool=classifier._productive_choice(choice,session)
				if session.run.get_completed_run_cycles()==tick and (productive or tick==72):break
				var result:=Replay.record(session,tapes[id],session.command(StringName(choice.type),choice.get("payload",{})));policy.observe_result(choice,result)
				actions.append({"id":str(id),"tick":tick,"type":str(choice.type),"phase":str(view.phase),"cash":session.run.get_cash_cents(),"ok":result.get("ok",false),"error":result.get("error",""),"wait_reason":wait_reason})
				if not result.ok:issues.append(actions[-1]);break
				if session.run.get_completed_run_cycles()==tick and tick==72:break
			if session.run.get_completed_run_cycles()!=tick:issues.append({"id":str(id),"tick":tick,"reason":"Cycle bound"})
			if not issues.is_empty():break
	var rows: Array=[];var archives: Dictionary={}
	for id: StringName in sessions:
		var session: RefCounted=sessions[id];var releases: Array=[];var archive: Array=[]
		for release: StringName in session.run.get_released_game_ids():
			var m: Dictionary=session.run.get_release_metadata(release);var s: Dictionary=session.run.get_released_game_sales(release)
			releases.append({"id":str(release),"metadata":m,"sales":s})
			archive.append({"id":release,"title":str(m.release_title),"year":int(m.release_year),"release_cycle":int(m.release_cycle),"genre":StringName(m.genre),"theme":StringName(m.theme),"review_tenths":int(s.review_tenths),"cores":m.review.cores.duplicate()})
		archives[id]=archive
		rows.append({"id":str(id),"genre":str(session.run.get_studio_specialty()),"cycle":session.run.get_completed_run_cycles(),"phase":str(session.phase()),"cash":session.run.get_cash_cents(),"scope":policies[id].policy.scope(session.run),"releases":releases,"policy":memories[id],"rng":session.run.random_streams.snapshot()})
		Replay.save_tape(output+"."+str(id)+".tape.json",tapes[id])
	var fixture: Dictionary={}
	if issues.is_empty():
		var player: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"opening-player","studio_name":"Opening verifier","specialty":"action","traits":[],"seed":"31"},catalog)
		var world:=RivalWorld.new()
		if not world.initialize_projected_cohort(player.run,sessions,archives):issues.append("January projection rejected")
		else:
			world.policy_states=memories.duplicate(true);world.market_snapshot=Book.snapshot(Book.build(sessions,72),0,72)
			var codec:=Codec.new();var payload:=codec.capture(world);var p:=StudioCheckpoint.new().capture(player.run)
			if payload.is_empty():issues.append("Projection capture "+codec.error)
			else:
				fixture={"player":p,"world":payload}
				var restored:=codec.restore(payload,p,player.run,catalog)
				if restored==null:issues.append("Projection restore "+codec.error)
	if Replay.source_identity()!=generation_source:issues.append("Generation source changed")
	for tape: Dictionary in tapes.values():
		if tape.source_identity!=generation_source:issues.append("Tape generation source changed")
	if issues.is_empty():
		var certificate:={"format":"certified-rival-opening-v1","source_identity":generation_source,"generation_source_identity":generation_source,"rng_algorithm":RunRandom.ALGORITHM,"engine_version":Engine.get_version_info().string,"seed":seed,"fixture":fixture}
		certificate.integrity=Replay.digest(certificate)
		FileAccess.open(output+".opening.json",FileAccess.WRITE).store_string(JSON.stringify(certificate,"\t"))
	var result:={"source":Replay.source_identity(),"seed":seed,"issues":issues,"rows":rows,"actions":actions,"fixture":fixture,"basis":Book.build(sessions,72)}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("QUALITY_COHORT "+JSON.stringify({"issues":issues,"rows":rows.map(func(r):return {"genre":r.genre,"cycle":r.cycle,"cash":r.cash,"scope":r.scope,"reviews":r.releases.map(func(t):return t.sales.review_tenths)})}));quit(0 if issues.is_empty() else 1)

func _replay_prefix(path: String,output: String,policies: Dictionary,fresh: Dictionary,memories: Dictionary) -> void:
	var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path));var expected: Dictionary={};var positions: Dictionary={};var issues: Array=[];var checks:=0;var tick:=-1
	if original.get("source")!=Replay.source_identity():issues.append("Replay source mismatch")
	for id: StringName in sessions:
		var tape:=Replay.load_tape(path+"."+str(id)+".tape.json");expected[id]=tape;positions[id]=0
		if tape.is_empty() or tape.get("source_identity")!=Replay.source_identity() or tape.get("engine_version")!=Engine.get_version_info().string or tape.get("rng_algorithm")!=RunRandom.ALGORITHM or tape.get("initial_state")!=fresh[id].initial_state or tape.get("initial_rng")!=sessions[id].run.random_streams.snapshot():issues.append("Replay initial identity "+str(id))
		checks+=1
	for trace: Dictionary in original.get("actions",[]):
		if not issues.is_empty():break
		if int(trace.tick)!=tick:
			tick=int(trace.tick);frozen=Book.snapshot(Book.build(sessions,tick),tick)
		var id:=StringName(trace.id);var session: RefCounted=sessions[id];var policy: RefCounted=policies[id];var index: int=positions[id]
		if index>=expected[id].steps.size():issues.append("Unexpected trace step");break
		var step: Dictionary=expected[id].steps[index];var view: Dictionary=policy.observation(session);var choice: Dictionary=policy.choose(view,policy)
		if choice.get("type")==&"blocked":choice={"type":&"rival_wait","payload":{}}
		var command: Dictionary=session.command(StringName(choice.type),choice.get("payload",{}))
		if command!=step.command:issues.append({"id":str(id),"step":index,"reason":"Policy command mismatch"});break
		checks+=1
		var result:=Replay.record(session,fresh[id],step.command);policy.observe_result(choice,result)
		if not result.ok or Replay.freeze(result)!=step.result or fresh[id].steps[-1].state!=step.state:issues.append({"id":str(id),"step":index,"reason":"Outcome/state/RNG mismatch"});break
		checks+=1;positions[id]=index+1
	var final: Dictionary={}
	for id: StringName in sessions:
		checks+=1
		if positions[id]!=expected[id].get("steps",[]).size() or sessions[id].run.get_completed_run_cycles()!=72:issues.append("Incomplete replay "+str(id))
		final[str(id)]={"steps":positions[id],"state":Replay.digest(Replay.state(sessions[id])),"rng":Replay.freeze(sessions[id].run.random_streams.snapshot()),"policy":memories[id].duplicate(true)}
		for row: Dictionary in original.get("rows",[]):
			if row.id!=str(id):continue
			var memory: Dictionary=row.policy.duplicate(true)
			for field in ["beta_hands","marketing_hands","loan_project"]:memory[field]=int(memory[field])
			checks+=1
			if memory!=memories[id]:issues.append("Decision memory mismatch "+str(id))
	var report:={"source":Replay.source_identity(),"checks":checks,"issues":issues,"owners":final};FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("QUALITY_PREFIX_REPLAY "+JSON.stringify({"checks":checks,"issues":issues,"steps":positions}));quit(0 if issues.is_empty() else 1)
