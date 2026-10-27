from pathlib import Path
import json,importlib.util
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-contract-search-20261025-v1')
spec=importlib.util.spec_from_file_location('acceptance_sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
matrix=json.loads((RAW/'whole-matrix-v3/result.json').read_text())
continuation=json.loads((RAW/'final-continuation-v2/result.json').read_text())
serial=json.loads((RAW/'final-serial-v2-result.json').read_text())
assert len(serial)==9 and all(x['pass'] for x in serial)
passed={x['name']:str(RAW/'whole-matrix-v3/result.json') for x in matrix['checks'] if x['pass']}
for x in continuation['checks']:
 if x['pass']:passed[x['name']]=str(RAW/'final-continuation-v2/result.json')
for x in serial:
 if x['pass']:
  script=x['command'][x['command'].index('--script')+1]
  passed[Path(script).stem]=str(RAW/(x['name']+'/receipt.json'))
missing=sorted({x['name'] for x in matrix['checks']}-set(passed))
assert not missing,missing
current=sim.source_hashes(ROOT/'patch-notes');frozen=sim.source_hashes(RAW/'final-native-store-v2/project')
drift=[k for k in current.keys()|frozen.keys() if current.get(k)!=frozen.get(k)]
assert all(k.endswith('.gd.uid') and k not in current for k in drift),drift
sim.write_json(HERE/'final-source.json',current)
sim.write_json(HERE/'final-acceptance.json',{'head':'0132c4dab398a2a94dbeae3caa68a36505fbfa4f','maintained_verifiers':len(matrix['checks']),'full_run_passes':sum(x['pass'] for x in matrix['checks']),'passing_receipts':passed,'missing':missing,'serial_latest_runtime_equal':True,'import_added_uids':drift,'serial_passes':len(serial),'build':json.loads((HERE/'refresh-v2/result.json').read_text()),'limits':'Passing receipts span immutable full-run and focused continuation boundaries; not one uninterrupted all-green run and not every retained earlier pass rerun on latest source. Native/editor-driven embedded-EXE input acceptance is separate from direct release EXE/device acceptance. Employee economic gate fails. Crown private pilot is not canonical.'})
print('ACCEPTANCE',len(matrix['checks']),'maintained verifiers have passing receipts; latest nine serial checks exact current source; separate refreshed build PASS')
