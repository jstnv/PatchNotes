from pathlib import Path
import importlib.util,os
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def module(name,path):
 spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
c=module('native_c',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
gate=module('native_gate',ROOT/'tools/release_gate.py')
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-root-first-rosters-20261025-v1')
out=c.RAW/'native-hud-wrapper-v3';out.mkdir(exist_ok=False)
wrapper,metadata=gate.checkpoint_wrapper(ROOT/'patch-notes/scripts/debug/verify_store_hud.gd',out)
text=wrapper.read_text(encoding='utf8').replace('47733','47739')
marker='func _initialize() -> void:\n'
assert text.count(marker)==1
text=text.replace(marker,marker+'\tOS.set_environment("PN_STORE_CAPTURE", "'+str(c.RAW/'native-hud-captures-v2').replace('\\','/')+'")\n\tassert(preload("res://scripts/tutorial/onboarding_preferences.gd").new().answer(true))\n')
wrapper.write_text(text,encoding='utf8')
captures=c.RAW/'native-hud-captures-v2';captures.mkdir()
os.environ['PN_STORE_CAPTURE']=str(captures)
result=c.run('native-store-hud-v2',c.RAW/'final-matrix/project',wrapper,native=True,reuse=True)
assert result['pass']
