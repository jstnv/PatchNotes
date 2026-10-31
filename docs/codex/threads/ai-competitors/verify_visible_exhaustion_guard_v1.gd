## Actual legal prefix, not a fabricated hand: stop at the last visible Feature deal.
extends SceneTree
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var root_path="C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/threads/ai-competitors/"
	var policy=load(root_path+"current_founder_public_smoke_policy_v3.gd").new()
	var recipe={"schema_version":1,"studio_id":"visible-corner","studio_name":"Visible Corner","specialty":"action","traits":["family_funding","cult_following"],"seed":"5607","rival_founder_profile":"rival-founder-active-1977-v1","prelude_capital_cents":"2500000"}
	var session=load("res://scripts/simulation/run_factory.gd").create_fresh_session(recipe,root.get_node("CardDatabase").get_development_catalog())
	for step in 40:
		var view: Dictionary=session.observation()
		if view.phase==&"design" and session.development.hand.active and session.development.hand._available_features.is_empty():
			var visible: int=view.development.candidates.filter(func(c: Dictionary)->bool:return c.type=="feature").size()
			if visible>0:
				var rejected: bool=not session.development.actions.can_finalize()
				print("VISIBLE_EXHAUSTION_GUARD visible=",visible," cycle=",view.run_cycle," exit_rejected=",rejected)
				quit(0 if rejected else 1);return
		var choice: Dictionary=policy.choose(view)
		var result: Dictionary=session.execute(session.command(choice.type,choice.get("payload",{})))
		if not result.ok:print("PREFIX_REJECTED ",result);quit(2);return
	print("CORNER_NOT_REACHED");quit(2)
