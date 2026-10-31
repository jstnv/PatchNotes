extends SceneTree
const Trial := preload("res://scripts/market/rival_trial.gd")
const Choice := preload("res://scripts/market/rival_synergy_choice.gd")
const Beta := preload("res://scripts/market/rival_beta_synergy_choice.gd")
const Batch := preload("res://scripts/simulation/campaign_batch.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0
var changed := {"design":0,"alpha":0,"beta":0}
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("RIVAL_SYNERGY: "+label)
# Exact previous trial selector. Kept here as an explicit test control, not runtime policy.
static func reference(view: Dictionary, genre: String, label: String) -> Dictionary:
	if view.phase==&"studio": return {"type":&"begin_development","payload":{"name":"%s %d"%[label,view.releases.size()+1],"genre":genre,"theme":"fantasy"}}
	if view.phase==&"contract": return {}
	var current: Dictionary=view.development
	if current.finalized: return {"type":&"launch"} if current.phase=="beta" else Trial._development(view,&"enter_next_phase")
	if current.confirmation_pending: return Trial._development(view,&"confirm_exit")
	if not current.active: return Trial._development(view,&"begin")
	if current.get("hand_revision",0)>=3 and current.get("can_exit",false): return Trial._development(view,&"request_exit")
	var cards: Array=current.candidates.duplicate(true)
	cards.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if (a.type=="feature")!=(b.type=="feature"):return a.type=="feature"
		return int(a.token)<int(b.token))
	if cards.size()<4:return {}
	var ids: Array[int]=[]
	for i in 4:ids.append(int(cards[i].token))
	return Trial._development(view,&"play",{"candidate_ids":ids})

# Hold the historical two-hand schedule for the selector-only A/B fixture.
# Live Design/Alpha policies now use Feature exhaustion instead.
static func trial_fixed_budget(view: Dictionary, genre: String, label: String) -> Dictionary:
	if view.phase in [&"design",&"alpha"] and view.development.get("active",false) and not view.development.get("finalized",false) and not view.development.get("confirmation_pending",false) and view.development.get("hand_revision",0)>=3 and view.development.get("can_exit",false):
		return Trial._development(view,&"request_exit")
	return Trial.choose(view,genre,label)
func policy(config: Dictionary) -> Callable:
	return func(view: Dictionary)->Dictionary:
		var before:=Replay.digest(view)
		var control:=reference(view,config.genre,"Synergy test")
		var chosen:=trial_fixed_budget(view,config.genre,"Synergy test") if config.mode=="trial" else control
		check(Replay.digest(view)==before,"policy observation remains untouched")
		if chosen.get("type")==&"development" and chosen.payload.request.type==&"play":
			var ids: Array=chosen.payload.request.payload.candidate_ids
			var visible: Array=view.development.candidates.map(func(c):return int(c.token))
			var seen:={}
			for id in ids:seen[id]=true
			check(ids.size()==4 and seen.size()==4 and ids.all(func(id):return visible.has(id)),"four distinct visible legal tokens")
			if config.mode=="trial":
				check(chosen==trial_fixed_budget(view,config.genre,"Synergy test"),"fixed-budget trial enables combined selector")
				if ids!=control.payload.request.payload.candidate_ids:changed[view.development.phase]+=1
		return chosen
func case_for(genre: String, seed_value: int, mode: String) -> Dictionary:
	return {"schema_version":"1","case_id":"%s-%d-%s"%[genre,seed_value,mode],"initial":{"recipe":{"schema_version":1,"studio_id":"matched-"+genre+str(seed_value),"studio_name":"Matched "+genre,"specialty":genre,"traits":["family_funding","cult_following"],"seed":str(seed_value)}},"max_commands":45,"target_release_count":1,"policy":{"id":"rival-synergy-verifier","version":"1","source_identity":FileAccess.get_sha256("res://scripts/debug/verify_rival_synergy.gd"),"config":{"genre":genre,"mode":mode}}}
func _initialize() -> void:
	await process_frame
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if output.is_empty():push_error("isolated output required");quit(2);return
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var scoped := Factory.create_fresh_session({"schema_version":1,"studio_id":"scope-check","studio_name":"Scope check","specialty":"action","traits":[],"seed":"4417"},catalog)
	check(Trial.uses_synergy_trial(&"incumbent-arcade-foundry",scoped.run) and not Trial.uses_synergy_trial(&"former-player",scoped.run),"only approved cohort IDs opt in")
	scoped.run.finalize_starter_selection()
	check(scoped.run.admit_feature_research(scoped.run.get_feature_research_quote(&"colored_text")) and scoped.run.research_feature(scoped.run.get_feature_research_quote(&"colored_text")),"legal later-Store pool fixture")
	check(not Trial.uses_synergy_trial(&"incumbent-arcade-foundry",scoped.run),"richer Store pool remains outside trial")
	var cases: Array=[]
	for genre in ["action","adventure","puzzle","sports"]:
		for seed_value in [4417,90210]:
			for mode in ["reference","trial"]:cases.append(case_for(genre,seed_value,mode))
	var report:=Batch.run_cases(cases,catalog,policy,output+".first")
	check(report.ok,"16 legal matched first releases")
	var continuations: Array=[]
	for genre in ["adventure","puzzle"]:
		for mode in ["reference","trial"]:
			var item:=case_for(genre,4417,mode)
			var path: String=(output+".first").path_join(item.case_id).path_join("studio_checkpoint.json")
			item.initial={"checkpoint":JSON.parse_string(FileAccess.get_file_as_string(path))}
			item.case_id+="-second";item.target_release_count=2
			continuations.append(item)
	var continued:=Batch.run_cases(continuations,catalog,policy,output+".second")
	check(continued.ok,"four own-checkpoint second releases")
	for results: Array in [report.results,continued.results]:
		for index in range(0,results.size(),2):
			check(results[index].initial_state==results[index+1].initial_state if results==report.results else true,"matched initial state/RNG")
			check(results[index].commands==results[index+1].commands and results[index].final_run_cycle==results[index+1].final_run_cycle,"same hand budget and release calendar")
	check(changed.beta>0,"actual default policy makes useful Beta changes")
	# Corrective Pass/invalid finite duplicates cannot be treated as a QA combo.
	var pass_hand: Array=[]
	for i in 4:pass_hand.append({"type":"pass","token":i,"primary_stat":"graphics","scope":0})
	check(Beta.pick({"candidates":pass_hand},pass_hand,&"test")==[0,1,2,3],"Corrective Pass hand keeps reference")
	var duplicate: Array=[]
	for i in 4:duplicate.append({"type":"beta","token":i,"definition":"playtest_rival_games","renewable":false,"beta_category":"insider","beta_value":1})
	check(Beta._assess(duplicate).is_empty(),"finite duplicate rejected")
	var worlds: Array=[]
	for repeat_index in 3:
		for mode in (["reference","trial"] if repeat_index%2==0 else ["trial","reference"]):
			var player:=Factory.create_fresh_session({"schema_version":1,"studio_id":"trial-player","studio_name":"Player Studio","specialty":"action","traits":[],"seed":"4417"},catalog)
			var world:=Trial.create_legacy_world(player.run,catalog)
			var initial:=Replay.digest(world.observation())
			var timings: Array=[]
			var choices: Array=[]
			var policies:={}
			for id in world.studios:
				var genre: String=str(world.studios[id].run.get_studio_specialty())
				var label: String=world.studios[id].run.get_studio_name()
				policies[id]=func(view: Dictionary)->Dictionary:
					var start:=Time.get_ticks_usec()
					var request:=reference(view,genre,label) if mode=="reference" else trial_fixed_budget(view,genre,label)
					choices.append(Time.get_ticks_usec()-start)
					return request
			for cycle in 20:
				check(player.run.complete_productive_action(Callable(),0,cycle),"matched player cycle")
				var start:=Time.get_ticks_usec()
				var result:=world.advance_committed_player_cycle(policies,12)
				timings.append(Time.get_ticks_usec()-start)
				check(result.ok and result.studios.all(func(row):return str(row.blocked_reason).is_empty()),"no rejected or blocked rival actions")
			var saved:=preload("res://scripts/market/rival_world_checkpoint.gd").new().capture(world)
			check(not saved.is_empty(),"actual world serializes")
			worlds.append({"mode":mode,"repeat":repeat_index,"initial":initial,"policy_us":choices,"world_cycle_us":timings,"releases":world.live_releases,"world_bytes":JSON.stringify(saved).length(),"state":saved})
	for index in range(0,worlds.size(),2):check(worlds[index].initial==worlds[index+1].initial,"same initial world for timing pair")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"checks":checks,"failures":failures,"changed":changed,"first":report,"second":continued,"worlds":worlds},"	"))
	print("RIVAL_SYNERGY checks=%d failures=%d first=%d second=%d beta_changes=%d"%[checks,failures,report.results.size(),continued.results.size(),changed.beta])
	quit(failures)
