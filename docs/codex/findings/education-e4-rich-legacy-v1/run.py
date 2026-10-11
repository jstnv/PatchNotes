from pathlib import Path
import hashlib,json,os,subprocess,re,uuid,zipfile
H=Path(__file__).resolve().parent
ROOT=H.parents[3];PROJECT=ROOT/'patch-notes';OLD=H.parent/'starwave-implementation-v1'
BASE=H.parent/'education-e4-compatibility-v1/probe.gd'
INPUT=OLD/'native-v3/before-starwave.checkpoint.1.json'
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def read(path):return json.loads(Path(path).read_text(encoding='utf8'))
def write(path,value):Path(path).write_text(json.dumps(value,indent=2)+'\n',encoding='utf8')
def provenance():
    e=read(INPUT);payload=json.loads(e['payload_utf8']);audit=read(OLD/'audit-summary-v3.json');pin=read(OLD/'source-pin-recovery-v3.json');manifest=read(OLD/'source-manifest-v3.json')
    assert sha(INPUT)=='01a7a395dc5c60543886a6840714d2c32de6cd83c6e28e48df579ce81010c202'
    assert hashlib.sha256(e['payload_utf8'].encode()).hexdigest()==e['payload_sha256']=='761448df55e1e7e99721d297a39a715d2115d8c10084d2e84631b745fb1d977c'
    assert payload['content_revision']=='c7f6f3165ea85f7afd5070042d053ce581f84338437640c3e4b6de787c1f5a5b'
    assert audit['passed'] and audit['checkpoint_sha256'][INPUT.name]==sha(INPUT)
    assert sha(OLD/'source-manifest-v3.json')==pin['source_manifest_sha256']
    assert sha(OLD/'audit-summary-v3.json')==pin['original_audit_summary_sha256']
    archive=OLD/pin['archive'];assert sha(archive)==pin['archive_sha256']
    with zipfile.ZipFile(archive) as z:
        assert set(z.namelist())==set(pin['archive_files'])
        for name in z.namelist():assert hashlib.sha256(z.read(name)).hexdigest()==pin['archive_files'][name]==manifest['files'][name]
    route=read(OLD/'native-v3/native-route.json');assert route['valid'] and not route['errors'] and not route['blockers'] and route['before_checkpoint']==payload
    paths=[INPUT,OLD/'native-v3/before-starwave.payload.json',OLD/'native-v3/native-route.json',OLD/'audit-summary-v3.json',OLD/'source-pin-recovery-v3.json',OLD/'source-manifest-v3.json',archive]
    return {'files':{str(p.relative_to(ROOT)):sha(p) for p in paths},'archive_members':len(pin['archive_files']),'revision':payload['content_revision']}
def source():
    paths=[PROJECT/'project.godot']+[p for p in (PROJECT/'scripts').rglob('*.gd') if 'debug' not in p.relative_to(PROJECT).parts]+list((PROJECT/'scenes').rglob('*.tscn'))+list((PROJECT/'data').rglob('*.json'))
    return {'runtime':{p.relative_to(PROJECT).as_posix():sha(p) for p in sorted(paths)},'drivers':{str(p.relative_to(ROOT)):sha(p) for p in [BASE,H/'probe.gd',H/'run.py',H/'PLAN.md']},'godot_sha256':sha(GODOT),'provenance_sha256':sha(H/'provenance.json')}
if __name__=='__main__':
    assert not (H/'source-before.json').exists(),'preserve existing attempt'
    write(H/'provenance.json',provenance());before=source();write(H/'source-before.json',before)
    profile=H/'profiles'/uuid.uuid4().hex[:10];saves=profile/'saves';saves.mkdir(parents=True);(saves/'checkpoint.1.json').write_bytes(INPUT.read_bytes())
    records=[]
    for mode in ['migrate','verify']:
        assert source()==before and provenance()==read(H/'provenance.json')
        inputs={str(p):sha(p) for p in saves.glob('checkpoint.*.json')}
        env=os.environ.copy();env.update(APPDATA=str(profile),LOCALAPPDATA=str(profile))
        cmd=[str(GODOT),'--headless','--path',str(PROJECT),'--script',str(H/'probe.gd'),'--',mode,str(saves),str(INPUT),str(H/(mode+'.result.json'))]
        write(H/(mode+'.before.json'),{'source':before,'inputs':inputs,'command':cmd,'profile':str(profile)})
        r=subprocess.run(cmd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
        text=r.stdout.decode('utf8',errors='replace');(H/(mode+'.log')).write_text(text,encoding='utf8')
        write(H/(mode+'.command.json'),{'command':cmd,'profile':str(profile),'exit_code':r.returncode})
        after=source();write(H/(mode+'.after.json'),after)
        errors=[s for s in text.splitlines() if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b|E4_ASSERT:',s,re.I) and s.strip()!='ERROR: Failed to read the root certificate store.']
        print(mode,r.returncode,text[-200:],flush=True)
        assert after==before and provenance()==read(H/'provenance.json'),'source/input drift'
        assert r.returncode==0 and not errors,(mode,errors)
        result=read(H/(mode+'.result.json'));assert result['passed'] and result['failures']==[]
        write(H/(mode+'.manifest.json'),{'source_sha256':sha(H/'source-before.json'),'inputs':inputs,'outputs':{str(p):sha(p) for p in saves.glob('checkpoint.*.json')},'artifacts':{ext:sha(H/(mode+'.'+ext)) for ext in ['before.json','after.json','command.json','log','result.json']}})
        records.append({'mode':mode,'checks':result['checks']})
    write(H/'source-after.json',source());write(H/'summary.json',{'passed':True,'processes':2,'native_checks':sum(i['checks'] for i in records),'records':records})
