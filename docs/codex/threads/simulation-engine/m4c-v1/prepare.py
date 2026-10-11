from pathlib import Path
import hashlib,json,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
files=list((ROOT/'patch-notes/scripts').rglob('*.gd'))+list((ROOT/'patch-notes/data').rglob('*.json'))+list((ROOT/'tools').rglob('*.py'))+[ROOT/'docs/codex/TODO.md',ROOT/'docs/codex/CURRENT_STATE.md',ROOT/'docs/codex/README.md']
with zipfile.ZipFile(HERE/'before-source.zip','x',zipfile.ZIP_DEFLATED) as archive:
    for path in files: archive.write(path,path.relative_to(ROOT))
(HERE/'before-hashes.json').write_text(json.dumps({path.relative_to(ROOT).as_posix():hashlib.sha256(path.read_bytes()).hexdigest() for path in files},indent=2),encoding='utf-8')
for args,name in [(['status','--short'],'status-before.txt'),(['diff','--','patch-notes/scripts','tools'],'diff-before.patch'),(['rev-parse','HEAD'],'head.txt')]:
    (HERE/name).write_bytes(subprocess.run(['git',*args],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,check=True).stdout)
print(len(files),'baseline files archived')
