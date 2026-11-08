extends SceneTree
var checks:=0
var failures:=0
class Store extends StudioCheckpointStore:
 func acquire() -> bool:
  if _writer != null: return true
  _writer=TCPServer.new()
  return _writer.listen(49188,"127.0.0.1")==OK
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void: call_deferred("verify")
func verify()->void:
 var run:=RunState.new()
 check(run.initialize_cash(0) and run.create_studio_with_traits("Overflow test",&"action",[]),"Create isolated Studio")
 var adapter:=StudioCheckpoint.new()
 var store:=Store.new("user://overflow-private",adapter.validate)
 var base:Dictionary=adapter.capture(run)
 var first:Dictionary=store.save(base)
 check(first.status==&"saved","Publish first valid checkpoint")
 if first.status!=&"saved":quit(1);return
 var prior_hash:=FileAccess.get_sha256(first.path)
 var many:Dictionary={"version":1,"pending":[],"dismissed":[]}
 var text:="x".repeat(4096)
 for i in 6300:
  many.pending.append({"id":"progress:%d"%i,"kind":"progress","topic":"","title":"Progress","body":text})
 check(run.set_studio_notice_state(many),"All oversized notices remain in memory")
 var payload:Dictionary=adapter.capture(run)
 check(not payload.is_empty(),"Large valid state is encoded for publication")
 if payload.is_empty():print("ERROR: ",adapter.error);quit(1);return
 var coordinator:=CheckpointCoordinator.new()
 coordinator.run=run;coordinator.store=store;coordinator.in_studio=true;coordinator.pending=true
 check(not coordinator.flush() and coordinator.failure=="SAVE_TOO_LARGE","Studio reports oversized checkpoint and blocks publication")
 check(not run.checkpoint_mutations_allowed,"Further gameplay mutations are blocked until the checkpoint can be saved")
 check(FileAccess.file_exists(first.path) and FileAccess.get_sha256(first.path)==prior_hash,"Previous published checkpoint remains untouched")
 check(run.get_studio_notice_state().pending.size()==6300,"Every oversized notice remains available in the running session")
 var reduced:Dictionary={"version":1,"pending":[many.pending[0]],"dismissed":[]}
 check(run.set_studio_notice_state(reduced),"Player can dismiss queued notices despite save failure")
 check(coordinator.flush() and run.checkpoint_mutations_allowed,"A later save succeeds and re-enables mutations after the queue is reduced")
 coordinator.free()
 print("OVERFLOW_BOUNDARY checks=%d failures=%d"%[checks,failures]);store.release_writer();quit(failures)
