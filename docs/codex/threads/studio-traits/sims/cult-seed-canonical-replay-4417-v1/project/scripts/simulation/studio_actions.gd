## Thin command adapter over existing RunState transactions. Quotes are never
## regenerated on submission. This does not define new prices or action costs.
extends RefCounted
const MONEY_ACTIONS := {&"bank_borrow":&"accept_bank_loan",&"bank_payoff":&"pay_off_bank_loan",&"education_payoff":&"pay_off_education"}

static func execute(run: RunState,kind: StringName,payload: Dictionary,in_studio: bool) -> Dictionary:
	if kind in MONEY_ACTIONS or kind == &"hire":
		if kind == &"hire" and not in_studio: return reject("Hiring requires Studio")
		if payload.size() != 1 or not payload.get("quote") is Dictionary: return reject("Exact quote required")
		var method: StringName = &"hire_production_specialist" if kind == &"hire" else MONEY_ACTIONS[kind]
		if not run.call(method,payload.quote): return reject("Financial action rejected")
		return {"ok":true,"events":[{"type":str(kind)+"_committed"}]}
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
	if run.is_primitive_contract_offer_available(): offers.append({"kind":&"ironclad"})
	if run.is_sidestreet_offer_available(): offers.append({"kind":&"sidestreet","offer_id":run.get_next_sidestreet_offer().offer_id})
	for id: StringName in run.get_pending_publisher_offer_ids():
		var quote := run.get_publisher_contract_offer(id)
		if not quote.is_empty(): offers.append({"kind":&"publisher","quote":quote})
	return {"finance":money.finance,"employees":run.get_employees(),"hire_quote":money.hire_quote,"education_payoff_quote":money.education_payoff_quote,"bank_payoff_quotes":money.bank_payoff_quotes,"contract_offers":offers}
