extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 var r:=RunState.new();assert(r.initialize_cash(0) and r.create_studio_with_traits("Four cycles",&"action",[]) and r.finalize_starter_selection())
 var initial:=r.get_cash_cents()
 for c in range(1,5):
  check(r.complete_productive_action(),"Productive action commits "+str(c))
  check(r.get_current_month()==c/4+1,"Fresh month at action "+str(c))
  check(r.get_cash_cents()==initial-(30000 if c==4 else 0),"Exactly one unchanged monthly rent at action "+str(c))
 FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"cycle":r.get_completed_run_cycles(),"month":r.get_current_month(),"cash":r.get_cash_cents()}));quit(0 if failures.is_empty() else 1)
