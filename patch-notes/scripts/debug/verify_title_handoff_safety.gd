extends SceneTree
class PrivateStore extends StudioCheckpointStore:
 func acquire()->bool:
  if _writer!=null:return true
  var server:=TCPServer.new()
  if server.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")!=OK:return false
  _writer=server;return true
var checks:=0
var failures:Array[String]=[]
func expect(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:go.call_deferred()
func wait_job(job:RefCounted)->bool:
 var deadline:=Time.get_ticks_msec()+120000
 while not job.poll() and Time.get_ticks_msec()<deadline:await process_frame
 return job.poll()
func wait_op(op:RefCounted)->bool:
 var deadline:=Time.get_ticks_msec()+120000
 while not op.done and Time.get_ticks_msec()<deadline:
  op.advance_async();await process_frame
 return op.done
func write_bytes(path:String,data:PackedByteArray)->bool:
 var f:=FileAccess.open(path,FileAccess.WRITE)
 if f==null:return false
 f.store_buffer(data);f.close();return true
func go()->void:
 await process_frame
 var catalog:RefCounted=root.get_node("CardDatabase").get_development_catalog()
 var owner:=CheckpointCoordinator.new();root.add_child(owner);owner.store=PrivateStore.new("user://saves/studio",owner._validate_payload);owner.rival_catalog=catalog
 var job=preload("res://scripts/persistence/checkpoint_read_job.gd").new();job.start(owner.store.directory,catalog)
 expect(await wait_job(job),"Title inspection completes")
 expect(job.inspected.get("status")==&"valid" and job.player!=null and job.world!=null,"Title fully validates pair")
 if job.player==null or job.world==null:finish();return
 var path:String=job.verified_source.path;var original:PackedByteArray=FileAccess.get_file_as_bytes(path)
 expect(not job.matches_current_generation(owner.store,catalog),"No lease cannot reuse validated title")
 expect(owner.store.acquire(),"Private writer lease acquired")
 expect(job.matches_current_generation(owner.store,catalog),"Exact current file and catalog reuse")
 var lease_job=preload("res://scripts/persistence/checkpoint_title_match_job.gd").new();lease_job.start(job,owner.store,catalog)
 owner.store.release_writer();expect(owner.store.acquire(),"Acquire a replacement writer lease")
 expect(await wait_job(lease_job),"Detached check drains after lease change")
 expect(not lease_job.lease_unchanged(owner.store),"Released and reacquired lease cannot promote old proof")
 var seq=job.inspected.payload.sequence;job.inspected.payload.sequence="999999"
 expect(not job.matches_current_generation(owner.store,catalog),"Mutated title DTO cannot reuse proof");job.inspected.payload.sequence=seq
 var identity:String=job.verified_identity;job.verified_identity="changed"
 expect(not job.matches_current_generation(owner.store,catalog),"Changed code identity cannot reuse proof");job.verified_identity=identity
 var different=PrivateStore.new("user://other-studio");different._writer=owner.store._writer
 expect(not job.matches_current_generation(different,catalog),"Different save directory cannot reuse proof");different._writer=null
 var other_catalog:RefCounted=preload("res://scripts/market/rival_opening_loader.gd").copy_catalog(catalog)
 var ids:Array=other_catalog.cards.keys();var card:CardData=other_catalog.cards[ids[0]];card.scope+=1
 expect(not job.matches_current_generation(owner.store,other_catalog),"Changed card definitions cannot reuse proof")
 var newest:=owner.store._path(int(job.verified_source.sequence)+1)
 expect(write_bytes(newest,original),"Different newest generation appears")
 expect(not job.matches_current_generation(owner.store,catalog),"Newer generation cannot reuse proof")
 expect(DirAccess.remove_absolute(newest)==OK,"Remove test-only generation")
 var broken:=original.duplicate();broken[broken.size()/2]=broken[broken.size()/2]^1
 expect(write_bytes(path,broken),"Corrupt test generation after title inspection")
 expect(not job.matches_current_generation(owner.store,catalog),"Changed bytes cannot reuse proof")
 var op=owner.begin_load(job.cache_store,job);expect(await wait_op(op),"Corrupt generation fallback completes")
 expect(op.restored==null and op.inspected.get("status")!=&"valid","Corrupt replacement is not restored")
 expect(write_bytes(path,original),"Restore test original")
 expect(job.matches_current_generation(owner.store,catalog),"Original exact bytes remain reusable")
 var replacement:=FileAccess.get_file_as_bytes(OS.get_environment("PN_REPLACEMENT_BYTES"));expect(not replacement.is_empty() and replacement!=original,"Distinct valid replacement exists")
 expect(write_bytes(path,replacement),"Install alternate private save")
 expect(not job.matches_current_generation(owner.store,catalog),"Alternate valid bytes do not reuse old title")
 var replacement_job=preload("res://scripts/persistence/checkpoint_read_job.gd").new();replacement_job.start(owner.store.directory,catalog);expect(await wait_job(replacement_job),"Alternate independent read completes")
 expect(replacement_job.inspected.get("status")==&"valid" and replacement_job.player!=null,"Alternate save validates")
 var restored=owner.begin_load(job.cache_store,job);expect(await wait_op(restored),"Alternate fallback load completes")
 expect(restored.restored!=null,"Alternate save restores via strict fallback")
 if restored.restored!=null and replacement_job.player!=null:
  expect(StudioCheckpoint.new().capture(restored.restored)==StudioCheckpoint.new().capture(replacement_job.player),"Fallback restores alternate complete player state")
  var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new()
  expect(codec.capture(owner.rival_world)==codec.capture(replacement_job.world),"Fallback restores alternate complete rival world")
 expect(FileAccess.get_file_as_bytes(path)==replacement,"Fallback does not rewrite replacement bytes")
 owner.store.release_writer();owner.queue_free();await process_frame;finish()
func finish()->void:
 var f=FileAccess.open(OS.get_environment("PN_PERF_REPORT"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures}));f.close()
 print("TITLE_HANDOFF_SAFETY checks=",checks," failures=",failures.size());quit(0 if failures.is_empty() else 1)
