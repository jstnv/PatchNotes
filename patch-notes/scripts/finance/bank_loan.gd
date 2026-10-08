class_name BankLoan
extends RefCounted

## Exact, compact equal-principal contracts. All public amounts are cents.
const MAX_INT: int = 9223372036854775807
const MIN_PRINCIPAL := 50000
const SCHEMA_VERSION := 1


static func _multiply(a: int, b: int) -> int:
	if a < 0 or b < 0 or (b > 0 and a > MAX_INT / b): return -1
	return a * b


static func _sum(a: int, b: int) -> int:
	return -1 if a < 0 or b < 0 or a > MAX_INT - b else a + b


## Sum floor((a*i+b)/m), i=0..n-1, in logarithmic time.
static func _floor_sum(n: int, m: int, a: int, b: int) -> int:
	var answer := 0
	while true:
		if a >= m:
			var triangle := _multiply(n / 2, n - 1) if n % 2 == 0 else _multiply(n, (n - 1) / 2)
			answer = _sum(answer, _multiply(triangle, a / m))
			if answer < 0: return -1
			a %= m
		if b >= m:
			answer = _sum(answer, _multiply(n, b / m))
			if answer < 0: return -1
			b %= m
		var highest := _sum(_multiply(a, n), b)
		if highest < 0: return -1
		if highest < m: return answer
		n = highest / m
		b = highest % m
		var previous := m
		m = a
		a = previous
	return answer


static func _segment_interest(opening: int, reduction: int, count: int) -> int:
	if count == 0: return 0
	var last := opening - reduction * (count - 1)
	return _sum(_multiply(count, last / 100), _floor_sum(count, 100, reduction, last % 100 + 50))


static func schedule(principal: Variant, months: Variant, accepted_cycle: Variant = 0) -> Dictionary:
	if typeof(principal) != TYPE_INT or typeof(months) != TYPE_INT or typeof(accepted_cycle) != TYPE_INT: return {}
	if principal < MIN_PRINCIPAL or months < 1 or months > principal or accepted_cycle < 0: return {}
	var gap := 2 + int(accepted_cycle % 2)
	if accepted_cycle > MAX_INT - gap: return {}
	var first: int = accepted_cycle + gap
	if months - 1 > (MAX_INT - first) / 2: return {}
	var q: int = principal / months
	var r: int = principal % months
	var first_interest: int = principal / 100 + int(principal % 100 >= 50)
	var maximum := _sum(q + int(r > 0), first_interest)
	var interest := _sum(_segment_interest(principal, q + 1, r), _segment_interest(principal - (q + 1) * r, q, months - r))
	if maximum < 0 or interest < 0 or _sum(principal, interest) < 0: return {}
	return {"schema_version": SCHEMA_VERSION, "principal_cents": principal, "term_months": months,
		"accepted_cycle": accepted_cycle, "first_due_cycle": first,
		"last_due_cycle": first + (months - 1) * 2, "maximum_installment_cents": maximum,
		"total_interest_cents": interest, "total_payment_cents": principal + interest}


static func installment(contract: Dictionary, number: int) -> Dictionary:
	var p: int = contract.get("principal_cents", 0)
	var n: int = contract.get("term_months", 0)
	if p < MIN_PRINCIPAL or n < 1 or n > p or number < 1 or number > n: return {}
	var q := p / n
	var r := p % n
	var opening := p - q * (number - 1) - mini(number - 1, r)
	var principal := q + int(number <= r)
	var interest := opening / 100 + int(opening % 100 >= 50)
	return {"number": number, "due_cycle": int(contract.first_due_cycle) + (number - 1) * 2,
		"opening_principal_cents": opening, "principal_cents": principal,
		"interest_cents": interest, "payment_cents": principal + interest}


static func eligibility(ledger: Dictionary, rent: int, obligations: int = 0) -> Dictionary:
	var result := {"eligible": false, "reason": "Two completed months with positive settled sales are required.",
		"older_sales_cents": 0, "latest_sales_cents": 0, "basis_cents": 0,
		"rent_cents": rent, "obligations_cents": obligations, "capacity_cents": 0}
	if rent < 0 or obligations < 0 or rent > MAX_INT - obligations: return result
	for loan: Dictionary in ledger.get("bank_loans", []):
		if not loan.closed:
			result.reason = "Pay off the active loan before borrowing again."
			return result
	for bill: Dictionary in ledger.get("obligations", []):
		if bill.unpaid_cents > 0:
			result.reason = "Clear all overdue bills before borrowing."
			return result
	var completed: int = int(ledger.get("last_cycle", 0)) / 2
	var rows: Array = ledger.get("monthly_rows", [])
	if completed < 2 or rows.size() < completed: return result
	var older: int = rows[completed - 2].sales_settled_cents
	var latest: int = rows[completed - 1].sales_settled_cents
	result.older_sales_cents = older
	result.latest_sales_cents = latest
	if older <= 0 or latest <= 0: return result
	# Average without overflowing older + latest.
	var average := older / 2 + latest / 2 + (older % 2 + latest % 2) / 2
	result.basis_cents = mini(latest, average)
	result.capacity_cents = maxi(0, int(result.basis_cents) - rent - obligations) / 4
	result.eligible = result.capacity_cents > 0
	result.reason = "Choose an amount and term to preview the exact payments." if result.eligible else "Settled sales do not cover rent and required obligations with lending capacity left."
	return result


static func maximum_principal(capacity: int, months: Variant, cycle: int, cash: int) -> int:
	if capacity <= 0 or typeof(months) != TYPE_INT or months < 1 or cash < 0: return 0
	var low := maxi(MIN_PRINCIPAL, int(months))
	var high := MAX_INT - cash
	# Interest alone bounds principal; avoid capacity*100 overflow.
	if capacity <= (MAX_INT - 49) / 100: high = mini(high, capacity * 100 + 49)
	var best := 0
	while low <= high:
		var middle := low + (high - low) / 2
		var value := schedule(middle, months, cycle)
		if not value.is_empty() and int(value.maximum_installment_cents) <= capacity:
			best = middle
			low = middle + 1
		else:
			high = middle - 1
	return best


static func quote(ledger: Dictionary, principal: Variant, months: Variant, run_id: StringName, rent: int, obligations: int = 0) -> Dictionary:
	var result := eligibility(ledger, rent, obligations)
	result["accepted"] = false
	result["maximum_principal_cents"] = maximum_principal(result.capacity_cents, months, ledger.last_cycle, ledger.cash_cents) if result.eligible else 0
	var terms := schedule(principal, months, ledger.last_cycle)
	if terms.is_empty() or run_id.is_empty():
		result.reason = "Enter at least $500.00 and a positive whole-month term with at least one principal cent per installment. Values must fit the calendar and exact-cent arithmetic."
		return result
	result["schedule"] = terms
	if not result.eligible: return result
	if principal > MAX_INT - int(ledger.cash_cents) or principal > result.maximum_principal_cents:
		result.reason = "The largest scheduled payment exceeds capacity, or the amount cannot be represented safely."
		return result
	var revision: int = ledger.actions.size()
	result["run_id"] = run_id
	result["loan_id"] = StringName("%s:bank:%d" % [run_id, ledger.get("bank_loans", []).size() + 1])
	result["quote_id"] = StringName("%s:quote:%d:%d:%d" % [run_id, revision, principal, months])
	result["revision"] = revision
	result.accepted = true
	result.reason = "Quote ready. Acceptance adds financing without advancing time."
	return result


static func parse_integer(text: String) -> int:
	if text.is_empty(): return -1
	var value := 0
	for character in text:
		var digit := character.unicode_at(0) - 48
		if digit < 0 or digit > 9 or value > (MAX_INT - digit) / 10: return -1
		value = value * 10 + digit
	return value


static func parse_dollars(text: String) -> int:
	var pieces := text.strip_edges().split(".", true)
	if pieces.size() > 2: return -1
	var dollars := parse_integer(pieces[0])
	if dollars < 0 or dollars > MAX_INT / 100: return -1
	var cents := 0
	if pieces.size() == 2:
		if pieces[1].length() < 1 or pieces[1].length() > 2: return -1
		cents = parse_integer(pieces[1])
		if cents < 0: return -1
		if pieces[1].length() == 1: cents *= 10
	return _sum(dollars * 100, cents)
