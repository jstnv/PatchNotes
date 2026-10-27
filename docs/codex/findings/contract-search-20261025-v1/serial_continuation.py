from pathlib import Path
import json,subprocess,sys,time
root=Path(__file__).resolve().parents[4]
raw=Path('C:/Users/64jus/AppData/Local/Temp/pn-contract-search-20261025-v1')
while True:
 r=json.loads((raw/'whole-matrix-v3/result.json').read_text())
 if 'canonical_unchanged' in r:break
 time.sleep(5)
names={x['name'] for x in r['checks'] if not x['pass']}
names.update(['verify_qa_employees','verify_qa_transactions','verify_qa_career','verify_employee_ui','verify_contract_search','verify_contract_search_ui','verify_campaign_session','verify_studio_checkpoint','verify_queue_source_migration','verify_publisher_relationships','verify_publisher_support','verify_checkpoint_runtime','verify_startup_recovery','verify_new_save_loading'])
cmd=[sys.executable,'-X','utf8',str(root/'docs/codex/findings/overnight-20261024-v1/all_checks.py'),'--output',str(raw/'final-continuation-v2'),'--port','47749','--answered-onboarding','--tests',*sorted(names)]
(raw/'final-continuation-v2-launch.json').write_text(json.dumps({'command':cmd,'scope':'Serial continuation of retained failures plus affected latest-source coverage; not a single all-green whole invocation'},indent=2))
print('Serial suites',len(names),flush=True)
raise SystemExit(subprocess.call(cmd,cwd=root))
