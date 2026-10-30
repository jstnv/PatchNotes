extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void:go.call_deferred()
func go() -> void:
	var args: Dictionary={}
	for arg in OS.get_cmdline_user_args():
		var pieces=arg.trim_prefix("--").split("=",true,1)
		if pieces.size()==2:args[pieces[0]]=pieces[1]
	var original=Replay.load_tape(str(args.original)+"/replay.tape.json")
	var c=Replay.load_tape(str(args.original)+"/case.variant.json")
	var target=Replay.load_tape(str(args.candidate)+"/replay.tape.json")
	var candidate=Replay.load_tape(str(args.candidate)+"/final_state.variant.json")
	var session=Factory.create_fresh_session(c.initial.recipe,root.get_node("CardDatabase").get_development_catalog())
	var ok: bool=original.source_identity==Replay.source_identity() and original.initial_rng==target.initial_rng and original.initial_rng==session.run.random_streams.snapshot() and original.initial_state==Replay.digest(Replay.state(session))
	var count: int=target.steps.size()
	for i in range(count):
		if not ok:break
		ok=original.steps[i].command==target.steps[i].command and original.steps[i].result==target.steps[i].result
		var result=session.execute(original.steps[i].command)
		ok=ok and Replay.freeze(result)==original.steps[i].result and Replay.digest(Replay.state(session))==original.steps[i].state
	var only_empty_addition: bool=candidate.run.get("_crown_briefs")=={}
	candidate.run.erase("_crown_briefs")
	var exact: bool=Replay.state(session)==candidate
	ok=ok and only_empty_addition and exact
	FileAccess.open(str(args.out),FileAccess.WRITE).store_string(JSON.stringify({"ok":ok,"commands":count,"initial_rng_equal":original.initial_rng==target.initial_rng,"empty_crown_addition_only":only_empty_addition,"all_other_final_state_and_rng_exact":exact,"baseline_source":Replay.source_identity(),"candidate_source":target.source_identity},"\t"))
	print("CROWN_PREFIX_CROSS_VERSION ok=%s steps=%d"%[ok,count]);quit(0 if ok else 1)
