"""Official variant/simulator entry points with bounded tracked Git provenance.

The shared checkout's full untracked listing exceeded174 MB and timed out.
Exact project inventories/hashes remain unchanged; this wrapper narrows only
Git status capture, and records that limitation. It does not change gameplay,
source compatibility, snapshot fences, import, execution or replay checks.
"""
from pathlib import Path
import json, subprocess, sys, shutil
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'tools'))
import simulate
import simulator_variant

def provenance(repo,evidence=None):
    result={'status_scope':'tracked-only; untracked project files are covered by exact source manifests'}
    for label,args in [('branch',['branch','--show-current']),('head',['rev-parse','HEAD']),('status',['status','--porcelain=v1','--untracked-files=no']),('diff',['diff','--binary','HEAD','--','patch-notes','tools/simulate.py'])]:
        try:
            c=subprocess.run(['git',*args],cwd=repo,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=30)
            if c.returncode:result[label]={'error':c.stderr.decode(errors='replace')};continue
            if evidence is not None and label in ['status','diff']:
                f=evidence/('git-status.txt' if label=='status' else 'source.diff.patch');f.write_bytes(c.stdout)
                result[label]={'artifact':f.name,'bytes':len(c.stdout),'sha256':simulate.sha(f),'exit':0}
            else:result[label]=c.stdout.decode('utf-8',errors='replace').strip()
        except subprocess.TimeoutExpired:result[label]={'error':'timeout'}
    result['dirty']=bool(result.get('status'))
    if evidence is not None:
        shutil.copy2(__file__,evidence/'provenance-wrapper.py')
        result['wrapper_sha256']=simulate.sha(Path(__file__))
    return result

if __name__=='__main__':
    tool=sys.argv.pop(1)
    module={'simulate':simulate,'variant':simulator_variant}[tool]
    module.git_provenance=provenance
    if hasattr(module,'sim'):module.sim.git_provenance=provenance
    sys.exit(module.main())
