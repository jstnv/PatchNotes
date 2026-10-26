extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "res://scripts/contracts/publisher_support.gd"
	check(ResourceLoader.exists(path),"support authority exists")
	if failures > 0:
		quit(1)
		return
	var support: GDScript = load(path)
	check(support.amounts(1499).is_empty(),"gate below15")
	check(support.amounts(1500) == {"budget_cents":87500,"funding_cents":70000,"marketing_points":5},"I15 exact package")
	check(support.amounts(2500) == {"budget_cents":112500,"funding_cents":91500,"marketing_points":6},"I25 exact package")
	check(support.amounts(10000).budget_cents == 300000,"cap100 remains eligible")
	check(support.amounts(10001).is_empty(),"reject out-of-range capacity")
	check(support.has_method("eligibility"),"renewal uses P1 authority")
	if not support.has_method("eligibility"):
		quit(1)
		return
	check(RunState.new().has_method("get_support_quote"),"runtime support quote authority")
	if not RunState.new().has_method("get_support_quote"):
		quit(1)
		return
	var old := {"raw_net_cents":0,"publisher_recoup_cents":0,"studio_earned_cents":0,"studio_settled_cents":0,"earning_cycles":0}
	var budget := 87500
	for age in range(1,27):
		var next: Dictionary = support.advance_rights(budget,old,age*10001,age,age%2==0)
		check(not next.is_empty(),"positive rights age%d" % age)
		if next.is_empty(): break
		check(next.publisher_recoup_cents == mini(budget,mini(age,24)*10001*20/100),"cumulative floor/cutoff age%d" % age)
		check(next.studio_earned_cents+next.publisher_recoup_cents == age*10001,"exact entitlement split age%d" % age)
		check(next.studio_settled_cents == (next.studio_earned_cents if age%2==0 else old.studio_settled_cents),"settlement alignment age%d" % age)
		old = next
	check(support.assessment(70,1000).passed,"both criteria inclusive")
	check(not support.assessment(69,1000).passed,"Review-only miss")
	check(not support.assessment(70,999).passed,"units-only miss")
	for release_parity in [0,1]:
		var aligned: Dictionary = support.empty_rights()
		for age in range(1,27):
			var next: Dictionary = support.advance_rights(budget,aligned,age*10001,age,(age+release_parity)%2==0)
			check(not next.is_empty() and next.studio_settled_cents == (next.studio_earned_cents if (age+release_parity)%2==0 else aligned.studio_settled_cents),"positive age%d settlement alignment%d" % [age,release_parity])
			aligned = next
	var capped: Dictionary = support.advance_rights(budget,support.empty_rights(),1000000,1,false)
	check(capped.publisher_recoup_cents == budget,"full package cap includes marketing budget")
	var after_cap: Dictionary = support.advance_rights(budget,capped,1000001,2,true)
	check(after_cap.publisher_recoup_cents == budget and after_cap.studio_earned_cents == 1000001-budget,"recoup stays capped and remaining cents belong to Studio")
	var funded := StudioFinanceLedger.plan(StudioFinanceLedger.create(0),1,0,70000,&"publisher_support",0,0,true,&"support-test")
	check(not funded.is_empty(),"funded start journal")
	if not funded.is_empty():
		var report := StudioFinanceLedger.report(funded.ledger,1,funded.cash_cents)
		check(report.available,"funding journal reconstructs")
		check(funded.ledger.monthly_rows[0].operating_revenue_cents == 0,"funding excludes operating revenue")
		check(funded.ledger.monthly_rows[0].net_profit_cents == 0,"funding excludes profit")
	print("Publisher support checks: %d, failures: %d" % [checks,failures])
	quit(1 if failures else 0)
