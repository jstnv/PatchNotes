from pathlib import Path
import json, zipfile
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
PROJECT=ROOT/'docs/codex/threads/contracts/simulators/crown-feedback-20261026-v1/project'
PACKET=ROOT/'docs/codex/threads/contracts/handoffs/crown-search-brief-20261025-v1'
with zipfile.ZipFile(PACKET/'candidate-source.zip') as z:
    policy=z.read('scripts/debug/csa_access.gd').decode().replace('\r\n','\n')
policy=policy.replace('{&"qa":50,&"marketing":25,&"insider":25}','{&"qa":50,&"marketing":50,&"insider":0}')
(PROJECT/'scripts/debug/csa_access.gd').write_text(policy,encoding='utf-8',newline='\n')
config=json.loads((ROOT/'docs/codex/threads/contracts/studies/crown-search-brief-20261025-v1/prefix.json').read_text())
config['policy']['version']='3-insider-hold'
for case in config['cases']:
    case['case_id']=case['case_id'].replace('prefix-','current-')
(OUT/'prefix-config.json').write_text(json.dumps(config,indent=2)+'\n')
print('Two legal, unfunded current-source access routes; Beta QA50/Marketing50/Insider0')
