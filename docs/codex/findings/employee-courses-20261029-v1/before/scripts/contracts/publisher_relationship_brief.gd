class_name PublisherRelationshipBrief
extends RefCounted

## Bounded SideStreet trial. Existing work-Contract cash and Promotion are
## deliberately separate from this relationship-only result.
const FULL := 10000
const MAX_REPUTATION_AWARD_BP := 1000

static func result(state: ContractState) -> Dictionary:
	if state == null or state.get_contract_id() != ContractDefinitions.SIDESTREET_BRIEF or not state.is_completed():
		return {}
	var completion := state.get_result()
	if completion == null or completion.get_payout_cents() != 0 or completion.get_promotion() != 0:
		return {}
	var numerator := completion.get_completion_numerator()
	if numerator < 0 or numerator > 64: return {}
	var completion_bp := numerator * FULL / 64
	var promise_bp := completion.get_challenge_grade_bp()
	if promise_bp not in [0,5000,10000]: return {}
	var award_bp := MAX_REPUTATION_AWARD_BP * mini(completion_bp,promise_bp) / FULL
	return {"completion_bp":completion_bp,"promise_bp":promise_bp,"raw_award_bp":award_bp}
