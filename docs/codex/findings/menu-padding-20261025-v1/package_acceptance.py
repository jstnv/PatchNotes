from pathlib import Path
import importlib.util,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
spec=importlib.util.spec_from_file_location('padding_pack',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-menu-padding-20261025-v1')
pack=Path(json.loads((HERE/'result.json').read_text())['exe']['path'])
assert c.run('exe-native-padding-v2',None,ROOT/'patch-notes/scripts/debug/verify_menu_transition_padding.gd',native=True,pack=pack)['pass']
assert c.run('exe-prior-world',None,HERE.parent/'store-prerequisite-links-20261024-v1/world_probe.gd',['--input='+str(c.RAW/'actual-prior-exe-world/result.json')],pack=pack)['pass']
