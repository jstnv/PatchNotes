extends SceneTree
var failures:=0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var inputs:Array=JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/lifespan-verification-v2/projection-inputs.json"))
	var results:Array=[]
	for input:Dictionary in inputs:
		var f:Dictionary=input.frozen
		for schedule in ["none","first","repeat","dormant"]:
			var rec:=ReleasedGameSales.create(&"projection",int(f.total_units),int(f.review_tenths),int(f.launch_awareness),int(f.market_bp))
			var release_cycle:=int(input.release.cycle)
			var cash:=int(input.release.cash_cents)
			var fees:=0
			var first_zero:=0
			var campaigns:Array=[]
			var boundaries:Array=[]
			for age in range(1,61):
				var projection:=ReleasedGameSales.get_projection(rec)
				var month:int=(age+1)/2
				if age%2==1 and month>1 and projection.projected_month_units==0 and first_zero==0:first_zero=month
				var campaign:bool=age%2==1 and month>1 and cash>=10000 and ((schedule=="first" and month==2) or (schedule=="repeat" and month in [2,3]) or (schedule=="dormant" and rec.campaign_count==0 and projection.projected_month_units==0))
				var cycle:=release_cycle+age
				var next:=ReleasedGameSales.next_cycle(rec,cycle,cycle%2==0,campaign)
				if next.is_empty():failures+=1;break
				if campaign:cash-=10000;fees+=10000;campaigns.append({"age_month":month,"run_cycle":cycle,"fee_cents":10000})
				cash+=int(next.settled_cents)-int(rec.settled_cents)
				rec=next
				if cycle%2==0:boundaries.append({"cycle":cycle,"age_cycle":age,"cash_cents":cash,"settled_cents":rec.settled_cents,"unpaid_cents":rec.entitlement_cents-rec.settled_cents})
			var report:=ReleasedGameMonthlyReport.build(rec,release_cycle)
			if report.is_empty():failures+=1
			results.append({"profile":input.id,"schedule":schedule,"label":"Conditional future ledger projection, NOT legal played time; single-title cash excludes future project costs and other titles","release_review":input.release.final_review,"first_organic_zero_month":first_zero,"campaigns":campaigns,"fees_cents":fees,"cash_cents":cash,"calendar_boundaries":boundaries,"monthly_report":report})
	FileAccess.open("res://design-logs/lifespan-verification-v2/projections-month30.json",FileAccess.WRITE).store_string(JSON.stringify({"results":results,"failures":failures}))
	print("Native Month30 projections: ",results.size()," failures=",failures)
	quit(failures)
