extends SceneTree
var failures:=0
func _initialize() -> void:_run.call_deferred()
func check(ok:bool,message:String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok:failures+=1
func _run() -> void:
	var beta:BetaPhase=load("res://scenes/phases/beta_phase.tscn").instantiate();root.add_child(beta);await process_frame
	var old:Dictionary={&"qa":50,&"marketing":45,&"insider":5}
	check(beta._priority_allocation.set_distribution(old),"Historical Beta distribution remains readable")
	beta.reset_priority_draft()
	check(beta._priority_draft[&"insider"]==10 and beta.get_node("%PriorityTotal").text=="105/100","Historical Beta draft and visible sliders both show corrected over-budget draft")
	beta.get_node("%MarketingPriority").value=40
	check(BetaPriorityAllocation.is_valid_new_distribution(beta._priority_draft),"One visible correction produces a legal 100 allocation")
	beta.queue_free();await process_frame
	var ledger:=StudioFinanceLedger.create(550000)
	for income:int in [0,400000,0,400000]:ledger=StudioFinanceLedger.plan(ledger,ledger.last_cycle+1,ledger.cash_cents,0,&"calendar",income,income,true).ledger
	for i in 2:
		var q:=StudioFinanceLedger.bank_quote(ledger,150000,12,&"selection")
		check(q.get("accepted",false),"Independent ordinary loan qualifies")
		if q.get("accepted",false):ledger=StudioFinanceLedger.accept_loan(ledger,q,&"selection").ledger
	var run:=RunState.new();run._studio_finance=ledger;run._cash_cents=ledger.cash_cents;run._completed_run_cycles=ledger.last_cycle
	var finances:=StudioFinances.new();root.add_child(finances);finances.bind_run(run);finances.open();finances.open_bank();await process_frame
	var selector:OptionButton=finances.get("loan_selector")
	check(selector!=null,"Concurrent Bank loans have an explicit selection control")
	if selector!=null:
		check(selector.item_count==2,"Both active loans listed")
		for i in 2:
			selector.select(i);selector.item_selected.emit(i)
			check(finances._payoff.get("loan_id")==ledger.bank_loans[i].loan_id,"Selected loan has its own payoff "+str(i))
			finances._confirm_payoff()
			check(finances._confirmation_payload.get("loan_id")==ledger.bank_loans[i].loan_id,"Confirmation freezes selected loan "+str(i))
			finances._cancel_confirmation()
	finances.queue_free();await process_frame
	var game:Control=load("res://scenes/gameplay.tscn").instantiate()
	var hud:GameplayHUD=game.get_node("%GameplayHUD");hud.get_parent().remove_child(hud);root.add_child(hud)
	hud.run=run;hud._guidance_ready=true;hud.tutorial_context=&"main_menu"
	hud.contextual_tip.show_tip("Still reading","An empty transient context must not dismiss this.")
	hud._refresh_guidance();check(hud.contextual_tip.panel.visible,"Transient empty guidance preserves open tip")
	hud.queue_free();game.free();await process_frame
	print("Review regression: %d failures"%failures);quit(failures)
