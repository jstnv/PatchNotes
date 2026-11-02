"""Run the existing acceptance pack beside a byte-identical release template.
The stock release disables command-line path overrides, so use its ordinary
adjacent-pack discovery in this separate test directory.
"""
from pathlib import Path
import hashlib,importlib.util,json,os,shutil,struct
out=Path(__file__).resolve().parent;root=out.parents[3];m=json.loads((out/'build-manifest.json').read_text(encoding='utf-8'));workspace=Path(m['workspace'])
spec=importlib.util.spec_from_file_location('support',root/'docs/codex/findings/export-queue-v3/export.py');support=importlib.util.module_from_spec(spec);spec.loader.exec_module(support);support.OUT=out
folder=workspace/'actual-template';folder.mkdir(exist_ok=False);exe=folder/'Patch Notes v0.03.exe'
shutil.copy2(Path(m['artifact'])/exe.name,exe);shutil.copy2(workspace/'template-acceptance.pck',exe.with_suffix('.pck'))
assert support.sha(exe)==m['artifacts'][exe.name]['sha256']
data=exe.with_suffix('.pck').read_bytes();*_,base,directory=struct.unpack_from('<6I2Q',data);count,=struct.unpack_from('<I',data,directory);pos=directory+4;entries={}
for _ in range(count):
    n,=struct.unpack_from('<I',data,pos);pos+=4;name='res://'+data[pos:pos+n].rstrip(b'\0').decode('utf-8').removeprefix('res://');pos+=n;offset,size=struct.unpack_from('<QQ',data,pos);pos+=16;md5=data[pos:pos+16];pos+=20
    payload=data[base+offset:base+offset+size];assert hashlib.md5(payload).digest()==md5;entries[name]=hashlib.sha256(payload).hexdigest()
original=json.loads((out/'pack-manifest-verified.json').read_text(encoding='utf-8'))['files']
changed=[name for name in original if original[name]['sha256']!=entries.get(name)]
assert set(changed).issubset({'res://project.binary','res://.godot/uid_cache.bin'}),changed
env=os.environ.copy();env.update(json.loads((out/'export-acceptance.json').read_text(encoding='utf-8'))[0]['profile'])
env['PN_CONTRACT_FIXTURE']=str(out/'current-release-pair.json');env['PN_CONTRACT_REPORT']=str(out/'template-continue-report.json');env['PN_CONTINUE_MODE']=''
result=support.run('template-adjacent-continue',[exe,'--audio-driver','Dummy','--quit-after','9000'],env,folder,timeout=150)
report=json.loads((out/'template-continue-report.json').read_text(encoding='utf-8'));assert not report['failures']
assert report['runtime']==json.loads((out/'final-native96/report.json').read_text(encoding='utf-8'))['runtime']
(out/'template-acceptance.json').write_text(json.dumps({'changed_original_entries':changed,'added_entries':sorted(set(entries)-set(original)),'all_original_runtime_payloads_match':True,'byte_identical_release_exe':True,'actual_exe':result,'report':report,'pointer_acceptance':'NOT RUN: Computer Use app approval timed out'},indent=2),encoding='utf-8',newline='\n')
print('ACTUAL RELEASE TEMPLATE CONTINUE PASS',report['continue_ms'],flush=True)
