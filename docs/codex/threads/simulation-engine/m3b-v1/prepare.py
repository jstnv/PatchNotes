from pathlib import Path
import hashlib,json,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
files=list((ROOT/'patch-notes/scripts').rglob('*.gd'))+list((ROOT/'patch-notes/data').rglob('*.json'))+[ROOT/'docs/codex/TODO.md',ROOT/'docs/codex/CURRENT_STATE.md']
with zipfile.ZipFile(HERE/'before-source.zip','x',zipfile.ZIP_DEFLATED) as z:
    for p in files:z.write(p,p.relative_to(ROOT))
(HERE/'before-hashes.json').write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files},indent=2),encoding='utf-8')
for args,name in [(['status','--short'],'status-before.txt'),(['diff','--','patch-notes/scripts'],'diff-before.patch'),(['rev-parse','HEAD'],'head.txt')]:
    (HERE/name).write_bytes(subprocess.run(['git',*args],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,check=True).stdout)
original=(ROOT/'patch-notes/scripts/phases/contract_phase.gd').read_text(encoding='utf-8')
(HERE/'contract_phase_oracle.gd').write_text(original.split('\n',1)[1],encoding='utf-8')
print('Archived',len(files),'files')
