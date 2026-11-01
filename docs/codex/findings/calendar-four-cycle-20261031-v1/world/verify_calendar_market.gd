extends SceneTree
const Market=preload("res://scripts/market/market_transaction_trial.gd")
const Book=preload("res://scripts/market/rival_standard_book.gd")
const Clock=preload("res://scripts/calendar/calendar_clock.gd")
class ProfileRun extends RunState:
	var test_calendar: Dictionary=Clock.fresh()
	func get_calendar_profile() -> Dictionary:return test_calendar.duplicate(true)
var checks:=0
var failures:=0
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",label)
func _initialize() -> void:
	var run:=ProfileRun.new();var world:=RivalWorld.new()
	world.player=run;world.cycle=1
	expect(Market.preview(world,2)==Market.neutral(),"Fresh four-cycle world retains January Market at cycle2")
	world.cycle=3
	var fresh: Dictionary=Market.preview(world,4)
	expect(fresh.get("version")==5 and fresh.get("calendar")==Clock.fresh() and fresh.get("cycle_start")==4,"Fresh first February snapshot carries calendar proof")
	run.test_calendar=Clock.upgrade({},3);world.cycle=3
	world.market_snapshot={"version":2,"cycle_start":2,"facts":[],"id":Market.identifier(2,[])}
	var frozen:=world.market_snapshot.duplicate(true)
	expect(Market.preview(world,4)==frozen,"Odd legacy cutover retains saved month until actual boundary")
	world.cycle=4
	var odd: Dictionary=Market.preview(world,5)
	expect(odd.get("version")==5 and odd.get("cycle_start")==5 and Market.valid(odd),"Odd raw cycle is a valid converted month boundary")
	var old_book: Dictionary=Book.snapshot({},2,72)
	expect(old_book.version==4 and not old_book.has("calendar") and Book.valid_snapshot(old_book),"Legacy Book snapshot shape remains version4")
	var script: Object=Market
	expect(script.has_method("within_window"),"Calendar presence-window helper is exposed")
	if script.has_method("within_window"):
		expect(script.call("within_window",1,24,Clock.fresh()),"Title remains present inside six fresh calendar months")
		expect(not script.call("within_window",1,28,Clock.fresh()),"Title expires beyond six fresh calendar months")
		expect(script.call("within_window",1,12,{}) and not script.call("within_window",1,14,{}),"Legacy twelve-cycle window remains exact")
	var basis: Dictionary=Book.build_records([{"studio_id":"rival","release_id":"historical","release_cycle":0,"review_tenths":65,"genre":"action","cores":[33,33,33,33]}],72)
	var dated_book: Dictionary=Book.snapshot(basis,5,72,[],run.test_calendar)
	expect(dated_book.get("version")==5 and dated_book.get("cycle_start")==5 and Book.valid_snapshot(dated_book),"Converted Book uses actual odd raw boundary")
	var details: Dictionary=Book.details(dated_book,"probe",&"action")
	expect(Book.is_details(details) and Book.valid_details(details,&"action") and Book.proof(details.snapshot_id).get("calendar")==run.test_calendar,"New Book details retain calendar in exact proof")
	var old_details: Dictionary=Book.details(Book.snapshot(basis,2,72),"probe",&"action")
	expect(Book.valid_details(old_details,&"action") and str(old_details.snapshot_id).begins_with(Book.PREFIX) and not Book.proof(old_details.snapshot_id).has("calendar"),"Old Book proof shape stays exact")
	var factor: Dictionary=Market.sales_factor(odd,"probe","release","action","fantasy")
	expect(Market.valid_factor(factor) and factor.cycle_start==5 and factor.size()==7,"New odd-boundary factor keeps seven fields")
	var old_factor: Dictionary=Market.neutral_factor();old_factor.cycle_start=5;old_factor.snapshot_id=Market.identifier(5,[])
	expect(not Market.valid_factor(old_factor),"Legacy factor prefix still rejects odd boundary")
	var opening: Dictionary=Market.snapshot(0,[],Clock.fresh())
	var opening_details: Dictionary=Market.targets(opening,"probe",&"action")
	expect(Market.valid_details(opening_details,&"action") and Market.valid_factor(Market.sales_factor(opening,"probe","release","action","fantasy")),"Explicit converted cycle-zero snapshots have valid references")
	print("CALENDAR_MARKET checks=%d failures=%d"%[checks,failures]);quit(int(failures>0))
