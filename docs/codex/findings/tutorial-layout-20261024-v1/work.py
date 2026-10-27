"""Isolated tutorial layout/cold-world verification; no player profile access."""
from pathlib import Path
import argparse,importlib.util
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('tutorial_layout_checks',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-tutorial-layout-20261024-v1')
parser=argparse.ArgumentParser();parser.add_argument('mode',choices=['prior','native','cold']);parser.add_argument('--project',type=Path,required=True);parser.add_argument('--name',required=True)
args=parser.parse_args()
before=c.sim.source_hashes(c.ROOT/'patch-notes')
if args.mode=='prior':
    result=c.run(args.name,args.project,HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd',reuse=True)
else:
    frozen=c.sim.source_hashes(args.project)
    assert all(frozen.get(k)==v for k,v in before.items()),'Current source mismatch'
    assert all(k.endswith(('.uid','.import')) for k in frozen.keys()-before.keys())
    if args.mode=='native':
        result=c.run(args.name,args.project,args.project/'scripts/debug/verify_guided_tutorial_ui.gd',native=True,reuse=True)
    else:
        result=c.run(args.name,args.project,HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd',['--input='+str(c.RAW/'prior-editor/result.json')],reuse=True)
assert c.sim.source_hashes(c.ROOT/'patch-notes')==before,'Canonical source changed during check'
raise SystemExit(0 if result['pass'] else 1)
