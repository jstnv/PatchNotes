from run_checks import *
from urllib.parse import unquote

paths=[BASE/'README.md',BASE/'DESIGN-REVIEW.md',BASE/'AI-VARIETY.md',BASE/'AI-VARIETY-PLAN.md',ROOT/'docs/codex/logs/2026-10-17-new-queue-implementation-v1.md']
broken=[];checked=0
for path in paths:
 for raw in re.findall(r'\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
  target=unquote(raw.strip('<>').split('#')[0])
  if not target or '://' in target:continue
  checked+=1
  if not (path.parent/target).exists():broken.append([str(path.relative_to(ROOT)),target])
assert not broken,broken
delta=sim.read_json(BASE/'source-delta.json')
tracked=[str(Path('patch-notes')/row['path']) for row in delta]
tracked+=sim.read_json(BASE/'documentation-changes.json')
tracked+=['tools/simulate.py','tools/release_gate.py','tools/tests/test_release_gate.py','tools/tests/test_simulate.py','docs/codex/findings/export-queue-v3/export.py','docs/codex/findings/export-queue-v3/inspect.py']
command=['git','-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol','diff','--check','--',*tracked]
result=subprocess.run(command,cwd=ROOT,capture_output=True,text=True)
(BASE/'focused-diff-check.log').write_text(result.stdout+result.stderr,encoding='utf-8')
assert result.returncode==0,result.stdout
assert sim.source_hashes(ROOT/'patch-notes')==sim.read_json(BASE/'final-source.json')
sim.write_json(BASE/'documentation-check.json',{'local_links_checked':checked,'broken_links':broken,'focused_diff_exit':result.returncode,'final_source_matches':True,'full_diff_note':'Repository-wide check retains one existing unrelated blank-space line in docs/codex/threads/banking-system/2026-10-10-export-acceptance-continuation-v1.md. It was not edited. CR-at-EOL is allowed for existing Windows line endings.'})
print(json.dumps({'local_links_checked':checked,'focused_diff_exit':result.returncode,'final_source_matches':True}))
