extends SceneTree
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var factory=load("res://scripts/simulation/run_factory.gd")
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var recipe={"schema_version":1,"studio_id":"scope-guard","studio_name":"Guard","specialty":"action","traits":[],"seed":"5607","rival_founder_profile":str(preload("res://scripts/market/rival_founder_profile.gd").ID)}
	var session=factory.create_fresh_session(recipe,catalog)
	var command=session.command(&"begin_development",{"name":"Scope Guard","genre":"action","theme":"fantasy"})
	var result=session.execute(command)
	if not result.ok:print("SETUP_FAIL ",result);quit(2);return
	var actions=session.development.actions
	# Requesting an exit while affordable finite Design work remains must reject.
	var guarded: bool=not actions.can_finalize()
	actions.phase=&"alpha"
	guarded=guarded and not actions.can_finalize()
	print("RIVAL_SCOPE_GUARD pending_feature_and_under_scope_alpha_rejected=",guarded)
	quit(0 if guarded else 1)
