extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const Codec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures: Array[String] = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func arg(prefix: String) -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix): return value.trim_prefix(prefix)
	return ""

func scope(run: RunState) -> int:
	var total := 0
	for id in run.get_future_project_feature_ids(): total += int(run._feature_definitions[id].scope)
	return total

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var seed := arg("--seed=")
	if seed.is_empty(): seed = "4417"
	var player: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"pool-player-"+seed,"studio_name":"Pool Check","specialty":"action","traits":[],"seed":seed},catalog)
	var world: RivalWorld
	var old_path := arg("--restore=")
	if not old_path.is_empty():
		var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(old_path))
		var studio := StudioCheckpoint.new()
		player.run = studio.hydrate(old.player)
		expect(player.run != null,"old player restores")
		if player.run == null: quit(1); return
		var codec := Codec.new()
		world = codec.restore(old.world,old.player,player.run,catalog)
		expect(world != null,"old world restores: "+codec.error)
		if world == null: quit(1); return
		expect(Replay.digest(world.observation())==old.observation,"old observation unchanged; no grant or replay")
		var bad: Dictionary = old.world.duplicate(true)
		bad.source_identity = "unknown-source"
		expect(codec.restore(bad,old.player,player.run,catalog)==null,"unknown source still rejects")
		bad = old.world.duplicate(true)
		bad.studios[0].run.content_revision = "wrong-content"
		expect(codec.restore(bad,old.player,player.run,catalog)==null,"wrong source/content pair still rejects")
		for id in world.studios:
			expect(scope(world.studios[id].run)==int(old.scopes[str(id)]),"saved ownership unchanged: "+str(id))
	else: world = Trial.create_world(player.run,catalog)
	expect(world != null,"actual trial bootstrap")
	if world == null: quit(1); return
	expect(scope(player.run)==12,"player pool remains12 Scope")
	var scopes := {}
	for id in world.studios:
		var session: RefCounted = world.studios[id]
		scopes[str(id)] = scope(session.run)
		if old_path.is_empty():
			expect(scope(session.run)==27,"new rival has27 Scope: "+str(id))
			for feature in session.run.get_owned_feature_ids(): expect(FeatureStoreCatalog.is_active(feature),"active grant: "+str(feature))
			var graph := FeatureStoreCatalog.graph(session.run._feature_definitions,session.run._feature_offers)
			for feature in session.run.get_owned_feature_ids():
				for parent in graph.parents[feature]: expect(session.run._owned_features.has(parent),"owned parent for "+str(feature))
		expect(Trial.uses_synergy_trial(id,session.run),"approved incumbent keeps synergy policy")
	var codec := Codec.new()
	var fixture := {"player":StudioCheckpoint.new().capture(player.run),"world":codec.capture(world),"observation":Replay.digest(world.observation()),"scopes":scopes}
	expect(not fixture.player.is_empty() and not fixture.world.is_empty(),"capture at Studio boundary: "+codec.error)
	var releases: Array = []
	var boundaries := {}
	var blocks: Array = []
	var durations: Array = []
	for index in range(maxi(0,20-world.cycle)):
		var start := Time.get_ticks_usec()
		expect(player.run.complete_productive_action(Callable(),0,player.run.get_completed_run_cycles()),"player boundary")
		var report: Dictionary = world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
		expect(report.ok,"legal rival boundary: "+str(world.cycle))
		durations.append((Time.get_ticks_usec()-start)/1000.0)
		for row: Dictionary in report.get("studios",[]):
			if not str(row.get("blocked_reason","")).is_empty(): blocks.append({"cycle":world.cycle,"row":row})
		if not report.ok: break
		if world.cycle in [1,5,20]:
			boundaries[str(world.cycle)] = {"player":StudioCheckpoint.new().capture(player.run),"world":codec.capture(world),"observation":Replay.digest(world.observation()),"scopes":scopes}
	for release in world.live_releases.values(): releases.append(release)
	expect(blocks.is_empty(),"no blocked rival action through cycle20")
	var result := {"source":Replay.source_identity(),"checks":checks,"failures":failures,"scopes":scopes,"fixture":fixture,"boundaries":boundaries,"cycle":world.cycle,"releases":releases,"blocked":blocks,"cycle_ms":durations,"world_digest":Replay.digest(world.observation())}
	var path := arg("--report=")
	if not path.is_empty():
		var output := FileAccess.open(path,FileAccess.WRITE)
		output.store_string(JSON.stringify(result,"\t"))
	print("LIVE_RIVAL_POOL "+JSON.stringify({"checks":checks,"failures":failures,"scopes":scopes,"cycle":world.cycle,"release_count":releases.size()}))
	quit(0 if failures.is_empty() else 1)
