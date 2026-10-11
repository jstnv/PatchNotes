"""Reproduce M4 command/state tape on frozen, instrumented source copies.
Instrumentation counts/times journal validation only; authoritative files untouched.
"""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys,time,zipfile
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
GODOT=Path(r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
CASE=ROOT/'docs/codex/findings/card-presentation-v2/m4-pilot-3x10/fit.json.batch/warmup-000/pilot-0000'
label=sys.argv[1]
out=HERE/label
out.mkdir()
project=out/'project';project.mkdir()
for folder in ['scripts','scenes','data','resources','assets']:
    shutil.copytree(ROOT/'patch-notes'/folder,project/folder)
for p in (ROOT/'patch-notes').iterdir():
    if p.is_file(): shutil.copy2(p,project/p.name)
if label.startswith('baseline'):
    with zipfile.ZipFile(HERE/'before-source.zip') as z:
        for name in z.namelist():
            if name.startswith('patch-notes/'):
                p=project/Path(name).relative_to('patch-notes');p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(z.read(name))
hashes={p.relative_to(project).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in project.rglob('*') if p.is_file()}
(out/'source.json').write_text(json.dumps(hashes,indent=2))
ledger=project/'scripts/finance/studio_finance_ledger.gd'
text=ledger.read_text(encoding='utf-8')
needle='static func _is_valid(ledger: Dictionary) -> bool:\n'
assert text.count(needle)==1
text=text.replace(needle,'''static var profile_calls := 0
static var profile_us := 0
static func _is_valid(ledger: Dictionary) -> bool:
\tvar started := Time.get_ticks_usec()
\tvar result := _profile_validate(ledger)
\tprofile_calls += 1
\tprofile_us += Time.get_ticks_usec()-started
\treturn result

static func _profile_validate(ledger: Dictionary) -> bool:
''')
ledger.write_text(text,encoding='utf-8')
shutil.copy2(HERE/'profile.gd',project/'scripts/debug/profile_campaign.gd')
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    p=out/key;p.mkdir();env[key]=str(p)
env.update(PN_PROFILE_CASE=str(CASE/'case.variant.json'),PN_PROFILE_TAPE=str(CASE/'replay.tape.json'),PN_CARD_FRAME_OUTPUT=str(out/'profile.json'))
commands=[]
for name,args in [('import',['--editor','--import','--quit']),('profile',['--script','res://scripts/debug/profile_campaign.gd'])]:
    command=[str(GODOT),'--headless','--path',str(project),*args]
    start=time.monotonic()
    with (out/(name+'.log')).open('wb') as log:
        result=subprocess.run(command,env=env,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=240)
    errors=[s for s in (out/(name+'.log')).read_text(errors='replace').splitlines() if ('SCRIPT ERROR' in s or s.startswith('ERROR:')) and s!='ERROR: Failed to read the root certificate store.']
    commands.append({'command':command,'exit':result.returncode,'errors':errors,'seconds':time.monotonic()-start})
    (out/'commands.json').write_text(json.dumps(commands,indent=2))
    assert result.returncode==0 and not errors,commands[-1]
report=json.loads((out/'profile.json').read_text())
assert report['failures']==0
rows=[row for sample in report['samples'][1:] for row in sample['steps']]
summary={field:sum(row[field] for row in rows) for field in rows[0] if field.endswith('_us') or field.endswith('_calls')}
summary.update(sample_seconds=[r['elapsed_us']/1e6 for r in report['samples'][1:]],commands_per_sample=len(report['samples'][0]['steps']),failures=report['failures'])
(out/'summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps(summary,indent=2))
