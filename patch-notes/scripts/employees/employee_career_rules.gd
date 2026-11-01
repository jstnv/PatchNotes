extends RefCounted

## Versioned, event-sourced Production and Project Manager trial courses.
const PRODUCTION: Array[StringName] = [&"production_planning", &"pass_alignment"]
const MANAGER: Array[StringName] = [&"manager_1", &"manager_2", &"manager_3", &"manager_4"]
const CORE: Array[StringName] = [&"graphics", &"sound", &"technology", &"design"]

static func active(state: Dictionary) -> bool:
	var events: Variant=state.get("events",[])
	return events is Array and events.any(func(e):return e is Dictionary and e.get("type")==&"career_activate")

## Called before typed decoding to reject new events under legacy revisions.
## Malformed containers still go through the ordinary schema/recovery error path.
static func payload_active(payload: Dictionary) -> bool:
	var record: Variant=payload.get("run",{})
	if not record is Dictionary:return false
	var employees: Variant=record.get("employees",{})
	return employees is Dictionary and active(employees)

static func course_ids(role: StringName) -> Array[StringName]:
	return PRODUCTION.duplicate() if role==&"production" else MANAGER.duplicate() if role==&"project_manager" else [] as Array[StringName]

static func progress() -> Dictionary:
	return {"courses":{},"projects":{},"games":{},"releases":[]}

static func completed(employee: Dictionary) -> int:
	var count:=0
	for course: Dictionary in employee.get("career",{}).get("courses",{}).values():
		if course.completed_cycle>=0:count+=1
	return count

static func wage(employee: Dictionary) -> int:return 100000+10000*completed(employee)

static func level(state: Dictionary) -> int:
	for employee: Dictionary in state.get("employees",{}).values():
		if employee.type==&"project_manager":return completed(employee)
	return 0

static func limits(state: Dictionary, beta: bool=false) -> Vector2i:
	var trained:=level(state)
	return Vector2i(40-5*trained,60+5*trained) if beta else Vector2i(20-5*trained,40+5*trained)

static func alignment_available(state: Dictionary) -> bool:
	for employee: Dictionary in state.get("employees",{}).values():
		if employee.type==&"production" and completed(employee)==2:return true
	return false

static func next_course(employee: Dictionary) -> StringName:
	var courses: Dictionary=employee.get("career",{}).get("courses",{})
	for id: StringName in course_ids(employee.type):
		if not courses.has(id):return id
		if courses[id].completed_cycle<0:return &""
	return &""

static func current_course(employee: Dictionary) -> StringName:
	for id: StringName in course_ids(employee.type):
		if employee.get("career",{}).get("courses",{}).has(id) and employee.career.courses[id].completed_cycle<0:return id
	return &""

static func enable(state: Dictionary, cycle: int) -> Dictionary:
	return EmployeeRoster._apply(state,{"type":&"career_activate","cycle":cycle,"rules_version":1}) if EmployeeRoster.valid(state) else {}

static func enroll(state: Dictionary, id: StringName, course: StringName, cycle: int) -> Dictionary:
	return EmployeeRoster._apply(state,{"type":&"career_course","employee_id":id,"course":course,"cycle":cycle,"fee_cents":15000}) if EmployeeRoster.valid(state) else {}

static func facts(cards: Array) -> Array:
	var result:=EmployeeRoster.card_facts(cards)
	for i in result.size():result[i].beta=cards[i].beta_category
	return result

static func hand(state: Dictionary, project: StringName, phase: StringName, project_cycle: int, cycle: int, cards: Array, priorities: Dictionary) -> Dictionary:
	return EmployeeRoster._apply(state,{"type":&"career_hand","project_id":project,"phase":phase,"project_cycle":project_cycle,"cycle":cycle,"cards":cards.duplicate(true),"priorities":priorities.duplicate()}) if EmployeeRoster.valid(state) else {}

static func release(state: Dictionary, project: StringName, cycle: int) -> Dictionary:
	return EmployeeRoster._apply(state,{"type":&"career_release","project_id":project,"cycle":cycle}) if EmployeeRoster.valid(state) else {}

static func apply(state: Dictionary, event: Dictionary, copy_source: bool=true) -> Dictionary:
	if typeof(event.get("cycle"))!=TYPE_INT or event.cycle<0:return {}
	# Public plans inspect their proven prefix. Private reconstruction enforces
	# these predicates with local indices in EmployeeRoster._validate_uncached.
	if copy_source:
		for prior: Dictionary in state.events:
			if prior.get("cycle",0)>event.cycle:return {}
	var next:=state.duplicate(true) if copy_source else state
	var kind: StringName=event.get("type",&"")
	if kind==&"career_activate":
		if event.size()!=3 or event.get("rules_version")!=1 or active(state):return {}
		for employee: Dictionary in next.employees.values():
			if employee.type!=&"production":continue
			employee.career=progress()
			if employee.trained:
				employee.career.courses[PRODUCTION[0]]={"cycle":event.cycle,"completed_cycle":event.cycle,"legacy":true}
	elif not active(state):return {}
	elif kind==&"career_hire":
		if event.size()!=3 or event.get("role") not in [&"production",&"project_manager"] or state.owner.is_empty():return {}
		if next.employees.values().any(func(e):return e.type==event.role):return {}
		var id:=StringName("%s:%s:1"%[state.owner,event.role])
		next.employees[id]={"employee_id":id,"owner":state.owner,"type":event.role,"hire_cycle":event.cycle,"trained":false,"projects":{},"career":progress()}
	elif kind==&"career_course":
		if event.size()!=5 or event.get("fee_cents")!=15000 or typeof(event.get("employee_id"))!=TYPE_STRING_NAME or typeof(event.get("course"))!=TYPE_STRING_NAME:return {}
		var employee: Dictionary=next.employees.get(event.employee_id,{})
		if employee.is_empty() or not employee.has("career") or event.cycle<employee.hire_cycle or event.course not in course_ids(employee.type) or next_course(employee)!=event.course:return {}
		employee.career.courses[event.course]={"cycle":event.cycle,"completed_cycle":-1,"legacy":false}
		employee.career.games[event.course]=[]
		employee.career.projects={}
	elif kind==&"career_hand":
		if event.size()!=7 or typeof(event.get("project_id"))!=TYPE_STRING_NAME or event.project_id.is_empty() or typeof(event.get("project_cycle"))!=TYPE_INT or event.project_cycle<0 or event.get("phase") not in [&"design",&"alpha",&"beta"] or not event.get("cards") is Array or (event.cards.is_empty() or event.cards.size()>4) or not event.get("priorities") is Dictionary:return {}
		for card in event.cards:
			if not card is Dictionary or card.size()!=5:return {}
			for key in ["id","type","primary","secondary","beta"]:
				if typeof(card.get(key))!=TYPE_STRING_NAME:return {}
			if card.id.is_empty() or card.type not in [&"pass",&"feature",&"beta"]:return {}
		var weights_ok:=BetaPriorityAllocation.is_valid_distribution(event.priorities) if event.phase==&"beta" else PriorityAllocation.is_valid_distribution(event.priorities)
		if not weights_ok:return {}
		if event.phase!=&"beta":
			if not PriorityAllocation.is_valid_with_bounds(event.priorities,limits(state)):return {}
		elif not BetaPriorityAllocation.insiders_enabled():
			var beta_limits:=limits(state,true)
			if event.priorities.get(&"insider",-1)!=0:return {}
			for category: StringName in [&"qa",&"marketing"]:
				if event.priorities[category]<beta_limits.x or event.priorities[category]>beta_limits.y:return {}
		if copy_source:
			for prior: Dictionary in state.events:
				if prior.type==kind and (prior.cycle==event.cycle or (prior.project_id==event.project_id and prior.phase==event.phase and prior.project_cycle==event.project_cycle)):return {}
		var action:=StringName("%s:%s:%d"%[event.project_id,event.phase,event.project_cycle])
		for employee: Dictionary in next.employees.values():
			if not employee.has("career"):continue
			var course:=current_course(employee)
			if course.is_empty():continue
			if event.cycle<=employee.career.courses[course].cycle:continue
			var project: Dictionary=employee.career.projects.get(event.project_id,{"design":[],"alpha":[],"specializations":[]})
			if employee.type==&"production":
				if event.phase in [&"design",&"alpha"] and EmployeeRoster.matches(event.cards):
					project[event.phase].append(action)
					if course==PRODUCTION[0] and event.phase==&"design":
						employee.trained=true;employee.career.courses[course].completed_cycle=event.cycle
			else:
				var stat: StringName=event.cards[0].beta if event.phase==&"beta" else event.cards[0].primary
				var same: bool=event.cards.size()==4 and event.cards.all(func(card):return (card.beta if event.phase==&"beta" else card.primary)==stat)
				var key: Variant=stat if event.phase==&"beta" else CORE.find(stat)
				var eligible: bool=stat in [&"qa",&"marketing"] and event.priorities.get(&"insider",-1)==0 if event.phase==&"beta" else stat in CORE
				if same and eligible and event.priorities.get(key,-1)==limits(state,event.phase==&"beta").x and project.specializations.size()<2:project.specializations.append(action)
			employee.career.projects[event.project_id]=project
	elif kind==&"career_release":
		if event.size()!=3 or typeof(event.get("project_id"))!=TYPE_STRING_NAME or event.project_id.is_empty():return {}
		for employee: Dictionary in next.employees.values():
			if not employee.has("career"):continue
			if event.project_id in employee.career.releases:return {}
			employee.career.releases.append(event.project_id)
			var course:=current_course(employee)
			if course.is_empty():continue
			var project: Dictionary=employee.career.projects.get(event.project_id,{})
			if employee.type==&"production":
				if course==PRODUCTION[1] and not project.get("design",[]).is_empty() and not project.get("alpha",[]).is_empty():employee.career.courses[course].completed_cycle=event.cycle
			elif project.get("specializations",[]).size()==2:
				employee.career.games[course].append(event.project_id)
				if employee.career.games[course].size()==4:
					employee.career.courses[course].completed_cycle=event.cycle;employee.trained=true
	else:return {}
	next.events.append(event.duplicate(true));return next

static func employee_schema() -> Dictionary:
	var s=CheckpointSchema
	var employee:=s.fields("employee_id owner type","id")
	employee.hire_cycle="uint";employee.trained="bool"
	employee.projects=s.map_of("id",{"trained_action":"id","used_action":"id","actions":s.array_of("id")})
	employee.career={"courses":s.map_of("id",{"cycle":"uint","completed_cycle":"int","legacy":"bool"}),"projects":s.map_of("id",{"design":s.array_of("id"),"alpha":s.array_of("id"),"specializations":s.array_of("id")}),"games":s.map_of("id",s.array_of("id")),"releases":s.array_of("id")}
	return employee

static func validate_saved(state: Dictionary, finance: Dictionary, metadata: Dictionary, active_project: StringName=&"") -> String:
	for event: Dictionary in state.events:
		if event.type==&"career_hand":
			if not metadata.has(event.project_id) and event.project_id!=active_project:return "Unknown career project"
			var kind: StringName=&"beta_income" if event.phase==&"beta" else &"feature_play"
			var commits:=0
			for action: Dictionary in finance.actions:
				if action.productive and action.cycle==event.cycle and action.source_id==event.project_id and action.kind==kind:commits+=1
			if commits!=1:return "Career hand has no committed action"
			if metadata.has(event.project_id) and event.project_cycle>=metadata[event.project_id].review.development_cycles:return "Career hand outside project lifetime"
		elif event.type==&"career_release":
			if not metadata.has(event.project_id) or metadata[event.project_id].release_cycle!=event.cycle:return "Career release has no committed game"
	for employee: Dictionary in state.employees.values():
		if not employee.has("career"):continue
		for course: StringName in employee.career.courses:
			var enrollment: Dictionary=employee.career.courses[course]
			if enrollment.legacy:continue
			var receipt:=StringName("%s:course:%s"%[employee.employee_id,course])
			var payments:=0
			for action: Dictionary in finance.actions:
				if action.source_id!=receipt:continue
				if action.cycle!=enrollment.cycle or action.direct_delta!=-15000 or action.get("operation",{}).get("course")!=course or action.get("operation",{}).get("rules_version")!=3:return "Career tuition mismatch"
				payments+=1
			if payments!=1:return "Missing career tuition"
		var payroll: Dictionary={}
		for pay: Dictionary in finance.employees:
			if pay.employee_id==employee.employee_id:payroll=pay
		if payroll.is_empty() or StudioFinanceLedger.payroll_wage(payroll,StudioFinanceLedger.MAX_INT)!=wage(employee):return "Career wage/progress mismatch"
	return ""

static func event_schemas() -> Array:
	var s=CheckpointSchema
	return [{"type":"id","cycle":"uint","rules_version":"uint"},{"type":"id","role":"id","cycle":"uint"},{"type":"id","employee_id":"id","course":"id","cycle":"uint","fee_cents":"uint"},{"type":"id","project_id":"id","cycle":"uint"},{"type":"id","project_id":"id","phase":"id","project_cycle":"uint","cycle":"uint","cards":s.array_of(s.fields("id type primary secondary beta","id")),"priorities":s.union_of([s.map_of("uint","uint"),s.map_of("id","uint")])}]
