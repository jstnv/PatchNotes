extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
class TimedPolicy extends "res://scripts/market/rival_career_policy.gd":
	var times: Dictionary={}
	func _hand(session: RefCounted,view: Dictionary,production: bool) -> Array[int]:
		var current: Dictionary=view.development;var cards: Array=current.candidates
		var best: Array[int]=[];var value:=-INF;var best_features:=-1
		var standards: Array=_standards(session);var goal:=6.5 if session.run.get_released_game_ids().is_empty() else 8.75
		var affordability := {}
		var by_token: Dictionary={}
		for i in range(session.development.hand.candidate_ids.size()):by_token[int(session.development.hand.candidate_ids[i])]=session.development.hand._candidate_cards[i]
		for a in range(cards.size()-3):
			for b in range(a+1,cards.size()-2):
				for c in range(b+1,cards.size()-1):
					for d in range(c+1,cards.size()):
						var offered: Array=[cards[a],cards[b],cards[c],cards[d]];var tokens: Array[int]=[];var selected: Array[CardData]=[];var features:=0
						for card: Dictionary in offered:
							if not by_token.has(int(card.token)):break
							selected.append(by_token[int(card.token)]);tokens.append(int(card.token))
							if card.type=="feature":features+=1
						if selected.size()!=4:continue
						# A strictly lower Feature count cannot beat an already legal best.
						if production and features<best_features:continue
						var score:=0.0
						if production:
							var t_base:=Time.get_ticks_usec()
							var base: Dictionary=session.development.hand.calculate_base(selected)
							times.base=int(times.get("base",0))+Time.get_ticks_usec()-t_base
							if not base.get("valid",false):continue
							var cost: int=session.run.primitive_feature_hand_cost_cents(selected,session.project_id())
							if cost<0:continue
							if not affordability.has(cost):
								var t_fee:=Time.get_ticks_usec();affordability[cost]=session.run.can_complete_productive_cycle(-cost);times.finance=int(times.get("finance",0))+Time.get_ticks_usec()-t_fee
							if not affordability[cost]:continue
							var t_score:=Time.get_ticks_usec()
							var assessed:=preload("res://scripts/market/rival_synergy_choice.gd")._assess(current,offered)
							times.assess=int(times.get("assess",0))+Time.get_ticks_usec()-t_score
							if assessed.is_empty():continue
							var predicted:=_rating(current.core,standards,assessed.final_core)
							score=minf(predicted,goal)-maxf(0.0,predicted-goal)*0.1
						else:
							var search:=0;var debug:=0;var marketing:=0;var valid:=true
							for card: Dictionary in offered:
								if card.type!="beta" or card.beta_category=="insider":valid=false;break
								if card.qa_operation=="search":search+=int(card.beta_value)
								elif card.qa_operation=="debug":debug+=int(card.beta_value)
								elif card.beta_category=="marketing":marketing+=int(card.beta_value)
							if not valid:continue
							if not state.search_done:score+=search*5.0
							score+=minf(debug,float(current.known_bugs+search))*6.0
							if state.search_done and int(current.known_bugs)==0:score+=marketing*4.0
							else:score+=marketing*0.1
							features=0
						if features>best_features or (features==best_features and score>value):best_features=features;value=score;best=tokens
		return best
	func _project_plan(session: RefCounted) -> Dictionary:
		var t:=Time.get_ticks_usec();var v:=super._project_plan(session);times.plan=int(times.get("plan",0))+Time.get_ticks_usec()-t;return v
class TimedDecision extends "res://scripts/market/rival_career_decision.gd":
	var times: Dictionary={}
	func _init(current: RefCounted,memory: Dictionary) -> void:
		super(current,memory);policy=TimedPolicy.new(current.run.get_studio_specialty());policy.state=memory;policy.times=times
	func observation(current: RefCounted) -> Dictionary:
		var t:=Time.get_ticks_usec();var v:=super.observation(current);times.observation=int(times.get("observation",0))+Time.get_ticks_usec()-t;return v
	func choose(view: Dictionary,lifetime: RefCounted) -> Dictionary:
		var t:=Time.get_ticks_usec();var v:=super.choose(view,lifetime);times.choose=int(times.get("choose",0))+Time.get_ticks_usec()-t;return v
func timed_policies(world: RivalWorld) -> Dictionary:
	var result: Dictionary={}
	for id: StringName in world.studios:
		var decision:=TimedDecision.new(world.studios[id],world.policy_states[id]);result[id]=decision.choose.bind(decision)
	return result
var failures: Array[String] = []
var checkpoints: Array = []

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer!=null: return true
		for port in range(47810,47820):
			var server := TCPServer.new()
			if server.listen(port,"127.0.0.1")==OK:
				_writer=server
				return true
		return false

class Meter extends CheckpointCoordinator:
	var validation_calls := 0
	var validation_us := 0
	func _validate_payload(payload: Dictionary) -> String:
		var start := Time.get_ticks_usec()
		var reason := super._validate_payload(payload)
		validation_us += Time.get_ticks_usec()-start
		validation_calls += 1
		return reason

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)

func measure(session: RefCounted, world: RivalWorld, meter: Meter) -> void:
	var start := Time.get_ticks_usec()
	meter.in_studio=true
	meter.pending=true
	meter.validation_calls=0
	meter.validation_us=0
	var kick:=Time.get_ticks_usec()
	meter._request_save()
	var kickoff_ms: float=(Time.get_ticks_usec()-kick)/1000.0
	var frames:=0
	var maximum:=0
	var prior:=Time.get_ticks_usec()
	while meter.is_saving():
		await process_frame
		var now:=Time.get_ticks_usec()
		maximum=maxi(maximum,now-prior)
		prior=now
		frames+=1
	check(meter.failure.is_empty(),"Private background world checkpoint: "+meter.failure)
	var row := {"kickoff_ms":kickoff_ms,"max_frame_gap_ms":maximum/1000.0,"frames":frames,"releases":session.run.get_released_game_ids().size(),"cycle":world.cycle,
		"save_ms":(Time.get_ticks_usec()-start)/1000.0,"main_coordinator_validator_calls":meter.validation_calls,"main_coordinator_validation_ms":meter.validation_us/1000.0}
	var scene: StudioPhase=load("res://scenes/phases/studio_phase.tscn").instantiate()
	start=Time.get_ticks_usec()
	check(scene.setup(null,session.run,session.snapshots),"Studio setup")
	root.add_child(scene)
	row.studio_mount_ms=(Time.get_ticks_usec()-start)/1000.0
	scene.free()
	if session.run.get_released_game_ids().size()==2:
		var store := FeatureStore.new()
		root.add_child(store)
		store.setup(session.run)
		var selected: StringName=&""
		for id: StringName in session.run._feature_definitions:
			if session.run.get_feature_research_quote(id).get("can_admit",false):
				selected=id
				break
		check(not selected.is_empty(),"A legal Feature can be queued after Game 2")
		start=Time.get_ticks_usec()
		check(session.run.admit_feature_research(session.run.get_feature_research_quote(selected)),"Queue actual research")
		await process_frame
		await process_frame
		row.queue_ms=(Time.get_ticks_usec()-start)/1000.0
		start=Time.get_ticks_usec()
		check(session.run.research_feature(session.run.get_feature_research_quote(selected)),"Actual research cycle")
		await process_frame
		await process_frame
		row.research_ms=(Time.get_ticks_usec()-start)/1000.0
		check(await meter.wait_saved(),"Newest Research action is durable before departure")
		store.free()
	meter.in_studio=false
	checkpoints.append(row)
	print(JSON.stringify(row))

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=Factory.create({"recipe":{"schema_version":1,"studio_id":"latency-world","studio_name":"Latency World","specialty":"action","traits":["family_funding"],"seed":"4417"}},catalog)
	check(session!=null,"Fixed-seed private Studio initializes")
	# Solvency fixture only; neither extra funds nor this test policy is player balance.
	check(session.run.add_cash(10000000),"Explicit synthetic accounting funds")
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://certified/rival-opening-5607-v1.json"))
	var world:=preload("res://scripts/market/rival_world_checkpoint.gd").new().restore(prior.fixture.world,StudioCheckpoint.new().capture(session.run),session.run,catalog,"0d8e6b57ddaa3c2a71c05af7ba92a4a4495cad5da80c7dad38b4b038f991fc99")
	check(world!=null,"Actual active-rival world initializes")
	var meter:=Meter.new();meter.debug_session=true
	meter.store=PrivateStore.new("user://latency-checkpoint",meter._validate_payload)
	meter.background_saves=true
	root.add_child(meter)
	meter.attach(session.run)
	check(meter.attach_rivals(world,catalog),"Actual player/world binding")
	var rival_times: Array=[]
	var advance:=func():
		var tick_start:=Time.get_ticks_usec()
		var policies:=timed_policies(world)
		var tick_report:=world.advance_committed_player_cycle(policies,Trial.ZERO_STEPS)
		var breakdown: Dictionary={}
		for id: StringName in policies:breakdown[id]=policies[id].get_object().times
		print("BREAKDOWN "+JSON.stringify({"cycle":world.cycle,"rows":breakdown}))
		rival_times.append({"cycle":world.cycle,"us":Time.get_ticks_usec()-tick_start,"ok":tick_report.ok})
		check(tick_report.ok,"Actual rival calendar commit")
		print("RIVAL_TICK "+JSON.stringify(rival_times[-1]))
	session.run.calendar_changed.connect(advance)
	await measure(session,world,meter)
	var policy:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Latency game","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	var commands:=0
	while session.run.get_released_game_ids().size()<1 and commands<180 and failures.is_empty():
		var before: int=session.run.get_released_game_ids().size()
		var choice: Dictionary=policy.call(session.observation())
		var outcome: Dictionary=session.execute(session.command(StringName(choice.type),choice.get("payload",{})))
		check(outcome.ok,"Legal deterministic campaign command "+str(commands))
		commands+=1
		if session.in_studio and session.run.get_released_game_ids().size()>before:
			await measure(session,world,meter)
	if true: # Explicit96-cycle performance fixture, not player/rival balance.
		while world.cycle<10 and failures.is_empty():
			check(session.run.complete_productive_action(),"Long shared-calendar action")
		await measure(session,world,meter)
	var adapter:=StudioCheckpoint.new()
	var player:=adapter.capture(session.run)
	var saved_world: Dictionary=load("res://scripts/market/rival_world_checkpoint.gd").new().capture(world)
	check(not player.is_empty() and not saved_world.is_empty(),"Final pre/post migration fixture captures")
	var report: Dictionary={"ok":failures.is_empty(),"failures":failures,"source_identity":Replay.source_identity(),"commands":commands,"timings":checkpoints,"rival_times":rival_times,
		"state":Replay.state(session),"player":player,"world":saved_world}
	if true:
		check(session.run.complete_productive_action(),"One expected continuation cycle commits")
		report.next_player=adapter.capture(session.run)
		report.next_world=load("res://scripts/market/rival_world_checkpoint.gd").new().capture(world)
		report.ok=failures.is_empty()
	var output:=""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):output=argument.trim_prefix("--output=")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report))
	print("Campaign action diagnostic: ",commands," commands; ",failures.size()," failures")
	session.run.calendar_changed.disconnect(advance)
	meter.free()
	quit(0 if failures.is_empty() else 1)
