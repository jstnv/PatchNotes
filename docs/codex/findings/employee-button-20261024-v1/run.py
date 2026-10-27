from pathlib import Path
import importlib.util
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('employee_checks', HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c = importlib.util.module_from_spec(spec); spec.loader.exec_module(c)
previous_root = c.RAW
c.RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-employee-button-20261024-v2')
c.RAW.mkdir(exist_ok=False)
results = [c.run('previous', previous_root/'keyboard-green/project', HERE/'probe.gd',
    ['--prior','--input='+str(previous_root/'previous-editor/result.json')],reuse=True)]
assert results[0]['pass']
results.append(c.run('final',c.ROOT/'patch-notes',HERE/'probe.gd',['--input='+str(c.RAW/'previous/result.json')]))
source = c.sim.source_hashes(c.ROOT/'patch-notes')
assert source == c.sim.source_hashes(c.RAW/'final/project')
c.sim.write_json(HERE/'result.json', {'pass':all(row['pass'] for row in results),'receipts':results,'canonical_unchanged':True,'raw':str(c.RAW)})
c.sim.write_json(HERE/'source.json',source)
raise SystemExit(0 if all(row['pass'] for row in results) else 1)
