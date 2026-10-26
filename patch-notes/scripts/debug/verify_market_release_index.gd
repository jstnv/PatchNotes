extends "res://scripts/debug/verify_rival_world_foundation.gd"

const Trial := preload("res://scripts/market/rival_trial.gd")
const Index := preload("res://queries/market_release_index.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Legacy := preload("res://scripts/legacy/legacy_world.gd")
const Founder := preload("res://scripts/legacy/founder_profile.gd")
const Ownership := preload("res://scripts/legacy/ownership_book.gd")

# Index invariants need two releases per owner on a bounded fixture route;
# this frozen schedule is independent of the live rival stopping decision.
static func fixed_index_choice(view: Dictionary, genre: String, label: String, enabled: bool) -> Dictionary:
	if view.phase in [&"design",&"alpha"] and view.development.get("active",false) and not view.development.get("finalized",false) and not view.development.get("confirmation_pending",false) and view.development.get("hand_revision",0)>=3 and view.development.get("can_exit",false):
		return Trial._development(view,&"request_exit")
	return Trial.choose(view,genre,label,enabled,enabled)

static func fixed_index_policies(world: RivalWorld) -> Dictionary:
	var result: Dictionary = {}
	for id: StringName in world.studios:
		var session: RefCounted = world.studios[id]
		var genre: String = str(session.run.get_studio_specialty())
		var label: String = session.run.get_studio_name()
		var enabled: bool = Trial.uses_synergy_trial(id,session.run)
		result[id] = func(view: Dictionary) -> Dictionary: return fixed_index_choice(view,genre,label,enabled)
	return result

func replay_world(tape: Dictionary, catalog: RefCounted, expected_world: String) -> Dictionary:
	var session: RefCounted = Factory.create_fresh_session(recipe("foundation-player","action","1001"),catalog)
	var world: RivalWorld = Trial.create_world(session.run,catalog)
	var initial := Replay.begin(session)
	for field in ["schema_version","source_identity","engine_version","rng_algorithm","initial_state","initial_rng"]:
		if not tape.has(field) or tape[field] != initial[field]: return {"ok":false,"error":"Initial world replay mismatch: "+field}
	if not tape.get("steps") is Array: return {"ok":false,"error":"Missing tape steps"}
	var policies := fixed_index_policies(world)
	for index in range(tape.steps.size()):
		var expected: Dictionary = tape.steps[index]
		var result: Dictionary = session.execute(expected.command)
		if Replay.freeze(result)!=expected.result or Replay.digest(Replay.state(session))!=expected.state:
			return {"ok":false,"error":"Player replay divergence at "+str(index)}
		# Match the original recorder: capture the player result first, then
		# advance real rivals before the next command. Standalone Replay.replay
		# cannot reproduce a tape whose next project uses their market snapshot.
		if session.run.get_completed_run_cycles()>world.cycle:
			if not world.advance_committed_player_cycle(policies,8).ok: return {"ok":false,"error":"Rival replay rejected"}
	if Replay.digest(WorldCodec.new().capture(world))!=expected_world: return {"ok":false,"error":"Whole-world replay divergence"}
	return {"ok":true}

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var codec := WorldCodec.new()
	var path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if OS.get_environment("PN_INDEX_COLD")=="1":
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var restored := codec.restore(saved.world,saved.player,StudioCheckpoint.new().hydrate(saved.player),catalog)
		expect(restored!=null,"fresh process restores world: "+codec.error)
		if restored!=null:
			expect(Replay.freeze(Index.query(restored))==saved.rows,"fresh process derives identical rows")
			expect(Replay.digest(codec.capture(restored))==saved.world_digest,"fresh process checkpoint bytes unchanged")
		var tape := Replay.load_tape(path+".tape.json")
		var replay: Dictionary = replay_world(tape,catalog,str(saved.replay_world_digest))
		expect(replay.ok,"fresh process identical command/state/RNG replay: "+str(replay.get("error","")))
		print("MARKET_INDEX_COLD checks=%d failures=%d steps=%d"%[checks,failures,tape.steps.size()]);quit(failures);return
	var player: RefCounted = Factory.create_fresh_session(recipe("foundation-player","action","1001"),catalog)
	var world: RefCounted = Trial.create_world(player.run,catalog)
	var action: RefCounted = world.studios[&"incumbent-arcade-foundry"]
	var adventure: RefCounted = world.studios[&"incumbent-wayfinder-works"]
	var tape := Replay.begin(player)
	var policies := fixed_index_policies(world)
	var p := policy("action","Player")
	var frozen := {}
	var zero_count := 0
	var growth := false
	var done := false
	for cycle in range(20):
		for step in range(12):
			var choice: Dictionary = p.call(player.observation())
			var result := Replay.record(player,tape,player.command(StringName(choice.type),choice.get("payload",{})))
			expect(result.ok,"legal player command")
			if player.in_studio and player.run.get_released_game_ids().size()>=2: done=true;break
			if not result.ok or player.run.get_completed_run_cycles()>cycle: break
		if player.run.get_completed_run_cycles()>world.cycle: expect(world.advance_committed_player_cycle(policies,8).ok,"legal rival calendar")
		var before := Replay.digest({"p":Replay.state(player),"a":Replay.state(action),"b":Replay.state(adventure),"w":codec.capture(world)})
		var indexed := Index.query(world)
		expect(indexed.ok,"all authoritative real releases indexed")
		for row: Dictionary in indexed.get("rows",[]):
			var key: String = row.studio_id+"/"+row.release_id
			var fixed := row.duplicate(true)
			for field in ["earned_units","entitlement_cents","settled_cents"]: fixed.erase(field)
			if frozen.has(key): expect(frozen[key]==fixed,"release identity/Core/Review stay frozen")
			else:
				frozen[key]=fixed
				if row.studio_id!="foundation-player": expect(row.earned_units==0 and row.settled_cents==0,"rival registration earns zero actual sales")
				zero_count+=1
			growth=growth or row.earned_units>0
			var owner: RunState = player.run if row.studio_id==str(player.run._bank_run_id) else world.studios[StringName(row.studio_id)].run
			var sales := owner.get_released_game_sales(StringName(row.release_id))
			expect(row.cores_available and row.earned_units==sales.earned_units and row.entitlement_cents==sales.entitlement_cents and row.settled_cents==sales.settled_cents,"actual earned counters and frozen Core vector")
		if not indexed.rows.is_empty(): indexed.rows[0].cores.clear();indexed.rows[0].earned_units=-1
		expect(before==Replay.digest({"p":Replay.state(player),"a":Replay.state(action),"b":Replay.state(adventure),"w":codec.capture(world)}),"query and output mutation leave every state/RNG/checkpoint byte unchanged")
		if done: break
	expect(zero_count>=6 and growth,"two legal releases per owner and settled growth observed")
	var replay_world_digest := Replay.digest(codec.capture(world))
	var rows := Index.query(world)
	world.studios={&"incumbent-wayfinder-works":adventure,&"incumbent-arcade-foundry":action}
	expect(Index.query(world)==rows,"dictionary insertion order independent")
	world.studios[&"foundation-player"]=player
	var duplicate := Index.query(world)
	expect(not duplicate.ok and not duplicate.has("rows"),"duplicate owner explicitly fails without partial rows")
	world.studios.erase(&"foundation-player")
	var id: StringName = player.run.get_released_game_ids()[0]
	var metadata: Dictionary = player.run.get_release_metadata(id)
	player.run._release_metadata[id].erase("genre")
	expect(not Index.query(world).ok,"missing required Genre explicitly fails")
	player.run._release_metadata[id]=metadata.duplicate(true)
	
	var old_player := StudioCheckpoint.new().capture(player.run)
	var old_run := StudioCheckpoint.new().hydrate(old_player)
	expect(old_run!=null,"player-only checkpoint still hydrates")
	if old_run!=null: old_run._release_metadata[id].review.erase("cores")
	var player_only: RefCounted=World.new();player_only.player=old_run
	var old_rows := Index.query(player_only)
	expect(old_rows.ok and not old_rows.rows[0].cores_available and old_rows.rows[0].cores.is_empty(),"missing older Core vector explicitly unavailable")
	player.run._release_metadata[id]=metadata
	for step in range(12):
		if action.in_studio: break
		expect(player.run.complete_productive_action(Callable(),0,world.cycle),"structural Studio calendar fixture")
		expect(world.advance_committed_player_cycle(policies,8).ok,"rivals continue to safe handoff boundary")
	rows=Index.query(world)
	# An actual safe Founder operator handoff retains the former player's releases.
	var books := {}
	for owner_id in Legacy.runs(world): books[owner_id]=Ownership.create(owner_id,{"founder:index":1000000})
	expect(Legacy.initialize(world,Founder.create("index","foundation-player",0),books),"explicit Founder fixture initializes")
	expect(Legacy.handoff(world,&"incumbent-arcade-foundry",true),"safe actual operator handoff")
	expect(Index.query(world)==rows,"former player retains stable owner identity and every release")
	var saved_player := StudioCheckpoint.new().capture(world.player)
	var saved_world := codec.capture(world)
	var restored := codec.restore(saved_world,saved_player,StudioCheckpoint.new().hydrate(saved_player),catalog)
	expect(restored!=null and Index.query(restored)==rows,"Studio rollback reconstructs identical derived rows: "+codec.error)
	expect(Replay.save_tape(path+".tape.json",tape),"exact integer replay tape saved")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"player":saved_player,"world":saved_world,"rows":Replay.freeze(rows),"world_digest":Replay.digest(saved_world),"replay_world_digest":replay_world_digest}))
	print("MARKET_INDEX checks=%d failures=%d rows=%d source=%s"%[checks,failures,rows.rows.size(),Replay.source_identity()]);quit(failures)
