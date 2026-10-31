from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v10/project'
f=P/'scripts/debug/quality_cohort_probe.gd';s=f.read_text(encoding='utf-8');old='\tvar classifier:=RivalWorld.new()';assert old in s;s=s.replace(old,'''	if not arg("--replay=").is_empty():
		_replay_prefix(arg("--replay="),output,policies,tapes,memories)
		return
'''+old,1)
s+='''
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
	var report:={"source":Replay.source_identity(),"checks":checks,"issues":issues,"owners":final};FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\\t"));print("QUALITY_PREFIX_REPLAY "+JSON.stringify({"checks":checks,"issues":issues,"steps":positions}));quit(0 if issues.is_empty() else 1)
''';f.write_bytes(s.encode());print('Same-provider source-matched ordered all-owner policy/command/result/state/RNG replay mode added.')
