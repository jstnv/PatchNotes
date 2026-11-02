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

 time_call("cycle preflight",func():return run.can_complete_productive_cycle())
 var began:=Time.get_ticks_usec()
 for index in 16:
  if not run.can_complete_productive_cycle():push_error("Legal repeated cycle preflight rejected");quit(1);return
 var elapsed:float=(Time.get_ticks_usec()-began)/1000.0
 rows.append({"warm16_preflight_ms":elapsed,"acceptance_ms":160.0})
 print("WARM16 ",elapsed)
 if elapsed>=160:push_error("Repeated unchanged UI preflight exceeds160ms budget")
 var file:=FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE);file.store_string(JSON.stringify({"rows":rows,"source":preload("res://scripts/simulation/development_replay.gd").source_identity()}));file.close();quit(1 if elapsed>=160 else 0)
