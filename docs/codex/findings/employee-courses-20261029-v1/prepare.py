from pathlib import Path
import json,shutil,subprocess
out=Path(__file__).resolve().parent;root=out.parents[3]
previous=out.parent/'studio-beams-20261029-v1'
for name in ['pin.py','run.py']:
    text=(previous/name).read_text(encoding='utf-8').replace('studio-beams-','employee-courses-')
    if name=='run.py': text=text.replace('else 130).returncode','else 600).returncode')
    (out/name).write_text(text,encoding='utf-8')
for name in ['source.json','baseline.json']:shutil.copyfile(previous/'source.json',out/name)
base=json.loads((out/'baseline.json').read_text(encoding='utf-8'))
for uri in base['runtime_files']:
    rel=uri.removeprefix('res://');target=out/'before'/rel
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/'patch-notes'/rel,target)
for cmd,name in [(['git','status','--porcelain'],'baseline-status.txt'),(['git','diff','--stat'],'baseline-diff-stat.txt')]:
    (out/name).write_bytes(subprocess.check_output(cmd,cwd=root))
print('Captured exact dirty runtime baseline '+base['runtime_identity'])
