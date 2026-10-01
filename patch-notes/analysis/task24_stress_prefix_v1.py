"""Normalize recorded completed checkpoints; never resume or invent game state."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1];out=root/'design-logs/task24-v1'
source=out/'stress_repeat_progress_independent.json'
p=json.loads(source.read_text(encoding='utf-8'))
command=json.loads((out/'stress-repeat-independent.command.json').read_text(encoding='utf-8'))
assert command['exit']=='timeout' and not command['errors']
visits=p['studio_visits'];releases=p['releases'];cycles=p['cycles'];final=visits[-1]
assert final['cycle']==981 and final['year']==2020 and final['is_studio']
assert len(releases)==99 and sum(r['meets_required_scope'] for r in releases)==98
assert len({r['release_id'] for r in releases})==99 and all(r['committed'] for r in releases)
assert releases[0]['scope']==20 and all(r['scope']>=r['required_scope']==30 for r in releases[1:])
assert [s['cycle'] for s in cycles]==list(range(1,982))
assert all(s['cash_cents']>=0 and s['unpaid_cents']>=0 for s in visits+cycles)
assert all(s['year']==1980+s['cycle']//24 for s in visits+cycles)
row={'arm':'repeat','case':0,'seed':270927000,'environment_seed':290929000,
     'valid':True,'valid_means':'recorded prefix invariants only; command timed out',
     'completed_prefix_validated':True,'censored':True,'status':'CENSORED_NATIVE_PREFIX',
     'requested_cycle':1104,'completed_cycle':981,'requested_horizon_met':False,
     'final':final,'releases':releases,'studio_visits':visits,'cycles':cycles,
     'owned_ids':final['owned_ids'],'errors':[],'blockers':[],
     'actions':None,'purchases':None,
     'limitations':['No final whole-route JSON: 600-second analysis timeout.',
                    'Full action/draw and per-release final sales dumps were not persisted by this checkpoint version.',
                    'Purchase history is null here rather than synthesized; actual ownership/cash snapshots are retained.',
                    'No outcome after cycle 981 is claimed.']}
result={'arm':'repeat','status':'CENSORED_NATIVE_PREFIX','censored':True,
        'checkpoint_source':source.name,'command_source':'stress-repeat-independent.command.json','rows':[row]}
(out/'stress_repeat_censored981.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('Validated native prefix:',len(releases),'releases',final['cycle'],'cycles',final['cash_cents'],'cents')
