extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("_run")
func units(review: int, awareness: int, market: int) -> int:
	var top: Array[int] = [500,review,200+awareness,market]
	var bottom: Array[int] = [70,200,10000]
	PrimitiveUnitsSoldCalculator._reduce_factors(top,bottom)
	return PrimitiveUnitsSoldCalculator._checked_product(top)/PrimitiveUnitsSoldCalculator._checked_product(bottom)
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var results := []
	for no_loss in [false,true]:
		var fan := StudioFanbase.create()
		var records := {}
		var finance := StudioFinanceLedger.create(550000)
		var launches := []
		var registered := {}
		var cycles := []
		for action: Dictionary in data.final.finance.actions:
			var cycle := int(action.cycle)
			var earned := 0
			var settled := 0
			if action.productive:
				var next := {}
				for id: StringName in records:
					var record := ReleasedGameSales.next_cycle(records[id],cycle,cycle%2==0)
					earned += int(record.entitlement_cents)-int(records[id].entitlement_cents)
					settled += int(record.settled_cents)-int(records[id].settled_cents)
					next[id] = record
				var before := fan.duplicate(true)
				fan = StudioFanbase.plan(fan,records,next,cycle)
				check(not fan.is_empty(),"Native fan model")
				check(StudioFanbase.plan(fan,records,next,cycle).is_empty(),"Repeated monthly callback rejects")
				if no_loss and cycle%2==0:
					fan.fans += int(fan.months[-1].lost)
					fan.months[-1].lost = 0
					fan.months[-1].net = fan.months[-1].gained
					fan.months[-1].ending = fan.fans
				if not no_loss:
					var observed: Dictionary = data.live_cycles[cycle-1]
					check(fan.fans == int(observed.fans),"Observed Fan total reproduced")
					check(JSON.parse_string(JSON.stringify(fan.months)) == observed.fan_history,"Observed monthly gain/loss reproduced")
					for saved: Dictionary in observed.records:
						var id := StringName(saved.release_id)
						for key in next[id]: check(next[id][key] == saved[key],"Observed exact sales field "+key)
				records = next
			var step := StudioFinanceLedger.plan(finance,cycle,finance.cash_cents,int(action.direct_delta),StringName(action.kind),earned,settled,bool(action.productive),StringName(action.source_id))
			check(not step.is_empty(),"Fixed-action finance remains feasible")
			finance = step.ledger
			if not no_loss:
				check(earned == int(action.sales_earned) and settled == int(action.settled),"Native earned and settled cash reproduced")
				check(finance.actions[-1].cash_before == int(action.cash_before),"Native pre-action cash reproduced")
			if action.productive:
				cycles.append({"cycle":cycle,"fans":fan.fans,"cash_cents":finance.cash_cents,"earned_cents":earned,"settled_cents":settled})
			for release: Dictionary in data.releases:
				var id := StringName(release.release_id)
				if int(release.cycle) != cycle or registered.has(id): continue
				var template := {}
				for saved: Dictionary in data.sales_records:
					if saved.release_id == String(id): template = saved
				var original_fans := int(data.final.fan_snapshot.releases[String(id)].launch_fans)
				var awareness := int(release.awareness)-StudioFanbase.awareness_for(original_fans)+StudioFanbase.awareness_for(fan.fans)
				var month_one := units(int(template.review_tenths),awareness,int(template.market_bp))
				var record := ReleasedGameSales.create(id,month_one,int(template.review_tenths),awareness,int(template.market_bp))
				fan = StudioFanbase.register_release(fan,record,fan.fans)
				records[id] = record
				registered[id] = true
				launches.append({"cycle":cycle,"fans":fan.fans,"review":release.final_review,"awareness":awareness,"month_one":month_one})
				if not no_loss: check(month_one == int(release.month_1_units) and awareness == int(release.awareness),"Observed launch reproduced")
		if not no_loss: check(finance.cash_cents == int(data.final.cash_cents),"Observed final exact cash")
		results.append({"no_loss":no_loss,"launches":launches,"months":fan.months,"cycles":cycles,"finance":finance,"records":records,"fans":fan.fans})
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"results":results}))
	print("Fan counterfactual: %d checks, %d failures" % [checks,failures])
	quit(failures)
