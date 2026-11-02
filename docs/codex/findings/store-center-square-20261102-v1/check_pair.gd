extends SceneTree
var failures:=0
func check(ok: bool,label: String)->void:
 print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
 var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(original.player)
 var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
 var catalog=root.get_node("CardDatabase").get_development_catalog()
 var world=codec.restore(original.world,original.player,run,catalog)
 check(run!=null and world!=null,"Genuine preceding paired save restores without restamping")
 if run==null or world==null:quit(1);return
 var player: Dictionary=adapter.capture(run);var captured: Dictionary=codec.capture(world)
 check(player==original.player,"Whole typed player/finance/history/RNG checkpoint is unchanged")
 var expected: Dictionary=original.world.duplicate(true)
 expected.source_identity=captured.source_identity
 check(captured==expected,"Whole world and rival RNG state unchanged apart from exact runtime source stamp")
 var bad: Dictionary=original.world.duplicate(true);bad.source_identity="0".repeat(64)
 check(codec.restore(bad,original.player,run,catalog)==null,"Unapproved source identity remains rejected")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"player":player,"world":captured,"failures":failures}))
 quit(failures)
