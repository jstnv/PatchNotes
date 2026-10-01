"""Compare seeded scene traces after aliasing intentionally random release UUIDs."""
from pathlib import Path
import json

OUT=Path(__file__).resolve().parents[1]/'design-logs/feature-store-staged-v1'

def normalized(row):
    ids={r['release_id']:f'release_{i+1}' for i,r in enumerate(row['releases'])}
    def visit(value):
        if isinstance(value,str):
            for raw,alias in ids.items():value=value.replace(raw,alias)
            return value
        if isinstance(value,list):return [visit(v) for v in value]
        if isinstance(value,dict):return {visit(k):visit(v) for k,v in value.items() if k!='seeded_initial_deal_passive'}
        return value
    return visit(row)

old=json.loads((OUT/'stage3_replay_reference_0_30.json').read_text())['rows'][0]
new=json.loads((OUT/'stage3_ordinary_production_0_30.json').read_text())['rows'][0]
passed=normalized(old)==normalized(new)
result={'pass':passed,'policy':'ordinary','seed':270927000,'cap':30,'actual_cycles':new['final']['cycle'],
    'releases':len(new['releases']),'normalization':'Alias random immutable release UUIDs chronologically; ignore added passive-deal observation key only.'}
(OUT/'stage3_replay_check_v1.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
assert passed

long_path=OUT/'stage3_ordinary_production_0_1104.json'
if long_path.exists():
    short=json.loads((OUT/'stage3_ordinary_production_0_240.json').read_text())['rows'][0]
    long=json.loads(long_path.read_text())['rows'][0]
    short_norm=normalized(short)
    long_norm=normalized(long)
    cutoff=short['final']['cycle']
    prefix=[s for s in long_norm['cycle_rows'] if s['cycle']<=cutoff]
    prefix_pass=prefix==short_norm['cycle_rows']
    extension_result={'pass':prefix_pass,'policy':'ordinary','seed':270927000,'matched_prefix_cycles':cutoff,
        'extension_final_cycles':long['final']['cycle'],'extension_releases':len(long['releases']),
        'normalization':'Chronological aliasing of immutable release UUIDs only.'}
    (OUT/'stage3_extension_prefix_check_v1.json').write_text(json.dumps(extension_result,indent=2))
    print(json.dumps(extension_result))
    assert prefix_pass

for name in ['stage3_ordinary_priority_0_1104','stage3_cautious_minimal_0_96']:
    repeated=OUT/(name+'_replay.json')
    if not repeated.exists():continue
    baseline=json.loads((OUT/(name+'.json')).read_text())['rows'][0]
    rerun=json.loads(repeated.read_text())['rows'][0]
    result={'pass':normalized(baseline)==normalized(rerun),'route':baseline['route'],'seed':baseline['seed'],
        'cycles':rerun['final']['cycle'],'releases':len(rerun['releases']),'normalization':'Chronological release UUID aliases only.'}
    (OUT/(name+'_replay_check.json')).write_text(json.dumps(result,indent=2))
    print(json.dumps(result))
    assert result['pass']
