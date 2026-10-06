## Read-only ledger parity and conditional portfolio earning; no free-Wait gameplay action.
extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _hydrate(raw: Dictionary) -> Dictionary:
	var result := ReleasedGameSales.create(StringName(raw.release_id),int(raw.total_units),int(raw.review_tenths),int(raw.launch_awareness),int(raw.market_bp))
	for key in result:
		if typeof(result[key])==TYPE_INT: result[key]=int(raw[key])
		elif key=="campaign_months":
			var months := {}
			for age in raw[key]:months[int(age)]=int(raw[key][age])
			result[key]=months
		elif key!="release_id": result[key]=raw[key]
	return result
func _run() -> void:
	var outputs: Array = []
	for policy in ["cautious","ordinary","synergy"]:
		for index in [0,1]:
			var paths: Array = []
			var end_cycle := 0
			for arm in ["next","newer","older","store"]:
				var path := "res://design-logs/task27-v1/route_main_%s_%s_%d.json"%[policy,arm,index]
				var row: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
				paths.append(row)
				end_cycle=maxi(end_cycle,int(row.final.cycle)+48)
			for row: Dictionary in paths:
				var previous := {}
				for point: Dictionary in row.live_cycles:
					for raw: Dictionary in point.records:
						var record := _hydrate(raw)
						if not ReleasedGameSales.is_valid(record): failures+=1
						var id := StringName(raw.release_id)
						if previous.has(id):
							var old: Dictionary = previous[id]
							if int(record.total_earned_cycles)==int(old.total_earned_cycles)+1:
								var expected := ReleasedGameSales.next_cycle(old,int(point.cycle),int(point.cycle)%2==0,int(record.campaign_count)>int(old.campaign_count))
								checks+=1
								if expected!=record:failures+=1
						previous[id]=record
				var records: Array[Dictionary] = []
				for raw: Dictionary in row.sales_records:records.append(_hydrate(raw))
				var cash := int(row.final.cash_cents)
				var months: Array = []
				for cycle in range(int(row.final.cycle)+1,end_cycle+1):
					var earned := 0
					var settled := 0
					for n in range(records.size()):
						var old := records[n]
						records[n]=ReleasedGameSales.next_cycle(old,cycle,cycle%2==0)
						if records[n].is_empty(): failures+=1;continue
						cash+=int(records[n].settled_cents)-int(old.settled_cents)
						earned+=int(records[n].entitlement_cents)
						settled+=int(records[n].settled_cents)
					if cycle%2==0:months.append({"cycle":cycle,"cash_cents":cash,"earned_cents":earned,"settled_cents":settled,"records":records.duplicate(true)})
				outputs.append({"policy":policy,"case":index,"arm":row.arm,"start_cycle":row.final.cycle,"end_cycle":end_cycle,"months":months,"final_cash_cents":cash,"label":"conditional native ledger projection; not a playable wait or future action trace"})
	var file := FileAccess.open("res://design-logs/task27-v1/portfolio.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"outputs":outputs,"native_trace_parity_checks":checks,"failures":failures}))
	print("TASK27 portfolio rows=",outputs.size()," native trace parity=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
