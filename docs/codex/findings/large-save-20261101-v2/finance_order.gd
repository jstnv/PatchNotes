extends SceneTree
const Reference=preload("res://../docs/codex/findings/large-save-20261101-v2/finance_reference.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func reorder(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary={};var keys: Array=value.keys();keys.reverse()
		for key in keys:result[key]=reorder(value[key])
		return result
	if value is Array:return value.map(reorder)
	return value
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var before: Dictionary=StudioCheckpoint.new()._decode_payload(pair.world.studios[0].run,pair.world.studios[0].development!=null).run.studio_finance
	var full: Array=[];var cached: Array=[]
	for i in 5:
		var plan:=StudioFinanceLedger.plan(before,before.last_cycle,before.cash_cents,1,&"other_income",0,0,false,&"order-check")
		check(not plan.is_empty(),"Ordinary checked transition produces a valid ledger")
		before=plan.ledger
		var other: Dictionary=reorder(before)
		check(var_to_bytes(before)!=var_to_bytes(other) and before==other,"Same typed ledger has a different Dictionary insertion order")
		var start:=Time.get_ticks_usec();check(Reference._validate_journal(other),"Full source-pinned journal reconstruction");full.append(Time.get_ticks_usec()-start)
		start=Time.get_ticks_usec();check(StudioFinanceLedger._is_valid(other),"Valid order change inherits exact semantic proof");cached.append(Time.get_ticks_usec()-start)
		var bad:=other.duplicate(true);bad.actions[-1].direct_delta=1.0
		check(not StudioFinanceLedger._is_valid(bad),"Float cannot inherit integer proof")
		bad=other.duplicate(true);bad.cash_cents+=1
		check(not StudioFinanceLedger._is_valid(bad),"Nested money changes require full reconstruction")
		bad=other.duplicate(true);bad.actions.reverse()
		check(not StudioFinanceLedger._is_valid(bad),"Array journal order remains authoritative")
	full.sort();cached.sort()
	check(cached[2]<full[2]*.40,"Codec Dictionary ordering does not trigger another full finance replay")
	print("FINANCE_ORDER checks=%d failures=%d full_us=%d reordered_us=%d"%[checks,failures,full[2],cached[2]]);quit(failures)
