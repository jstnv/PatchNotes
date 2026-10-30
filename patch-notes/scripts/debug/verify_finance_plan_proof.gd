extends SceneTree
const Before:=preload("res://scripts/debug/fixtures/finance_before_campaign_latency.gd")
var checks:=0
var failures:=0
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize()->void:
	await process_frame
	var ledger:=Before.create(100000000)
	for cycle in range(1,97):ledger=Before.plan(ledger,cycle,ledger.cash_cents,0,&"calendar",0,0,true).ledger
	var pristine:=ledger.duplicate(true)
	var result:=StudioFinanceLedger.plan(ledger,97,ledger.cash_cents,-123,&"store",0,0,true,&"research")
	expect(var_to_bytes(result)==var_to_bytes(Before.plan(ledger,97,ledger.cash_cents,-123,&"store",0,0,true,&"research")),"Trusted transition remains byte-exact to independent original")
	expect(var_to_bytes(pristine)==var_to_bytes(ledger),"Planner leaves input untouched")
	var start:=Time.get_ticks_usec()
	expect(Before._is_valid(result.ledger),"Original full replay validates planned output")
	var replay_us:=Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	expect(StudioFinanceLedger._is_valid(result.ledger),"New read validates planned output")
	var read_us:=Time.get_ticks_usec()-start
	expect(read_us*4<replay_us,"Validated transition avoids replaying its entire prefix on the next read")
	for field: String in ["cash_before","direct_delta","settled","cycle"]:
		var changed: Dictionary=result.ledger.duplicate(true)
		changed.actions[-1][field]+=1
		expect(not StudioFinanceLedger._is_valid(changed),"Altered planned journal rejects: "+field)
	var bad: Dictionary=result.ledger.duplicate(true)
	bad.credit.score+=1
	expect(StudioFinanceLedger.plan(bad,98,bad.cash_cents,0,&"calendar",0,0,true).is_empty(),"Corrupt source cannot create a trusted transition")
	bad=result.ledger.duplicate(true);bad.actions[-1].cycle=float(bad.actions[-1].cycle)
	expect(not StudioFinanceLedger._is_valid(bad),"Equal float on newly planned journal rejects")
	bad=result.ledger.duplicate(true);bad.actions[-1].kind=String(bad.actions[-1].kind)
	expect(not StudioFinanceLedger._is_valid(bad),"Equal String on newly planned journal rejects")
	bad=result.ledger.duplicate(true);bad.monthly_rows[-1].closing_cash_cents+=1
	expect(not StudioFinanceLedger._is_valid(bad),"Detached planned-row mutation rejects")
	for cycle in range(98,123):
		ledger=result.ledger
		result=StudioFinanceLedger.plan(ledger,cycle,ledger.cash_cents,-17,&"store",0,0,true,&"research")
		expect(var_to_bytes(result)==var_to_bytes(Before.plan(ledger,cycle,ledger.cash_cents,-17,&"store",0,0,true,&"research")),"Repeated exact transition "+str(cycle))
		expect(Before._is_valid(result.ledger),"Independent full replay still accepts "+str(cycle))
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"full_replay_us":replay_us,"first_read_us":read_us}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print(JSON.stringify(report));quit(1 if failures else 0)
