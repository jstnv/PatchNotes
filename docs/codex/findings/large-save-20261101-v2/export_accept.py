from pathlib import Path
import importlib.util,json,os,socket,subprocess,sys,tempfile,time
out=Path(__file__).resolve().parent;root=out.parents[3];sys.path.insert(0,str(root));from tools import simulate as sim
m=json.loads((out/'build-manifest.json').read_text(encoding='utf-8'));artifact=Path(m['artifact']);exe=artifact/'Patch Notes v0.03.exe'
spec=importlib.util.spec_from_file_location('support',root/'docs/codex/findings/export-queue-v3/export.py');support=importlib.util.module_from_spec(spec);spec.loader.exec_module(support);support.OUT=out
resume='--resume' in sys.argv
rows=json.loads((out/'export-acceptance.json').read_text(encoding='utf-8')) if resume else []
if resume:
    env=os.environ.copy();env.update(rows[0]['profile'])
else:
    profile=Path(tempfile.mkdtemp(prefix='export-accept-',dir=Path(m['workspace'])));env=support.isolated_export_environment(profile)
with socket.socket() as sock:sock.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(sock.getsockname()[1])
def run(name,script=None,fixture=None,native=False,mode=None,timeout=180):
    target=out/name;target.mkdir(exist_ok=False);e=env.copy();e['PN_CONTRACT_REPORT']=str(target/'report.json');e['PN_CONTINUE_MODE']=mode or ''
    if fixture:e['PN_CONTRACT_FIXTURE']=str(Path(fixture).resolve())
    argv=[exe,*([] if native else ['--headless']),'--audio-driver','Dummy']
    if script:argv=[Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe'),*argv[1:],'--main-pack',exe.with_suffix('.pck'),'--script',script]
    else:argv+=['--quit-after','90']
    start=time.monotonic();result=support.run(name,argv,e,artifact,timeout);result['seconds']=time.monotonic()-start
    if script:assert (target/'report.json').exists() or str(script).endswith('compatibility.gd'),'Missing test report'
    result['name']=name;rows.append(result);(out/'export-acceptance.json').write_text(json.dumps(rows,indent=2),encoding='utf-8',newline='\n')
    return target/'report.json'
probe=out/'pack-probe/report.json' if resume else run('pack-probe',out/'export_probe.gd')
info=json.loads(probe.read_text(encoding='utf-8'));expected=json.loads((out/'final-native96/report.json').read_text(encoding='utf-8'))['runtime']
assert info['runtime']==expected,('Editor/export source identity differs',info['runtime'],expected)
(artifact/'Licenses/Godot.txt').write_text(info['license'],encoding='utf-8',newline='\n')
(artifact/'Licenses/Godot-third-party.json').write_text(json.dumps({'licenses':info['license_info'],'copyright':info['copyright_info']},ensure_ascii=False,indent=2),encoding='utf-8',newline='\n')
if not resume:
    run('pack-old-compatibility',root/'docs/codex/findings/contract-latency-20261101-v1/compatibility.gd',out/'preceding-pair.json')
    run('exe-native-startup',native=True)
report=out/'pack-native96/report.json' if resume else run('pack-native96',out/'export_profile.gd',root/'docs/codex/findings/awards-presentation-20261101-v2/current-world/fixture.json',native=True)
r=json.loads(report.read_text(encoding='utf-8'));editor=json.loads((out/'final-native96/report.json').read_text(encoding='utf-8'))
assert not r['failures'] and r['player']==editor['player'] and r['world']==editor['world'],'Export/native state differs'
pair={'player':r['player'],'world':r['world']};fixture=out/'current-release-pair.json';fixture.write_text(json.dumps(pair,indent=2),encoding='utf-8',newline='\n')
run('pack-current-seed-v2',out/'cold_continue.gd',fixture,mode='seed')
run('pack-cold-continue-v2',out/'cold_continue.gd',fixture,native=True)
for entry in rows:
    report=out/entry['name']/'report.json'
    if report.exists():assert not json.loads(report.read_text(encoding='utf-8')).get('failures'),entry['name']
assert support.sha(exe)==m['artifacts'][exe.name]['sha256'] and support.sha(exe.with_suffix('.pck'))==m['artifacts'][exe.with_suffix('.pck').name]['sha256']
print('EXPORTED ACCEPTANCE PASS',len(rows),flush=True)
