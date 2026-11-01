class_name EmployeeRoster
extends RefCounted
const SCHEMA_VERSION := 1
const QA := preload("res://scripts/employees/qa_employee_rules.gd")
const Career := preload("res://scripts/employees/employee_career_rules.gd")
static func create(owner: StringName) -> Dictionary:
	return {"schema_version":SCHEMA_VERSION,"owner":owner,"employees":{},"events":[]}

static func hire(state: Dictionary, id: StringName, cycle: int) -> Dictionary:
	if not valid(state): return {}
	return _apply(state,{"type":&"hire","employee_id":id,"cycle":cycle})

static func card_facts(cards: Array) -> Array:
	var facts := []
	for card: CardData in cards:
		if card == null: return []
		facts.append({"id":card.id,"type":card.card_type,"primary":card.primary_stat,"secondary":card.secondary_stat})
	return facts

static func matches(facts: Array) -> bool:
	for card: Dictionary in facts:
		if card.type != &"pass": continue
		for feature: Dictionary in facts:
			if feature.type == &"feature" and not card.primary.is_empty() and card.primary in [feature.primary,feature.secondary]: return true
	return false

static func plan_hand(state: Dictionary, project_id: StringName, phase: StringName, project_cycle: int, run_cycle: int, cards: Array, before: Dictionary, proposed: Dictionary = {}) -> Dictionary:
	if not valid(state): return {}
	var facts := card_facts(cards)
	if (facts.is_empty() or facts.size() > 4) or project_id.is_empty() or project_cycle < 0 or run_cycle < 0 or phase not in [&"design",&"alpha"]: return {}
	var changed := not proposed.is_empty()
	if changed and (not PriorityAllocation.is_valid_with_bounds(proposed,Career.limits(state)) or proposed == before): return {}
	return _apply(state,{"type":&"hand","project_id":project_id,"phase":phase,"project_cycle":project_cycle,"cycle":run_cycle,"cards":facts,"before":before.duplicate(),"proposed":proposed.duplicate()})

static func available(state: Dictionary, project_id: StringName) -> bool:
	if not valid(state): return false
	for employee: Dictionary in state.employees.values():
		if employee.type == &"production" and employee.trained and employee.projects.get(project_id,{}).get("used_action",&"").is_empty(): return true
	return false

static func _apply(state: Dictionary, event: Dictionary, copy_source: bool=true) -> Dictionary:
	if str(event.get("type",&"")).begins_with("career_"):return Career.apply(state,event,copy_source)
	if event.get("type") in [&"employee_trial",&"hire_specialist",&"course",&"qa_beta",&"qa_proc",&"qa_finalize",&"qa_swap"]: return QA.apply(state,event,copy_source)
	var next := state.duplicate(true) if copy_source else state
	if event.get("type") == &"hire":
		if typeof(event.get("employee_id")) != TYPE_STRING_NAME or event.employee_id.is_empty() or typeof(event.get("cycle")) != TYPE_INT or event.cycle < 0 or next.employees.has(event.employee_id): return {}
		next.employees[event.employee_id] = {"employee_id":event.employee_id,"owner":state.owner,"type":&"production","hire_cycle":event.cycle,"trained":false,"projects":{}}
	elif event.get("type") == &"hand":
		for key in ["project_id","phase"]:
			if typeof(event.get(key)) != TYPE_STRING_NAME or event[key].is_empty(): return {}
		for key in ["project_cycle","cycle"]:
			if typeof(event.get(key)) != TYPE_INT or event[key] < 0: return {}
		if event.phase not in [&"design",&"alpha"] or typeof(event.get("cards")) != TYPE_ARRAY or (event.cards.is_empty() or event.cards.size()>4): return {}
		for card in event.cards:
			if typeof(card)!=TYPE_DICTIONARY: return {}
			for key in ["id","type","primary","secondary"]:
				if typeof(card.get(key))!=TYPE_STRING_NAME: return {}
			if card.id.is_empty() or card.type not in [&"pass",&"feature"]: return {}
		if typeof(event.get("before"))!=TYPE_DICTIONARY or typeof(event.get("proposed"))!=TYPE_DICTIONARY: return {}
		var use: bool = not event.proposed.is_empty()
		if use and (not PriorityAllocation.is_valid_distribution(event.proposed) or event.proposed==event.before): return {}
		var qualifying := matches(event.cards)
		var action := StringName("%s:%s:%d" % [event.project_id,event.phase,event.project_cycle])
		var used := false
		for id: StringName in next.employees:
			var employee: Dictionary = next.employees[id]
			if employee.type != &"production": continue
			if event.cycle < employee.hire_cycle: return {}
			var progress: Dictionary = employee.projects.get(event.project_id,{"trained_action":&"","used_action":&"","actions":[]})
			if action in progress.actions: return {}
			if use and not used and qualifying and employee.trained and progress.used_action.is_empty():
				progress.used_action = action
				used = true
			var enrolled: bool=not employee.has("career") or employee.career.courses.has(&"production_planning")
			if qualifying and enrolled and event.phase == &"design" and progress.trained_action.is_empty():
				progress.trained_action = action
				employee.trained = true
			progress.actions.append(action)
			employee.projects[event.project_id] = progress
		if use and not used: return {}
	else: return {}
	next.events.append(event.duplicate(true))
	return next

static func valid(state: Dictionary) -> bool:
	return _validate_uncached(state)

static func _validate_uncached(state: Dictionary) -> bool:
	if state.get("schema_version") != SCHEMA_VERSION or typeof(state.get("owner")) != TYPE_STRING_NAME or typeof(state.get("events")) != TYPE_ARRAY: return false
	var rebuilt := create(state.owner)
	var maximum_cycle: int=-1
	var hand_cycles: Dictionary={}
	var hand_identities: Dictionary={}
	for event in state.events:
		if typeof(event)!=TYPE_DICTIONARY: return false
		# Rebuild into a private state. Public plans still copy their input; copying
		# the entire growing journal on every replayed event caused quadratic stalls.
		rebuilt = _apply(rebuilt,event,false)
		if rebuilt.is_empty(): return false
		# The private Career reducer omits repeated prefix scans. These local
		# indices prove the same predicates across every fully replayed event;
		# no roster, revision or validation result survives this call.
		if str(event.type).begins_with("career_") and event.cycle<maximum_cycle:return false
		maximum_cycle=maxi(maximum_cycle,event.cycle)
		if event.type==&"career_hand":
			# phase historically accepts String and StringName by value. Preserve
			# that equality; use typed tuple bytes rather than delimiter strings.
			var identity:=var_to_bytes([event.project_id,StringName(event.phase),event.project_cycle])
			if hand_cycles.has(event.cycle) or hand_identities.has(identity):return false
			hand_cycles[event.cycle]=true;hand_identities[identity]=true
	return rebuilt == state

static func hire_specialist(state: Dictionary, role: StringName, cycle: int) -> Dictionary:
	if Career.active(state) and role in [&"production",&"project_manager"]:
		return _apply(state,{"type":&"career_hire","role":role,"cycle":cycle}) if valid(state) else {}
	return _apply(state,{"type":&"hire_specialist","role":role,"cycle":cycle}) if valid(state) else {}
static func buy_course(state: Dictionary, id: StringName, course: StringName, cycle: int) -> Dictionary:
	return _apply(state,{"type":&"course","employee_id":id,"course":course,"cycle":cycle,"fee_cents":15000}) if valid(state) else {}
static func qa_beta_hand(state: Dictionary, project: StringName, project_cycle: int, cycle: int, search: int, debug: int, discovered: int, fixed: int) -> Dictionary:
	return _apply(state,{"type":&"qa_beta","project_id":project,"project_cycle":project_cycle,"cycle":cycle,"search":search,"debug":debug,"discovered":discovered,"fixed":fixed}) if valid(state) else {}
static func qa_wage(e: Dictionary) -> int: return QA.wage(e)
static func qa_swap_available(state: Dictionary, project: StringName) -> bool: return valid(state) and QA.available(state,project)
static func qa_swap(state: Dictionary, project: StringName, project_cycle: int, cycle: int) -> Dictionary:
	return _apply(state,{"type":&"qa_swap","project_id":project,"project_cycle":project_cycle,"cycle":cycle}) if valid(state) else {}
static func qa_proc(state: Dictionary, project: StringName, project_cycle: int, cycle: int, phase: StringName, features: int) -> Dictionary:
	return _apply(state,{"type":&"qa_proc","project_id":project,"project_cycle":project_cycle,"cycle":cycle,"phase":phase,"features":features,"rules_version":1,"chance_percent":QA.PROC_PERCENT}) if valid(state) else {}
static func qa_finalize(state: Dictionary, project: StringName, project_cycle: int, cycle: int) -> Dictionary:
	return _apply(state,{"type":&"qa_finalize","project_id":project,"project_cycle":project_cycle,"cycle":cycle}) if valid(state) else {}

static func trial_active(state: Dictionary) -> bool:
	# Earlier private v2 prototypes already have explicit new-role/course events.
	for event: Dictionary in state.get("events",[]):
		if event.get("type") in [&"employee_trial",&"hire_specialist",&"course"]:return true
	return false
static func activate_trial(state: Dictionary,cycle: int) -> Dictionary:
	return {} if not valid(state) or trial_active(state) else _apply(state,{"type":&"employee_trial","cycle":cycle,"rules_version":2})
