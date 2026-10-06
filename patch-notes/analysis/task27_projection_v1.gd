## Native sales replay and isolated trial projections. Projection cycles are NOT claimed player actions.
extends SceneTree
const Trial = preload("res://analysis/task27_trial_ledger.gd")
const Calc = preload("res://analysis/task27_trial_calculator.gd")
var failures := 0
var parity := 0
var results: Array = []
var profiles: Array = []
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	for policy in ["cautious","ordinary","synergy"]:
		for index in [0,1]:
			var row: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/task27-v1/route_main_%s_next_%d.json" % [policy,index]))
			for n in [0,1]:
				var release: Dictionary = row.releases[n]
				var frozen: Dictionary = row.sales_records[n]
				var profile := {"id":"%s_%d_g%d"%[policy,index,n+1],"release":release,"frozen":frozen}
				profiles.append(profile)
	for profile: Dictionary in profiles:
		for variant in ["control","carry0","carry30","retention_faster","retention_slower"]:
			for schedule in (["none","first","repeat","every","dormant"] if variant=="control" else ["none","first"]):
				for fee in ([5000,7500,10000] if variant=="control" and schedule!="none" else [10000]):
					results.append(_project(profile,variant,schedule,fee,24))
	# Bounded dormancy extension: two existing weak and strong profile inputs, no synthetic Review.
	var ranked := profiles.duplicate()
	ranked.sort_custom(func(a,b):return a.release.final_review < b.release.final_review)
	for profile: Dictionary in [ranked[0],ranked[-1]]:
		for schedule in ["none","dormant"]: results.append(_project(profile,"control",schedule,10000,120))
	var file := FileAccess.open("res://design-logs/task27-v1/projections.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"profiles":profiles,"results":results,"failures":failures,"native_parity_cycles":parity}))
	print("TASK27 projections=",results.size()," native parity cycles=",parity," failures=",failures)
	quit(0 if failures==0 else 1)
func _project(profile: Dictionary,variant: String,schedule: String,fee: int,horizon: int) -> Dictionary:
	Calc.DISCOVERY_CARRYOVER_BASIS_POINTS = 0 if variant=="carry0" else 3000 if variant=="carry30" else 1500
	Calc.retention_offset_bp = -500 if variant=="retention_faster" else 500 if variant=="retention_slower" else 0
	var f: Dictionary = profile.frozen
	var release: Dictionary = profile.release
	var record: Dictionary = Trial.create(&"projection",int(f.total_units),int(f.review_tenths),int(f.launch_awareness),int(f.market_bp))
	var native := ReleasedGameSales.create(&"projection",int(f.total_units),int(f.review_tenths),int(f.launch_awareness),int(f.market_bp))
	var rows: Array = []
	var cash := int(release.cash_cents)
	var cost := 0
	var first_zero := 0
	var first_unaffordable := 0
	var month_start_units := 0
	for age_cycle in range(1,horizon*2+1):
		var month: int = (age_cycle+1)/2
		var quote: Dictionary = Trial.get_projection(record)
		if month<=horizon and age_cycle%2==1:
			month_start_units = int(record.earned_units)
			if month>1 and quote.projected_month_units==0 and first_zero==0: first_zero=month
		var requested: bool = month>=2 and month<=horizon and age_cycle%2==1 and ((schedule=="first" and month==2) or (schedule=="repeat" and month in [2,3]) or schedule=="every" or (schedule=="dormant" and int(record.campaign_count)==0 and int(quote.projected_month_units)==0))
		if requested and cash<fee and first_unaffordable==0: first_unaffordable=month
		var campaign: bool = requested and cash>=fee and quote.can_campaign
		if campaign: cash-=fee;cost+=fee
		var cycle := int(release.cycle)+age_cycle
		var settled_before := int(record.settled_cents)
		record = Trial.next_cycle(record,cycle,cycle%2==0,campaign)
		if record.is_empty(): failures+=1;break
		cash+=int(record.settled_cents)-settled_before
		if variant=="control":
			native=ReleasedGameSales.next_cycle(native,cycle,cycle%2==0,campaign)
			parity+=1
			if native!=record: failures+=1
		if age_cycle%2==0 or cycle%2==0:
			rows.append({"age_month":month,"age_cycle":age_cycle,"cycle":cycle,"calendar_boundary":cycle%2==0,"organic_scaled":record.organic_awareness_scaled,"active_scaled":record.active_awareness_scaled,"monthly_units":int(f.total_units) if month==1 else record.monthly_units,"earned_units":record.earned_units,"earned_cents":record.entitlement_cents,"settled_cents":record.settled_cents,"cash_cents":cash,"campaign_count":record.campaign_count,"campaign_cost_cents":cost})
	return {"profile":profile.id,"variant":variant,"schedule":schedule,"fee_cents":fee,"horizon":horizon,"first_zero_month":first_zero,"first_unaffordable_month":first_unaffordable,"rows":rows,"final":record,"cost_cents":cost}

