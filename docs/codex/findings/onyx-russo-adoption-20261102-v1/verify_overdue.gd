extends SceneTree
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:go.call_deferred()
func go()->void:
 await process_frame
 var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Overdue Overview",&"action",[])
 check(run.spend_cash_cents(run.get_cash_cents()),"Fixture legally spends its cash")
 for cycle in 4:check(run.complete_productive_action(),"Legal productive cycle "+str(cycle+1))
 var report:=run.get_studio_finance_report()
 check(report.total_overdue_cents>0,"Monthly settlement creates genuine unpaid rent")
 var overview:=preload("res://scripts/ui/studio_overview.gd").new();root.add_child(overview);overview.size=Vector2(800,500);overview.bind_run(run);await process_frame
 check(overview.values.Cash.text=="-$300.00" and report.total_overdue_cents==30000,"Overview agrees with current negative net-bankroll rule")
 check(overview.captions["Next Bill"].text.contains("month 2 end"),"Next Bill caption uses the four-week calendar")
 var file:=FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures}));file.close()
 overview.free();quit(failures)
