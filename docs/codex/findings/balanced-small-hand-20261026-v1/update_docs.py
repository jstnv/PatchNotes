from pathlib import Path
out=Path(__file__).resolve().parent;root=out.parents[3]
def update(name,transform):
 p=root/'docs/codex'/name;data=p.read_bytes();nl='\r\n' if b'\r\n' in data else '\n'
 p.write_bytes(transform(data.decode().replace('\r\n','\n')).replace('\n',nl).encode())
entry='**2026-10-26 Balanced Production small-hand allowance — IMPLEMENTED locally.** All-positive hand category totals differing by at most1 point now qualify alongside the existing inclusive15% rule.2/2/3/2 qualifies; omitted categories and a2-point low-score gap do not. Existing1.25 reward makes9→11→3/3/3/2.1,309 arithmetic/AI checks, Design/Alpha suites,8 exact live/headless comparisons,80 characterization cases,115 native tutorial checks and10 predecessor restore checks pass. [Rule interpretation, source and limits](logs/2026-10-26-balanced-small-hand-v1.md). Existing EXE/ZIP unchanged.\n\n'
for name in ['CURRENT_STATE.md','TODO.md']:
 # Re-read immediately before each minimal shared-ledger edit.
 update(name,lambda s:s.replace('\n\n','\n\n'+entry,1))
decision='## 2026-10-26 — neighboring whole-point Balanced hands\n\nUser-directed example2/2/3/2 now qualifies. Narrow implementation interpretation: all four hand category totals must be positive, and either highest minus lowest≤1 or each is within inclusive15% of the raw four-category mean. This supplements the percentage-only trigger, preserving the Feature gate and Specialization precedence. The1.25/floor-once reward is unchanged:9→11→3/3/3/2. No Scope/pressure/cost/cycle change or historical rescoring. [Source and checks](logs/2026-10-26-balanced-small-hand-v1.md).\n\n'
update('DECISIONS.md',lambda s:s.replace('\n\n','\n\n'+decision,1))
section='## Balanced Production small-hand eligibility — 2026-10-26\n\n**IMPLEMENTED locally:** user requested2/2/3/2 to qualify. Preserve the15% raw-hand rule and add an integer allowance: every category must contribute positively and highest minus lowest must be at most1 point. Thus2/2/3/2 or1/1/2/2 qualifies;0/1/1/1 or2/2/4/2 does not. This supersedes percentage-only eligibility below, retaining primary-plus-secondary totals, at least one Feature and Specialization precedence. Keep the1.25 reward and fixed remainder order:9→11→3/3/3/2. Shared live/headless/AI authority; no historical rescoring. [Checks and limits](../logs/2026-10-26-balanced-small-hand-v1.md).\n\n'
update('design/core-and-studio.md',lambda s:s.replace('## Balanced Production bonus — 2026-10-26',section+'## Balanced Production bonus — 2026-10-26',1))
p=root/'docs/codex/logs/2026-10-26-balanced-small-hand-plan-v1.md'
p.write_bytes(p.read_bytes().replace(b'- [ ]',b'- [x]'))
