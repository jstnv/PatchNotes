"""Select only old private-profile export dependencies identical to installed templates."""
from pathlib import Path
import hashlib,json,stat,subprocess,time
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
installed=Path(r'C:\Users\64jus\AppData\Roaming\Godot\export_templates\4.7.1.stable')
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as s:
        for b in iter(lambda:s.read(1024*1024),b''): h.update(b)
    return h.hexdigest()
def no_links(p):
    for item in (p,*p.parents):
        s=item.lstat()
        if stat.S_ISLNK(s.st_mode) or getattr(s,'st_reparse_tag',0) in [0xa0000003,0xa000000c]:raise ValueError('linked path')
found=json.loads((OUT/'template-candidates.json').read_text())
tracked=subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).decode().casefold().split('\0')
targets=[];skipped=[];originals={};cutoff=time.time()-48*3600
for i,relative in enumerate(found['skipped']):
    try:
        p=ROOT/relative;no_links(p)
        assert p.resolve().is_relative_to((ROOT/'docs').resolve())
        assert p.name=='4.7.1.stable' and p.parent.name=='export_templates' and p.parent.parent.name=='Godot' and p.parent.parent.parent.name=='APPDATA'
        assert '.codex-godot-temp' not in p.parts
        prefix=p.relative_to(ROOT).as_posix().casefold()+'/'
        assert not any(t.startswith(prefix) for t in tracked)
        rows=[]
        for f in sorted(p.iterdir()):
            no_links(f);before=f.stat()
            assert f.is_file() and before.st_mtime<cutoff
            if f.name=='version.txt':
                content=f.read_text().strip();assert content=='4.7.1.stable'
                digest=sha(f)
            else:
                source=installed/f.name
                assert f.suffix=='.exe' and f.name.startswith('windows_') and source.is_file() and before.st_size==source.stat().st_size
                if f.name not in originals: originals[f.name]={'path':str(source),'sha256':sha(source),'bytes':source.stat().st_size}
                digest=sha(f);assert digest==originals[f.name]['sha256']
            after=f.stat();assert (before.st_size,before.st_mtime_ns)==(after.st_size,after.st_mtime_ns)
            rows.append({'path':f.name,'bytes':after.st_size,'mtime_ns':after.st_mtime_ns,'sha256':digest})
        assert rows
        targets.append({'path':relative,'absolute_path':str(p.resolve()),'kind':'copied-godot-export-templates','files':rows,'logical_bytes':sum(r['bytes'] for r in rows)})
    except (OSError,ValueError,AssertionError) as exc:skipped.append({'path':relative,'reason':str(exc) or 'safety check did not match'})
    if (i+1)%5==0:print(f'Template hash check {i+1}/{len(found["skipped"])}',flush=True)
result={'status':'PREFLIGHT_ONLY','root':str(ROOT),'targets':targets,'skipped':skipped,'retained_original_templates':originals,'logical_bytes':sum(t['logical_bytes'] for t in targets)}
(OUT/'approved-template-preflight.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'accepted':len(targets),'skipped':len(skipped),'logical_bytes':result['logical_bytes']},indent=2))
