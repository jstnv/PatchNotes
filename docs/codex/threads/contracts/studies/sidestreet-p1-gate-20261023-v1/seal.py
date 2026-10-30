from pathlib import Path
import sys,json,hashlib,re,subprocess
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def ck(v,s):checks.append({'pass':bool(v),'check':s})
base=read(T/'simulators/sidestreet-p1-gate-v1/base-manifest.json')
current=sim.source_hashes(R/'patch-notes')
ck(base==current,'canonical full source manifest unchanged since completed P1')
analysis=read(H/'analysis.json');ck(not analysis['failures'],'all198 analysis checks pass')
packet=T/'handoffs/sidestreet-p1-gate-20261023-v1'
for p,digest in read(packet/'handoff-integrity.json').items():ck(sha(packet/p)==digest,'sealed packet '+p)
for p in [H/'checks-v1/audit.json',H/'observer-v1/result.json']:ck(read(p)['failures']==0,p.name+' focused audit passes')
for i in [1,2]:
    report=read(T/f'sims/sidestreet-p1-replay-{i}-20261023-v1/run-report.json')
    ck(report['ok'] and report['replay']['telemetry_verified'],'fresh replay '+str(i))
documents=[T/'SIDESTREET-P1-GATE-FINDINGS-2026-10-23-v1.md',T/'SIDESTREET-P2-AND-FIRST-COMMISSION-PROPOSAL-2026-10-23-v1.md']
for p in documents:
    for ref in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
        if '://' not in ref:ck((p.parent/ref.split('#')[0]).exists(),p.name+' link '+ref)
index={}
folders=[H,packet,*[T/f'sims/sidestreet-p1-{arm}-{batch}-20261023-v1' for arm in ['balanced','skip'] for batch in [1,2]],T/'sims/sidestreet-p1-baseline-20261023-v1',T/'sims/sidestreet-p1-replay-1-20261023-v1',T/'sims/sidestreet-p1-replay-2-20261023-v1']
import os
for folder in folders:
    for directory,dirs,files in os.walk(folder):
        dirs[:]=[d for d in dirs if d not in ['project','profile','.godot','__pycache__']]
        for name in files:
            p=Path(directory)/name
            if p in [H/'evidence-index.json',H/'verification.json']:continue
            index[p.relative_to(R).as_posix()]=sha(p)
for p in documents:index[p.relative_to(R).as_posix()]=sha(p)
(H/'evidence-index.json').write_text(json.dumps(index,indent=2),encoding='utf-8')
result={'checks':checks,'failures':[c for c in checks if not c['pass']],'sealed_files':len(index),'branch':subprocess.check_output(['git','branch','--show-current'],cwd=R,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=R,text=True).strip(),'canonical_identity':sim.manifest_identity(current) if hasattr(sim,'manifest_identity') else None}
(H/'verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':result['failures'],'sealed_files':len(index)}))
