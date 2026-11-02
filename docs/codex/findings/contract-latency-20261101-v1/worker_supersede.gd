extends SceneTree
const Writer=preload("res://scripts/persistence/checkpoint_write.gd")
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	var job:=Writer.new()
	check(job.has_method("supersede") and job.has_method("_begin_publication"),"Writer distinguishes supersedable preparation from publication")
	if failures:quit(failures);return
	job.supersede()
	check(not job._begin_publication(),"Newer Studio state can discard preparation before Store starts")
	job=Writer.new()
	check(job._begin_publication(),"Current writer enters publication")
	job.supersede()
	check(job._begin_publication(),"Once publication starts it cannot be cancelled")
	print("CONTRACT_WORKER_SUPERSEDE checks=%d failures=%d"%[checks,failures]);quit(failures)
