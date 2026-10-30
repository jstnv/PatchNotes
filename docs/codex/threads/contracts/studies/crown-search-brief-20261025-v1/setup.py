from pathlib import Path
import json,sys,subprocess,zipfile,hashlib
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[5];THREAD=HERE.parents[1]
PARENT=THREAD/'simulators/crown-search-access-20261025-v1'
VAR=THREAD/'simulators/crown-search-brief-20261025-v1'
OLD=THREAD/'simulators/crown-brief-pilot-20261025-v1'
def write(p,x):p.write_text(json.dumps(x,indent=2)+'\n',encoding='utf-8')
def main():
    args=[sys.executable,'tools/simulator_variant.py','create','--id','crown-search-brief-20261025-v1','--owner','contracts','--from-variant',str(PARENT),'--output',str(VAR)]
    write(HERE/'create-command.json',args)
    with (HERE/'create.log').open('w') as f:r=subprocess.run(args,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT)
    assert r.returncode==0
    oldbase=zipfile.ZipFile(ROOT/'docs/codex/threads/simulation-engine/simulators/queue-crown-access-20261024-v1/base-source.zip')
    changes=json.loads((ROOT/'docs/codex/findings/queue-closeout-20261024-v1/crown-merge-initial.json').read_text())
    tmp=HERE/'merge';tmp.mkdir();receipt=[]
    for entry in changes:
        path=entry['path']
        if '/debug/' in path:continue
        target=VAR/'project'/path;candidate=(OLD/'project'/path).read_bytes()
        if path not in oldbase.namelist():
            assert not target.exists();target.write_bytes(candidate);status='added'
        else:
            current=target.read_bytes();base=oldbase.read(path)
            # Only the historical Crown delta; three-way merge preserves current Search and all unrelated changes.
            inputs=[tmp/(str(len(receipt))+x) for x in ['-current','-base','-candidate']]
            for p,data in zip(inputs,[current,base,candidate]):p.write_bytes(data)
            r=subprocess.run(['git','merge-file','-p',*[str(p) for p in inputs]],cwd=ROOT,capture_output=True)
            (tmp/(str(len(receipt))+'-result')).write_bytes(r.stdout)
            status='clean' if r.returncode==0 else 'conflict'
            if r.returncode==0:target.write_bytes(r.stdout)
        receipt.append(dict(path=path,status=status))
    write(HERE/'merge.json',receipt)
    print(json.dumps(receipt))
if __name__=='__main__':main()
