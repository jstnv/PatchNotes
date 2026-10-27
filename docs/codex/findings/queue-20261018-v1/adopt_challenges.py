"""Apply only reviewed candidate hunks; preserve all current unrelated edits."""
from pathlib import Path
import json,zipfile,hashlib,difflib,sys
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
PACKET=ROOT/'docs/codex/threads/contracts/handoffs/contracts-challenges-runtime-v2'
h=json.loads((PACKET/'handoff.json').read_text())
base=zipfile.ZipFile(PACKET/'base-source.zip');candidate=zipfile.ZipFile(PACKET/'candidate-source.zip')
def sha(x):return hashlib.sha256(x).hexdigest() if x is not None else None
prepared={};report=[]
for change in h['changes']:
 name=change['path'];dest=ROOT/'patch-notes'/name
 before=base.read(name) if name in base.namelist() else None
 after=candidate.read(name) if name in candidate.namelist() else None
 assert sha(before)==change['before_sha256'] and sha(after)==change['after_sha256'],name
 current=dest.read_bytes() if dest.exists() else None
 if current==after:report.append({'path':name,'action':'already identical; retained'});continue
 if before is None:
  assert current is None,name
  prepared[dest]=after;report.append({'path':name,'action':'reviewed addition','after':sha(after)});continue
 old=before.decode().replace('\r\n','\n');new=after.decode().replace('\r\n','\n');merged=current.decode().replace('\r\n','\n')
 manual=[]
 for group in difflib.SequenceMatcher(None,old.splitlines(True),new.splitlines(True),autojunk=False).get_grouped_opcodes(3):
  old_chunk=''.join(old.splitlines(True)[group[0][1]:group[-1][2]])
  new_chunk=''.join(new.splitlines(True)[group[0][3]:group[-1][4]])
  if merged.count(old_chunk)==1:merged=merged.replace(old_chunk,new_chunk,1)
  elif name=='scripts/persistence/studio_checkpoint.gd' and ('const RULES :=' in old_chunk or 'if rules in [RULES' in old_chunk or 'INCOMPATIBLE_CONTENT_OR_RNG' in old_chunk):manual.append(old_chunk)
  else:raise RuntimeError('Non-unique/current-conflicting hunk '+name+'\n'+old_chunk)
 if name=='scripts/persistence/studio_checkpoint.gd':
  assert len(manual)==3
  merged=merged.replace('const RULES := PRE_BRANCH_RULES + "-branches1"','const PRE_CHALLENGE_RULES := PRE_BRANCH_RULES + "-branches1"\nconst RULES := "finance6-bank1-employees1-traits8-sales1-contracts4-research1-review2-fanbase1-starwave1-education1-cult2-branches1"')
  merged=merged.replace('[RULES, PRE_BRANCH_RULES, PRE_CULT20_RULES]','[RULES, PRE_CHALLENGE_RULES, PRE_BRANCH_RULES, PRE_CULT20_RULES]')
  merged=merged.replace('(_catalog_revisions(RULES) + _catalog_revisions(PRE_BRANCH_RULES)','(_catalog_revisions(RULES) + _catalog_revisions(PRE_CHALLENGE_RULES) + _catalog_revisions(PRE_BRANCH_RULES)')
 prepared[dest]=merged.encode()
 report.append({'path':name,'action':'current-source hunk reconciliation','before':sha(current),'after':sha(merged.encode()),'branch_rule_hunks_reconciled':len(manual)})
(OUT/'challenge-adoption.json').write_text(json.dumps(report,indent=2)+'\n')
if '--apply' in sys.argv:
 for dest,body in prepared.items():dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(body)
 print('Applied',len(prepared),'reviewed files; unrelated edits preserved')
else: print('Prepared',len(prepared),'reviewed files; dry run only')
