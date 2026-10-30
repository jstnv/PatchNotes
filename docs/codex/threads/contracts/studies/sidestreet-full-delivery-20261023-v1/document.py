# Unexecuted optimistic draft retained for provenance. Actual outcomes supersede it.
# Use closeout_docs.py; this draft must not publish its disproven expectations.
raise SystemExit('Superseded by closeout_docs.py after the retained delivery misses')
from pathlib import Path
import json,hashlib
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
def read(p):return json.loads(p.read_text())
v=read(H/'verification.json');a=read(H/'analysis-complete-v2.json')
assert v['failures']==a['failures']==0
def write(path,text):
    with path.open('x',encoding='utf-8',newline='\n') as f:f.write(text)
rows=a['rows'];first=rows[1];second=rows[3];bounded=rows[4];cap=rows[5]
table='| Commission | Scope | Review | Fee | Credited Reputation | Credited Investment |\n| --- | ---: | ---: | ---: | ---: | ---: |\n'
for i,d in enumerate(cap['commissions'],1):
    table+=f"| {i} | {d['scope']}/{d['required']} | {int(d['review_tenths'])/10:.1f} | ${int(d['fee_cents'])/100:,.2f} | {int(d['credited_rep'])/100:.2f} | {int(d['credited_inv'])/100:.2f} |\n"
rel='studies/sidestreet-full-delivery-20261023-v1'
finding=f'''# SideStreet full-delivery gate — findings v1

2026-10-23, America/Los_Angeles. **PASS: private Gate0 full delivery, positive production R/I, repeat completion, cap clipping and exact cold continuation.** This closes the evidence gap in the [v2 adoption specification](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md) for the unchanged private candidate. Canonical adoption, migration, native UI/export and populated ownership acceptance remain queued. No balance change or canonical activation is inferred.

## Authority, source and experiment

User: “Go ahead and and complete the remaining gate.” [Approved trial terms](SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md) stay unchanged. [Predeclared plan]({rel}/PLAN.md) records hypotheses, comparison cases, seed, policies, legal prefixes, measurements, process/command/release limits and stopping rules. [Execution record]({rel}/EXECUTION.md) retains the source-neutral audit failure and correction.

Branch `main`, HEAD `{v['head']}`. Original P1 baseline `42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847`; unchanged private v3 identity `{v['candidate_identity']}`; mechanics `439ae519201eb5f4b5d487edd407722cb7b9ee0df723db16455c9999ca52140a`. Closeout canonical identity `{v['canonical_identity']}`. Current-source drift is recorded by the runner; no overlapping candidate path conflict was found. No gameplay code was changed in this follow-up.

All first cases start from the exact legally earned Sports1112 release4 Studio/RNG envelope used by the prior study (cycle42, Reputation29.37, Investment0, cash$5,440.05). No traits, resources, cards, standing or state were injected. Every case uses normal commands, visible research quotes and the unchanged Feature-first policy with 5/7/6 Design/Alpha/Beta hands. New source-pinned outputs and profiles keep the original evidence intact.

## Root cause and legal preparation

The earlier owned playable Feature pool totaled **26 finite Scope**, all played in the miss. More hands cannot regenerate exhausted finite Features. Adding **Sprites (Scope2, Design)** and **General Combat (Scope2, Alpha)** to the prior Maps route supplies the missing four. The existing portfolio already meets their parents. Ownership is only supply; the new actual route separately proves all30 Scope were played.

Each of Maps, Sprites and General Combat cost $450 through actual two-part research payments and one productive research cycle: **$1,350 / three cycles total**, or **$900 / two cycles more than the Maps-only control**. Normal prior-title settlements and calendar/rent remained active during preparation. No discount, free grant or affordability override was used.

| First-delivery case | Commands | Final cycle | Scope | Review | Fee | New R/I |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Maps-only commissioned control | 33 | 62 | 26/30 | 6.4 | $5,199.60 | 0/0 |
| Expanded portfolio, commissioned | 35 | 64 | 30/30 | 7.8 | $6,000 | +15/+15 |
| Same expanded portfolio, self-owned | 34 | 64 | 30/30 | 7.8 | None | 0/0 |

The ownership pair matches exact initial state/RNG, production/review, raw launch sales, Fans and final RNG. Cash differs by exactly the full fee; both have no arrears. Comparing the portfolio intervention with the Maps-only control includes different spending/calendar exposure and is not a free-upgrade counterfactual. The old miss remains reproduced, not erased.

## Repeat completion, cold Continue and caps

The full-delivery Studio checkpoint cold-continues exactly into a second commission: 29 commands, cycle83, Scope30/30, Review8.6, $6,000 and another +15R/+15I. Its completed history persists alongside the first deal. The next exact Studio checkpoint continues through five more commissions under the same policy, with no further research or changed terms. **Commission6 misses at29/30 Scope, Review6.7:** it earns$5,799.60 and no standing. The original study stops at its declared seven commissions with R100/I90. Its two unsupported expectations (all seven full, both caps reached) remain in the original analysis.

To close the remaining Investment-cap coverage, the [separate follow-up plan]({rel}/FOLLOWUP-PLAN-v2.md) was recorded and announced before one further commissioned game, using the exact cycle178 Studio/RNG and unchanged policy. This explicitly adds one case and one replay; it does not rewrite or silently extend the original study. No seed, hand limit, portfolio or term changes were made. No further continuation was allowed under that follow-up plan.

{table}

At cycle{cap['cycle']}, eight commissions are retained: seven full deliveries and the unchanged29/30 miss, totaling ${sum(int(d['fee_cents']) for d in cap['commissions'])/100:,.2f} in fees. Both standing measures reach **100**. The final completion requests +15/+15 but credits **0 Reputation and10 Investment**, with no retroactive award for the earlier miss. Final cash is ${cap['cash_cents']/100:,.2f}; arrears are ${cap['arrears_cents']/100:,.2f}. This is a bounded legal witness, not a reward-rate or long-term balance approval. Publisher-owned raw title history remains available while Studio sales entitlement is excluded.

## Checks and retained limits

- Five original campaign cases completed within their limits: 33/35/34 first-batch commands, 29 second-completion commands, and {bounded['commands']} repeat-sequence commands. The separately predeclared follow-up used{cap['commands']} commands. No campaign rejection or timeout occurred. No source-capture retry was needed.
- Four fresh-process exact replays cover the full first delivery, second completion, seven-commission sequence and separate Investment-cap follow-up. Replay includes state/RNG and telemetry. All three cold starting envelopes equal their preceding complete final state/RNG.
- Typed completed-save audits check every commissioned source, full fee receipt, requested/credited standing, idempotent retries, publisher ownership, rejected altered/duplicate/missing award history and exact capture/hydrate. The first full settlement also passes37 existing corruption/source checks and13 observer/duplicate-launch checks.
- [Final actual-grade analysis]({rel}/analysis-complete-v2.json): {len(a['checks'])} invariant/acceptance checks, zero failures. The [original analysis]({rel}/analysis-complete.json) retains its two disproven route expectations; these were not gameplay formula failures. [Final source/evidence verification]({rel}/verification.json): {len(v['checks'])} checks, zero failures. The sealed v2 source packet still matches this unchanged candidate.
- **Retained harness failure:** the first new gate audit did not parse because a Variant return needed an explicit Dictionary annotation. Its original script/log remain; `gate_audit_v2.gd` changes only that annotation and passes in a fresh process. It was not a gameplay failure and produced no failed campaign command to reduce. Godot ObjectDB cleanup warnings remain in logs; leak-free teardown is not claimed.
- This is one Sports seed and one portfolio, not broad specialty accessibility. Sprites/General Combat are a demonstrated route, not new mandatory prerequisites. No old-save migration, graphical, human-comprehension, populated multi-Studio or exported acceptance is closed here.

## Exact commands and evidence

Python: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`. Run helper paths from `{rel}/`:

- `run.py first`, `run.py second`, `run.py caps`, `run.py recovery`: exact `tools/simulate.py run --variant ... --config ... --output ... --godot ... --timeout 600` invocations, exit codes and full outputs in [first]({rel}/first.command.json), [second]({rel}/second.command.json), [caps]({rel}/caps.command.json), [follow-up]({rel}/recovery.command.json).
- `checks.py first audit` (retained parse failure; other jobs pass), `checks.py first auditfixed`, `checks.py second audit`, `checks.py caps audit`, `checks.py recovery audit`: isolated focused checks against frozen source. Original and corrected harnesses retained; v3 checks each actual grade rather than assuming every delivery is full.
- `checks.py first replay`, `checks.py second replay`, `checks.py caps replay`, `checks.py recovery replay`: exact fresh replay commands in each stage's `*-replay/command.json`.
- `analyze.py first`, `analyze.py complete`, `analyze_v2.py complete`, `verify.py`: source-pinned results, paired checks, actual ordered cap reconstruction, retained-failure/hypothesis and sealed-handoff integrity checks.

Bundles: [first](sims/sidestreet-full-delivery-first-20261023-v1/run-report.json), [second](sims/sidestreet-full-delivery-second-20261023-v1/run-report.json), [caps](sims/sidestreet-full-delivery-caps-20261023-v1/run-report.json), [separate follow-up](sims/sidestreet-full-delivery-recovery-20261023-v1/run-report.json). Retain whole bundles, frozen projects, profiles, tapes and hashes for reproduction.

## Recommendation

Close the private full-delivery gate and proceed with the approved [adoption addendum](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md). PN Implementation must reproduce the route on reconciled canonical source and finish its existing transaction, migration, UI, ownership and export acceptance. Keep the terms and all earlier miss evidence. P4 support, broader tiers and balance remain OPEN.
'''
write(T/'SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md',finding)
addendum='''# SideStreet P2/P3 adoption addendum — v3

2026-10-23. **APPROVED bounded scope; HANDED OFF. Private Gate0 implemented and verified in the unchanged simulator candidate. Canonical implementation remains queued.**

This addendum supersedes only the “unproven legal full delivery / positive award / second completion” evidence status in [v2 adoption](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md). All approved terms and implementation tasks A–E remain. [New findings](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) prove legal full delivery, eight completed commissions including one retained miss, clipped R/I, saved source history and exact fresh-process replay.

## Exact delta and authority

**No new gameplay delta.** Adopt the original twelve paths from the [sealed v2 packet](handoffs/sidestreet-p2-p3-20261023-v2/HANDOFF.md), candidate `0d7276b32153e9184f25c4cacaa75e520a3119988af64262068741b245cb2567`, with the [approved trial terms](SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md). New artifacts are external experiment policies, legal campaign inputs, audits and evidence. Never replace current canonical source wholesale with the archived project.

## Gate0 result and reproduction acceptance

- **Implemented and verified privately:** legally earned Sports1112 release4 R29.37; research Maps, Sprites, General Combat for $450/one productive cycle each; prepare the same Sports/Fantasy project; quote required Scope30/Review6/$6,000; use5/7/6 hands under the visible Feature-first policy. Full delivery produces Scope30/30, Review7.8 and exact $6,000/+15R/+15I.
- **Implemented and verified privately:** cold Studio Continue into a second full commission (Review8.6), five further completions including a29/30 miss, and a separately predeclared one-commission Investment-cap follow-up. Both R/I caps reach100 with independent clipping and no duplicate receipt/award. Four fresh replays and typed corruption/observer checks pass. Preserve the Maps-only miss, repeated-delivery miss, partial/zero results and source-neutral audit failure. Full portfolio ownership does not guarantee all Features are played within finite hand limits.
- **Approved and handed off:** rerun the legal route against reconciled canonical mechanics. Preserve state/RNG checks; regenerate the legal prefix if gameplay/source compatibility changes. Do not copy checkpoints across incompatible revisions. Confirm actual fee/standing, prior histories, cap clipping and exact cold disk Continue on the adopted source.
- **Approved and handed off, still pending:** production transaction hardening, native Brief/quote/confirmation/results and owner-aware Finance, named current-P1 player/world migration, populated Founder/Studio isolation, exported acceptance and human comprehension as specified by v2 tasks A–E. The private proof does not close these categories.
- **Proposed/Open:** guidance about reachable Scope or portfolio readiness may improve clarity; the three researched Features are one proven route, not required contract gates. P4 support and broader publisher tiers remain OPEN. No price, score, reward or hand-limit change is proposed by this addendum.

## Evidence contract

The [original study plan](studies/sidestreet-full-delivery-20261023-v1/PLAN.md), [separate follow-up plan](studies/sidestreet-full-delivery-20261023-v1/FOLLOWUP-PLAN-v2.md), [actual-grade analysis](studies/sidestreet-full-delivery-20261023-v1/analysis-complete-v2.json), [verification and hashes](studies/sidestreet-full-delivery-20261023-v1/verification.json) and linked full bundles supplement the sealed v2 packet. The original failed hypotheses, sealed packet and earlier findings remain immutable. No commit, push, chat dispatch or canonical activation occurred in this follow-up.
'''
write(T/'SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md',addendum)
log=f'''# Contracts full-delivery gate session

2026-10-23, America/Los_Angeles. Branch main, HEAD `{v['head']}`; shared dirty worktree and `.codex-godot-temp` preserved. Canonical source closeout identity `{v['canonical_identity']}`; private candidate unchanged. No canonical gameplay, tests, assets or configuration edited; no commit, push or chat dispatch.

User authorized completing the remaining full-delivery gate. Read current state/TODO, local workflow, simulator usage/variants, publisher authority and relevant prior findings/source before work. [Predeclared plan]({rel}/PLAN.md), [actual results](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) and [adoption v3](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) retain exact commands, boundaries and recommendations.

Changed files: new `{rel}/` scripts/plans/configs/audits/results, five original campaign cases plus one explicitly predeclared follow-up in four new isolated bundles and four replay bundles; versioned findings/adoption, this log, thread README/HANDOFF; one narrow publisher TODO paragraph. All unrelated TODO bytes are preserved by the queue edit receipt. No old sealed artifact was edited.

Results: full30/30 Scope, first Review7.8 and second8.6, $6,000 and +15/+15 each before cap; eight total commissioned completions include seven full and one retained29/30 miss. Original study stopped at seven commissions with R100/I90; the separate one-case follow-up reaches both100 caps without changing terms/policy. Six campaign cases and four exact fresh replays PASS. Original analysis retains two unsupported expectations; final actual-grade analysis {len(a['checks'])}/0 failures and verification {len(v['checks'])}/0 failures. Extra legal preparation relative to Maps control: Sprites and General Combat, $900/two cycles. Maps-only control repeats26/30 miss. One audit type-inference parse failure retained and corrected only in a new harness revision; no campaign failure/timeout or gameplay repair. Cleanup warnings retained.

Follow-up: PN Implementation adopts/reconciles the existing delta and reruns source-compatible route, named migration, production atomicity, native/exported and multi-Studio acceptance. No unresolved private Gate0 design blocker remains. Broader accessibility, balance, P4 support and player comprehension remain open. This evidence does not activate canonical gameplay.
'''
write(T/'SESSION-LOG-2026-10-23-sidestreet-full-delivery-v1.md',log)
# Thread-owned summaries preserve historical sections.
for file,title,paragraph in [
('README.md','# Contracts design thread','**2026-10-23 SideStreet private Gate0 PASS.** [Full-delivery findings](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) and [adoption v3](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) supersede the earlier unproven-full-delivery status. Legal Store research supplies the missing Scope: first commission 30/30, Review 7.8, $6,000/+15R/+15I. Second completion and eight-commission history (including one miss and a separately planned cap follow-up) pass cold continuation and four fresh replays. Candidate code and approved values are unchanged. Canonical adoption/migration/UI/export remain queued; P4 remains OPEN.'),
('HANDOFF.md',None,'## 2026-10-23 full-delivery gate closure\n\n**Implemented and verified privately; approved adoption handed off:** [v3 addendum](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) and [new evidence](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) prove legal full delivery, positive R/I, repeat completion, clipping and cold continuation. No new gameplay delta; use the existing sealed v2 candidate. Canonical transaction, migration, UI, populated ownership and export acceptance remain PN Implementation work. Older unproven Gate0 statements below are historical.')]:
    p=T/file;s=p.read_text(encoding='utf-8');pos=s.index('\n')+1
    p.write_text(s[:pos]+'\n'+paragraph+'\n'+s[pos:],encoding='utf-8')
# Reread immediately before narrow shared edit; preserve all other bytes.
p=R/'docs/codex/TODO.md';before=p.read_bytes();s=before.decode('utf-8')
matches=[line for line in s.splitlines(keepends=True) if line.startswith('**2026-10-23 SideStreet P2/P3 —')]
assert len(matches)==1,'Reread concurrent queue status before adapting edit'
old=matches[0];new=old
needle='**Before activation, demonstrate a legal full-Scope/Review6 delivery, positive production +15R/+15I with caps/Continue, and a second commission completion.**'
assert needle in new,'Gate wording changed; review concurrent owner update'
new=new.replace(needle,'**Private Gate0 now PASS:** [v3 adoption addendum](threads/contracts/SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) and [full-delivery evidence](threads/contracts/SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) prove legal 30/30 Scope, Review 7.8, full $6,000/+15R/+15I, cold second completion and both caps across eight completions including one retained miss and a separately predeclared cap follow-up. Four fresh exact replays pass. Reproduce on reconciled canonical source and complete the existing migration/native/export/ownership acceptance before activation.',1)
new=new.replace('Current fixed routes verify','Earlier fixed routes verify',1).replace('none earns a full award.','those earlier routes earned no full award; the new legal portfolio closes that evidence gap.',1)
assert new!=old and p.read_bytes()==before,'TODO changed during narrow edit'
after=s.replace(old,new,1).encode('utf-8')
assert after.decode('utf-8').replace(new,old,1).encode('utf-8')==before
p.write_bytes(after)
write(H/'queue-edit.json',json.dumps(dict(before_sha256=hashlib.sha256(before).hexdigest(),after_sha256=hashlib.sha256(after).hexdigest(),before=old,after=new,unrelated_bytes_preserved=True),indent=2))
print('Findings, adoption addendum, session log and narrow TODO update written; private Gate0 closed.')
