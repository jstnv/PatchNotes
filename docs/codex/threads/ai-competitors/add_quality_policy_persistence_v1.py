from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v5/project'
def edit(path,old,new,count=1):
 f=P/path;s=f.read_text(encoding='utf-8');assert old in s,(path,old[:70]);f.write_bytes(s.replace(old,new,count).encode())
edit('scripts/market/rival_career_policy.gd','"marketing_hands":0}','"marketing_hands":0,"loan_project":-1}')
edit('scripts/market/rival_career_policy.gd','if str(view.project_id)!=str(state.project_id):state={"project_id":str(view.project_id),"search_done":false,"beta_hands":0,"marketing_hands":0,"loan_project":int(state.get("loan_project",-1))}', '''if str(view.project_id)!=str(state.project_id):
		var loan_project: int=int(state.loan_project)
		state.clear();state.merge({"version":"career-v1","project_id":str(view.project_id),"search_done":false,"beta_hands":0,"marketing_hands":0,"loan_project":loan_project})''')
wrapper='''## Versioned, persisted policy memory is separate from gameplay command state.
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
	return {"run_id":current.run._bank_run_id,"project_id":current.project_id(),"phase":current.phase(),"releases":current.run.get_released_game_ids(),"development":{} if current.in_studio else current.development.observation(false)}
func choose(view: Dictionary,_lifetime: RefCounted) -> Dictionary:
	prior=view;return policy.choose(session,view)
func observe_result(choice: Dictionary,result: Dictionary) -> void:
	policy.observe_result(prior,choice,result)
'''
(P/'scripts/market/rival_career_decision.gd').write_bytes(wrapper.encode())
edit('scripts/market/rival_world.gd','var legacy: Dictionary = {}','var policy_states: Dictionary = {}\nvar legacy: Dictionary = {}')
edit('scripts/market/rival_world.gd','accepted.append({"type":chosen.type,"events":result.events.duplicate(true)})','if policy.get_object().has_method("observe_result"):policy.get_object().observe_result(chosen,result)\n\t\taccepted.append({"type":chosen.type,"events":result.events.duplicate(true)})',2)
edit('scripts/market/rival_trial.gd','var policy := TrialPolicy.new()','''if session.run._rival_founder_profile=="rival-founder-active-1977-v2":
			if not world.policy_states.has(id):world.policy_states[id]={}
			var career:=preload("res://scripts/market/rival_career_decision.gd").new(session,world.policy_states[id])
			result[id]=career.choose.bind(career)
			continue
		var policy := TrialPolicy.new()''')
f=P/'scripts/market/rival_world_checkpoint.gd';s=f.read_text(encoding='utf-8')
s=s.replace('var payload := {"schema_version":"2" if projected else "1"','var payload := {"schema_version":("3" if not world.policy_states.is_empty() else "2") if projected else "1"',1)
s=s.replace('if projected: row.offset = str(offset)','''if projected: row.offset = str(offset)
		if not world.policy_states.is_empty():
			if not world.policy_states.has(id):error="Missing career policy state";return {}
			row.policy=world.policy_states[id].duplicate(true)''',1)
s=s.replace('if payload.schema_version=="2" else','if payload.schema_version in ["2","3"] else')
s=s.replace('row.run=adapter.encode_snapshot(row.run)','''if payload.schema_version=="3":
			row.policy=_encode(row.policy,_policy_schema())
			if not error.is_empty():return {}
		row.run=adapter.encode_snapshot(row.run)''',1)
s=s.replace('var projected: bool=payload.get("schema_version")=="2"','var projected: bool=payload.get("schema_version") in ["2","3"]\n\tvar career: bool=payload.get("schema_version")=="3"',1)
s=s.replace('payload.get("schema_version") not in ["1","2"]','payload.get("schema_version") not in ["1","2","3"]',1)
s=s.replace('row.size()!=(6 if projected else 5)','row.size()!=((7 if career else 6) if projected else 5)',1)
s=s.replace('rows.append({"id":id,"run":row.run,"sequence":sequence,"development":dev,"archive":archive,"offset":offset})','''var memory: Dictionary={}
		if career:
			memory=_decode(row.get("policy",{}),_policy_schema())
			if not error.is_empty() or memory.version!="career-v1" or memory.beta_hands>12 or memory.marketing_hands>12 or memory.loan_project< -1:error="Invalid career policy memory";return {}
		rows.append({"id":id,"run":row.run,"sequence":sequence,"development":dev,"archive":archive,"offset":offset,"policy":memory})''',1)
s=s.replace('var active: bool = not row.development.is_empty()','if not row.get("policy",{}).is_empty():world.policy_states[row.id]=row.policy.duplicate(true)\n\t\tvar active: bool = not row.development.is_empty()',1)
s+='''
static func _policy_schema() -> Dictionary:
	return {"version":"text","project_id":"text","search_done":"bool","beta_hands":"uint","marketing_hands":"uint","loan_project":"int"}
'''
f.write_bytes(s.encode());print('Versioned policy memory and legacy-only policy routing added.')
