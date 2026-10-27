"""Source-final serial continuation. Wait for the sole economic test worker."""
from pathlib import Path
import importlib.util,json,time
ROOT=Path(__file__).resolve().parents[4]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-contract-search-20261025-v1')
wage=Path('C:/Users/64jus/AppData/Local/Temp/pn-qa-employees-20261025-v1/quality-wages-v3/driver-result.json')
while not (wage.exists() and json.loads(wage.read_text()).get('complete')):time.sleep(5)
spec=importlib.util.spec_from_file_location('final_serial_checks',ROOT/'docs/codex/findings/store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.RAW=RAW
rows=[]
project=RAW/'final-native-store-v2/project'
def run(name,script,args=(),native=False,fresh=False):
    r=c.run(name,ROOT/'patch-notes' if fresh else project,ROOT/script,args,native=native,reuse=not fresh)
    rows.append({'name':name,**r});(RAW/'final-serial-v2-result.json').write_text(json.dumps(rows,indent=2))
    return r['pass']
if not run('final-native-store-v2','patch-notes/scripts/debug/verify_studio_mouse_navigation.gd',native=True,fresh=True):print('Store check failed; remaining checks retained independently',flush=True)
run('final-zero-work-v2','patch-notes/scripts/debug/verify_zero_work_release.gd')
run('final-parent-v2','patch-notes/scripts/debug/verify_feature_parents.gd')
if run('final-search-career-v2','patch-notes/scripts/debug/verify_contract_search.gd'):
    run('final-cold-search-v2','docs/codex/findings/contract-search-20261025-v1/cold_search_consumer.gd',['--input='+str(RAW/'final-search-career-v2/result.json')])
run('final-world-v2','docs/codex/findings/store-prerequisite-links-20261024-v1/world_probe.gd')
run('final-loader-v2','patch-notes/scripts/debug/verify_new_save_loading.gd',native=True)
run('final-transparent-store-v2','patch-notes/scripts/debug/verify_store_transparent_toolbar.gd',native=True)
run('final-employee-ui-v2','patch-notes/scripts/debug/verify_employee_ui.gd',native=True)
print('FINAL_SERIAL_V2',sum(r['pass'] for r in rows),'/',len(rows),flush=True)
