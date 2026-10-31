extends SceneTree
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _initialize() -> void:
	await process_frame
	for costly in [false,true]:
		var run=RunState.new();check(run.initialize_cash(0),"Initial cash")
		check(run.create_studio_with_traits("Rent fixture",&"action",[&"expensive_lease"] if costly else []),"Create Studio")
		var rent=31500 if costly else 30000
		check(run.get_studio_finance_report().monthly_rent_cents==rent,"New Studio rent %d"%rent)
		var before=run.get_cash_cents();check(run.complete_productive_action() and run.get_cash_cents()==before,"First half no rent")
		check(run.complete_productive_action() and run.get_cash_cents()==before-rent,"Monthly exact rent")
		var quote=run.get_bank_quote(999999,12)
		check(quote.minimum_principal_cents==rent*3,"Three actual rents")
		var codec=StudioCheckpoint.new();var payload=codec.capture(run)
		check(not payload.is_empty(),"New Studio capture: "+codec.error)
		if not payload.is_empty():
			var restored=codec.hydrate(payload);check(restored!=null and restored.get_studio_finance_report().monthly_rent_cents==rent,"New Studio cold rent")
	for costly in [false,true]:
		var r=RunState.new();r.initialize_cash(0);r.create_studio_with_traits("Arrears",&"action",[&"expensive_lease"] if costly else [])
		var rent=31500 if costly else 30000
		check(r.spend_cash_cents(r.get_cash_cents()-10000),"Controlled cash-poor fixture")
		check(r.complete_productive_action() and r.complete_productive_action(),"Due month commits partial rent")
		var q=r.get_bank_quote(999999,12)
		check(q.accepted and q.floor_facility and q.minimum_principal_cents==rent*3,"Recovery facility uses actual three rents")
		check(q.recovery_cents==rent-10000 and q.net_proceeds_cents==rent*2+10000,"Original overdue deducted exactly")
	for rent in [30000,31500,50000,51500]:check(not StudioFinanceLedger.create(570000,rent).is_empty(),"Supported stored rent %d"%rent)
	check(StudioFinanceLedger.create(570000,30100).is_empty(),"Unapproved rent rejected")
	var prior=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[1].trim_prefix("--previous=")))
	var current=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[2].trim_prefix("--current=")))
	for index in prior.size():
		var old: Dictionary=prior[index].player;var a=StudioCheckpoint.new();var r=a.hydrate(old)
		check(r!=null,"Genuine old rent hydrate: "+a.error)
		if r==null:continue
		check(JSON.stringify(a.capture(r))==JSON.stringify(old),"Old player fields/history/RNG exact")
		var rent: int=51500 if index else 50000
		check(r.get_bank_quote(999999,12).minimum_principal_cents==rent*3,"Old quote keeps three stored rents")
		var cash=r.get_cash_cents();check(r.complete_productive_action() and r.get_cash_cents()==cash,"Old next odd half")
		check(r.complete_productive_action() and r.get_studio_finance_snapshot().monthly_rows[-1].rent_due_cents==rent,"Old next bill retains rent")
		var forged=old.duplicate(true);forged.run.studio_finance.monthly_rent_cents=31500 if index==0 else 30000
		check(a.hydrate(forged)==null,"Trait/history rent forgery rejected")
		check(current[index].cycles==prior[index].cycles and current[index].releases==prior[index].releases,"Matched legal two-release clock")
		check(current[index].cash-prior[index].cash==80000,"Four months save exact800 dollars")
		check(current[index].player.rng==old.rng and current[index].player.run.released_games==old.run.released_games,"RNG and actual releases unchanged")
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures else 0)
