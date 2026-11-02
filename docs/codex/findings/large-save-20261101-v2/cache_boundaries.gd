extends SceneTree
const Reference=preload("res://../docs/codex/findings/large-save-20261101-v2/fanbase_reference.gd")
const Clock=preload("res://scripts/calendar/calendar_clock.gd")
const JournalKey=preload("res://scripts/finance/journal_key.gd")
var checks:=0
var failures:=0
class ParallelCheck extends RefCounted:
	var data: Dictionary
	func work() -> bool:
		for i in 12:
			if not StudioFanbase.validate(data.state,data.records,data.metadata,data.cycle,0,data.closed,data.close):return false
		return true
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func fresh(calendar: Dictionary={}) -> Dictionary:
	return {"state":StudioFanbase.create(0,calendar),"records":{},"metadata":{},"cycle":0,"closed":{},"close":-1,"calendar":calendar}
func launch(x: Dictionary,id: StringName) -> void:
	var record:=ReleasedGameSales.create(id,300,70,100,10000,0,x.calendar,x.calendar)
	x.records[id]=record
	x.metadata[id]={"release_cycle":x.cycle,"review":{"launch_fans":x.state.fans,"fan_awareness":StudioFanbase.awareness_for(x.state.fans)}}
	x.state=StudioFanbase.register_release(x.state,record,x.state.fans)
func tick(x: Dictionary,campaign: bool=false,factor: Dictionary={}) -> void:
	var next: Dictionary={};x.cycle+=1
	for id: StringName in x.records:
		next[id]=x.records[id] if x.close>=0 and x.cycle>x.close and x.closed.has(id) else ReleasedGameSales.next_cycle(x.records[id],x.cycle,Clock.is_boundary(x.cycle,x.calendar),campaign,factor.get("factor_bp",10000),factor.get("snapshot_id","market-0-neutral"),factor)
	x.state=StudioFanbase.plan(x.state,x.records,next,x.cycle,x.closed if x.close>=0 and x.cycle>x.close else {})
	x.records=next
func agree(x: Dictionary,label: String,expected: bool=true) -> void:
	var snapshot:=var_to_bytes(x)
	var cold:=Reference.validate(x.state,x.records,x.metadata,x.cycle,0,x.closed,x.close)
	var warm:=StudioFanbase.validate(x.state,x.records,x.metadata,x.cycle,0,x.closed,x.close)
	check(cold==expected and warm==cold,label)
	check(var_to_bytes(x)==snapshot,"Inputs stay detached: "+label)
func _initialize() -> void:
	await process_frame
	var x:=fresh(Clock.fresh());tick(x);launch(x,&"before");agree(x,"Warm same-cycle pre-award launch")
	var receipt: Dictionary={"id":&"annual-awards:1980","year":1980,"cycle":1,"nominations":1,"wins":1,"fans":50,"awareness":5,"before":[&"before"]}
	x.state=StudioFanbase.AwardReceipts.plan(x.state,receipt)
	agree(x,"Award added at a previously cached boundary")
	launch(x,&"after");agree(x,"Same-cycle post-award launch cannot reuse earlier cutoff")
	var bad:=x.duplicate(true);bad.state.annual_awards[0].before=[&"after"]
	agree(bad,"Changed receipt launch ordering rejects",false)
	x=fresh(Clock.upgrade({},9));launch(x,&"frozen-1977")
	for i in 9:tick(x)
	agree(x,"Odd legacy calendar cutoff before closure")
	x.closed[&"frozen-1977"]=true;x.close=9
	for i in 6:tick(x);agree(x,"Frozen historical title through odd calendar/month boundary")
	var campaign:=fresh(Clock.fresh());launch(campaign,&"campaign")
	for i in 5:tick(campaign)
	agree(campaign,"Uncampaigned history warms cache")
	var changed:=fresh(Clock.fresh());launch(changed,&"campaign")
	for i in 5:tick(changed,i==4)
	agree(changed,"Valid changed historical campaign recalculates from launch")
	for i in 4:tick(campaign,i==3)
	agree(campaign,"Future campaign extends an unchanged valid prefix")
	var facts: Array=[{"studio_id":"other","release_id":"other-1","release_cycle":0,"genre":"action","theme":"fantasy","review_tenths":70,"cores_available":true,"cores":[1,1,1,1]}]
	var market:=ReleasedGameSales.Market.snapshot(4,facts,Clock.fresh())
	var factor:=ReleasedGameSales.Market.sales_factor(market,"owner","factor","action","fantasy")
	check(not factor.is_empty() and factor.factor_bp<10000,"Market computes a valid changed historical factor")
	var factor_base:=fresh(Clock.fresh());launch(factor_base,&"factor")
	for i in 5:tick(factor_base)
	agree(factor_base,"Neutral historical factor warms prefix")
	var factor_changed:=fresh(Clock.fresh());launch(factor_changed,&"factor")
	for i in 5:tick(factor_changed,false,factor if i==4 else {})
	agree(factor_changed,"Valid changed historical market factor recomputes exactly")
	market=ReleasedGameSales.Market.snapshot(8,facts,Clock.fresh())
	factor=ReleasedGameSales.Market.sales_factor(market,"owner","factor","action","fantasy")
	for i in 4:tick(factor_base,false,factor if i==3 else {})
	agree(factor_base,"Future market factors extend the unchanged prefix")
	var saved:=campaign.duplicate(true)
	campaign.state.months[0].ending+=1;agree(campaign,"Historical month edit cannot poison retained state",false)
	agree(saved,"Original detached state remains valid after caller mutation")
	var job:=ParallelCheck.new();job.data=saved.duplicate(true)
	var thread:=Thread.new();thread.start(job.work)
	for i in 12:agree(saved,"Concurrent exact-prefix validation")
	check(thread.wait_to_finish(),"Background calculation reuse remains valid")
	for i in 24:check(StudioFanbase.validate(StudioFanbase.create(i),{},{},0,i),"Independent valid starting state fills eviction table")
	var cost:=0
	for entry: Dictionary in StudioFanbase._replays:
		check(entry.cost==entry.key.size()+var_to_bytes([entry.rebuilt,entry.current]).size(),"Replay byte accounting includes both native copies")
		cost+=entry.cost
	check(StudioFanbase._replays.size()<=StudioFanbase.REPLAY_LIMIT and cost==StudioFanbase._replay_bytes and cost<=StudioFanbase.REPLAY_BYTES,"Replay count and byte limits survive eviction")
	agree(saved,"Evicted old context still reconstructs exactly")
	var ledger:=StudioFinanceLedger.create(10000)
	for i in 132:
		var plan:=StudioFinanceLedger.plan(ledger,0,ledger.cash_cents,1,&"other_income",0,0,false,&"bounds")
		check(not plan.is_empty(),"Valid journal fills bounded native proof cache");ledger=plan.ledger
	check(not JournalKey.same({"key":1},{&"key":1}),"StringName dictionary keys cannot inherit String proof")
	check(not JournalKey.same({"key":&"value"},{"key":"value"}),"ID/text values remain distinct")
	var typed: Array[int]=[1]
	check(not JournalKey.same([1],typed),"Typed arrays do not inherit untyped proof")
	for value: Variant in [1,"bad",{},null]:
		var malformed:=ledger.duplicate(true);malformed.actions=value
		check(not StudioFinanceLedger._is_valid(malformed),"Malformed action containers reject without cache exceptions")
	cost=0
	for proof: Dictionary in StudioFinanceLedger._validated_journals:cost+=proof.cost
	check(cost==StudioFinanceLedger._validated_journal_bytes and cost<=StudioFinanceLedger.VALIDATED_JOURNAL_BYTES and StudioFinanceLedger._validated_journals.size()<=StudioFinanceLedger.VALIDATED_JOURNAL_LIMIT,"Finance native proof count and bytes stay bounded")
	print("CACHE_BOUNDARIES checks=%d failures=%d"%[checks,failures]);quit(failures)
