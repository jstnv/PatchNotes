from pathlib import Path
import hashlib,json
out=Path(__file__).resolve().parent
root=out.parents[3]
source=root/'docs/codex/threads/contracts/simulators/crown-feedback-20261026-v1/project/scripts/debug/csa_access.gd'
data=source.read_bytes()
assert b'crown_brief' not in data and b'"cash"' in data
(out/'policy.gd').write_bytes(data)
config={'schema_version':'1','policy':{'script':'policy.gd','id':'queue-review-canonical-cash18','version':'1'},'cases':[{
    'schema_version':'1','case_id':'action-4417-three-releases','initial':{'recipe':{
        'schema_version':1,'studio_id':'queue-review-4417','studio_name':'Queue review','specialty':'action','traits':[],'seed':'4417'}},
    'max_commands':400,'target_release_count':3,'telemetry':True,
    'policy':{'config':{'specialty':'action','ratios':[30,20,30,20],'first_hands':2,'cash_searches':18}}}]}
(out/'campaign.json').write_text(json.dumps(config,indent=2)+'\n')
(out/'policy-provenance.json').write_text(json.dumps({'source':str(source.relative_to(root)),
    'sha256':hashlib.sha256(data).hexdigest(),'copied_without_edits':True,
    'scope':'public-observation player regression; no private Crown activation or numeric grants'},indent=2)+'\n')
runner=(out.parent/'balanced-boost-20261026-v1/run.py').read_text()
(out/'run.py').write_text(runner.replace('balanced-boost','queue-review'))
