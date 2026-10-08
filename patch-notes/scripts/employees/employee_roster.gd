class_name EmployeeRoster
extends RefCounted
const SCHEMA_VERSION := 1

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
	if facts.size() != 4 or project_id.is_empty() or project_cycle < 0 or run_cycle < 0 or phase not in [&"design",&"alpha"]: return {}
	var changed := not proposed.is_empty()
	if changed and (not PriorityAllocation.is_valid_distribution(proposed) or proposed == before): return {}
	return _apply(state,{"type":&"hand","project_id":project_id,"phase":phase,"project_cycle":project_cycle,"cycle":run_cycle,"cards":facts,"before":before.duplicate(),"proposed":proposed.duplicate()})

static func available(state: Dictionary, project_id: StringName) -> bool:
	if not valid(state): return false
	for employee: Dictionary in state.employees.values():
		if employee.trained and employee.projects.get(project_id,{}).get("used_action",&"").is_empty(): return true
	return false

static func _apply(state: Dictionary, event: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	if event.get("type") == &"hire":
		if typeof(event.get("employee_id")) != TYPE_STRING_NAME or event.employee_id.is_empty() or typeof(event.get("cycle")) != TYPE_INT or event.cycle < 0 or next.employees.has(event.employee_id): return {}
		next.employees[event.employee_id] = {"employee_id":event.employee_id,"owner":state.owner,"type":&"production","hire_cycle":event.cycle,"trained":false,"projects":{}}
	elif event.get("type") == &"hand":
		for key in ["project_id","phase"]:
			if typeof(event.get(key)) != TYPE_STRING_NAME or event[key].is_empty(): return {}
		for key in ["project_cycle","cycle"]:
			if typeof(event.get(key)) != TYPE_INT or event[key] < 0: return {}
		if event.phase not in [&"design",&"alpha"] or typeof(event.get("cards")) != TYPE_ARRAY or event.cards.size()!=4: return {}
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
			if event.cycle < employee.hire_cycle: return {}
			var progress: Dictionary = employee.projects.get(event.project_id,{"trained_action":&"","used_action":&"","actions":[]})
			if action in progress.actions: return {}
			if use and not used and qualifying and employee.trained and progress.used_action.is_empty():
				progress.used_action = action
				used = true
			if qualifying and event.phase == &"design" and progress.trained_action.is_empty():
				progress.trained_action = action
				employee.trained = true
			progress.actions.append(action)
			employee.projects[event.project_id] = progress
		if use and not used: return {}
	else: return {}
	next.events.append(event.duplicate(true))
	return next

static func valid(state: Dictionary) -> bool:
	if state.get("schema_version") != SCHEMA_VERSION or typeof(state.get("owner")) != TYPE_STRING_NAME or typeof(state.get("events")) != TYPE_ARRAY: return false
	var rebuilt := create(state.owner)
	for event in state.events:
		if typeof(event)!=TYPE_DICTIONARY: return false
		rebuilt = _apply(rebuilt,event)
		if rebuilt.is_empty(): return false
	return rebuilt == state
