"""Focused maintained checks, serial to bound memory and isolate writer leases."""
from pathlib import Path
import json
import subprocess
import sys

here=Path(__file__).resolve().parent
names=sys.argv[1:] or ['verify_checkpoint_codec','verify_checkpoint_store','verify_studio_checkpoint',
    'verify_checkpoint_rng','verify_checkpoint_runtime','verify_feature_research','verify_research_integration',
    'verify_research_ui','verify_feature_store','verify_feature_store_navigation','verify_finance_observation',
    'verify_bank_finance','verify_bank_integration','verify_simulation_efficiency','verify_launch_extraction',
    'verify_release_menus','verify_qa_employees','verify_qa_transactions','verify_new_save_loading',
    'verify_save_tutorial_invitation','verify_continue_loading','verify_pause_menu','verify_contract_search_ui','verify_gameplay_transition']
results=[]
for name in names:
    label='bg-final-'+name.removeprefix('verify_').replace('_','-')
    proc=subprocess.run([sys.executable,'-X','utf8',str(here/'run_checks.py'),label,name,'--isolate'],capture_output=True)
    command=here/f'{label}.command.json'
    record=json.loads(command.read_text()) if command.exists() else {'exit':proc.returncode,'errors':[proc.stderr.decode('utf-8',errors='replace')]}
    row={'name':name,'ok':proc.returncode==0,'seconds':record.get('seconds'),'errors':record.get('errors')}
    results.append(row)
    (here/'final-suite.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(json.dumps(row),flush=True)
sys.exit(0 if all(row['ok'] for row in results) else 1)
