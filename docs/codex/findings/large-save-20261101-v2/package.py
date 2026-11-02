from pathlib import Path
import hashlib,json,sys,zipfile
out=Path(__file__).resolve().parent;root=out.parents[3];sys.path.insert(0,str(root));from tools import simulate as sim
m=json.loads((out/'build-manifest.json').read_text(encoding='utf-8'));artifact=Path(m['artifact'])
def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
assert json.loads((out/'template-acceptance.json').read_text(encoding='utf-8'))['report']['failures']==[]
assert sim.source_hashes(root/'patch-notes')==m['source_manifest'],'Canonical source changed since export'
assert sha(artifact/'Patch Notes v0.03.exe')==m['artifacts']['Patch Notes v0.03.exe']['sha256']
assert sha(artifact/'Patch Notes v0.03.pck')==m['artifacts']['Patch Notes v0.03.pck']['sha256']
files=sorted(p for p in artifact.rglob('*') if p.is_file() and p.name!='SHA256SUMS.txt')
(artifact/'SHA256SUMS.txt').write_text(''.join(sha(p)+'  '+p.relative_to(artifact).as_posix()+'\n' for p in files),encoding='utf-8',newline='\n')
files=sorted(p for p in artifact.rglob('*') if p.is_file());target=artifact.parent/(artifact.name+'.zip')
with zipfile.ZipFile(target,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in files:z.write(p,artifact.name+'/'+p.relative_to(artifact).as_posix())
with zipfile.ZipFile(target) as z:
    assert z.testzip() is None
    assert len(z.namelist())==len(files) and len(set(z.namelist()))==len(files)
    for p in files:assert hashlib.sha256(z.read(artifact.name+'/'+p.relative_to(artifact).as_posix())).hexdigest()==sha(p)
result={'zip':str(target),'bytes':target.stat().st_size,'sha256':sha(target),'crc_all_valid':True,'every_member_matches_original':True,'files':{p.relative_to(artifact).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in files},'canonical_source_unchanged':True}
(out/'delivery.json').write_text(json.dumps(result,indent=2),encoding='utf-8',newline='\n')
m['status']='export, PCK integrity, default EXE startup, packed-content flow/cold Continue, actual template instrumented Continue, ZIP integrity verified; native pointer acceptance NOT RUN'
m['artifacts']=result['files'];m['delivery']={k:result[k] for k in ['zip','bytes','sha256']}
(out/'build-manifest.json').write_text(json.dumps(m,indent=2),encoding='utf-8',newline='\n')
print(json.dumps({k:result[k] for k in ['zip','bytes','sha256','crc_all_valid','canonical_source_unchanged']}),flush=True)
