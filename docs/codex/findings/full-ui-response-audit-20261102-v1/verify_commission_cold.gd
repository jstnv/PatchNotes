extends SceneTree
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func expect(ok: bool,label: String) -> void:
 checks+=1
 print("PASS: " if ok else "FAIL: ",label)
 if not ok: failures+=1
func _initialize() -> void: verify.call_deferred()
func verify() -> void:
 var args:=OS.get_cmdline_user_args()
 var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 expect(report is Dictionary and report.get("failures",-1)==0,"Retained legal producer report is successful")
 if not report is Dictionary or not report.has("checkpoint"):quit(1);return
 var dto: Dictionary=report.checkpoint
 var adapter:=StudioCheckpoint.new()
 var restored: RunState=adapter.hydrate(dto)
 expect(restored!=null,"Fresh-process strict Commission player codec accepts genuine legal career: "+adapter.error)
 if restored!=null:
  expect(adapter.capture(restored)==dto,"Whole typed player, finance, history, engines and RNG wire DTO roundtrip is exact")
  expect(Replay.freeze(restored.get_contract_search_state())==report.search,"All legal Search offers and receipts remain exact")
  expect(restored.get_released_game_ids().size()==int(report.results[0].final_release_count),"Every legal released game is retained")
  expect(restored.get_completed_run_cycles()==int(report.results[0].final_run_cycle),"Calendar cycle is retained without a productive action")
  var altered:=dto.duplicate(true)
  altered["unexpected_cold_field"]=true
  expect(StudioCheckpoint.new().hydrate(altered)==null,"Unknown top-level player field remains rejected")
 var result:={"checks":checks,"failures":failures,"source":Replay.source_identity(),"scope":"Fresh independent process, strict player DTO only; paired world Continue/durable Store acceptance is separate"}
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(result))
 print("COMMISSION_COLD checks=%d failures=%d"%[checks,failures]);quit(failures)
