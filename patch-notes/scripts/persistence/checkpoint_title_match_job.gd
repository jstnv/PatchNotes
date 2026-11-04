extends RefCounted
## Detached, read-only one-shot check; keeps UI frames moving while the caller
## holds its Studio writer lease. A mismatch always falls back to strict load.
var matched:=false
var _task:=-1
var _title_job: RefCounted
var _directory: String
var _lease: TCPServer
var _catalog: RefCounted
func start(title_job: RefCounted,store: StudioCheckpointStore,definitions: RefCounted)->void:
 if store==null or store._writer==null:return
 _title_job=title_job;_directory=store.directory;_lease=store._writer
 _catalog=preload("res://scripts/market/rival_opening_loader.gd").copy_catalog(definitions)
 _task=WorkerThreadPool.add_task(_match.bind(self),false,"Verify unchanged Studio save")
func _match(_lifetime: RefCounted)->void:
 matched=_title_job._matches_directory(_directory,_catalog)
func poll()->bool:
 if _task==-2:return true
 if _task<0:return true
 if not WorkerThreadPool.is_task_completed(_task):return false
 WorkerThreadPool.wait_for_task_completion(_task);_task=-2;return true

func lease_unchanged(store: StudioCheckpointStore)->bool:
 return store!=null and _lease!=null and store._writer==_lease and _lease.is_listening()
