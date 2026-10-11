extends "res://scripts/debug/verify_education_debt.gd"

func _run() -> void:
	var run:=RunState.new();run.initialize_cash(0)
	check(run.create_studio_with_traits("Education atomicity",&"action",[&"college_dropout"]),"Create active account through normal confirmation")
	var adapter:=StudioCheckpoint.new()
	var before:=adapter.capture(run)
	var quote:=run.get_education_payoff_quote()
	for property in ["account_id","revision","principal_cents","interest_cents","total_cents","other_due_cents","required_cash_cents","type"]:
		var wrong:=quote.duplicate(true)
		wrong[property]=&"forged" if property in ["type","account_id"] else wrong[property]+1
		check(not run.pay_off_education(wrong) and adapter.capture(run)==before,"Invalid payoff field leaves complete RunState and RNG unchanged: "+property)
	var floating:=quote.duplicate(true);floating.total_cents=float(quote.total_cents)
	check(not run.pay_off_education(floating) and adapter.capture(run)==before,"Floating monetary input rejects atomically")
	check(run.spend_cash_cents(80001,&"other_expense"),"Construct exact one-cent-short cash through journal")
	quote=run.get_education_payoff_quote();before=adapter.capture(run)
	check(run.get_cash_cents()==quote.required_cash_cents-1 and not run.pay_off_education(quote) and adapter.capture(run)==before,"One-cent-short payoff preserves cash, account, calendar, all run fields and RNG")
	check(run.add_cash_cents(1,&"other_income"),"Explicit one-cent fixture recovery")
	check(not run.pay_off_education(quote),"Any intervening cash action invalidates quoted revision")
	quote=run.get_education_payoff_quote();var credit:Dictionary=run.get_studio_finance_snapshot().credit
	check(run.pay_off_education(quote) and run.get_cash_cents()==0 and run.get_completed_run_cycles()==0 and run.get_studio_finance_snapshot().credit==credit,"Exact-cash payoff closes in zero cycles without credit gain")
	before=adapter.capture(run)
	check(not run.pay_off_education(quote) and adapter.capture(run)==before,"Repeated full payoff preserves all state")
	var fresh:=RunState.new();fresh.initialize_cash(0);fresh.create_studio_with_traits("Corruption",&"action",[&"graduate"])
	var payload:=adapter.capture(fresh)
	for property in ["account_id","run_id","trait_id","closed","closed_cycle","early_payoff","issued","principal_paid_cents","interest_paid_cents"]:
		var decoded:Dictionary=CheckpointCodec.new().decode(payload,CheckpointSchema.root())
		var value:Variant=decoded.run.studio_finance.education[property]
		decoded.run.studio_finance.education[property]=not value if value is bool else value+1 if value is int else &"forged"
		check(adapter.hydrate(CheckpointCodec.new().encode(decoded,CheckpointSchema.root()))==null,"Corrupt account field rejects whole save: "+property)
	for property in ["principal_cents","regular_due_cents","term_months","first_due_cycle","last_due_cycle","total_interest_cents","total_payment_cents"]:
		var decoded:Dictionary=CheckpointCodec.new().decode(payload,CheckpointSchema.root())
		decoded.run.studio_finance.education.schedule[property]+=1
		check(adapter.hydrate(CheckpointCodec.new().encode(decoded,CheckpointSchema.root()))==null,"Corrupt immutable schedule rejects: "+property)
	var bad_receipt:Dictionary=CheckpointCodec.new().decode(payload,CheckpointSchema.root())
	for action:Dictionary in bad_receipt.run.studio_finance.actions:
		if action.source_id==&"studio_trait_unspent_points_v1":action.source_id=&"unproven_points"
	for tx:Dictionary in bad_receipt.run.studio_finance.transactions:
		if tx.source_id==&"studio_trait_unspent_points_v1":tx.source_id=&"unproven_points"
	check(F._is_valid(bad_receipt.run.studio_finance),"Forged receipt fixture independently remains finance-replayable")
	check(adapter.hydrate(CheckpointCodec.new().encode(bad_receipt,CheckpointSchema.root()))==null,"Startup funding cross-provenance rejects renamed point receipt")
	var pre_fanbase:=payload.duplicate(true);pre_fanbase.content_revision=adapter.previous_revision()
	check(adapter.hydrate(pre_fanbase)==null,"Unsupported pre-Fanbase rules remain rejected")
	check(adapter.hydrate(payload)!=null,"Valid payload still restores after corruption attempts")
	print("Education atomicity: %d checks, %d failures"%[checks,failures]);quit(failures)
