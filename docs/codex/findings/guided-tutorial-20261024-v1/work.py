"""Focused native and exact predecessor checks; never use player profiles."""
from pathlib import Path
import argparse, importlib.util, json
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('guided_checks',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c = importlib.util.module_from_spec(spec); spec.loader.exec_module(c)
c.RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-guided-tutorial-20261024-v1')
parser = argparse.ArgumentParser()
parser.add_argument('mode',choices=['previous-pack','native','cold'])
parser.add_argument('--project',type=Path)
parser.add_argument('--name')
args = parser.parse_args()
results = []
if args.mode == 'previous-pack':
    build = json.loads((HERE.parent/'build-v002-20261024-v1/result.json').read_text())
    executable = Path(build['exe']['path'])
    assert c.sim.sha(executable) == build['exe']['sha256']
    results.append(c.run('previous-pack',None,HERE.parent/'employee-button-20261024-v1/probe.gd',
        ['--prior','--input=C:/Users/64jus/AppData/Local/Temp/pn-build-v002-20261024-v1/editor-world/result.json'],pack=executable))
else:
    assert args.project and args.name
    before = c.sim.source_hashes(c.ROOT/'patch-notes')
    assert c.sim.source_hashes(args.project) == before, 'Must use current immutable snapshot'
    if args.mode == 'native':
        results.append(c.run(args.name,args.project,args.project/'scripts/debug/verify_guided_tutorial_ui.gd',native=True,reuse=True))
    else:
        for previous,fixture in [('editor',Path('C:/Users/64jus/AppData/Local/Temp/pn-build-v002-20261024-v1/editor-world/result.json')),
                                 ('v002',c.RAW/'previous-pack/result.json')]:
            results.append(c.run(args.name+'-'+previous,args.project,HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd',
                ['--input='+str(fixture)],reuse=True))
    assert c.sim.source_hashes(c.ROOT/'patch-notes') == before, 'Canonical drift'
raise SystemExit(0 if all(row['pass'] for row in results) else 1)
