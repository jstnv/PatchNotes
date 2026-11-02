extends SceneTree
const Browser=preload("res://scripts/ui/engine_market_browser.gd")
const WorldCodec=preload("res://scripts/market/rival_world_checkpoint.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:verify.call_deferred()
func verify()->void:
 await process_frame
 var run:=RunState.new();run.initialize_cash(0)
 check(run.create_studio_with_traits("Progression Launch",&"action",[]),"Fresh normal Studio")
 var cash:=run.get_cash_cents();var cycles:=run.get_completed_run_cycles()
 var made:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Launch Engine"))
 check(made.get("ok",false) and run.get_cash_cents()==cash-10000 and run.get_completed_run_cycles()==cycles,"Normal100-dollar zero-cycle creation")
 if not made.get("ok",false):quit(1);return
 var id:StringName=made.engine_id
 check(run.get_engine_feature_state().engines[id].capacity==25,"Fresh proprietary engine starts at25 Scope")
 check(run.ProprietaryEngines.VERSION==3,"Capacity revision is explicitly versioned")
 var browser:=Browser.new();root.add_child(browser);browser.open(run,null,id)
 var entry:=browser.find_child("OpenEngineSkillTree",true,false) as Button
 check(entry!=null and entry.is_visible_in_tree() and not entry.disabled,"Owned engine has a visible Skill Tree entry")
 if entry!=null:
  entry.pressed.emit();await process_frame
  check(browser.skill_tree.is_visible_in_tree() and not browser.details.visible and not browser.creation.visible,"Skill Tree is its own normal engine destination")
  var rendered:=text_of(browser.skill_tree)
  for value in ["Graphics","Sound","Technology","Design","4-Color Palette","8-Bit Sound","Keyboard & Mouse","Text","$125","$250","Generation III","Generation IV","30","35"]:check(rendered.contains(value),"Skill Tree shows "+value)
  check(browser.find_child("BackToEngine",true,false)!=null,"Skill Tree provides Back to selected engine")
 browser._inspect(&"public_action")
 if entry!=null:check(not entry.visible,"Public engine cannot open upgrades")
 browser.queue_free();await process_frame
 var pair:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
 var adapter:=StudioCheckpoint.new();var native:Dictionary=adapter._decode_payload(pair.player)
 var old:=adapter.hydrate(pair.player)
 check(old!=null,"Actual preceding Studio loads")
 if old!=null:
  for engine:StringName in native.run.get("proprietary_engines",{}).get("engines",{}):
   check(old.get_engine_feature_state().engines[engine].capacity==native.run.engine_features.engines[engine].capacity+5,"Existing engine receives revised capacity")
   check(old.get_proprietary_engine_row(engine)==native.run.proprietary_engines.engines[engine],"Existing nodes/challenges/receipts are unchanged")
  var codec:=WorldCodec.new();var world:=codec.restore(pair.world,pair.player,old,root.get_node("CardDatabase").get_development_catalog())
  check(world!=null,"Genuine old player/world still restores: "+codec.error)
  if world!=null:
   var captured:={"player":adapter.capture(old),"world":codec.capture(world)}
   FileAccess.open(OS.get_environment("PN_CONTRACT_FIXTURE_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(captured))
   print("CAPTURED_SOURCE ",captured.world.get("source_identity",""))
 FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
 quit(1 if failures else 0)
func text_of(node:Node)->String:
 var text:String=str(node.get("text")) if node is Label or node is Button else ""
 for child in node.get_children():text+="\n"+text_of(child)
 return text
