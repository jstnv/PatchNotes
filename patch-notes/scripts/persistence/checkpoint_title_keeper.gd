## Own a detached, read-only title inspection when its scene is replaced.
## A new title may adopt the same task; no second worker needs to race it.
extends Node

var job: RefCounted

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if job==null:queue_free()

func _process(_delta: float) -> void:
	if job==null or job.poll():
		job=null
		_forget()
		queue_free()

func _forget() -> void:
	var root:=get_tree().root
	if not root.has_meta("checkpoint_title_inspections"):return
	var keepers: Array=root.get_meta("checkpoint_title_inspections")
	keepers.erase(self)
	if keepers.is_empty():root.remove_meta("checkpoint_title_inspections")
	else:root.set_meta("checkpoint_title_inspections",keepers)

func _exit_tree() -> void:
	_forget()
	# During application shutdown the tree itself can no longer poll. The task
	# must finish before its detached data and the worker pool are released.
	_join_pending()

func root_exiting() -> void:
	# The root may exit before a deferred add_child has run.
	_join_pending()
	if not is_inside_tree():queue_free()

func _join_pending() -> void:
	if job!=null:
		var task_id: int=job._task
		if task_id>=0:WorkerThreadPool.wait_for_task_completion(task_id)
		job=null
