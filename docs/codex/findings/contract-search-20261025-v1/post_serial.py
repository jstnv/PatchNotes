from pathlib import Path
import importlib.util,json,time
root=Path(__file__).resolve().parents[4];raw=Path('C:/Users/64jus/AppData/Local/Temp/pn-contract-search-20261025-v1')
while True:
 f=raw/'final-continuation-v2/result.json'
 if f.exists() and 'canonical_unchanged' in json.loads(f.read_text()):break
 time.sleep(5)
spec=importlib.util.spec_from_file_location('post_checks',root/'docs/codex/findings/store-prerequisite-links-20261024-v1/checks.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.RAW=raw
results=[]
def run(name,script,args=(),native=False,reuse=True):
 project=raw/'native-current/project' if reuse else root/'patch-notes'
 r=c.run(name,project,root/script,args,native=native,reuse=reuse);results.append({'name':name,**r});(raw/'post-serial-result.json').write_text(json.dumps(results,indent=2));return r['pass']
if not run('native-current','patch-notes/scripts/debug/verify_contract_search_ui.gd',native=True,reuse=False):raise SystemExit(1)
run('native-employees-current','patch-notes/scripts/debug/verify_employee_ui.gd',native=True)
run('native-loader-current','patch-notes/scripts/debug/verify_new_save_loading.gd',native=True)
run('cold-search-current','docs/codex/findings/contract-search-20261025-v1/cold_search_consumer.gd',['--input='+str(raw/'final-continuation-v2/verifier-artifacts/verify_contract_search/result.json')])
if run('qa-career-current','patch-notes/scripts/debug/verify_qa_career.gd'):
 run('cold-qa-career-current','docs/codex/findings/qa-employees-20261025-v1/cold_career_consumer.gd',['--input='+str(raw/'qa-career-current/result.json')])
run('current-world-v3','docs/codex/findings/store-prerequisite-links-20261024-v1/world_probe.gd')
run('legacy-world-current','docs/codex/findings/contract-search-20261025-v1/cold_predecessor_consumer.gd',['--input='+str(raw/'genuine-old-payroll-world/result.json')])
run('parent-focus-current','patch-notes/scripts/debug/verify_feature_parents.gd')
raise SystemExit(not all(r['pass'] for r in results))
