extends "res://scripts/debug/verify_fanbase_checkpoint.gd"
func _run() -> void:
 var run:=fan_run();var p:=fan_project(run,7.0,"Strong")
 print("STRONG scope=",p.get_current_scope()," review=",p.get_review_result().get_final_review())
 assert(run.register_release(p))
 for i in range(4):assert(run.complete_productive_action())
 print("FANS_AFTER_STRONG ",run.get_fans()," ",run.get_fanbase_history())
 var weak:=fan_project(run,4.0,"Weak");assert(run.register_release(weak))
 for i in range(8):
  assert(run.complete_productive_action())
  if i%4==3:print("FANS_AFTER_WEAK ",i+1," ",run.get_fanbase_history())
 quit()
