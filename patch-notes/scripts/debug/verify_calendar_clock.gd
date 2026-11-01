extends SceneTree
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
 await process_frame
 var path="res://scripts/calendar/calendar_clock.gd"
 check(ResourceLoader.exists(path),"One authoritative calendar clock exists")
 if ResourceLoader.exists(path):
  var c=load(path);var p=c.fresh()
  for n in range(97):
   check(c.month(n,p)==n/4+1 and c.year(n,1980,p)==1980+n/48,"Fresh quarter-month date "+str(n))
   check(c.is_boundary(n,p)==(n>0 and n%4==0),"Fresh monthly boundary "+str(n))
  check(c.month_of_year(48,p)==1 and c.year(48,1980,p)==1981,"One year after48 actual actions")
  for cut in [0,1,8,9,47,48]:
   var m=c.upgrade({},cut)
   check(c.position(cut,m)==c.position(cut,{}),"Migration preserves exact date/progress "+str(cut))
   check(c.upgrade(m,cut+1)==m,"Migration is idempotent "+str(cut))
   for n in range(cut+1,cut+13):
    var pos=c.position(n,m)
    check(c.cycle_at(pos.month_index,pos.quarter,m)==n,"Clock inverse "+str(cut)+":"+str(n))
  var odd=c.upgrade({},9)
  check(c.month_end(5,odd)==11 and c.month_end(6,odd)==15,"Odd legacy cutover has correct future boundaries")
  check(c.retarget_cycle(12,{},odd)==15 and c.retarget_cycle(8,{},odd)==8,"Future dues map by date; past timestamps stay exact")
  check(c.first_full_month_end(1,p)==8 and c.first_full_month_end(0,p)==4,"Full-month hire/loan timing")
  check(c.action_month(4,true,p)==1 and c.action_month(4,false,p)==2,"Closing and zero-cycle finance rows")
  check(c.label(48,1980,p).contains("1981") and c.label(48,1980,p).contains("Month 1"),"Date labels use year and month-of-year")
 var native=load(path).fresh()
 var wire=CheckpointCodec.new().encode(native,CheckpointSchema.calendar_profile())
 check(load(path).from_saved_profile(wire)==native and not load(path).valid(wire),"Typed saved display decodes without weakening native validation")
 var run:=RunState.new();run.initialize_cash(0)
 check(run.create_studio_with_traits("Calendar clock",&"action",[]) and run.finalize_starter_selection(),"New Studio selects quarter-month timing")
 for n in range(1,5):
  check(run.complete_productive_action() and run.get_current_month()==1+n/4,"Four actual productive actions complete exactly one month")
  check(run.get_current_half()==(n%4)/2+1,"Legacy half query still means half; labels show Weeks")
 check(run.get_calendar_label().contains("Month 2, Week 1"),"Week presentation resets with the new month")
 print("CALENDAR_CLOCK checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
