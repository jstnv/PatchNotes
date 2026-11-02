## Read-only presentation of current progression. No quotes, actions or RNG.
extends RefCounted

const DIRECTIONS := {&"graphics":Vector2i.LEFT,&"sound":Vector2i.RIGHT,&"technology":Vector2i.UP,&"design":Vector2i.DOWN}
const FOUNDATIONS := {&"graphics":"4-Color Palette",&"sound":"8-Bit Sound",&"technology":"Keyboard & Mouse",&"design":"Text"}

static func item(id: StringName,title: String,cell: Vector2i,parents: Array,state: String,status: String,description: String="") -> Dictionary:
	return {"id":id,"title":title,"cell":cell,"parents":parents,"state":state,"status":status,"description":description,"action":"","kind":&"info"}

static func engine(run: RunState,id: StringName) -> Array:
	var row:=run.get_proprietary_engine_row(id)
	if row.is_empty():return []
	var rules=run.ProprietaryEngines
	var capacity: int=rules.CAPACITY+5*rules.milestone(row)
	var rows: Array=[item(&"engine",str(row.name),Vector2i.ZERO,[],"complete","%d maximum Scope"%capacity,"Four independent branches. Accepted printed Feature Core using this engine earns each active challenge; Passes and synergies do not count.\n\nFour purchased nodes in a generation automatically expand Scope: 25 → 30 → 35. The expansion is free and consumes no cycle.\n\nGeneration III (40 Scope) / IV (45 Scope) remain unavailable; no later upgrades can be purchased.")]
	var milestone: int=rules.milestone(row)
	if milestone<2:
		var count:=0
		for branch: StringName in rules.BRANCHES:
			if rules.generation(row,branch)>milestone:count+=1
		rows[0].description+="\n\nNext Scope Expansion %s: %d/4 upgrades purchased → %d maximum Scope."%["I" if milestone==0 else "II",count,rules.CAPACITY+5*(milestone+1)]
	for branch: StringName in rules.BRANCHES:
		var direction: Vector2i=DIRECTIONS[branch]
		var foundation:=StringName(str(branch)+"_foundation")
		var base:=item(foundation,FOUNDATIONS[branch],direction,[&"engine"],"complete","Foundation",str(branch).capitalize()+" foundation technology. Supporting a technology does not grant its Feature card.")
		base.branch=branch;rows.append(base)
		var level: int=rules.generation(row,branch)
		for generation in [1,2]:
			var node: Dictionary=rules.node(branch,generation)
			var owned: bool=level>=generation
			var active: bool=level==generation-1
			var progress: int=int(row.challenge_progress.get(branch,0)) if active else int(node.threshold) if owned else 0
			var state: String="complete" if owned else "ready" if active and progress>=int(node.threshold) else "active" if active else "locked"
			var status: String="Purchased" if owned else "%d / %d Core"%[progress,int(node.threshold)] if active else "Requires Generation I"
			var effect: String="+20% matching Feature Core toward Pass Budget generation" if generation==1 else "+10% matching Pass effectiveness" if branch in [&"graphics",&"sound"] else "−15% matching Feature bug pressure"
			var parent: StringName=foundation if generation==1 else StringName(str(branch)+"_1")
			var entry:=item(StringName(str(branch)+"_"+str(generation)),str(node.name),direction*(generation+1),[parent],state,status,"Generation %s · %s\n\n%s\n\n%s. A ready challenge must still be purchased. Purchases consume no productive cycle."%["I" if generation==1 else "II",str(branch).capitalize(),status,effect])
			entry.merge({"kind":&"skill","branch":branch,"generation":generation,"cost_cents":int(node.cost_cents),"action":"Purchase · "+CashFormatter.format_exact_cents(node.cost_cents)},true)
			rows.append(entry)
	return rows

static func courses(run: RunState) -> Array:
	var roster:=run.get_employees()
	var rows: Array=[item(&"courses","Employee Courses",Vector2i.ZERO,[],"complete","Training paths","Enrollment starts a challenge. The permanent benefit and prospective wage increase are earned only when the challenge completes. Inspect a course before enrolling.")]
	for role: StringName in [&"production",&"qa",&"project_manager"]:
		var employee: Dictionary={}
		for candidate: Dictionary in roster.employees.values():
			if candidate.type==role:employee=candidate;break
		var direction: Vector2i=Vector2i.LEFT if role==&"production" else Vector2i.UP if role==&"qa" else Vector2i.RIGHT
		var root:=StringName("role_"+str(role))
		var name: String="Production Specialist" if role==&"production" else "QA Specialist" if role==&"qa" else "Project Manager"
		rows.append(item(root,name,direction,[&"courses"],"complete" if not employee.is_empty() else "locked","Hired" if not employee.is_empty() else "Hire in Roster", "Hire this role through Roster. Courses do not hire employees or award their benefits immediately."))
		var ids: Array=[&"mixed",&"pure"] if role==&"qa" else EmployeeRoster.Career.course_ids(role)
		var previous: StringName=root
		var preceding_complete:=true
		for index in ids.size():
			var course: StringName=ids[index]
			var record: Dictionary=employee.get("courses",{}).get(course,{}) if role==&"qa" else employee.get("career",{}).get("courses",{}).get(course,{})
			var completed: bool=not record.is_empty() and int(record.completed_cycle)>=0
			var state: String="complete" if completed else "active" if not record.is_empty() else "ready" if not employee.is_empty() and (role==&"qa" or preceding_complete) else "locked"
			var cell: Vector2i=Vector2i(-1 if index==0 else 1,-2) if role==&"qa" else direction*(index+2)
			var parent: StringName=root if role==&"qa" else previous
			var title: String="Search & Fix" if course==&"mixed" else "QA Versatility" if course==&"pure" else "Production Planning" if course==&"production_planning" else "Pass Alignment" if course==&"pass_alignment" else "Project Management "+str(index+1)
			var status: String="Completed" if completed else "Training" if not record.is_empty() else "Hire first" if employee.is_empty() else "Available to enroll" if state=="ready" else "Complete parent course"
			var entry:=item(course,title,cell,[parent],state,status)
			entry.merge({"kind":&"course","role":role,"employee_id":employee.get("employee_id",&""),"course":course,"cost_cents":15000,"action":"Enroll · $150.00"},true)
			rows.append(entry)
			previous=course;preceding_complete=completed
	return rows
