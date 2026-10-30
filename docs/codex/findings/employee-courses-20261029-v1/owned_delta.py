from pathlib import Path
import json,hashlib,difflib,subprocess,shutil
out=Path(__file__).resolve().parent;root=out.parents[3]
base=json.loads((out/'baseline.json').read_text())
source=json.loads((out/'source.json').read_text())
owned=[uri for uri,sha in source['runtime_files'].items() if base['runtime_files'].get(uri)!=sha]
diff=[]
for uri in owned:
    rel=uri.removeprefix('res://');before=out/'before'/rel;current=root/'patch-notes'/rel
    old=before.read_text(encoding='utf-8').splitlines(True) if before.exists() else []
    new=current.read_text(encoding='utf-8').splitlines(True)
    diff.extend(difflib.unified_diff(old,new,fromfile='before/'+rel,tofile='patch-notes/'+rel))
    retained=out/'after'/rel;retained.parent.mkdir(parents=True,exist_ok=True)
    if retained.exists():assert retained.read_bytes()==current.read_bytes(), 'Preserve retained final source'
    else:shutil.copyfile(current,retained)
(out/'owned-runtime-files.json').write_text(json.dumps(owned,indent=2))
(out/'review.diff').write_text(''.join(diff),encoding='utf-8')
paths=['patch-notes/'+uri.removeprefix('res://') for uri in owned]
result=subprocess.run(['git','-c','core.whitespace=cr-at-eol','diff','--check','--',*paths],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
(out/'owned-diff-check.txt').write_text(result.stdout or 'PASS: no tracked owned-file whitespace errors\n')
receipt={'runtime_identity':source['runtime_identity'],'baseline':base['runtime_identity'],'owned_runtime_count':len(owned),'diff_sha256':hashlib.sha256((out/'review.diff').read_bytes()).hexdigest(),'git_diff_check_exit':result.returncode}
(out/'owned-delta.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(receipt));raise SystemExit(result.returncode)
