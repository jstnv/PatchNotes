## Versioned, persisted policy memory is separate from gameplay command state.
extends "res://scripts/simulation/decision_policy.gd"
const Career:=preload("res://scripts/market/rival_career_policy.gd")
var session: RefCounted
var policy: RefCounted
var prior: Dictionary
func _init(current: RefCounted,memory: Dictionary) -> void:
	session=current;policy=Career.new(current.run.get_studio_specialty())
	if memory.is_empty():memory.merge({"version":"career-v1","project_id":"","search_done":false,"beta_hands":0,"marketing_hands":0,"loan_project":-1})
	policy.state=memory
func observation(current: RefCounted) -> Dictionary:
	var development: Dictionary={} if current.in_studio else current.development.observation(false)
	if not current.in_studio:development.can_exit=current.development.actions.can_finalize()
	var view: Dictionary={"run_id":current.run._bank_run_id,"project_id":current.project_id(),"phase":current.phase(),"releases":current.run.get_released_game_ids(),"development":development}
	if current.in_studio:
		view.engine_features=current.run.get_engine_feature_state()
		view.engine_configuration=current.run.get_engine_configuration_quote()
		view.selected_engine_id=current.run.get_selected_engine_id()
		view.engine_available_features=current.run.get_future_project_feature_ids()
	return view
func choose(view: Dictionary,_lifetime: RefCounted) -> Dictionary:
	prior=view;return policy.choose(session,view)
func observe_result(choice: Dictionary,result: Dictionary) -> void:
	policy.observe_result(prior,choice,result)

func allows_post_boundary() -> bool:
	if session.in_studio or session.phase()!=&"beta":return false
	if session.development.finalized:return true
	return policy.beta_complete(observation(session))
