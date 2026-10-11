extends SceneTree

const Finance := preload("res://scripts/finance/studio_finance_ledger.gd")
const StudioActions := preload("res://scripts/simulation/studio_actions.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const OWNER := &"finance_observation_fixture"
var checks := 0
var failures := 0
var comparisons: Array = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+label)

## Original M4 aggregate retained as the comparison path. This calls the
## independently validating public getters, including their Run-level gates.
func legacy_observation(run: RunState) -> Dictionary:
	var finance := run.get_studio_finance_report()
	var payoffs: Array = []
	for loan: Dictionary in finance.get("bank_loans", []):
		if not loan.closed: payoffs.append(run.get_bank_payoff_quote(loan.loan_id))
	var offers: Array = []
	if run.is_primitive_contract_offer_available(): offers.append({"kind":&"ironclad"})
	if run.is_sidestreet_offer_available(): offers.append({"kind":&"sidestreet","offer_id":run.get_next_sidestreet_offer().offer_id})
	for id: StringName in run.get_pending_publisher_offer_ids():
		var quote := run.get_publisher_contract_offer(id)
		if not quote.is_empty(): offers.append({"kind":&"publisher","quote":quote})
	return {"finance":finance,"employees":run.get_employees(),"hire_quote":run.get_production_hire_quote(),"education_payoff_quote":run.get_education_payoff_quote(),"bank_payoff_quotes":payoffs,"contract_offers":offers}

func compare(run: RunState, label: String) -> Dictionary:
	var before: Variant = Replay.freeze(run)
	var old := legacy_observation(run)
	var actual := StudioActions.observation(run)
	expect(old == actual, label+": exact aggregate")
	expect(JSON.stringify(Replay.freeze(old)) == JSON.stringify(Replay.freeze(actual)), label+": canonical ordering and types")
	expect(before == Replay.freeze(run), label+": no state or RNG mutation")
	comparisons.append({"case":label,"digest":Replay.digest(actual)})
	return actual

func fixture(ledger: Dictionary) -> RunState:
	var run := RunState.new()
	run._bank_run_id = OWNER
	run._studio_finance = ledger.duplicate(true)
	run._first_studio_economy = true
	run._cash_cents = int(ledger.get("cash_cents", 0))
	run._completed_run_cycles = int(ledger.get("last_cycle", 0))
	run._employees = EmployeeRoster.create(OWNER)
	# A release-presence marker isolates the hiring getter's existing gate. It is
	# never offered to campaign execution or represented as a legal release route.
	run._released_games[&"presence_probe"] = {}
	return run

func step(ledger: Dictionary, earned: int = 0) -> Dictionary:
	var planned := Finance.plan(ledger, int(ledger.last_cycle)+1, int(ledger.cash_cents), 0, &"calendar", earned, earned, true)
	expect(not planned.is_empty(), "Fixture productive journal step")
	return planned.get("ledger", {})

func ready(education: bool = false) -> Dictionary:
	var ledger := Finance.create(1000000)
	if education:
		var opened := Finance.open_education(ledger, OWNER, &"college_dropout")
		expect(not opened.is_empty(), "Fixture education opens")
		ledger = opened.get("ledger", {})
	for index in range(4): ledger = step(ledger, 200000 if index % 2 == 1 else 0)
	return ledger

func _initialize() -> void:
	await process_frame
	var base := ready()
	var run := fixture(base)
	var ordinary := compare(run, "valid_base")
	expect(ordinary.finance.available and not ordinary.hire_quote.is_empty(), "Released Studio hiring quote available")
	expect(ordinary.education_payoff_quote.is_empty() and ordinary.bank_payoff_quotes.is_empty(), "Absent liabilities have no payoffs")
	for gate in ["no_economy", "no_release", "invalid_roster", "hired_roster", "empty_run_id"]:
		var gated := fixture(base)
		match gate:
			"no_economy": gated._first_studio_economy = false
			"no_release": gated._released_games.clear()
			"invalid_roster": gated._employees = {}
			"hired_roster": gated._employees = EmployeeRoster.hire(gated._employees, &"fixture_employee", gated.get_completed_run_cycles())
			"empty_run_id": gated._bank_run_id = &""
		expect(compare(gated, gate).hire_quote.is_empty(), gate+": hire quote withheld")
	var busy := fixture(base)
	busy._productive_cycle_in_progress = true
	busy._publishing_cycle = true
	busy._feature_purchase_in_progress = true
	busy.checkpoint_mutations_allowed = false
	expect(not compare(busy, "busy_and_checkpoint_blocked").hire_quote.is_empty(), "Observation preserves existing quote despite mutation gates")
	var loan_quote := Finance.bank_quote(base, 50000, 12, OWNER)
	expect(loan_quote.get("accepted", false), "Fixture Bank quote accepted")
	var borrowed := Finance.accept_loan(base, loan_quote, OWNER)
	expect(not borrowed.is_empty(), "Fixture Bank acceptance")
	var loan_ledger: Dictionary = borrowed.get("ledger", {})
	var open_loan := compare(fixture(loan_ledger), "open_bank_loan")
	expect(open_loan.bank_payoff_quotes.size() == 1, "One open Bank payoff")
	var closed := Finance.pay_off(loan_ledger, Finance.payoff_quote(loan_ledger, loan_quote.loan_id))
	expect(not closed.is_empty(), "Fixture Bank payoff")
	expect(compare(fixture(closed.get("ledger", {})), "closed_bank_loan").bank_payoff_quotes.is_empty(), "Closed Bank loan omitted")
	var spent := Finance.plan(loan_ledger, int(loan_ledger.last_cycle), int(loan_ledger.cash_cents), -(int(loan_ledger.cash_cents)-50100), &"other_expense")
	expect(not spent.is_empty(), "Fixture partial-payment funding")
	var partial: Dictionary = spent.get("ledger", {})
	partial = step(step(partial))
	var partial_report := compare(fixture(partial), "partial_bank_due")
	expect(partial_report.finance.total_overdue_cents > 0 and partial_report.bank_payoff_quotes.size() == 1 and partial_report.hire_quote.is_empty(), "Partial debt remains quoted and hiring blocked")
	var hired := Finance.hire_employee(base, Finance.hire_quote(base, OWNER), OWNER)
	expect(not hired.is_empty(), "Fixture employee journal hire")
	var payroll: Dictionary = hired.get("ledger", {})
	payroll = step(step(payroll))
	var payroll_run := fixture(payroll)
	payroll_run._employees = EmployeeRoster.hire(payroll_run._employees, StringName(str(OWNER)+":production:1"), int(base.last_cycle))
	var payroll_report := compare(payroll_run, "payroll_due_paid")
	expect(payroll_report.finance.monthly_payroll_cents == 1000 and payroll_report.hire_quote.is_empty(), "Paid payroll retains hiring gate")
	var education := ready(true)
	var school_loan := Finance.bank_quote(education, 50000, 12, OWNER)
	expect(school_loan.get("accepted", false), "Fixture education plus Bank accepted")
	var school_borrowed := Finance.accept_loan(education, school_loan, OWNER)
	expect(not school_borrowed.is_empty(), "Fixture education plus Bank journal")
	education = school_borrowed.get("ledger", {})
	var education_run := fixture(education)
	var education_report := compare(education_run, "education_and_bank")
	expect(not education_report.education_payoff_quote.is_empty() and education_report.bank_payoff_quotes.size() == 1, "Both debt quotes retained")
	for mismatch in ["cash", "cycle"]:
		var mismatched := fixture(education)
		if mismatch == "cash": mismatched._cash_cents += 1
		else: mismatched._completed_run_cycles += 1
		var observed := compare(mismatched, mismatch+"_mismatch")
		expect(observed.finance == {"available":false} and observed.bank_payoff_quotes.is_empty(), mismatch+": report/Bank list unavailable")
		expect(not observed.education_payoff_quote.is_empty() and not observed.hire_quote.is_empty(), mismatch+": independent existing quote behavior retained")
	for invalidity in ["empty", "schema", "cash", "action", "rows"]:
		var invalid := education.duplicate(true)
		match invalidity:
			"empty": invalid.clear()
			"schema": invalid.schema_version = -1
			"cash": invalid.cash_cents += 1
			"action": invalid.actions[0].kind = &"foreign_action"
			"rows": invalid.monthly_rows[0].closing_cash_cents += 1
		var observed := compare(fixture(invalid), "invalid_"+invalidity)
		expect(observed.finance == {"available":false} and observed.hire_quote.is_empty() and observed.education_payoff_quote.is_empty() and observed.bank_payoff_quotes.is_empty(), invalidity+": all invalid-ledger quotes withheld")
	var unchanged: Variant = Replay.freeze(education_run)
	var detached := StudioActions.observation(education_run)
	detached.finance.rows[0].clear()
	detached.finance.bank_loans[0].schedule.clear()
	detached.finance.education.clear()
	detached.employees.clear()
	detached.hire_quote.clear()
	detached.education_payoff_quote.clear()
	detached.bank_payoff_quotes[0].clear()
	detached.contract_offers.clear()
	expect(Replay.freeze(education_run) == unchanged, "Mutating returned bundle cannot mutate Run, journal or RNG")
	compare(education_run, "after_detached_mutation")
	var prior := StudioActions.observation(education_run)
	var receipt := Finance.plan(education_run._studio_finance, education_run.get_completed_run_cycles(), education_run.get_cash_cents(), 1, &"other_income")
	expect(not receipt.is_empty(), "Fixture later observation revision")
	education_run._studio_finance = receipt.get("ledger", {})
	education_run._cash_cents = int(receipt.get("cash_cents", 0))
	var changed := compare(education_run, "after_new_receipt")
	expect(changed != prior and changed.education_payoff_quote.revision == int(prior.education_payoff_quote.revision)+1 and changed.bank_payoff_quotes[0].revision == int(prior.bank_payoff_quotes[0].revision)+1, "No validation or quote cache survives between observations")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output, FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"comparisons":comparisons}, "\t"))
	print("Finance observation: %d checks, %d comparisons, %d failures" % [checks, comparisons.size(), failures])
	quit(0 if failures == 0 else 1)
