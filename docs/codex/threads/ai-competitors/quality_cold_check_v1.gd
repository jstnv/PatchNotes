extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Trial:=preload("res://scripts/market/rival_trial.gd")
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const Book:=preload("res://scripts/market/rival_standard_book.gd")
const Market:=preload("res://scripts/market/market_transaction_trial.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func arg(prefix: String) -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return ""
func player(catalog: RefCounted,index: int) -> RefCounted:
	var id:=""
	for i in range(100):
		id="cold-player-"+str(i)
		if id.sha256_text().substr(0,8).hex_to_int()%2==index:break
	return Factory.create_fresh_session({"schema_version":1,"studio_id":id,"studio_name":"Cold verifier","specialty":"action","traits":[],"seed":"717"},catalog)
func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog();var rows: Array=[]
	for seed_index in range(2):
		var session:=player(catalog,seed_index);var rng: Dictionary=session.run.random_streams.snapshot();var started:=Time.get_ticks_usec();var world:=Trial.create_world(session.run,catalog)
		check(world!=null,"strict certified opening "+str(seed_index))
		if world==null:continue
		var init_us:=Time.get_ticks_usec()-started
		check(world.studios.size()==8 and world.cycle==0 and world.policy_states.size()==8,"eight owned January states")
		check(session.run.random_streams.snapshot()==rng,"opening consumes no player RNG")
		var scope:=0
		for id: StringName in session.run.get_future_project_feature_ids():scope+=int(session.run._feature_definitions[id].scope)
		check(scope==12,"player founding Scope stays12")
		var titles:=0
		for id: StringName in world.studios:
			var owner: RefCounted=world.studios[id];check(owner.run.get_current_year()==1980 and owner.run._calendar_start_year==1977 and owner.run.get_completed_run_cycles()==72 and not owner.in_studio,"real epoch and January project")
			check(world.calendar_offsets[id]==72 and owner.run._historical_close_cycle==72,"typed historical closure")
			titles+=world.historical_archive[id].size()
			for title: Dictionary in world.historical_archive[id]:check(title.year>=1977 and title.year<1980 and title.id in owner.run.get_released_game_ids(),"actual historical title")
		check(titles==24 and world.live_releases.is_empty() and world.market_snapshot.facts.is_empty(),"24 histories, zero live pressure")
		check(Market.sales_factor(world.market_snapshot,str(session.run._bank_run_id),"probe","action","fantasy").factor_bp==10000,"archives create no sales crowding")
		for genre: String in world.market_snapshot.basis:
			var first: Dictionary=world.market_snapshot.basis[genre].first;var effective: int=(int(first.release_cycle)/2+1)*2
			check(not Book.build(world.studios,effective-1).has(genre),"first standard absent in release month")
			check(Book.build(world.studios,effective)[genre].first==first,"first actual-Core standard following month")
		var adapter:=StudioCheckpoint.new();var p:=adapter.capture(session.run);var codec:=Codec.new();var saved:=codec.capture(world);var restored_player:=adapter.hydrate(p);var cold:=codec.restore(saved,p,restored_player,catalog)
		check(cold!=null,"cold world restores: "+codec.error)
		if cold==null:continue
		check(codec.capture(cold)==saved and adapter.capture(restored_player)==p,"cold authoritative player/world exact")
		var a: Dictionary=Trial.policies(world);var b: Dictionary=Trial.policies(cold)
		for id: StringName in world.studios:
			var va: Dictionary=a[id].get_object().observation(world.studios[id]);var vb: Dictionary=b[id].get_object().observation(cold.studios[id]);var ca: Dictionary=a[id].call(va);var cb: Dictionary=b[id].call(vb)
			check(ca==cb,"cold next policy choice exact")
		check(world.policy_states==cold.policy_states,"cold policy memory exact after observation")
		var ids: Array=world.studios.keys();var before: Dictionary={}
		for id: StringName in ids:before[id]=world.studios[id].run.random_streams.snapshot()
		world.studios[ids[0]].run.random_streams.stream(RunRandom.STREAMS[0]).randi()
		for i in range(1,ids.size()):check(world.studios[ids[i]].run.random_streams.snapshot()==before[ids[i]],"owner RNG objects independent")
		world.studios[ids[0]].run.random_streams.restore(before[ids[0]])
		for field in ["unknown_source","beta_hands","project_id","loan_project","cash","basis"]:
			var bad: Dictionary=saved.duplicate(true)
			match field:
				"unknown_source":bad.source_identity="f".repeat(64)
				"beta_hands":bad.studios[0].policy.beta_hands="13"
				"project_id":bad.studios[0].policy.project_id="unowned-project"
				"loan_project":bad.studios[0].policy.loan_project="999"
				"cash":bad.studios[0].run.run.cash_cents="999999999"
				"basis":
					var editor:=Codec.new();var native: Dictionary=editor._decode(bad.market,Codec._market_schema());var key: String=native.basis.keys()[0];native.basis[key].first.cores[0]+=1
					var changed:=Book.snapshot(native.basis,0,72)
					check(Book.valid_snapshot(changed),"corrupt basis remains structurally valid")
					bad.market=editor._encode(changed,Codec._market_schema())
					check(editor.error.is_empty(),"corrupt basis encoding succeeds before provenance rejection")
			check(codec.restore(bad,p,restored_player,catalog)==null,"reject corruption "+field)
		rows.append({"seed_index":seed_index,"hydrate_us":init_us,"historical_titles":titles,"source":Replay.source_identity()})
	var report:={"checks":checks,"failures":failures,"source":Replay.source_identity(),"rows":rows};FileAccess.open(arg("--output="),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("QUALITY_COLD "+JSON.stringify(report));quit(0 if failures.is_empty() else 1)
