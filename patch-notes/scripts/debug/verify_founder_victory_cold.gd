extends SceneTree

const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var frame: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not frame is Dictionary or not frame.get("player") is Dictionary or not frame.get("world") is Dictionary:
		push_error("Missing prior-process world frame"); quit(1); return
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var adapter := StudioCheckpoint.new()
	var codec := WorldCodec.new()
	var player: RunState=adapter.hydrate(frame.player)
	var world: RivalWorld=codec.restore(frame.world,frame.player,player,catalog)
	check(world!=null and codec.error.is_empty(),"Fresh process restores candidate founder world")
	if world==null: quit(1); return
	check(world.legacy.version==2 and world.legacy.victory.claims.is_empty() and Replay.digest(codec.capture(world))==frame.digest,"Cold Continue retains empty versioned victory ledger exactly")
	var corrupt: Dictionary=frame.world.duplicate(true)
	corrupt.legacy.victory.original_studio_id="wrong-original"
	check(codec.restore(corrupt,frame.player,adapter.hydrate(frame.player),catalog)==null,"Forged original Studio rejects on restore")
	corrupt=frame.world.duplicate(true)
	corrupt.legacy.victory.claims=[{"id":"victory:subsidiaries"}]
	check(codec.restore(corrupt,frame.player,adapter.hydrate(frame.player),catalog)==null,"Unproven victory claim rejects on restore")
	var historical: Dictionary=frame.world.duplicate(true)
	historical.legacy.version="1"
	historical.legacy.erase("victory")
	var old: RivalWorld=codec.restore(historical,frame.player,adapter.hydrate(frame.player),catalog)
	check(old!=null and old.legacy.version==1 and old.legacy.founder==world.legacy.founder,"Same-source version-one founder data remains readable")
	historical.legacy.founder.milestone_ids.append("victory:subsidiaries")
	check(codec.restore(historical,frame.player,adapter.hydrate(frame.player),catalog)==null,"Version-one data cannot carry an unproven victory milestone")
	print("Founder victory cold restore: %d checks, %d failures"%[checks,failures])
	quit(failures)
