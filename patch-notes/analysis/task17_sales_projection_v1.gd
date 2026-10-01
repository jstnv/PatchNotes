## Pure current-code projection of captured releases; not a claim of UI actions.
extends SceneTree

func _initialize() -> void:
	var root_path := "res://design-logs/tutorial-task17-v1/"
	var profiles: Array[Dictionary]=[]
	for file in ["strong_final.json","strong_next_game.json"]:
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(root_path+file))
		for row: Dictionary in data.rows:
			for number in range(1,5):
				var key:="game_%d"%number
				if not row.has(key): continue
				var release: Dictionary=row[key]
				var record: Dictionary={}
				for r: Dictionary in row.frozen_sales_records:
					if r.release_id==release.release_id: record=r
				profiles.append({"id":file+"/"+str(int(row.case))+"/"+key,"release":release,"record":record})
	for policy in ["cautious","ordinary","optimizer"]:
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/campaign_opportunity_capture_v1_"+policy+"_campaign_task17_calibration.json"))
		for row: Dictionary in data.rows:
			profiles.append({"id":"weak/"+policy+"/"+str(int(row.case)),"release":row.game_2,"record":row.campaign_history_after})
	var results: Array[Dictionary]=[]
	var failures:=0
	for profile: Dictionary in profiles:
		for schedule in ["none","first","first_two","first_three","every","dormant"]:
			var r: Dictionary=profile.record
			var record:=ReleasedGameSales.create(&"projection",int(r.total_units),int(r.review_tenths),int(r.launch_awareness),int(r.market_bp))
			var snapshots: Array[Dictionary]=[]
			var cost:=0
			for age_cycle in range(1,50):
				var month:=(age_cycle+1)/2
				var quote:=ReleasedGameSales.get_projection(record)
				var requested:bool=month>=2 and age_cycle%2==1 and ((schedule=="first" and month==2) or (schedule=="first_two" and month<=3) or (schedule=="first_three" and month<=4) or schedule=="every" or (schedule=="dormant" and record.campaign_count==0 and quote.projected_month_units==0))
				if month>24: requested=false
				var cash:=int(profile.release.cash_cents)+int(record.settled_cents)-cost
				var bought:bool=requested and cash>=10000 and quote.can_campaign
				if bought: cost+=10000
				var cycle:=int(profile.release.cycle)+age_cycle
				record=ReleasedGameSales.next_cycle(record,cycle,cycle%2==0,bought)
				if record.is_empty(): failures+=1; break
				snapshots.append({"age_cycle":age_cycle,"cycle":cycle,"campaign":bought,"cash_cents":int(profile.release.cash_cents)+int(record.settled_cents)-cost,"cost_cents":cost,"record":record.duplicate(true)})
			results.append({"profile":profile.id,"schedule":schedule,"snapshots":snapshots})
	var output:=FileAccess.open(root_path+"native_sales_projections.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"failures":failures,"profiles":profiles,"results":results},"  "))
	print("TASK17 native sales profiles=",profiles.size()," arms=",results.size()," failures=",failures)
	quit(0 if failures==0 else 1)
