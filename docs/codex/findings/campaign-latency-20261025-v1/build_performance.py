"""Preserve v0.03; make a separate source-pinned performance package."""
from pathlib import Path
import importlib.util
import json
import shutil
import subprocess
import sys
import zipfile

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
OUT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\Performance\v003p')
DELIVERY=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\Builds\Patch Notes v0.03 - Performance')
NAME='Patch Notes v0.03 - Performance'
OUT.mkdir(exist_ok=False)
DELIVERY.mkdir(exist_ok=False)

def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    value=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value

sim=module('latency_sim',ROOT/'tools/simulate.py')
export=module('latency_export',ROOT/'docs/codex/findings/export-queue-v3/export.py')
before=sim.source_hashes(ROOT/'patch-notes')
fixture=json.loads((HERE/'long-final.result.json').read_text())
assert fixture['ok'] and int(fixture['player']['run']['completed_run_cycles'])==96
editor_identity=fixture['world']['source_identity']
export.OUT=OUT
export.ROOT=ROOT/'patch-notes'
original_run=export.run
overrides={}

def build_run(name,argv,env,cwd,timeout=180):
    args=list(argv)
    if name=='clean-import':
        project=Path(args[args.index('--path')+1])
        config=project/'project.godot'
        config.write_text(config.read_text().replace('config/name="Patch Notes Demo"','config/name="Patch Notes"'),encoding='utf-8')
        presets=project/'export_presets.cfg'
        text=presets.read_text().replace('binary_format/embed_pck=false','binary_format/embed_pck=true')
        text=text.replace('debug/export_console_wrapper=1','debug/export_console_wrapper=0')
        text=text.replace('application/file_version=""','application/file_version="0.0.3.0"')
        text=text.replace('application/product_version=""','application/product_version="0.0.3.0"')
        presets.write_text(text,encoding='utf-8')
        world=project/'scripts/market/rival_world_checkpoint.gd'
        source=world.read_text()
        assert source.count('var source_ok: bool = ')==1
        world.write_text(source.replace('var source_ok: bool = ','var source_ok: bool = predecessor_source=="'+editor_identity+'" or '),encoding='utf-8')
        for rel in ['project.godot','export_presets.cfg','scripts/market/rival_world_checkpoint.gd']:
            overrides[rel]={'canonical_sha256':sim.sha(ROOT/'patch-notes'/rel),'build_sha256':sim.sha(project/rel)}
    if '--export-release' in args:
        args[args.index('--export-release')+1]='Patch Notes v0.03'
        args[-1]=Path(args[-1]).parent/(NAME+'.exe')
    return original_run(name,args,env,cwd,timeout)

export.run=build_run
sys.argv=[str(__file__)]
export.main()
manifest=json.loads((OUT/'build-manifest.json').read_text())
workspace=Path(manifest['workspace'])
project=workspace/'source'
exe=workspace/'demo'/(NAME+'.exe')
env=dict(__import__('os').environ)
env.update(json.loads((OUT/'export-release.command.json').read_text())['profile'])
pack=OUT/'validation.pck'
original_run('validation-pack',[export.GODOT,'--headless','--text-driver','Dummy','--path',project,'--export-pack','Patch Notes v0.03',pack],env,workspace)
inspection=ROOT/'docs/codex/findings/export-queue-v3/inspect.py'
text=inspection.read_text().replace('OUT=Path(__file__).resolve().parent','OUT=Path('+repr(str(OUT))+')')
text=text.replace("path=Path(m['workspace'])/'demo/Patch Notes Demo.pck'",'path=Path('+repr(str(pack))+')')
exec(compile(text,str(inspection),'exec'),{'__file__':str(inspection)})
probe=ROOT/'docs/codex/findings/contract-search-20261025-v1/v003/package_probe.gd'
for label in ['long-final','compiled-v003']:
    target=OUT/(label+'-package.json')
    original_run(label+'-package',[export.GODOT,'--headless','--main-pack',exe,'--script',probe,'--',OUT/'pack-manifest-verified.json',HERE/(label+'.result.json'),target],sim.isolated_environment(OUT/label),workspace)

for label,flags in [('headless-startup',['--headless']),('native-startup',[])]:
    original_run(label,[exe,*flags,'--quit-after','30'],sim.isolated_environment(OUT/label),workspace,90)
pe=module('latency_pe',ROOT/'docs/codex/findings/logo-icon-20261024-v1/inspect_icon.py')
pe.verify(exe,ROOT/'patch-notes/assets/branding/patch_notes_paper.ico',OUT/'pe-icons.json')
profile=sim.isolated_environment(OUT/'played')
profile['PN_CARD_FRAME_OUTPUT']=str(OUT/'embedded-campaign.json')
original_run('embedded-campaign',[export.GODOT,'--headless','--main-pack',exe,'--script',ROOT/'patch-notes/scripts/debug/profile_campaign_actions.gd'],profile,workspace,180)
played=json.loads((OUT/'embedded-campaign.json').read_text())
old=json.loads((HERE/'compiled-v003.result.json').read_text())
assert played['ok'] and played['state']==old['state'] and played['player']==old['player']
assert {k:v for k,v in played['world'].items() if k!='source_identity'}=={k:v for k,v in old['world'].items() if k!='source_identity'}
for path in exe.parent.iterdir():
    if path.is_file():shutil.copy2(path,DELIVERY/path.name)
assert not list(DELIVERY.glob('*.pck')) and not list(DELIVERY.glob('*.console.exe'))
(DELIVERY/'README.txt').write_text('Patch Notes v0.03 - Performance\nWindows 64-bit development build\n\nRun '+NAME+'.exe. Game data is embedded.\n\nReduces repeated Store refreshes, finance reconstruction and checkpoint validation. Previous v0.03 saves remain supported; application save/settings folder is unchanged. Card rules, scoring, research costs and the Studio-only Continue boundary are unchanged.\n\nEmployees remain unavailable under the existing economic gate. Crown paid Briefs remain private research. Automated checks do not establish final balance, audible/device acceptance or release readiness.\n',encoding='utf-8')
archive=DELIVERY.parent/(NAME+'.zip')
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in sorted(DELIVERY.iterdir()):z.write(path,NAME+'/'+path.name)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert __import__('hashlib').sha256(z.read(NAME+'/'+exe.name)).hexdigest()==sim.sha(exe)
after=sim.source_hashes(ROOT/'patch-notes')
drift=[k for k in before.keys()|after.keys() if before.get(k)!=after.get(k)]
assert all(k.startswith('scripts/debug/') or k.endswith(('.import','.uid')) for k in drift),drift
assert all(sim.sha(ROOT/'patch-notes'/p)==h for p,h in manifest['included'].items())
manifest['build_only_overrides']=overrides
sim.write_json(OUT/'build-manifest.json',manifest)
result={'pass':True,'version':'0.03','head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'exe':{'path':str(DELIVERY/exe.name),'sha256':sim.sha(exe),'bytes':exe.stat().st_size},
    'zip':{'path':str(archive),'sha256':sim.sha(archive),'bytes':archive.stat().st_size},
    'editor_package':json.loads((OUT/'long-final-package.json').read_text()),
    'old_v003_package':json.loads((OUT/'compiled-v003-package.json').read_text()),
    'embedded_four_game_exact':True,'included_inputs_unchanged':True,'raw':str(OUT),'release_ready':False}
sim.write_json(HERE/'package.json',result)
sim.write_json(HERE/'final-source.json',after)
for name in ['build-manifest.json','pack-manifest-verified.json','pe-icons.json','clean-import.command.json','export-release.command.json','validation-pack.command.json','headless-startup.command.json','native-startup.command.json','embedded-campaign.command.json']:
    shutil.copy2(OUT/name,HERE/name)
print(json.dumps(result,indent=2),flush=True)
