from pathlib import Path
import argparse,importlib.util
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
spec=importlib.util.spec_from_file_location('studio_checks',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-studio-release-actions-20261025-v1')
c.RAW.mkdir(exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('--pack',type=Path);p.add_argument('--project',type=Path);p.add_argument('--script',type=Path);p.add_argument('--native',action='store_true');p.add_argument('--input',type=Path);a=p.parse_args()
script=(a.script or HERE/'launch_probe.gd').resolve()
args=['--input='+str(a.input)] if a.input else []
r=c.run(a.name,a.project or ROOT/'patch-notes',script,args,native=a.native,pack=a.pack,reuse=a.project is not None and a.pack is None)
raise SystemExit(0 if r['pass'] else 1)
