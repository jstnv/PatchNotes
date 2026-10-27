from pathlib import Path
import argparse,importlib.util
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
spec=importlib.util.spec_from_file_location('padding_c',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-menu-padding-20261025-v1')
c.RAW.mkdir(exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('name');p.add_argument('--project',type=Path,required=True);p.add_argument('--script',type=Path,required=True);p.add_argument('--native',action='store_true');p.add_argument('--input',type=Path);a=p.parse_args()
result=c.run(a.name,a.project,a.script.resolve(),['--input='+str(a.input)] if a.input else [],native=a.native,reuse=True)
raise SystemExit(0 if result['pass'] else 1)
