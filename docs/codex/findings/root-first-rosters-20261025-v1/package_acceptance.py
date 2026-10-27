from pathlib import Path
import importlib.util,json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
spec=importlib.util.spec_from_file_location('pack_c',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-root-first-rosters-20261025-v1')
pack=Path(json.loads((HERE/'result.json').read_text())['exe']['path'])
old_pack=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Studio Fix/Patch Notes v0.02 - Studio Fix.exe')
world_probe=HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd'
jobs=[('exe-root-rosters',pack,ROOT/'patch-notes/scripts/debug/verify_root_first_rosters.gd',['--input='+str(ROOT/'patch-notes/scripts/debug/fixtures/studio_specialties_v3.json')],False),
('exe-old-rosters',pack,HERE/'old_rosters_probe.gd',['--input='+str(c.RAW/'prior-exe-rosters/result.json')],False),
('old-exe-world',old_pack,world_probe,[],False),
('exe-old-world',pack,world_probe,['--input='+str(c.RAW/'old-exe-world/result.json')],False),
('exe-current-world',pack,world_probe,['--input='+str(c.RAW/'current-world/result.json')],False),
('exe-overlay-native',pack,ROOT/'patch-notes/scripts/debug/verify_store_transparent_toolbar.gd',[],True)]
for name,selected,script,args,native in jobs:
 result=c.run(name,None,script,args,native=native,pack=selected)
 assert result['pass'],name
