"""Serial native E4 probes; source freeze must be confirmed before invocation."""
from pathlib import Path
import os, json, subprocess, hashlib, uuid, re

H = Path(__file__).resolve().parent
OLD = H.parent / 'education-legacy-fixtures-v1'
PROJECT = H.parents[3] / 'patch-notes'
GODOT = Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
FIXTURES = [f'v{v}-{t}' for v in (3, 4, 5) for t in ('college_dropout', 'graduate')] + ['v5-ordinary']
CASES = ['unsupported_revision', 'checksum', 'numeric_cash', 'extra_education', 'old_version6', 'cash_discontinuity', 'retroactive_refund']

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def write(p, value): Path(p).write_text(json.dumps(value, indent=2) + '\n', encoding='utf8')
def capture():
    files = [PROJECT/'project.godot'] + [p for p in (PROJECT/'scripts').rglob('*.gd') if 'debug' not in p.relative_to(PROJECT).parts] + list((PROJECT/'data').rglob('*.json')) + list((PROJECT/'scenes').rglob('*.tscn'))
    return {'files': {p.relative_to(PROJECT).as_posix(): sha(p) for p in sorted(files)},
            'drivers': {n: sha(H/n) for n in ['probe.gd', 'run.py', 'PLAN.md']}, 'godot': sha(GODOT),
            'old_source': sha(OLD/'source-before.json'),
            'fixtures': {n: {ext: sha(OLD/(n+'.'+ext)) for ext in ['checkpoint.json', 'payload.json', 'manifest.json']} for n in FIXTURES}}
def original_valid():
    for name in FIXTURES:
        m=json.loads((OLD/(name+'.manifest.json')).read_text())
        for ext, digest in m['files'].items(): assert sha(OLD/(name+'.'+ext)) == digest, (name, ext)
def validate_log(text):
    return [line for line in text.splitlines() if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b|E4_ASSERT:', line, re.I)
            and line.strip() != 'ERROR: Failed to read the root certificate store.']
def execute(name, mode, path, fixture, profile):
    assert not (H/(name+'.result.json')).exists(), ('preserve completed/failed artifact', name)
    original_valid(); assert capture()==SOURCE, 'source drift before '+name
    inputs={str(p):sha(p) for p in sorted(path.rglob('checkpoint.*.json'))} if path.is_dir() else {str(path):sha(path)}
    inputs[str(fixture)]=sha(fixture)
    command=[str(GODOT),'--headless','--path',str(PROJECT),'--script',str(H/'probe.gd'),'--',mode,str(path),str(fixture),str(H/(name+'.result.json'))]
    env=os.environ.copy();env.update(APPDATA=str(profile),LOCALAPPDATA=str(profile))
    write(H/(name+'.before.json'), {'source':SOURCE,'inputs':inputs,'command':command,'profile':str(profile)})
    result=subprocess.run(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
    log=result.stdout.decode('utf8',errors='replace');(H/(name+'.log')).write_text(log,encoding='utf8')
    write(H/(name+'.command.json'),{'command':command,'profile':str(profile),'exit_code':result.returncode})
    after=capture();write(H/(name+'.after.json'),after)
    errors=validate_log(log)
    print(name,result.returncode,log[-180:],flush=True)
    assert after==SOURCE,'source drift during '+name
    original_valid()
    assert result.returncode==0 and not errors,(name,errors)
    report=json.loads((H/(name+'.result.json')).read_text());assert report['passed'] and not report['failures'],name
    outputs={str(p):sha(p) for p in sorted(path.rglob('checkpoint.*.json'))} if path.is_dir() else {}
    write(H/(name+'.manifest.json'),{'source_sha256':sha(H/'source-before.json'),'inputs':inputs,'outputs':outputs,
        'artifacts':{ext:sha(H/(name+'.'+ext)) for ext in ['before.json','after.json','command.json','log','result.json']}})
    return {'name':name,'mode':mode,'checks':report['checks']}
def envelope(payload):
    raw=json.dumps(payload,separators=(',',':'),ensure_ascii=False)
    return json.dumps({'format':'patch-notes-studio-checkpoint','schema_version':'1','payload_utf8':raw,'payload_sha256':hashlib.sha256(raw.encode()).hexdigest()},separators=(',',':'),ensure_ascii=False).encode()

if __name__=='__main__':
    assert not (H/'source-before.json').exists(),'preserve prior attempt; use explicit new attempt directory'
    original_valid();SOURCE=capture();write(H/'source-before.json',SOURCE)
    records=[]
    for name in FIXTURES:
        profile=H/'profiles'/(name+'-'+uuid.uuid4().hex[:8]);saves=profile/'saves';saves.mkdir(parents=True)
        fixture=OLD/(name+'.checkpoint.json');(saves/'checkpoint.1.json').write_bytes(fixture.read_bytes())
        records.append(execute(name+'-migrate','migrate',saves,fixture,profile))
        records.append(execute(name+'-verify','verify',saves,fixture,profile))
    profile=H/'profiles'/('rejections-'+uuid.uuid4().hex[:8]);profile.mkdir(parents=True)
    fixture=OLD/'v5-graduate.checkpoint.json'
    original=json.loads((OLD/'v5-graduate.payload.json').read_text())
    for case in CASES:
        path=profile/case;path.mkdir();(path/'checkpoint.1.json').write_bytes(fixture.read_bytes())
        payload=json.loads(json.dumps(original));payload['sequence']='2'
        if case=='unsupported_revision':payload['content_revision']='unsupported-e4-negative-control'
        elif case=='numeric_cash':payload['run']['cash_cents']=570000
        elif case=='extra_education':payload['run']['studio_finance']['education']={}
        elif case=='old_version6':payload['run']['studio_traits']['version']='6'
        elif case=='cash_discontinuity':payload['run']['studio_finance']['actions'][0]['cash_before']='550001'
        elif case=='retroactive_refund':payload['run']['studio_traits']['refunded_points']='6'
        raw=envelope(payload)
        if case=='checksum':
            outer=json.loads(raw);outer['payload_sha256']='0'*64;raw=json.dumps(outer,separators=(',',':')).encode()
        (path/'checkpoint.2.json').write_bytes(raw)
    recovery=profile/'unsupported-valid-copy';recovery.mkdir();(recovery/'checkpoint.1.json').write_bytes(fixture.read_bytes())
    records.append(execute('rejections','reject',profile,fixture,profile))
    records.append(execute('recovery-cold','verify_recovery',H/'rejections.result.json',fixture,profile))
    assert capture()==SOURCE;write(H/'source-after.json',SOURCE)
    write(H/'summary.json',{'passed':True,'processes':len(records),'native_checks':sum(r['checks'] for r in records),'records':records})
    print('E4 native compatibility probe completed',len(records),'processes',flush=True)
