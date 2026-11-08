extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,s:String)->void:
 checks+=1
 if not ok:failures+=1
 print(("PASS: " if ok else "FAIL: ")+s)
func _initialize()->void:go.call_deferred()
func go()->void:
 var path:=OS.get_environment("PN_PRIOR_SAVE")
 var envelope:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 var raw:String=envelope.get("payload_utf8","")
 check(raw.sha256_text()==envelope.get("payload_sha256"),"real prior checkpoint checksum")
 var payload:Dictionary=JSON.parse_string(raw)
 var old_source:String=OS.get_environment("PN_EXPECTED_SOURCE")
 check(payload.rival_world.source_identity==old_source and payload.rival_world.studios.size()==8,"exact prior source and eight actors")
 check(payload.content_revision==StudioCheckpoint.new().revision(),"prior player matches current rules revision")
 var player_payload:Dictionary=payload.duplicate(true)
 player_payload.erase("rival_world")
 var adapter:=StudioCheckpoint.new()
 var player=adapter.hydrate(player_payload)
 check(player!=null,"prior player hydrates: "+adapter.error)
 if player==null:print("RESULT ",checks," ",failures);quit(1);return
 var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new()
 var catalog=root.get_node("CardDatabase").get_development_catalog()
 var world=codec.restore(payload.rival_world,player_payload,player,catalog)
 check(world!=null,"prior eight-rival world restores: "+codec.error)
 if world!=null:
  check(world.studios.size()==8 and int(world.cycle)==int(payload.run.completed_run_cycles),"rivals and cycle preserved")
  var next:Dictionary=codec.capture(world)
  check(not next.is_empty() and next.source_identity==preload("res://scripts/simulation/development_replay.gd").source_identity(),"recapture adopts new source identity")
  var again=codec.restore(next,player_payload,player,catalog)
  check(again!=null,"recaptured world restores: "+codec.error)
  var bad:Dictionary=payload.rival_world.duplicate(true);bad.source_identity="unknown"
  check(codec.restore(bad,player_payload,player,catalog)==null,"unknown source rejected")
  bad=payload.rival_world.duplicate(true);bad.erase("annual_awards")
  check(codec.restore(bad,player_payload,player,catalog)==null,"missing required awards rejected")
  var wrong:Dictionary=player_payload.duplicate(true);wrong.content_revision="wrong"
  check(codec.restore(payload.rival_world,wrong,player,catalog)==null,"wrong paired content revision rejected")
 print("PRIOR_SOURCE_ACCEPTANCE checks=",checks," failures=",failures)
 quit(1 if failures else 0)

