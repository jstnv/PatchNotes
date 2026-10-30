## Thin command adapter over existing RunState transactions. Quotes are never
## regenerated on submission. This does not define new prices or action costs.
extends RefCounted
const MONEY_ACTIONS := {&"bank_borrow":&"accept_bank_loan",&"bank_payoff":&"pay_off_bank_loan",&"education_payoff":&"pay_off_education"}

static func execute(run: RunState,kind: StringName,payload: Dictionary,in_studio: bool) -> Dictionary:
	if kind==&"activate_employees":
		if not in_studio or not payload.is_empty() or run.get_released_game_ids().size()<2 or not run.activate_employee_trial():return reject("Employee activation unavailable")
		return {"ok":true,"events":[{"type":"employee_courses_activated"}]}
	if kind in MONEY_ACTIONS or kind in [&"hire",&"course"]:
		if kind in [&"hire",&"course"] and not in_studio: return reject("Hiring requires Studio")
		if kind in [&"hire",&"course"] and not run.uses_employee_courses():return reject("Activate the current employee system after Game 2")
		if payload.size() != 1 or not payload.get("quote") is Dictionary: return reject("Exact quote required")
		var method: StringName = (&"hire_specialist" if kind==&"hire" else &"purchase_employee_course") if kind in [&"hire",&"course"] else MONEY_ACTIONS[kind]
		if not run.call(method,payload.quote): return reject("Financial action rejected")
		return {"ok":true,"events":[{"type":str(kind)+"_committed"}]}
	if kind==&"search_contracts":
		if not in_studio or payload.size()!=1 or not payload.get("quote") is Dictionary:return reject("Exact Studio search quote required")
		if not run.search_contracts(payload.quote):return reject("Contract search rejected")
		return {"ok":true,"events":[{"type":"contract_found","receipt":run.get_contract_search_state().receipts[-1]}]}
	if kind == &"accept_contract":
		if not in_studio or run.get_active_contract() != null: return reject("Contract acceptance requires Studio")
		if not payload.get("kind") is String and not payload.get("kind") is StringName: return reject("Contract kind required")
		var state: ContractState
		match StringName(payload.kind):
			&"ironclad":
				if payload.size() != 1: return reject("Unexpected Ironclad payload")
				state = run.accept_primitive_contract()
			&"sidestreet":
				if payload.size() != 2 or (not payload.get("offer_id") is String and not payload.get("offer_id") is StringName): return reject("SideStreet offer ID required")
				state = run.accept_sidestreet_offer(StringName(payload.offer_id))
			&"sidestreet_brief":
				if payload.size() not in [2,3] or (not payload.get("offer_id") is String and not payload.get("offer_id") is StringName): return reject("Brief ID required")
				# Observations expose the detached quote alongside the command ID.
				# Accept that exact row, but never silently discard altered terms.
				if payload.size()==3 and (not payload.has("quote") or payload.quote!=run.get_sidestreet_brief_offer()): return reject("Brief quote changed")
				state = run.accept_sidestreet_brief(StringName(payload.offer_id))
			&"publisher":
				if payload.size() != 2 or not payload.get("quote") is Dictionary: return reject("Publisher quote required")
				state = run.accept_publisher_contract(payload.quote)
		if state == null: return reject("Contract acceptance rejected")
		return {"ok":true,"state":state,"events":[{"type":"contract_accepted","offer_id":state.get_offer_id()}]}
	return reject("Unsupported Studio action")

static func reject(message: String) -> Dictionary:
	return {"ok":false,"error":message,"events":[]}

static func observation(run: RunState) -> Dictionary:
	var money := run.get_studio_action_finance_observation()
	var offers: Array = []
	var brief := run.get_sidestreet_brief_offer()
	if not brief.is_empty() and run.get_active_contract()==null: offers.append({"kind":&"sidestreet_brief","offer_id":brief.offer_id,"quote":brief})
	if run.is_primitive_contract_offer_available(): offers.append({"kind":&"ironclad"})
	if run.is_sidestreet_offer_available(): offers.append({"kind":&"sidestreet","offer_id":run.get_next_sidestreet_offer().offer_id})
	for id: StringName in run.get_pending_publisher_offer_ids():
		var quote := run.get_publisher_contract_offer(id)
		if not quote.is_empty(): offers.append({"kind":&"publisher","quote":quote})
	var enabled:=run.uses_employee_courses()
	return {"finance":money.finance,"employees":run.get_employee_observation(),"hire_quote":money.hire_quote if enabled else {},"education_payoff_quote":money.education_payoff_quote,"bank_payoff_quotes":money.bank_payoff_quotes,"contract_offers":offers,"contract_search":run.get_contract_search_catalog(),"search_history":run.get_contract_search_state(),"hire_quotes":[run.get_employee_hire_quote(&"production"),run.get_employee_hire_quote(&"qa"),run.get_employee_hire_quote(&"project_manager")] if enabled else [],"course_quotes":[run.get_qa_course_quote(&"mixed"),run.get_qa_course_quote(&"pure")]+run.get_employee_course_quotes() if enabled else [],"employee_activation_available":run.get_released_game_ids().size()>=2 and not enabled}
