extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var job=load("res://scripts/persistence/checkpoint_write.gd").new()
	check(job.has_method("_presentation_payload"),"Unchanged presentation snapshots reuse validated encoding")
	if not job.has_method("_presentation_payload"):quit(1);return
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var run:=adapter.hydrate(pair.player)
	var world=codec.restore(pair.world,pair.player,run,catalog)
	check(world!=null,"Genuine world fully restores before memo proof")
	if world==null:quit(1);return
	job.previous_player=adapter.snapshot(run)
	job.previous_world=codec.snapshot(world,adapter)
	job.previous_payload=adapter.encode_snapshot(job.previous_player)
	job.previous_payload["rival_world"]=codec.encode_snapshot(job.previous_world)
	check(world.advance_awards_stage(),"Actual presentation stage advances")
	job.player=adapter.snapshot(run);job.world=codec.snapshot(world,adapter)
	var source: String=load("res://scripts/simulation/development_replay.gd").source_identity()
	var memo: Dictionary=job._presentation_payload(source)
	var full:=adapter.encode_snapshot(job.player);full["rival_world"]=codec.encode_snapshot(job.world)
	check(not memo.is_empty() and var_to_bytes(memo)==var_to_bytes(full),"Memoized payload is byte/type exact against full encoding")
	var original: Dictionary=job.player
	job.player=original.duplicate(true);job.player.run.cash_cents+=1
	check(job._presentation_payload(source).is_empty(),"Cash change requires full encoding")
	job.player=original
	var old: Dictionary=job.world
	job.world=old.duplicate(true);job.world.studios[0].run.run.cash_cents+=1
	check(job._presentation_payload(source).is_empty(),"Rival change requires full encoding")
	job.world=old.duplicate(true);job.world.annual_awards.entries[0].result.awards[0].nominees[0].score+=1
	check(job._presentation_payload(source).is_empty(),"Frozen rank change requires full encoding")
	job.world=old.duplicate(true);job.world.annual_awards.entries[0].stage=10
	check(job._presentation_payload(source).is_empty(),"Invalid presentation cannot reuse encoding")
	job.world=old
	check(job._presentation_payload("unknown").is_empty(),"Changed executable identity requires full encoding")
	for path in [["rng","snapshot","state"],["run_id"],["content_revision"]]:
		job.player=original.duplicate(true)
		var parent: Dictionary=job.player
		for key in path.slice(0,-1):parent=parent[key]
		var key: String=path[-1]
		parent[key]=str(parent[key])+"-changed"
		check(job._presentation_payload(source).is_empty(),"Player identity/RNG/content mutation requires full encoding: "+str(path))
	job.player=original
	for path in [["studios",0,"run","rng","snapshot","state"],["studios",0,"id"],["studios",0,"offset"],["studios",0,"policy","search_done"],["annual_awards","entries",0,"owners",0,"offset"],["annual_awards","entries",0,"result","rewards",0,"fans"]]:
		job.world=old.duplicate(true)
		var parent: Variant=job.world
		for key in path.slice(0,-1):parent=parent[key]
		var key: Variant=path[-1]
		var value: Variant=parent[key]
		parent[key]=not value if value is bool else value+1 if value is int else str(value)+"-changed"
		check(job._presentation_payload(source).is_empty(),"World/RNG/policy/owner/reward mutation requires full encoding: "+str(path))
	job.world=old
	job.previous_payload.content_revision="unknown"
	check(job._presentation_payload(source).is_empty(),"Prior content revision mismatch requires full encoding")
	print("AWARDS_ENCODING_MEMO checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
