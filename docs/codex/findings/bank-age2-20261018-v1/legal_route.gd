extends "res://scripts/debug/verify_primitive_branches.gd"

var rows: Array = []
var tape: Dictionary
var session: RefCounted
var output: String

func action(kind: StringName, payload: Dictionary = {}, expected := true) -> bool:
	var before := Replay.digest(Replay.state(session))
	var request: Dictionary = session.command(kind, payload)
	var result := Replay.record(session, tape, request)
	check(result.ok == expected, "%s expected accepted=%s: %s" % [kind, expected, result.get("error", "")])
	if not result.ok: check(Replay.digest(Replay.state(session)) == before, "rejected action is atomic including RNG")
	rows.append({"request":request,"result":result,"cycle":session.run.get_completed_run_cycles(),"cash":session.run.get_cash_cents(),"finance":session.run.get_studio_finance_snapshot(),"observation":session.observation()})
	return result.ok

func contract_action(kind: StringName, payload: Dictionary = {}, expected := true) -> bool:
	return action(&"contract", {"request":session.contract.command(kind,payload)}, expected)

func bank_bills(run: RunState) -> Array:
	return run.get_studio_finance_report().outstanding_expenses.filter(func(b: Dictionary) -> bool: return b.expense_type == &"bank_installment")

func _initialize() -> void:
	await process_frame
	catalog = root.get_node("CardDatabase").get_development_catalog()
	output = OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var input := ProjectSettings.globalize_path("res://../docs/codex/findings/queue-completion-20261011-v1/checkpoints/education-distressed-committed/checkpoint.33.json")
	var payload := CheckpointCodec.new().open_envelope(FileAccess.get_file_as_string(input))
	session = from_payload(payload)
	check(session != null, "actual Studio49 prefix restores")
	if session == null: quit(1); return
	var initial: Dictionary = session.export_checkpoint()
	tape = Replay.begin(session)
	check(action(&"accept_contract", {"kind":&"ironclad"}), "different route: available Ironclad advance")
	contract_action(&"begin")
	var a := {0:30,1:20,2:25,3:25}
	var b := {0:20,1:30,2:25,3:25}
	contract_action(&"priorities", {"distribution":a})
	var first: Array[int] = session.contract.candidate_ids.slice(0,4)
	contract_action(&"play", {"candidate_ids":first})
	contract_action(&"priorities", {"distribution":b})
	var blocked: Array = bank_bills(session.run)
	check(not blocked.is_empty(), "legal delayed Ironclad route creates an unpaid Bank due")
	if blocked.is_empty():
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"rows":rows,"checks":checks,"failures":failures},"\t"))
		quit(failures);return
	check(session.run.get_completed_run_cycles()==52 and int(blocked[0].due_cycle)==52 and int(blocked[0].overdue_cycles)==0, "original unpaid Bank due52 age0")
	var unpaid_state := Replay.digest(Replay.state(session))
	contract_action(&"priorities", {"distribution":a}, false)
	check(Replay.digest(Replay.state(session))==unpaid_state, "trying to carry arrears leaves all state unchanged")
	check(session.export_checkpoint().is_empty(), "active Contract cannot publish a Continue checkpoint")
	# A real redraw is allowed, but consumes redraws rather than calendar time.
	contract_action(&"redraw", {"candidate_ids":[session.contract.candidate_ids[0]]})
	check(session.run.get_completed_run_cycles()==52 and bank_bills(session.run)==blocked, "zero-cycle redraw cannot age or rewrite bills")
	var alternatives: Array = []
	for i in 4:
		for j in range(i+1,5):
			for k in range(j+1,6):
				for l in range(k+1,7):
					var cards: Array[CardData] = [session.contract.cards[i],session.contract.cards[j],session.contract.cards[k],session.contract.cards[l]]
					var plan: Dictionary = session.contract._state.plan_hand(cards)
					if plan.is_empty(): continue
					alternatives.append({"tokens":[session.contract.candidate_ids[i],session.contract.candidate_ids[j],session.contract.candidate_ids[k],session.contract.candidate_ids[l]],"definitions":cards.map(func(card):return str(card.id)),"income":plan.remainder_cents,"can_commit":session.run.can_complete_productive_cycle(plan.remainder_cents)})
	alternatives.sort_custom(func(x: Dictionary,y: Dictionary)->bool:return x.income < y.income)
	check(alternatives.size()==35, "all35 visible second-hand combinations evaluated read-only")
	var selected: Dictionary = {}
	for choice: Dictionary in alternatives:
		if choice.can_commit: selected=choice;break
	if not alternatives[0].can_commit: contract_action(&"play", {"candidate_ids":alternatives[0].tokens}, false)
	check(not selected.is_empty(), "ordinary earned Contract recovery is available")
	if not selected.is_empty():
		contract_action(&"play", {"candidate_ids":selected.tokens})
		check(bank_bills(session.run).is_empty(), "successful income hand clears Bank arrears before calendar advance")
		action(&"dismiss_contract")
	var final: Dictionary = session.export_checkpoint()
	check(not final.is_empty(), "completed Contract returns to saveable Studio")
	var reproduction := Replay.replay(Factory.create({"checkpoint":initial},catalog),tape)
	check(reproduction.ok, "exact legal and rejected action replay")
	var target := false
	for row: Dictionary in rows:
		for bill: Dictionary in row.finance.obligations:
			if bill.expense_type==&"bank_installment" and bill.unpaid_cents>0 and row.cycle-int(bill.due_cycle)>=2: target=true
	Replay.save_tape(output+".tape.json",tape)
	FileAccess.open(output+".initial.json",FileAccess.WRITE).store_string(JSON.stringify(initial,"\t"))
	FileAccess.open(output+".studio.json",FileAccess.WRITE).store_string(JSON.stringify(final,"\t"))
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"input":input,"input_sha256":FileAccess.get_sha256(input),"rows":rows,"alternatives":alternatives,"selected":selected,"still_unpaid_age2_reached":target,"checks":checks,"failures":failures},"\t"))
	print("BANK_ALTERNATE_ROUTE checks=%d failures=%d target_reached=%s"%[checks,failures,target])
	quit(failures)
