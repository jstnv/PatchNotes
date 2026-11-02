"""Actual release template, software-level Continue test. No OS input or player saves.

An isolated pack changes only the boot scene and adds a test runner. Shipped
runtime scripts/data are hash-matched to the original pack. The unmodified
EXE/shipped-pack startup is tested separately by export_accept.py.
"""
from pathlib import Path
import importlib.util,json,os,re,shutil,struct,subprocess
out=Path(__file__).resolve().parent;root=out.parents[3];m=json.loads((out/'build-manifest.json').read_text(encoding='utf-8'));workspace=Path(m['workspace'])
spec=importlib.util.spec_from_file_location('support',root/'docs/codex/findings/export-queue-v3/export.py');support=importlib.util.module_from_spec(spec);spec.loader.exec_module(support);support.OUT=out
godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
project=workspace/'template-acceptance';shutil.copytree(Path(m['project']),project)
config=project/'project.godot';text=config.read_text(encoding='utf-8');text,n=re.subn(r'^run/main_scene=.*$', 'run/main_scene="res://acceptance_boot.tscn"',text,flags=re.M);assert n==1;config.write_text(text,encoding='utf-8',newline='\n')
script=(out/'cold_continue.gd').read_text(encoding='utf-8').replace('extends SceneTree','extends Node').replace('func _initialize()','func _ready()').replace('await process_frame','await get_tree().process_frame').replace('root.','get_tree().root.').replace(';quit(', ';get_tree().quit(')
(project/'acceptance_runner.gd').write_text(script,encoding='utf-8',newline='\n')
(project/'acceptance_boot.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://acceptance_runner.gd" id="1"]\n\n[node name="AcceptanceBootstrap" type="Node"]\nscript = ExtResource("1")\n',encoding='utf-8',newline='\n')
profile=workspace/'template-export-profile';profile.mkdir();env=support.isolated_export_environment(profile)
support.run('template-import',[godot,'--headless','--path',project,'--editor','--import','--quit'],env,profile,timeout=180)
pack=workspace/'template-acceptance.pck'
support.run('template-pack',[godot,'--headless','--text-driver','Dummy','--path',project,'--export-pack',m['export_preset'],pack],env,profile,timeout=180)
def entries(path):
    import hashlib
    data=path.read_bytes();*_,base,directory=struct.unpack_from('<6I2Q',data);count,=struct.unpack_from('<I',data,directory);pos=directory+4;result={}
    for _ in range(count):
        n,=struct.unpack_from('<I',data,pos);pos+=4;name=data[pos:pos+n].rstrip(b'\0').decode('utf-8');pos+=n;offset,size=struct.unpack_from('<QQ',data,pos);pos+=16;md5=data[pos:pos+16];pos+=20
        payload=data[base+offset:base+offset+size];assert hashlib.md5(payload).digest()==md5;result[name]=hashlib.sha256(payload).hexdigest()
    return result
original=entries(Path(m['artifact'])/'Patch Notes v0.03.pck');instrumented=entries(pack)
changed=[name for name in original if original[name]!=instrumented.get(name)]
assert changed==['project.binary'] or set(changed).issubset({'project.binary','.godot/uid_cache.bin'}),changed
env=os.environ.copy();env.update(json.loads((out/'export-acceptance.json').read_text(encoding='utf-8'))[0]['profile'])
env['PN_CONTRACT_FIXTURE']=str(out/'current-release-pair.json');env['PN_CONTRACT_REPORT']=str(out/'template-continue-report.json');env['PN_CONTINUE_MODE']=''
result=support.run('template-cold-continue',[Path(m['artifact'])/'Patch Notes v0.03.exe','--main-pack',pack,'--audio-driver','Dummy','--quit-after','9000'],env,Path(m['artifact']),timeout=150)
report=json.loads((out/'template-continue-report.json').read_text(encoding='utf-8'));assert not report['failures']
assert report['runtime']==json.loads((out/'final-native96/report.json').read_text(encoding='utf-8'))['runtime']
(out/'template-acceptance.json').write_text(json.dumps({'changed_original_entries':changed,'added_entries':sorted(set(instrumented)-set(original)),'all_original_runtime_payloads_match':True,'actual_exe':result,'report':report,'pointer_acceptance':'NOT RUN: Computer Use app approval timed out'},indent=2),encoding='utf-8',newline='\n')
print('ACTUAL RELEASE TEMPLATE CONTINUE PASS',report['continue_ms'],flush=True)
