from pathlib import Path
import importlib.util
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
spec=importlib.util.spec_from_file_location('extra_c',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-root-first-rosters-20261025-v1')
project=c.RAW/'final-matrix/project'
jobs=[('eight-genre-campaigns',HERE/'campaign_probe.gd',[]),
('restore-prior-editor-world',HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd',['--input=C:/Users/64jus/AppData/Local/Temp/pn-studio-release-actions-20261025-v1/current-world/result.json']),
('current-world',HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd',[])]
for name,script,args in jobs:
 result=c.run(name,project,script,args,reuse=True)
 assert result['pass'],name
