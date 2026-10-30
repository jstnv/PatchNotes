from pathlib import Path
import sys,json,subprocess
from paths import bundle
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
argv=[sys.executable,str(R/'tools/simulator_variant.py'),'handoff','--variant',str(T/'simulators/sidestreet-commission-p1-v3'),'--output',str(T/'handoffs/sidestreet-p2-p3-20261023-v1'),'--design-record',str(T/'SIDESTREET-P2-P3-ADOPTION-2026-10-23-v1.md'),'--summary','APPROVED bounded SideStreet P2/P3 pilot, GATED implementation review: two-hand partial-credit Reputation Briefs through P1, R20 project-bound commission, proportional $6000 launch fee, full-only +15 R/+15 I and publisher-owned sales. Gate/quote checks pass; actual commission delivery verification was BLOCKED before execution by two canonical capture races. Complete Gate0 before adoption; source archive is not implementation or delivery evidence.']
for stage in ['prefix']:
    argv+=['--evidence',str(bundle(stage))]
for criterion in [
    'GATE0 BEFORE ADOPTION: complete the prepared four-case current-source delivery comparison, long-arm later-sales continuations, completed-deal save/observer checks and fresh delivery replays after shared-source work stabilizes. Two retained capture failures executed no delivery case; do not claim those results.',
    'Preserve existing cash Contracts, legacy publisher unlock counts, canonical edits, RNG/source compatibility and Studio-only Continue; P1 remains the sole R/I ledger.',
    'Production transactions must preplan and commit fee, rights, source result, standing, Fans, Promotion and finance coherently; stale/altered quotes and callback changes reject; retries award once.',
    'Adopt named current-P1 Studio/world migration prospectively without historical reward backfill; reject orphan/renamed publisher receipts and reconstruct raw-title rights against Studio earned/settled finance.',
    'Provide actual native quote/result/Finance disclosures including underdelivery, obligations, banked Promotion and publisher-owned sales; verify supported sizes and input navigation.',
    'Verify full/partial/zero delivery, capped awards, a second legal commission completion, actual later sales/Bank exclusion, populated Studio/Founder isolation and fresh disk/exported Continue.',
    'Use final findings and retained failures as evidence boundaries. P4 funding/marketing/support and broader publisher tiers remain OPEN; no automatic adoption, final balance lock, commit or push.'
]: argv+=['--acceptance',criterion]
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
with (H/'seal.command.json').open('x') as f:json.dump(dict(argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr),f,indent=2)
print(p.stdout);print(p.stderr);sys.exit(p.returncode)
