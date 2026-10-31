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
	for rent in [30000,31500,50000,51500]:check(not StudioFinanceLedger.create(570000,rent).is_empty(),"Supported stored rent %d"%rent)
	check(StudioFinanceLedger.create(570000,30100).is_empty(),"Unapproved rent rejected")
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}));quit(1 if failures else 0)
