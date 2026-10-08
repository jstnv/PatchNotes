extends SceneTree
const B := preload("res://scripts/finance/bank_loan.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for principal in [50000,50001,75037,150000,250000,99999999]:
		for months in [1,2,3,6,12,18,24,97,1000]:
			var terms := B.schedule(principal,months,13)
			check(not terms.is_empty(),"Representable terms")
			var remaining: int = principal
			var interest := 0
			var largest := 0
			for i in range(1,months+1):
				var due := B.installment(terms,i)
				var piece: int = principal / months + int(i <= principal % months)
				var expected_interest := (remaining + 50) / 100
				check(due.opening_principal_cents == remaining and due.principal_cents == piece and due.interest_cents == expected_interest,"Independent iterative installment")
				check(due.due_cycle == 16 + (i-1)*2,"Odd-cycle dated installment")
				remaining -= piece
				interest += expected_interest
				largest = maxi(largest,due.payment_cents)
			check(remaining == 0 and terms.total_interest_cents == interest and terms.maximum_installment_cents == largest,"Compact totals match independent complete schedule")
	for bad in [-1,0,49999,50000.0,"50000",true,null]:
		check(B.schedule(bad,12).is_empty(),"Malformed principal rejected")
	for bad in [-1,0,50001,12.0,"12",true,null]:
		check(B.schedule(50000,bad).is_empty(),"Malformed term rejected")
	check(B.schedule(50000,12,12).first_due_cycle == 14,"Even first-full-month due")
	check(B.schedule(50000,12,B.MAX_INT).is_empty(),"Calendar overflow rejected")
	check(B.schedule(B.MAX_INT,1).is_empty(),"Total payment overflow rejected")
	var long_interest := 0
	for opening in range(1,50001): long_interest += (opening + 50) / 100
	check(long_interest == 12500500 and B.schedule(50000,50000).total_interest_cents == long_interest,"Long schedule matches independent cent-by-cent interest")
	for capacity in [100,500,5000,15000,1000000]:
		for months in [1,12,96,1000]:
			var maximum := B.maximum_principal(capacity,months,0,550000)
			if maximum == 0:
				check(B.schedule(50000,months).maximum_installment_cents > capacity,"Zero capacity maximum explained")
			else:
				check(B.schedule(maximum,months).maximum_installment_cents <= capacity,"Maximum fits capacity")
				check(B.schedule(maximum+1,months).maximum_installment_cents > capacity,"Next cent exceeds capacity")
	print("Bank loan arithmetic: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
