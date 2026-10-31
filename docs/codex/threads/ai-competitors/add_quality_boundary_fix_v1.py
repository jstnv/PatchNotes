from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v13/project'
def edit(path,old,new):
 f=P/path;s=f.read_text(encoding='utf-8');assert old in s,(path,old[:60]);f.write_bytes(s.replace(old,new,1).encode())
edit('scripts/market/rival_world.gd','''while zero_steps < limit:
		var chosen := _choice(policy,session)''','''while zero_steps < limit:
		# Only natural Beta completion/launch needs this same-tick window.
		# Other new-policy choices probe next-cycle affordability; defer them
		# until all owners settle and that authoritative Market exists.
		if run._rival_founder_profile=="rival-founder-active-1977-v2":
			var decision: Object=policy.get_object()
			if decision.has_method("allows_post_boundary"):
				if not decision.allows_post_boundary():break
			elif session.in_studio or session.phase()!=&"beta" or not session.development.finalized:break
		var chosen := _choice(policy,session)''')
f=P/'scripts/market/rival_career_decision.gd';s=f.read_text(encoding='utf-8');s+='''
func allows_post_boundary() -> bool:
	if session.in_studio or session.phase()!=&"beta":return false
	if session.development.finalized:return true
	return policy.beta_complete(observation(session))
''';f.write_bytes(s.encode())
f=P/'scripts/market/rival_career_policy.gd';s=f.read_text(encoding='utf-8')
old='if ((state.search_done and int(current.known_bugs)==0 and int(state.marketing_hands)>=1) or int(state.beta_hands)>=12) and current.can_exit:return _dev(view,&"request_exit")';assert old in s;s=s.replace(old,'if beta_complete(view):return _dev(view,&"request_exit")',1)
old='''var goal:=6.5 if run.get_released_game_ids().is_empty() else 8.75
		var needs_more:''';assert old in s
s=s.replace(old,'''var finite:=not session.development.hand._available_features.is_empty()
		for card: Dictionary in current.candidates:
			if card.type=="feature":finite=true
		if view.phase==&"alpha" and not finite and int(current.scope)<int(current.required_scope):return {"type":&"blocked","payload":{"reason":"Frozen Feature supply cannot complete required Scope"}}
		var goal:=6.5 if run.get_released_game_ids().is_empty() else 8.75
		var needs_more:''',1)
s+='''
func beta_complete(view: Dictionary) -> bool:
	if view.phase!=&"beta":return false
	return view.development.can_exit and ((state.search_done and int(view.development.known_bugs)==0 and int(state.marketing_hands)>=1) or int(state.beta_hands)>=12)
''';f.write_bytes(s.encode())
(P/'export_presets.cfg').write_bytes((P.parents[1]/'rival-quality-1977-20261030-v12/project/export_presets.cfg').read_bytes())
print('No speculative market authority: defer new-policy planning to next pre-boundary; retain same-tick natural Beta launch. Exhausted underScope blocks explicitly.')
