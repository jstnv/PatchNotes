extends SceneTree
var rows:Array=[]
func time_call(label:String,callback:Callable,count:int=3)->void:
 var times:Array=[]
 for i in count:
  var began:=Time.get_ticks_usec();var result=callback.call();times.append((Time.get_ticks_usec()-began)/1000.0)
 rows.append({"label":label,"milliseconds":times});print("MICRO ",JSON.stringify(rows[-1]))
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var pair:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
 var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(pair.player);var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new();var catalog:RefCounted=root.get_node("CardDatabase").get_development_catalog();var world=codec.restore(pair.world,pair.player,run,catalog)
 if world==null:push_error(codec.error);quit(1);return
 time_call("finance report",func():return run.get_studio_finance_report())
 time_call("cycle preflight",func():return run.can_complete_productive_cycle())
 time_call("player native snapshot",func():return adapter.snapshot(run))
 time_call("world UI observation",func():return world.observation())
 time_call("world native snapshot",func():return codec.snapshot(world,adapter))
 time_call("full player capture",func():return adapter.capture(run))
 var file:=FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE);file.store_string(JSON.stringify({"rows":rows,"source":preload("res://scripts/simulation/development_replay.gd").source_identity()}));file.close();quit(0)
