from run import *
from collections import Counter
import re
def money(c):return f'${c/100:,.2f}'
def main():
 access=load(ACCESS/'analysis.json');study=load(HERE/'analysis.json');pin=load(HERE/'execution-pin.json')
 assert len(access['rows'])==12 and len(study['rows'])==4
 checks=load(HERE/'checks.json');cross=load(HERE/'cross-checks.json')
 assert all(x['ok'] for x in checks['checks']) and all(x['ok'] for x in cross)
 verifications={}
 for path in [ACCESS/'replay-action-4417-cash18-exit.json',ACCESS/'replay-action-4417-cash6-exit.json',ACCESS/'reduce-action-4417-cash6-exit.json',ACCESS/'cold-exit.json',HERE/'replay-skip-action-4417-cash18-exit.json',HERE/'replay-mean-simulation-4417-cash18-exit.json',HERE/'cold-exit.json']:
  x=load(path);verifications[str(path)]=x;assert x['exit_code']==0,path
 for raw,cid,prior in [(ACCESSRAW/'cold','access-cold',ACCESSRAW/'action-4417-v2/cases/action-4417-cash18'),(RAW/'cold','brief-cold',RAW/'branches/cases/mean-action-4417-cash18')]:
  a=load(raw/'cases'/cid/'result.json');b=load(prior/'result.json')
  assert a['status']=='completed' and a['initial_state']==b['final_state'] and a['initial_rng']==b['final_rng']
 write(HERE/'final-verification.json',dict(processes=verifications,cold_initial_state_rng_exact=True,cross_prefixes_exact_except_empty_crown=True))
 table='\n'.join(f"| {r['case']} | {r['releases']} | {r['cycles']} | {('cycle '+str(r['access']['cycle'])) if r['access'] else 'Not reached'} | {money(r['minimum_cash_cents'])} | {money(r['max_overdue_cents'])} |" for r in access['rows'])
 bt='\n'.join(f"| {r['case']} | {r['reputation_bp']/100:.2f} | {r['final_cycle']} | {money(r['final_cash_cents'])} | {money(r['min_cash_cents'])} |" for r in study['rows'])
 rawlink=lambda p:f'<{str(p).replace(chr(92),"/")}>'
 text=f'''# Crown paid Search: access and Brief affordability v1

2026-10-25. **Completed bounded private research; rewards unchanged.** [Approved terms](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md) remain a bounded pilot, not final balance or canonical activation. [Adoption/review handoff](CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md).

## Result and recommendation

Keep the approved Brief formula and rewards. The larger immediate concern is an affordable route to Crown, followed by clear pre-hand grade information. Under this fixed policy, four18-search Action/Simulation cases earn access at Game2/cycle100; all six6-search cases and both18-search Puzzle cases fail financially before Game2 releases. This does not establish that18 searches are necessary or that Puzzle cannot unlock Crown. The policy deliberately spends four Research acquisitions and10/10/12 Game2 hands; shorter quality-aware production may avoid its failure.

After legal access, both tested routes afford three Briefs with no arrears. Each earns12.50R as7.50,5.00,0.00 over9 extra cycles. At the next release Action has$870.63 less cash and Simulation$1,520.98 less than skipping. Both retain the same next-game Review as their skip comparison. Zero direct Brief cash does not mean zero cash movement: the existing high-review game's sales settle during the nine added cycles.

## Source and method

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout. No canonical source edits, commits or pushes by this study.
- Baseline named variant `crown-search-access-20261025-v1`, original/creation identity `434971b9525f09fab3fa0846ed094f53d6ee778f76ae8b97740a136c7b0fda3f`; executed mechanics `ce24d2a07703a664edd86574b2c678666f9307c5160710a62ce55603c7a74692`.
- Child candidate `crown-search-brief-20261025-v1`, source manifest identity `{pin['identity']}`; executed mechanics `9dd1e4551338d38894dace6eb98bc635c38b7e6ec47427b4078cf0ccfe8b0bd6`. [Exact pin and13-path delta](studies/crown-search-brief-20261025-v1/execution-pin.json). Two paths are experiment policy/probe; eleven are runtime/observation/schema integration.
- [Access preregistration](studies/crown-search-access-20261025-v1/PLAN.md), [Brief preregistration](studies/crown-search-brief-20261025-v1/PLAN.md), exact `*-command.json`/exit files alongside each script, and original runner command manifests in raw bundles. Python3.12.14, Godot4.7.1; unique project/cache/profile per documented runner invocation.
- Action/Puzzle/Simulation, seeds4417/4521, six matched initial state/RNG groups, all12 current roster-v3 fixture checks. No traits, Bank, employee trial, synthetic funds, hidden future draws or redraws. Same public policy except6 versus18 paid cash Searches. Four-release/420-command bounds;600seconds import/run. Funding includes real cycles/rent; recipes remain legal.
- Four real Research purchases, first release2/2/2 hands, Game2 with10/10/12, later6/6/6. Fixed purchase list and visible-only selection are declared policy limitations. No release reward/gate changes.
- Select first accessible seed per specialty by preregistered order; Action4417 and Simulation4417 qualify, Puzzle is excluded because neither tested route earns access. Regenerated candidate prefixes finish at Game2/cycle100 with$1,093.22 and$886.09. Exact original-tape replay verifies every prefix command/result/state; after removing only the new empty Crown map, complete final state and RNG match the baseline. No checkpoint identity bypass.
- Two same-candidate skip/three-Brief pairs start from identical legal Studio checkpoint/state/RNG and produce one further game,100-command limit. Public-pool256-scenario mean first-hand planning, exact second-hand projection; no redraws. Each search-plus-work takes3 productive cycles. R20 remains a diagnostic only, not a newly approved Crown commission gate.

## Access results

| Case | Releases | Cycles | Crown access | Cash low | Peak arrears |
|---|---:|---:|---|---:|---:|
{table}

12 declared cases:4 completed,8 affordability rejections,1,876 accepted commands. Four successes finish4 releases; eight failures finish1 release. Six-study pairs all retained. The18-search routes spend36 more funding cycles than6-search routes, before any difference in survival/production.100 cycles is about4 years2 months in the24-cycle game calendar; it is not a recommended onboarding duration.

## Post-access results

| Case | Crown R earned | Final cycle | Final cash | Cash low |
|---|---:|---:|---:|---:|
{bt}

All four complete with no overdue. Brief runs use47/49 accepted commands; skips29/31. Both start at cycle100; Brief final release128 versus skip119. Each has a third zero award despite high completion: final half-unit Cores Action20/8/22/12, Simulation24/8/24/10 exceed the spread fade. The projection checks match actual Scope/Cores and standing after every hand. Requested and credited are equal here because standing remains far below the cap.

## Verification, failures and limits

- Three focused maintained suites PASS: Contract challenge runtime, publisher relationships43 assertions, and paid Contract Search125 assertions/91 commands. New Crown probe32/32 PASS: strict terms/source, publisher isolation, pending/stale guards, zero first-hand award, no cash/Promotion/Investment, once-only completion,3-cycle cost and pending/completed Studio restore.
- Both cross-version prefixes PASS (183/185 commands), with only the documented empty Crown record added. All other final state and RNG exact.
- Four representative fresh-process replays PASS: baseline Action success241 commands, baseline Action affordability rejection92 commands, candidate skip Action29 and candidate mean Simulation49. Telemetry is recomputed. Representative affordability failure reduced and confirmed by the documented reducer. Original failed case retained.
- Baseline and candidate fresh-process Studio Continue PASS, with exact restored initial state/RNG. [Verification receipts](studies/crown-search-brief-20261025-v1/final-verification.json).
- Initial two v1 adapter cases reject their first command because JSON priorities were floats; v2 converts only those four priorities to integers. Same seeds, values and bounds; original input/output retained. They are not counted among12 corrected economic cases.
- Initial raw three-way merge conflicts were retained, then reconciled with explicit UTF-8/LF handling and current Search behavior preserved. No conflicting merge marker was executed. Existing ObjectDB exit warnings remain in raw logs; no simulation timeout or rejected case was discarded.
- Only3 specialties/2 seeds for access, and2 earned post-access starts. No optimality, whole-population balance, active-rival career, player comprehension, UI/device or canonical deployment claim. No earned R100 cap witness; core ledger cap regression is not a replacement for broader career evidence. Original Crown private release-source saves are not migrated by this candidate; canonical migration/exposure remains a gate.

## Retained evidence

- [Access analysis](studies/crown-search-access-20261025-v1/analysis.json), [case/tape hashes](studies/crown-search-access-20261025-v1/evidence-manifest.json), [raw access bundles]({rawlink(ACCESSRAW)}).
- [Brief analysis](studies/crown-search-brief-20261025-v1/analysis.json), [case/tape hashes](studies/crown-search-brief-20261025-v1/evidence-manifest.json), [focused checks](studies/crown-search-brief-20261025-v1/checks.json), [prefix comparisons](studies/crown-search-brief-20261025-v1/cross-checks.json), [raw candidate bundles]({rawlink(RAW)}).

Recommended next design experiment: reserve-aware, quality-aware Game2 exits and necessary-only Research on the same fixed failed prefixes, keeping rewards, Review7 and redraw policy unchanged. Register it separately; it was not run here. In parallel, review the approved Crown pilot's integration and grade-preview acceptance, without activating wider Crown cash/commission/support catalogs.
'''
 (THREAD/'CROWN-SEARCH-BRIEF-FINDINGS-2026-10-25-v1.md').write_text(text,encoding='utf-8')
 handoff='''# Crown paid-Search Brief — adoption review v1

2026-10-25. [Findings/source/commands](CROWN-SEARCH-BRIEF-FINDINGS-2026-10-25-v1.md) · [exact approved terms](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md).

| Item | Status | Scope / acceptance / dependency |
|---|---|---|
| CSB1 retained Balanced Craft pilot formula | **approved** | Two hands, Scope9/Core4/spread2/fade6, min grade, floor arithmetic, up to10R, zero cash/advance/Promotion/Investment. Existing partial routes and rewards remain unchanged. Bounded pilot only |
| CSB2 private paid-Search integration and evidence | **implemented and verified — private only** | Named candidate and exact manifest;12 current behavior cases, regenerated legal access, four paired branches,32 structural checks, focused maintained checks, cross-version prefix state/RNG, replays, reduction and cold Continue. Not canonical activation |
| CSB3 adoption review packet | **handed off — DESIGN review needed** | Review whether to authorize canonical player exposure after all gates below. No duplicate SideStreet Search task, arbitrary values, broader catalog or default rival-AI adoption |
| CSB4 cheaper current-roster access | **proposed** | Separate bounded read-only comparison of quality-aware phase exit/Research reserves using retained failures. Keep seeds, rewards and Review7; do not require18 searches as a new rule |

## Exact candidate delta

See `studies/crown-search-brief-20261025-v1/execution-pin.json` and the sealed versioned packet under `handoffs/crown-search-brief-20261025-v1/`.

1. Register the dedicated Crown Brief definition/challenge without altering cash Contracts or SideStreet terms.
2. Extend trusted Search support to Crown/Brief only. Freeze known template/terms/Studio/publisher/ordinal/standing/cycle/revisions. Use actual paid Search IDs with empty release source, never fabricated release IDs. Pending checks key on publisher and work; preserve existing SideStreet intro/backlog and commissions.
3. Add durable Crown offers, frozen Primitive pools, active/completed routing and atomic final-hand zero-currency standing settlement through the current relationship ledger. Releases issue no free Crown Brief.
4. Add strict candidate checkpoint schema, code-owned source resolver and source/rules identity. Preserve current SideStreet serialization. The prototype's private rules tag is a fence, not a canonical migration decision.
5. Expose detached public planning-pool data for the experimental policy. `csa_access.gd` and `crown_search_probe.gd` are experiment helpers, not production AI or player rules.

## Gates before canonical exposure

- Explicit activation/adoption review: approved numerical pilot terms do not silently approve all product/UI/migration decisions.
- Reconcile the11 runtime/observation/schema paths against then-current canonical source; preserve unrelated Search/Employees/Bank/market work. Do not copy the whole private project.
- Integrate the actual Studio publisher/work chooser and preview. Show one Search cycle plus two hand cycles, zero currency/Investment, up-to10R, precise targets and provisional grade. Dominant-Core increases can lower reward; final projected grade/requested/credited must agree with committed results. Handle no funds, zero grade and cap-full standing before spending. No new hidden minimum grade or cooldown.
- Named current/editor/old Search-save migration must preserve pending/active/completed rights, frozen pool/source, cap/duplicate history and exact RNG. Private predecessor Crown saves require an explicit accept/reject policy; never accept unknown schema. Studio-only Continue remains required.
- Repeat affected structural/relationship/Search/checkpoint suites; independent replay and post-completion cold Continue; request tampering, cross-Studio/publisher isolation, failure injection at settlement and cap/zero-award cases. Preserve rejection atomicity and existing SideStreet/commission/support outcomes.
- Active-rival world and native UI checks at both supported sizes; requested final build/export/device checks remain separate. Private headless success does not close them.
- Accessibility recommendation is limited:2 earned post-unlock starts are solvent, but8/12 access routes failed under the tested policy. Keep this visible in adoption review; no reward/gate tuning is included.

The next design research is CSB4 and preview comprehension. Crown cash packages, commissions/support, other publisher tiers, cap policy changes, broader balance and redraw optimization remain OPEN/parked.
'''
 (THREAD/'CROWN-SEARCH-BRIEF-HANDOFF-2026-10-25-v1.md').write_text(handoff,encoding='utf-8')
 print('Wrote findings and gated handoff; final checks satisfied.')
if __name__=='__main__':main()
