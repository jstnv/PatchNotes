from run import *
source=(HERE/'greedy.gd').read_text(encoding='utf-8')
anchor='\tprediction = project(state,chosen)'
assert source.count(anchor)==1
source=source.replace(anchor,'\tif int(state.hand_count)==0 and config.arm in ["mean","downside"]:\n\t\tvar selection := plan_first(state,cards)\n\t\tchosen=[]\n\t\tfor index in selection: chosen.append(cards[index])\n'+anchor)
(HERE/'policy.gd').write_text(source+'\n'+(HERE/'planner.gd').read_text(encoding='utf-8'),encoding='utf-8')
write(HERE/'policy-pins.json',{name:sha(HERE/name) for name in ['PLAN.md','greedy.gd','planner.gd','policy.gd','controls.json','planning-4521.json','planning-4522.json']})
print('Policy and fixed experiment inputs pinned.')
