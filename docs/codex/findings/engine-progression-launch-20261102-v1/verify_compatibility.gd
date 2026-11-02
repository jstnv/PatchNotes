extends SceneTree
const WorldCodec=preload("res://scripts/market/rival_world_checkpoint.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var pair:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
 var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(pair.player)
 check(run!=null,"Genuine exact predecessor player hydrates")
 if run==null:quit(1);return
 var before:Dictionary=adapter._decode_payload(pair.player)
 var after:Dictionary=adapter._decode_payload(adapter.capture(run))
 var expected:Dictionary=before.duplicate(true)
 expected.run.proprietary_engines.version=3
 for id:StringName in expected.run.proprietary_engines.engines:expected.run.engine_features.engines[id].capacity+=5
 check(after==expected,"Entire predecessor player changes only proprietary version/capacity")
 var catalog=root.get_node("CardDatabase").get_development_catalog()
 var codec:=WorldCodec.new();var world:=codec.restore(pair.world,pair.player,run,catalog)
 check(world!=null,"Exact predecessor world restores: "+codec.error)
 if world==null:quit(1);return
 var world_expected:Dictionary=pair.world.duplicate(true);var actual:Dictionary=codec.capture(world)
 world_expected.source_identity=actual.source_identity
 check(actual==world_expected,"Entire preceding rival world changes only source stamp")
 var active:=-1
 for i in pair.world.studios.size():
  if pair.world.studios[i].development!=null:active=i;break
 check(active>=0,"Genuine preceding active-rival fixture retained")
 for mode in ["annual","budget","engine","capacity","source","rng","calendar"]:
  var bad:Dictionary=pair.world.duplicate(true)
  if mode=="annual":bad.erase("annual_awards")
  elif mode=="budget":bad.studios[active].development.erase("pass_budget")
  elif mode=="engine":bad.studios[active].development.project.erase("_engine_id")
  elif mode=="capacity":bad.studios[active].development.project.erase("_engine_capacity")
  elif mode=="source":bad.source_identity="unknown-engine-source"
  elif mode=="rng":bad.studios[active].run.rng[0].value.state="01"
  else:bad.cycle=str(int(bad.cycle)+1)
  check(WorldCodec.new().restore(bad,pair.player,run,catalog)==null,"Protected predecessor state still rejects: "+mode)
 var id:StringName=run.get_proprietary_engine_state().engines.keys()[0]
 var bad_run:=adapter.hydrate(pair.player)
 bad_run._proprietary_engines.version=2
 check(adapter.capture(bad_run).is_empty(),"Old version cannot claim new25-base capacities")
 bad_run=adapter.hydrate(pair.player);bad_run._engine_features.engines[id].capacity=20
 check(adapter.capture(bad_run).is_empty(),"New version cannot silently retain old20-base capacities")
 for capacity in [0,19,21,26,36,40,45]:
  check(not run.ProprietaryEngines.valid_frozen_capacity(capacity,35),"Reject impossible frozen proprietary capacity "+str(capacity))
 for capacity in [20,25,30,35]:check(run.ProprietaryEngines.valid_frozen_capacity(capacity,35),"Preserve legitimate earlier frozen capacity "+str(capacity))
 check(not run.ProprietaryEngines.valid_frozen_capacity(30,25),"Frozen projects cannot exceed current engine capacity")
 check(run.ProprietaryEngines.node(&"graphics",3).is_empty() and run.ProprietaryEngines.node(&"graphics",4).is_empty(),"Unimplemented generations have no purchase definitions")
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures else 0)
