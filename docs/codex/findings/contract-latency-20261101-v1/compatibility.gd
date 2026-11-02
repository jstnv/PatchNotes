extends SceneTree
const WorldCodec=preload("res://scripts/market/rival_world_checkpoint.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(pair.player)
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var codec:=WorldCodec.new();var world:=codec.restore(pair.world,pair.player,run,catalog)
	check(world!=null,"Cold genuine preceding Contract save restores: "+codec.error)
	if world==null:quit(1);return
	check(adapter.capture(run)==pair.player,"Player finance/history/RNG is unchanged")
	var actual:=codec.capture(world);var expected: Dictionary=pair.world.duplicate(true)
	expected.source_identity=actual.source_identity
	check(actual==expected,"Entire rival world is unchanged except executing-source stamp")
	var active:=-1
	for i in pair.world.studios.size():
		if pair.world.studios[i].development!=null:active=i;break
	check(active>=0,"Genuine fixture contains frozen active rival project")
	for mode in ["annual","budget","engine","capacity","source","rng","calendar"]:
		var bad: Dictionary=pair.world.duplicate(true)
		if mode=="annual":bad.erase("annual_awards")
		elif mode=="budget":bad.studios[active].development.erase("pass_budget")
		elif mode=="engine":bad.studios[active].development.project.erase("_engine_id")
		elif mode=="capacity":bad.studios[active].development.project.erase("_engine_capacity")
		elif mode=="source":bad.source_identity="unknown-contract-source"
		elif mode=="rng":bad.studios[active].run.rng[0].value.state="01"
		else:bad.cycle=str(int(bad.cycle)+1)
		check(WorldCodec.new().restore(bad,pair.player,run,catalog)==null,"Predecessor still rejects missing/invalid protected state: "+mode)
	print("CONTRACT_COMPATIBILITY checks=%d failures=%d"%[checks,failures]);quit(failures)
