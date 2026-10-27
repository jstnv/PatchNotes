from pathlib import Path
import importlib.util
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
spec=importlib.util.spec_from_file_location('padding_extra',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-menu-padding-20261025-v1')
project=c.RAW/'green/project'
probe=HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd'
for name,script,args,native in [
('native',HERE/'native_probe.gd',[],True),
('restore-prior-editor',probe,['--input=C:/Users/64jus/AppData/Local/Temp/pn-root-first-rosters-20261025-v1/current-world/result.json'],False),
('current-world',probe,[],False)]:
 result=c.run(name,project,script,args,native=native,reuse=True)
 assert result['pass'],name
old=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Root First/Patch Notes v0.02 - Root First.exe')
assert c.run('actual-prior-exe-world',None,probe,pack=old)['pass']
assert c.run('restore-prior-exe',project,probe,['--input='+str(c.RAW/'actual-prior-exe-world/result.json')],reuse=True)['pass']
