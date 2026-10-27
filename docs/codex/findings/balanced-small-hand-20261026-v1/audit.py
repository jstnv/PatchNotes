from pathlib import Path
import hashlib,json,re,subprocess
out=Path(__file__).resolve().parent;root=out.parents[3]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
paths=re.findall(r"edit\('([^']+)'",(out/'edit_copy.py').read_text())
paths += ['scripts/cards/balanced_production.gd','scripts/debug/verify_balanced_boost.gd']
targets=['patch-notes/'+p for p in paths]
targets += ['docs/codex/'+p for p in ['CURRENT_STATE.md','TODO.md','DECISIONS.md','design/core-and-studio.md','logs/2026-10-26-balanced-small-hand-v1.md']]
before=(out/'before/scripts/cards/balanced_production.gd').read_text()
after=(root/'patch-notes/scripts/cards/balanced_production.gd').read_text()
assert before.split('static func redistribute',1)[1]==after.split('static func redistribute',1)[1]
receipts={}
for label in ['baseline','arithmetic-final','design','alpha','parity','characterization','tutorial-native','cold']:
 p=out/(label+'-run.json');r=json.loads(p.read_text())
 assert r['exit']==0 and not r['errors'],label
 receipts[label]={'sha256':sha(p),'command':r['command'],'exit':r['exit']}
check=subprocess.run(['git','-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol','diff','--check','--',*targets],cwd=root,capture_output=True,text=True)
assert check.returncode==0,check.stdout+check.stderr
result={'date':'2026-10-26','branch':subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip(),
 'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
 'source_sha256':{p:sha(root/p) for p in targets},'receipts':receipts,'reward_body_unchanged':True,'diff_check':check.returncode}
(out/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'passing_runs':len(receipts),'pinned_files':len(targets),'reward_body_unchanged':True,'diff_check':check.returncode}))
