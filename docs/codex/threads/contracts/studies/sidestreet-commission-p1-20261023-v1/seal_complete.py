from pathlib import Path
import sys,json,subprocess
from paths import bundle
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
argv=json.loads((H/'seal.command.json').read_text())['argv']
argv[argv.index('--output')+1]=str(T/'handoffs/sidestreet-p2-p3-20261023-v2')
argv[argv.index('--design-record')+1]=str(T/'SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md')
argv[argv.index('--summary')+1]='APPROVED bounded SideStreet P2/P3 pilot: P1-backed partial-credit Reputation Briefs, frozen R20 commission quotes, proportional $6000 launch fee and publisher-owned sales. Current-source partial/zero settlements, rights/finance saves, observers and fresh replays pass. The predeclared long route misses Scope; prove legal full delivery/+15R/+15I and a second completion before activation, then complete native/migration/export acceptance. Do not lower approved targets or adopt the archive wholesale.'
argv[argv.index('--acceptance')+1]='GATE0 BEFORE ACTIVATION: demonstrate legal full required Scope and Review6 under approved terms, full $6000 plus production +15R/+15I including cap clipping/cold restore, and a second completed commission. Current routes prove only partial/zero payouts; preserve their misses and do not silently change terms.'
for stage in ['delivery','continue']:argv+=['--evidence',str(bundle(stage))]
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
with (H/'seal-complete.command.json').open('x') as f:json.dump(dict(argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr),f,indent=2)
print(p.stdout);print(p.stderr);sys.exit(p.returncode)
