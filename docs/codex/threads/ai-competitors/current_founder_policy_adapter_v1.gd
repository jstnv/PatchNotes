## Trusted isolated study adapter, not approved competitor policy or balance.
## Standard simulator factories retain this DecisionPolicy and its observation seam.
extends "res://scripts/simulation/decision_policy.gd"
const POLICY_ID := "rival-founder-prelude-candidate"
const POLICY_VERSION := "3"
const Helper=preload("res://scripts/market/rival_prelude_policy.gd")
const Historical=preload("res://scripts/market/historical_standard_trial.gd")
const Market=preload("res://scripts/market/market_transaction_trial.gd")
var session: RefCounted
var helper: RefCounted
static func factory(config: Dictionary) -> Callable:
	if config.get("genre","") not in ["action","adventure","role_playing","strategy","simulation","puzzle","sports","racing"]:return Callable()
	var policy=load(get_script_path()).new()
	policy.helper=Helper.new(config.genre,"audio_path")
	return policy.choose.bind(policy)
static func get_script_path() -> String:
	return "res://scripts/debug/experiment_policy/supplied_policy.gd"
func observation(value: RefCounted) -> Dictionary:
	session=value
	session.run._market_provider=Callable(self,"_market")
	return session.observation()
func choose(view: Dictionary) -> Dictionary:
	return helper.choose(session,view)
func _market(owner_id: StringName,target_cycle: int) -> Dictionary:
	if session==null or owner_id!=session.run._bank_run_id:return {}
	var source: Dictionary=Historical.source_from_run(session.run)
	return Market.neutral() if source.is_empty() or target_cycle<Historical.effective_cycle(source) else Historical.snapshot(source,target_cycle)
