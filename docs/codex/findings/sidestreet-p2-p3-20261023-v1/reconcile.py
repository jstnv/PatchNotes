"""Minimal shared-record reconciliation after verified bounded acceptance."""
from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def edit(path,transform):
    before=path.read_bytes();text=before.decode('utf8');sep='\r\n' if '\r\n' in text else '\n'
    after=transform(text,sep)
    assert path.read_bytes()==before,'Concurrent edit; reread before reconciling '+str(path)
    path.write_bytes(after.encode('utf8'))
def main():
    assert json.loads((HERE/'final-audit.json').read_text(encoding='utf8'))['pass']
    findings='findings/sidestreet-p2-p3-20261023-v1/README.md'
    def todo(text,sep):
        lines=text.splitlines(keepends=True);counts=[0,0]
        for i,line in enumerate(lines):
            if line.startswith('**2026-10-23 SideStreet P2/P3 implementation — IN PROGRESS here:'):
                lines[i]='**2026-10-24 SideStreet P2/P3 — IMPLEMENTED locally; final interaction acceptance PARTIAL/BLOCKED.** Approved Brief/commission mechanics, atomic transactions, named P1 migration and playable UI are integrated.36 affected suites,224 independent campaign checks,six fresh replays,ten audits,both-size source/compiled-PCK routes and20 cold Continues pass. Direct release EXE Continue/playthrough is blocked by another running game’s production save writer62741; its session was preserved. [Source/build evidence and exact remaining scope]('+findings+'). No commit, push or release-readiness claim.'+sep;counts[0]+=1
            elif line.startswith('**2026-10-23 SideStreet P2/P3 — QUEUED for PN Implementation;'):
                lines[i]='**SideStreet P2/P3 adoption tasks A–E — code and feasible acceptance COMPLETE; direct EXE interaction BLOCKED.** [Approved v3 authority](threads/contracts/SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md), [v2 criteria](threads/contracts/SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md), [sealed candidate](threads/contracts/handoffs/sidestreet-p2-p3-20261023-v2/HANDOFF.md). Canonical legal full delivery/positive R/I, second completion, both caps, zero/partial fees, publisher-owned sales/Bank exclusion, coherent observers, corruption rejection, populated Founder control transfers and old/current disk preservation pass at the [recorded source/native/exported-PCK boundaries]('+findings+'). Remaining: safely close the other game, then verify the direct release EXE Brief→R20→quote→release/result→later-sales→cold Continue interaction at both supported sizes. Actual EXE startup and save-lock refusal pass; that refusal is not successful Continue. Trial values remain approved ACTIVE/TRIAL design, not final balance; shorter-policy misses and the separately declared10/10/10 witness remain distinct. P4 support/renewal, broader tiers, default rival commission policy and human comprehension remain OPEN. No approved implementation work is left QUEUED in this slice.'+sep;counts[1]+=1
            else:
                lines[i]=line.replace('The bounded P2/P3 pilot is now approved and queued above; P4 and broader publisher scope remain OPEN.','The bounded P2/P3 pilot is now implemented locally above; direct EXE interaction remains blocked, and P4/broader publisher scope remains OPEN.').replace('approved bounded P2/P3 implementation and its remaining full-delivery gate are queued above','bounded P2/P3 is implemented locally, with direct EXE interaction still blocked above')
        assert counts==[1,1],counts
        return ''.join(lines)
    edit(ROOT/'docs/codex/TODO.md',todo)
    def prepend(text,sep,body):
        first,rest=text.split(sep,1)
        return first+sep+sep+body.replace('\n',sep)+sep+rest
    state='**2026-10-24 SideStreet P2/P3 — IMPLEMENTED locally at approved trial scope; final interaction acceptance PARTIAL/BLOCKED:** separate Reputation Briefs and R20 commissioned games use atomic P1/finance/release planning, strict prospective player/active-rival migration and owner-aware playable UI. Canonical full/repeat/cap/partial/zero evidence passes224 checks,six exact replays andten audits;36 affected suites,both-size source/actual-compiled-PCK routes and20 cold Continues pass. Clean359-entry package and actual EXE startups pass. Direct release EXE Continue is blocked by another running game’s production writer; the other session and isolated generation bytes were preserved. [Source pins, files, captures, warnings and remaining gates]('+findings+'). Player Continue stays Studio-only; P4/default rival commission policy/final balance and human/device acceptance remain OPEN. No commit/push or release-ready claim.'
    edit(ROOT/'docs/codex/CURRENT_STATE.md',lambda text,sep:prepend(text,sep,state))
    design='''## SideStreet P2/P3 canonical integration — 2026-10-24

**IMPLEMENTED locally at the approved ACTIVE/TRIAL design scope; final direct-EXE interaction acceptance remains PARTIAL/BLOCKED.** [Approval](../threads/contracts/SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md), [source-pinned implementation and acceptance](../findings/sidestreet-p2-p3-20261023-v1/README.md). This supersedes earlier proposed/queued SideStreet P2/P3 labels only; sealed findings remain historical evidence.

- Separate Reputation Brief: two successful four-card hands; Scope10/Core3 each,64-unit denominator. No successful redraw and Scope≤10 gives full promise;11 half;12+ or any successful redraw zero. Reputation award basis points are `floor(1000 * min(completion_bp,promise_bp) / 10000)`, at most10R. No cash/advance/Promotion/Investment; one release-paced opportunity without missed backlog. Legacy completed cash-Contract counts are unchanged.
- SideStreet R20 grants access to an optional commissioned game without spending standing. Normal chosen name/Genre/Theme preparation freezes actual positive required Scope, identities, cycle, Review6 target, maximum600000-cent fee and publisher sales rights. One pending commission; no cancellation after Begin. `scope_bp=min(10000,floor(10000*delivered/required))`, `review_bp=clamp(500*(review_tenths-40),0,10000)`, `delivery_bp=min(scope_bp,review_bp)`, `fee=floor(600000*delivery_bp/10000)`. Only full delivery requests1500R/1500I basis points through P1; independent100 caps clip credit, retaining qualifying zero-credit events. Every partial/zero completion retains one named receipt/event. Later prepared projects may quote again.
- Raw title sales/units/history and Fans remain, while Studio earned/settled/Bank sales inputs are zero for the publisher-owned title; Studio post-launch campaigns are unavailable. The fee is a separate publisher receipt subject to ordinary obligations. Banked Promotion is consumed normally. No base score, Review, rent/payroll/Bank, research price or hand-limit change.
- All effects are planned before hand/Begin/release commitment and published coherently. Frozen predecessor validation adds empty pilot sources without backfill, with exact named world/source pairs. Active rival commissions use an explicit project-linked DTO; player Continue remains Studio-only. Unknown/renamed/duplicated/orphan sources, forged required Scope and sales-rights mismatches reject.

Canonical legal full/second delivery and both caps pass; the original shorter-policy misses remain. The researched trio and separate10/10/10 witness are evidence routes, not prerequisites or recommended pacing. Native source and audited compiled-PCK flows pass at both supported sizes. Another running game holds the production save lock, so actual release EXE interaction remains blocked; startup and refusal/preservation are verified. P4 support/renewal, other tiers, default AI commission policy, human comprehension/device/audio/license acceptance and final balance remain OPEN/PROPOSED.
'''
    edit(ROOT/'docs/codex/design/publishers-contracts.md',lambda text,sep:prepend(text,sep,design))
    decision='''
## 2026-10-24 — SideStreet P2/P3 canonical adoption

Approved bounded trial terms are integrated locally: separate release-paced Reputation Briefs, R20 access to normal frozen commissioned preparation, proportional fee/full-only R/I through P1 and publisher-owned sales separation. Preserve existing cash Contracts, finance/RNG owners and the Studio-only player Continue boundary. Named P1 migration is prospective; no backdated awards or arbitrary source relabeling. Active commissioned rivals have an explicit validated DTO. [Design](design/publishers-contracts.md) · [verified outcomes and exact source/build limits](findings/sidestreet-p2-p3-20261023-v1/README.md).

Canonical full/repeat/cap, native source/compiled-PCK and cold preservation checks pass. Final direct release EXE interaction remains BLOCKED by another running game's production save writer; leave that session intact and retain PARTIAL acceptance until it can close safely. Trial values are not final balance approval. P4 support/renewal, broader tiers, default AI commission policy and human/device acceptance remain OPEN. No commit/push/release-ready claim.
'''
    edit(ROOT/'docs/codex/DECISIONS.md',lambda text,sep:text+decision.replace('\n',sep))
    thread='**2026-10-24 PN Implementation reconciliation — SideStreet P2/P3 implemented locally; final direct-EXE interaction acceptance PARTIAL/BLOCKED.** [Canonical source/build evidence, legal full/repeat/caps and native/cold matrix](../../findings/sidestreet-p2-p3-20261023-v1/README.md), [session log](../../logs/2026-10-24-sidestreet-p2-p3-adoption-v1.md).36 affected suites,six fresh replays,both-size source/compiled-PCK flows and20 cold Continues pass. The actual release EXE correctly refuses a competing save writer; the other game was preserved. Approved terms are unchanged; P4 private support/renewal findings below remain PROPOSED and were not adopted. This supersedes older queued/private-only P2/P3 status statements below without rewriting their historical evidence.'
    edit(ROOT/'docs/codex/threads/contracts/README.md',lambda text,sep:prepend(text,sep,thread))
    def plan(text,sep):
        for n in [2,3,4,5]:text=text.replace('- [ ] **'+str(n)+'.','- [x] **'+str(n)+'.',1)
        text+=('''
- 2026-10-24 final feasible acceptance PASS: final v5 editor a6766632… and actual compiled PCK1be636f8…;44 canonical source paths,13 unchanged seals,36 affected suites,224 independent checks,six exact replays,ten audits,five native routes and20 cold processes/eight writers. Populated Founder handoff/return preserves exact Studio ledgers and RNG. All source/build fences and scoped whitespace pass. See the dated adoption log and findings README for full identities/results.
- Task6 remains PARTIAL/BLOCKED only for direct release EXE interaction: real Computer Use Continue displayed another-process save-lock recovery, retained generation bytes and exited0. The other running game was left open. Actual PCK instrumentation uses the editor engine because release templates ignore --script; no EXE playthrough is inferred from it. All remaining approved implementation work is complete locally. Human/device/balance and P4/default-policy design stay OPEN. No commit or push.
''').replace('\n',sep)
        return text
    edit(ROOT/'docs/codex/logs/2026-10-23-sidestreet-p2-p3-plan-v1.md',plan)
    print('Reconciled TODO, current state, design, decisions, Contracts status and execution ledger; direct EXE acceptance remains blocked.')
if __name__=='__main__':main()
