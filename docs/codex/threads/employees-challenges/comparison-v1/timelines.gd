extends SceneTree

var checks := 0
var failures: Array = []
var result: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _arg(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix): return arg.trim_prefix(prefix)
	return ""

func _run() -> void:
	var directory := _arg("--input=")
	var supplement := _arg("--supplement=") == "1"
	var shortlist := _arg("--shortlist=") == "1"
	if supplement:
		var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_arg("--out=")))
		result = previous.routes
		checks = int(previous.checks)
	for file: String in DirAccess.get_files_at(directory):
		if not file.ends_with(".json"): continue
		if file == "route_base_middle_synergy_1104_bundle_1.json": continue # rejected pilot: active public setter
		var route: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join(file)))
		if not route.has("releases") or not route.valid: continue
		# All native controls plus bundled reward routes. Paid/curated costs are
		# compared in the reward findings; avoid multiplying their payroll grid.
		if not route.reward in ["none","bundle"]: continue
		var tag := file.trim_suffix(".json")
		var variants: Dictionary = result[tag] if supplement else {}
		if not supplement: variants["native"] = _timeline(route,0,"start",0,0,"hire")
		for count in ([1] if shortlist else [1,2,3]):
			for hire_point in (["studio"] if supplement or shortlist else ["start","release"]):
				for hire_cycles in [0,1]:
					for course_cycles in ([0] if shortlist else [0,1]):
						for course_point in (["hire"] if shortlist else ["hire","game2"]):
							var key := "%d_%s_%d_%d_%s" % [count,hire_point,hire_cycles,course_cycles,course_point]
							variants[key] = _timeline(route,count,hire_point,hire_cycles,course_cycles,course_point)
		result[tag] = variants
	FileAccess.open(_arg("--out="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"routes":result}))
	print("NATIVE TIMELINES checks=",checks," failures=",failures.size()," routes=",result.size())
	quit(0 if failures.is_empty() else 1)

func _timeline(route: Dictionary, count: int, hire_point: String, hire_cycles: int, course_cycles: int, course_point: String) -> Dictionary:
	var releases: Array = route.releases
	var next_release := 0
	var records: Array[Dictionary] = []
	var cycle := 0
	var events: Array = []
	var hires: Array = []
	var courses: Array = []
	var hired := false
	var coursed := false
	var first_departure := -1
	for index in range(route.actions.size()):
		if route.actions[index].phase == "predevelopment": first_departure = int(route.actions[index].before.cycle); break
	var ledger: Dictionary = route.final.finance
	for action: Dictionary in ledger.actions:
		# Initial creation receipts occur before a hypothetical run-start hire.
		if not hired and count > 0 and ((hire_point == "start" and action.productive) or (hire_point == "release" and next_release >= 1) or (hire_point == "studio" and next_release == 1 and str(action.kind) in ["store","development"])):
			hired = true
			for employee in range(count):
				var before := cycle
				if hire_cycles == 1:
					cycle += 1
					events.append(_earning(records,cycle,0,true,"hire",employee))
				else: events.append({"cycle":cycle,"productive":false,"direct":0,"earned":0,"settled":0,"kind":"hire","employee":employee})
				hires.append({"employee":employee,"before":before,"cycle":cycle,"productive":hire_cycles==1})
		if hired and not coursed and (course_point == "hire" or next_release >= 2):
			coursed = true
			for employee in range(count):
				var before := cycle
				if course_cycles == 1:
					cycle += 1
					events.append(_earning(records,cycle,0,true,"course",employee))
				else: events.append({"cycle":cycle,"productive":false,"direct":0,"earned":0,"settled":0,"kind":"course","employee":employee})
				courses.append({"employee":employee,"before":before,"cycle":cycle,"productive":course_cycles==1})
		if action.productive: cycle += 1
		var event := _earning(records,cycle,int(action.direct_delta),action.productive,str(action.kind),-1)
		event["native_cycle"] = action.cycle
		event["source"] = action.source_id
		if count == 0:
			checks += 1
			if event.earned != int(action.sales_earned) or event.settled != int(action.settled): failures.append({"route":route.seed,"cycle":cycle,"reason":"native earned/settled mismatch"})
		events.append(event)
		if action.productive:
			while next_release < releases.size() and int(releases[next_release].cycle) == int(action.cycle):
				var r: Dictionary = releases[next_release]
				var frozen: Dictionary = r.sales_record
				var record := ReleasedGameSales.create(StringName(r.release_id),int(frozen.total_units),int(frozen.review_tenths),int(frozen.launch_awareness),int(frozen.market_bp))
				if record.is_empty(): failures.append({"reason":"release reconstruction rejected"})
				records.append(record)
				events.append({"cycle":cycle,"productive":false,"direct":0,"earned":0,"settled":0,"kind":"release","release":next_release+1,"review":r.final_review,"scope":r.scope})
				next_release += 1
	return {"initial":ledger.initial_cash_cents,"events":events,"hires":hires,"courses":courses,"final_cycle":cycle}

func _earning(records: Array[Dictionary], cycle: int, direct: int, productive: bool, kind: String, employee: int) -> Dictionary:
	var earned := 0
	var settled := 0
	if productive:
		for i in range(records.size()):
			var updated := ReleasedGameSales.next_cycle(records[i],cycle,cycle%2==0)
			if updated.is_empty(): failures.append({"cycle":cycle,"reason":"native sales calculation rejected"}); continue
			earned += int(updated.entitlement_cents)-int(records[i].entitlement_cents)
			settled += int(updated.settled_cents)-int(records[i].settled_cents)
			records[i] = updated
	return {"cycle":cycle,"productive":productive,"direct":direct,"earned":earned,"settled":settled,"kind":kind,"employee":employee}
