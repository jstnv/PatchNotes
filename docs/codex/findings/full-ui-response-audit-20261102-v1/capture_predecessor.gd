extends SceneTree
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
 var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(original.player)
 var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
 var catalog:RefCounted=root.get_node("CardDatabase").get_development_catalog()
 var world=codec.restore(original.world,original.player,run,catalog)
 if run==null or world==null:push_error(codec.error);quit(1);return
 var player:Dictionary=adapter.capture(run);var captured:Dictionary=codec.capture(world)
 if player!=original.player or captured.is_empty():push_error("Intake native pair capture failed");quit(1);return
 var file:=FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE);file.store_string(JSON.stringify({"player":player,"world":captured}));file.close()
 print("INTAKE_PAIR source=",captured.source_identity," cycle=",run.get_completed_run_cycles()," genuine previous player preserved")
 quit(0)
