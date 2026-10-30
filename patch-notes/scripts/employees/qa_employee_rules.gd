extends RefCounted
## Event-sourced QA state; speculative plans own their RNG and never mutate Run.
const PROC_PERCENT := 25 # Delegated 2026-10-25 trial; final balance remains OPEN.
static func employee(owner: StringName, cycle: int) -> Dictionary:
	var id := StringName("%s:qa:1" % owner)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(id) + ":qa-trial-v1")
	return {"employee_id":id,"owner":owner,"type":&"qa","hire_cycle":cycle,"trained":false,"swap_trained":false,"courses":{},"search_count":0,"debug_count":0,"projects":{},"pending_design":{},"rng_seed":rng.seed,"rng_state":rng.state}
static func wage(e: Dictionary) -> int:
	return 100000 + 10000 * (int(e.trained) + int(e.swap_trained))
static func available(state: Dictionary, project: StringName) -> bool:
	for e: Dictionary in state.employees.values():
		if e.type == &"qa" and e.swap_trained:
			var p: Dictionary = e.projects.get(project,{})
			if not p.get("armed_action",&"").is_empty() and p.get("used_action",&"").is_empty(): return true
	return false
static func apply(state: Dictionary, event: Dictionary, copy_source: bool=true) -> Dictionary:
	var next := state.duplicate(true) if copy_source else state
	var kind: StringName = event.get("type",&"")
	if typeof(event.get("cycle"))!=TYPE_INT:return {}
	for prior: Dictionary in state.events:
		if prior.get("cycle",0)>event.cycle:return {}
		# A Run commits at most one hand on a productive cycle. Changing the
		# supplied project-cycle must never make that hand train twice.
		if kind in [&"qa_beta",&"qa_proc"] and prior.type==kind and prior.cycle==event.cycle:return {}
	if kind==&"employee_trial":
		if event.keys().size()!=3 or event.get("rules_version")!=2 or event.cycle<0 or EmployeeRoster.trial_active(state):return {}
	elif kind == &"hire_specialist":
		if event.keys().size()!=3 or event.get("role") not in [&"production",&"qa"] or typeof(event.get("cycle"))!=TYPE_INT or event.cycle<0: return {}
		for e: Dictionary in next.employees.values():
			if e.type==event.role: return {}
		var id := StringName("%s:%s:1"%[state.owner,event.role])
		if state.owner.is_empty(): return {}
		next.employees[id] = employee(state.owner,event.cycle) if event.role==&"qa" else {"employee_id":id,"owner":state.owner,"type":&"production","hire_cycle":event.cycle,"trained":false,"projects":{}}
	elif kind == &"course":
		if event.keys().size()!=5 or event.get("course") not in [&"mixed",&"pure"] or typeof(event.get("employee_id"))!=TYPE_STRING_NAME or typeof(event.get("cycle"))!=TYPE_INT or typeof(event.get("fee_cents"))!=TYPE_INT or event.fee_cents!=15000: return {}
		var e: Dictionary=next.employees.get(event.employee_id,{})
		if e.is_empty() or e.type!=&"qa" or event.cycle<e.hire_cycle or e.courses.has(event.course): return {}
		e.courses[event.course]={"cycle":event.cycle,"completed_cycle":-1}
	elif kind in [&"qa_beta",&"qa_proc",&"qa_finalize",&"qa_swap"]:
		if typeof(event.get("project_id"))!=TYPE_STRING_NAME or event.project_id.is_empty() or typeof(event.get("project_cycle"))!=TYPE_INT or event.project_cycle<0 or typeof(event.get("cycle"))!=TYPE_INT or event.cycle<0: return {}
		var action := StringName("%s:%s:%d"%[event.project_id,kind,event.project_cycle])
		var found := false
		for e: Dictionary in next.employees.values():
			if e.type!=&"qa": continue
			if event.cycle<e.hire_cycle: return {}
			var p: Dictionary=e.projects.get(event.project_id,{"armed_action":&"","used_action":&"","actions":[]})
			if action in p.actions: return {}
			if kind==&"qa_beta":
				if event.keys().size()!=8: return {}
				for k in ["search","debug","discovered","fixed"]:
					if typeof(event.get(k))!=TYPE_INT or event[k]<0: return {}
				if event.search+event.debug>4: return {}
				var was_trained: bool=e.swap_trained
				if e.courses.has(&"mixed") and not e.trained and event.cycle>e.courses[&"mixed"].cycle and event.search>0 and event.debug>0 and event.discovered>0 and event.fixed>0:
					e.trained=true; e.courses[&"mixed"].completed_cycle=event.cycle
				var pure: bool=event.search==4 or event.debug==4
				if e.courses.has(&"pure") and event.cycle>e.courses[&"pure"].cycle:
					if event.search==4: e.search_count=mini(3,e.search_count+1)
					if event.debug==4: e.debug_count=mini(3,e.debug_count+1)
					if not e.swap_trained and e.search_count==3 and e.debug_count==3:
						e.swap_trained=true; e.courses[&"pure"].completed_cycle=event.cycle
				if was_trained and pure and p.armed_action.is_empty(): p.armed_action=action
			elif kind==&"qa_swap":
				if event.keys().size()!=4 or not e.swap_trained or p.armed_action.is_empty() or not p.used_action.is_empty(): return {}
				var armed:=str(p.armed_action)
				if event.project_cycle<=int(armed.substr(armed.rfind(":")+1)):return {}
				p.used_action=action;found=true
			elif kind==&"qa_proc":
				if event.keys().size()!=8 or event.get("rules_version")!=1 or event.get("chance_percent")!=25 or event.get("phase") not in [&"design",&"alpha"] or typeof(event.get("features"))!=TYPE_INT or event.features<1 or event.features>4 or not e.trained: return {}
				var rng:=RandomNumberGenerator.new(); rng.seed=e.rng_seed; rng.state=e.rng_state
				var successes:=0
				for i in range(event.features):
					if rng.randi_range(1,100)<=event.chance_percent: successes+=1
				e.rng_state=rng.state
				if event.phase==&"design": e.pending_design[event.project_id]=int(e.pending_design.get(event.project_id,0))+successes
				# Alpha successes are planned identically and applied to real Hidden Bugs by Run.
				found=true
			elif kind==&"qa_finalize":
				if event.keys().size()!=4: return {}
				e.pending_design.erase(event.project_id)
			p.actions.append(action);e.projects[event.project_id]=p
		if kind in [&"qa_proc",&"qa_swap"] and not found: return {}
	else: return {}
	next.events.append(event.duplicate(true));return next
static func schema() -> Dictionary:
	var S=CheckpointSchema
	var qa: Dictionary=S.fields("employee_id owner type","id")
	qa.merge(S.fields("hire_cycle search_count debug_count"));qa.merge(S.fields("trained swap_trained","bool"))
	qa.courses=S.map_of("id",{"cycle":"uint","completed_cycle":"int"})
	qa.projects=S.map_of("id",{"armed_action":"id","used_action":"id","actions":S.array_of("id")})
	qa.pending_design=S.map_of("id","uint");qa.rng_seed="int";qa.rng_state="int"
	return qa
static func event_schemas() -> Array:
	var S=CheckpointSchema
	var base: Dictionary=S.fields("type project_id","id");base.merge(S.fields("project_cycle cycle"))
	var beta: Dictionary=base.duplicate();beta.merge(S.fields("search debug discovered fixed"))
	var proc: Dictionary=base.duplicate();proc.phase="id";proc.features="uint";proc.rules_version="uint";proc.chance_percent="uint"
	return [{"type":"id","cycle":"uint","rules_version":"uint"},{"type":"id","role":"id","cycle":"uint"},{"type":"id","employee_id":"id","course":"id","cycle":"uint","fee_cents":"uint"},base,beta,proc]
