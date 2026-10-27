"""Read-only preflight for the explicitly approved old generated-cache cleanup."""
from pathlib import Path
import datetime as dt, hashlib, importlib.util, json, os, re, stat, subprocess, time

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
assert ROOT==Path(r'C:\Users\64jus\OneDrive\Documents\GitHub\PatchNotes')
DOCS=ROOT/'docs'
def dump(name,value): (OUT/name).write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda:stream.read(1024*1024),b''): h.update(block)
    return h.hexdigest()
def no_links(path):
    for item in (path,*path.parents):
        s=item.lstat()
        if stat.S_ISLNK(s.st_mode) or getattr(s,'st_reparse_tag',0) in (0xa0000003,0xa000000c):
            raise ValueError('link or junction: '+str(item))
def tree(path):
    files=[]
    for directory,dirs,names in os.walk(path,followlinks=False,onerror=lambda e:(_ for _ in ()).throw(e)):
        for name in dirs+names: no_links(Path(directory)/name)
        for name in names:
            p=Path(directory)/name;s=p.stat()
            files.append({'path':str(p.relative_to(path)),'bytes':s.st_size,'mtime_ns':s.st_mtime_ns})
    return sorted(files,key=lambda f:f['path'])

tracked=subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).decode('utf-8').split('\0')
tracked=[p.casefold() for p in tracked if p]
status=subprocess.check_output(['git','status','--porcelain=v1','--untracked-files=no'],cwd=ROOT).decode('utf-8')
(OUT/'tracked-status-before.txt').write_text(status,encoding='utf-8')
spec=importlib.util.spec_from_file_location('cleanup_sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
dump('canonical-source-before.json',sim.source_hashes(ROOT/'patch-notes'))
proposal=json.loads((OUT/'cache-candidates.json').read_text())
accepted=[];skipped=[];started=time.monotonic()
for i,row in enumerate(proposal['candidates']):
    try:
        rel=Path(row['path']);p=ROOT/rel
        if rel.is_absolute() or '..' in rel.parts or rel.parts[0]!='docs' or p.name!='.godot' or '.codex-godot-temp' in rel.parts: raise ValueError('outside allowlist')
        no_links(p)
        if not p.resolve().is_relative_to(DOCS.resolve()): raise ValueError('resolved outside docs')
        prefix=p.relative_to(ROOT).as_posix().casefold()+'/'
        if any(t.startswith(prefix) for t in tracked): raise ValueError('tracked descendant')
        project=p.parent
        if not (project/'project.godot').is_file() or not (project/'scripts').is_dir(): raise ValueError('missing regenerable project')
        files=tree(p)
        if sum(f['bytes'] for f in files)!=row['logical_bytes'] or len(files)!=row['files'] or max((f['mtime_ns'] for f in files),default=0)!=row['latest_mtime_ns']: raise ValueError('changed since proposal')
        source_checks=0
        # Import metadata next to each raw asset records its original source_file.
        for base in [project/'assets',project/'resources']:
            if not base.exists(): continue
            for d,dirs,names in os.walk(base,followlinks=False):
                dirs[:]=[n for n in dirs if not n.startswith('.')]
                for name in names:
                    if not name.endswith('.import'): continue
                    metadata=(Path(d)/name).read_text(encoding='utf-8')
                    match=re.search(r'^source_file="res://([^"\r\n]+)"',metadata,re.M)
                    if match:
                        raw=project/match[1]
                        no_links(raw)
                        if not raw.resolve().is_relative_to(project.resolve()) or not raw.is_file(): raise ValueError('missing original import source')
                        source_checks+=1
        accepted.append({'path':str(rel),'absolute_path':str(p.resolve()),'kind':'godot-import-cache','logical_bytes':sum(f['bytes'] for f in files),'files':files,'raw_import_sources_checked':source_checks})
    except (OSError,ValueError) as exc: skipped.append({'path':row['path'],'reason':str(exc)})
    if (i+1)%150==0: print(f'Preflight {i+1}/{len(proposal["candidates"])}',flush=True)
result={'status':'PREFLIGHT_ONLY','root':str(ROOT),'created_utc':dt.datetime.now(dt.timezone.utc).isoformat(),'elapsed_seconds':time.monotonic()-started,'targets':accepted,'skipped':skipped,'logical_bytes':sum(t['logical_bytes'] for t in accepted)}
dump('approved-cache-preflight.json',result)
print(json.dumps({'accepted':len(accepted),'skipped':len(skipped),'logical_bytes':result['logical_bytes'],'elapsed_seconds':result['elapsed_seconds']},indent=2))
