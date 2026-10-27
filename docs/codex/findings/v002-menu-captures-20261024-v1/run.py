from pathlib import Path
import importlib.util, json, shutil
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('menu_capture_checks',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c = importlib.util.module_from_spec(spec); spec.loader.exec_module(c)
c.RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-v002-menu-captures-20261024-v1')
c.RAW.mkdir(exist_ok=False)
build = json.loads((HERE.parent/'build-v002-20261024-v1/result.json').read_text())
executable = Path(build['exe']['path'])
assert c.sim.sha(executable) == build['exe']['sha256']
receipt = c.run('native',None,HERE/'capture.gd',native=True,pack=executable)
assert receipt['pass']
captures = {}
for name in ['main-menu','how-to-play','studio-creation']:
    image = c.RAW/'native/capture'/(name+'.png')
    assert image.exists()
    shutil.copy2(image,HERE/image.name)
    captures[image.name] = c.sim.sha(image)
c.sim.write_json(HERE/'result.json',{'pass':True,'size':[1280,720],'exe_sha256':build['exe']['sha256'],
    'capture_sha256':captures,'receipt':receipt,'raw':str(c.RAW),'scope':'Native rendering from the exact shipped v0.02 embedded package, isolated empty profile; actual pointer navigation, no Studio creation/commit.'})
