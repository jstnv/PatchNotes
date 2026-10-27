from pathlib import Path
import ast,json,re,subprocess
base=Path(__file__).resolve().parent;root=base.parents[3]
errors=[];links=0
documents=[base/'README.md',base/'CAPTURES.md',root/'docs/codex/logs/2026-10-17-bank-publisher-final-acceptance-v1.md']
for p in documents:
 text=p.read_text(encoding='utf-8')
 for target in re.findall(r'\]\(([^)]+)\)',text):
  if '://' in target or target.startswith('#'):continue
  links+=1
  if not (p.parent/target.split('#')[0]).resolve().exists():errors.append(str(p)+' missing '+target)
 for i,line in enumerate(text.splitlines(),1):
  if line.rstrip()!=line:errors.append(str(p)+':'+str(i)+' trailing whitespace')
for p in base.glob('*.py'):ast.parse(p.read_text(encoding='utf-8'),filename=str(p))
result=dict(documents=len(documents),local_links=links,errors=errors)
(base/'documentation-check.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result));raise SystemExit(bool(errors))
