class_name FeatureSpendingGuidance
extends RefCounted

## Read-only estimates, never purchase permission or a second calendar.
const VERSION := "current_path_spending_advice_v2"
const MAX_INT: int = 9223372036854775807

static func pacing(releases: Dictionary) -> Dictionary:
	var total := 0
	var samples: Array = []
	var excluded := 0
	for id: StringName in releases:
		var review: Dictionary = releases[id].get("review", {})
		var cycles: Variant = review.get("development_cycles", null)
		if typeof(cycles) != TYPE_INT or cycles < 0:
			excluded += 1
			continue
		if cycles > MAX_INT - total:
			return {"available": false, "reason": "Cycle history exceeds the supported range."}
		total += cycles
		samples.append({"release_id": id, "development_cycles": cycles})
	var count := samples.size()
	# Keep the exact numerator/denominator. Never round through float for money.
	return {"available": count > 0, "sample_count": count, "excluded_count": excluded,
		"total_development_cycles": total, "samples": samples,
		"average_development_cycles": float(total) / count if count > 0 else 0.0,
		"rounded_development_cycles": total / count + (1 if total % count > 0 else 0) if count > 0 else 0}

static func estimate(history: Dictionary, pool: Dictionary, finance: Dictionary,
		cycle: int, cash: int, purchase_cents: int, purchase_cycles: int, ledger: Dictionary = {}) -> Dictionary:
	if history.has("reason"):
		return {"available": false, "reason": history.reason}
	if not finance.get("available", false) or not pool.get("available", false) or cycle < 0 or cash < 0 or purchase_cents < 0 or purchase_cycles < 0:
		return {"available": false, "reason": "Spending estimate unavailable: financial or Feature history is incomplete."}
	var play_cost := int(pool.known_play_cost_cents)
	var unpaid := int(finance.get("total_overdue_cents", finance.unpaid_rent_cents))
	if unpaid > MAX_INT - play_cost:
		return {"available": false, "reason": "Spending estimate exceeds the supported range."}
	var reserve := play_cost + unpaid
	var rent := 0
	var boundaries := 0
	var horizon := 0
	if history.get("available", false):
		var development := int(history.rounded_development_cycles)
		# Pre-Development is one run cycle outside ProjectState's cycle count.
		if development > MAX_INT - 1 - purchase_cycles:
			return {"available": false, "reason": "Spending horizon exceeds the supported range."}
		horizon = development + 1 + purchase_cycles
		if horizon > MAX_INT - cycle:
			return {"available": false, "reason": "Spending horizon exceeds the calendar range."}
		boundaries = horizon / 2 + (1 if horizon % 2 + cycle % 2 >= 2 else 0)
		var monthly := int(finance.monthly_rent_cents)
		if monthly <= 0 or boundaries > (MAX_INT - reserve) / monthly:
			return {"available": false, "reason": "Spending estimate exceeds the supported range."}
		rent = boundaries * monthly
		reserve += rent
	var payroll := 0
	var bank := 0
	if history.get("available", false) and not ledger.is_empty():
		var end_cycle := cycle + horizon
		for employee: Dictionary in ledger.employees:
			var first: int = employee.first_due_cycle + employee.issued * 2
			var count := (end_cycle - first) / 2 + 1 if first <= end_cycle else 0
			var wage: int = employee.wage_cents
			if first <= cycle or wage < 0 or (wage > 0 and count > (MAX_INT-reserve)/wage): return {"available":false,"reason":"Payroll estimate unavailable."}
			payroll += count*wage
			reserve += count*wage
		for loan: Dictionary in ledger.bank_loans:
			if loan.closed: continue
			for number in range(int(loan.issued)+1,int(loan.schedule.term_months)+1):
				var due := BankLoan.installment(loan.schedule,number)
				if due.due_cycle > end_cycle: break
				if due.due_cycle <= cycle or due.payment_cents > MAX_INT-reserve: return {"available":false,"reason":"Bank estimate unavailable."}
				bank += int(due.payment_cents)
				reserve += int(due.payment_cents)
	var remaining := cash - purchase_cents
	return {"available": true, "policy": VERSION, "pacing_available": history.get("available", false),
		"complete": history.get("available", false) and history.get("excluded_count", 0) == 0 and pool.unpriced_count == 0 and not ledger.is_empty(),
		"payroll_cents":payroll,"bank_cents":bank,"scheduled_bills_available":not ledger.is_empty(),
		"monthly_rent_cents": finance.monthly_rent_cents, "purchase_cents": purchase_cents, "purchase_cycles": purchase_cycles,
		"cash_after_price_cents": remaining, "known_play_cost_cents": play_cost,
		"unpriced_count": pool.unpriced_count, "owned_feature_count": pool.feature_count,
		"unpaid_cents": unpaid, "rent_cents": rent, "rent_boundaries": boundaries,
		"horizon_cycles": horizon, "reserve_cents": reserve,
		"below_reserve": remaining < reserve, "purchase_affordable": cash >= purchase_cents}

static func message(advice: Dictionary) -> String:
	if not advice.get("available", false): return advice.get("reason", "Spending estimate unavailable.")
	var prefix := "Purchase path" if not advice.get("acquisition", {}).get("steps", []).is_empty() else "Next game"
	var parts: Array[String] = []
	if advice.below_reserve: parts.append("May leave too little for known next-project costs. Consider waiting until sales actually settle.")
	if not advice.complete: parts.append("Some future costs are unknown; check the itemized costs before buying.")
	elif not advice.below_reserve: parts.append("Current quotes fit the known-cost estimate, but future costs and income can change.")
	return prefix + ": " + " ".join(parts)

static func acquisition_text(advice: Dictionary) -> String:
	var path: Dictionary = advice.get("acquisition", {})
	if path.is_empty() or path.steps.is_empty(): return ""
	var lines: Array[String] = ["Cost to acquire — current quotes"]
	for step: Dictionary in path.steps:
		var research: Dictionary = step.get("research",{})
		if not research.is_empty():
			lines.append("%s: base %s; down %s %s; next installment %s; %d actions left. Conditional remaining total %s." % [step.name,CashFormatter.format_exact_cents(research.base_cents),CashFormatter.format_exact_cents(research.down_cents),"already paid" if research.queued else "due on admission",CashFormatter.format_exact_cents(research.due_cents),research.remaining_actions,CashFormatter.format_exact_cents(step.price_cents)])
			continue
		lines.append("%s: %s · %d cycle(s) · %s" % [step.name,CashFormatter.format_exact_cents(step.price_cents),step.cycles,step.status])
	lines.append("Conditional total: %s · %d cycle(s)" % [CashFormatter.format_exact_cents(path.price_cents),path.cycles])
	for requirement: String in path.requirements: lines.append("Requirement: " + requirement)
	lines.append("Each step is separate. Requote before every admission/research action: bills, settlement, familiarity and unlocks can change.")
	return "\n".join(lines)

static func explanation(advice: Dictionary) -> String:
	if not advice.get("available", false): return message(advice)
	var rent_text := "Rent: %s (%d future monthly dues at %s/month)." % [CashFormatter.format_exact_cents(advice.rent_cents),advice.rent_boundaries,CashFormatter.format_exact_cents(advice.monthly_rent_cents)] if advice.pacing_available else "Rent estimate unavailable until a game is released; %s/month. Future payroll/Bank horizon unknown." % CashFormatter.format_exact_cents(advice.monthly_rent_cents)
	var bills := "Scheduled payroll: %s. Bank installments: %s." % [CashFormatter.format_exact_cents(advice.payroll_cents),CashFormatter.format_exact_cents(advice.bank_cents)] if advice.get("scheduled_bills_available",false) and advice.pacing_available else "Future payroll/Bank bills excluded: schedule or pace unavailable."
	return "Purchases remain your choice; this is not a cash guarantee.\nProspective pool if the path is completed: play each known-price Feature once, %s. Unpaid typed bills: %s.\n%s\n%s\nKnown next-project costs: %s. Quoted acquisition is separate; purchase cycles are included in the bill horizon.\nUses observed development pace plus setup and acquisition cycles. %d Feature play fees are unknown and excluded. Optional actions, longer development and future income are excluded. Sales must actually settle. No draw/play guarantee." % [CashFormatter.format_exact_cents(advice.known_play_cost_cents),CashFormatter.format_exact_cents(advice.unpaid_cents),rent_text,bills,CashFormatter.format_exact_cents(advice.reserve_cents),advice.unpriced_count]
