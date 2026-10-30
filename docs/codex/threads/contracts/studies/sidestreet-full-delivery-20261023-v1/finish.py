from pathlib import Path
import json,hashlib,re,subprocess
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
def read(p):return json.loads(p.read_text())
def write(p,s):
    with p.open('x',encoding='utf-8',newline='\n') as f:f.write(s)
v=read(H/'verification.json');a=read(H/'analysis-complete-v4.json')
assert v['failures']==a['failures']==0
last=a['rows'][-1];final=last['commissions'][-1]
assert last['standing_bp']=={'reputation':10000,'investment':10000}
rel='studies/sidestreet-full-delivery-20261023-v1'
table='| Commission | Scope | Review | Fee | Credited Reputation | Credited Investment |\n| --- | ---: | ---: | ---: | ---: | ---: |\n'
for i,d in enumerate(last['commissions'],1):
    table+=f"| {i} | {d['scope']}/{d['required']} | {int(d['review_tenths'])/10:.1f} | ${int(d['fee_cents'])/100:,.2f} | {int(d['credited_rep'])/100:.2f} | {int(d['credited_inv'])/100:.2f} |\n"
finding=f'''# SideStreet full-delivery gate — findings v1

2026-10-23, America/Los_Angeles. **Private Gate0 PASS:** legal full delivery, positive production R/I, second completion, both actual production caps, cold continuation and exact replay. Canonical adoption, migration, native/exported UI and populated ownership acceptance remain pending. No balance or gameplay-rule changes.

## Authority and source

User authorized completing the remaining gate. [Approved trial terms](SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md) remain unchanged. Branch `main`, HEAD `{v['head']}`; shared dirty worktree preserved. Original P1 baseline `42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847`; unchanged private v3 candidate `{v['candidate_identity']}`; mechanics `439ae519201eb5f4b5d487edd407722cb7b9ee0df723db16455c9999ca52140a`. Closeout canonical identity `{v['canonical_identity']}`; no conflicting candidate path found. No gameplay code was changed in this follow-up.

## Plans, legal starts and boundaries

Three separately predeclared stages preserve their own limits and all misses:

1. [Original study]({rel}/PLAN.md): same legal Sports1112 release4 Studio/RNG (cycle42, cash$5,440.05, R29.37/I0, no traits); Maps-only commission versus expanded-portfolio commission/self-owned control, then cold second completion and five further commissions. Feature-first5/7/6 hands. Five cases total;180 commands/first or second case,400/repeat sequence; stop at seven total commissions even if caps are unreached.
2. [One-case same-policy follow-up]({rel}/FOLLOWUP-PLAN-v2.md): explicitly announced new case from exact cycle178 Studio/RNG, unchanged5/7/6 policy, no purchases,180commands to release12. Stop after that case even on a miss.
3. [Separate production-time experiment]({rel}/READINESS-PLAN-v3.md): after both earlier stages stopped, explicitly announced **10/10/10 hands** from exact cycle197 Studio/RNG, same portfolio/terms,180commands to release13. One case and one replay only. This changes player effort, not gameplay rules, and is not a matched policy/balance comparison.

All processes/imports have600second limits, at most two concurrent processes and a10GiB disk floor. New unique outputs/profiles; no arbitrary grants, seed swaps, player saves or checkpoint identity edits. Research uses normal visible quotes and actual costs/cycles. Source/RNG compatibility and Studio-only Continue remain enforced. All three stage stopping conditions were honored; no outcomes were rewritten.

Legal starting provenance: [original current-source prefix](sims/sidestreet-commission-p1-prefix-20261023-v3/run-report.json), whose complete source-compatible Studio envelope is copied unchanged into the first cases. Earlier prefix tapes/replays remain retained in that study.

## Full delivery and repeat completion

The earlier playable owned pool totaled **26 finite Scope**, all played in the miss. Sprites (Design, Scope2) and General Combat (Alpha, Scope2) supply the missing four; their parents were already owned. Actual delivery, not ownership alone, establishes completion.

Maps, Sprites and General Combat each cost **$450 / one productive research cycle**. Total preparation: **$1,350 / three cycles**; relative to the Maps-only control, **+$900 / two cycles**. Normal affordability, rent and prior-title settlements remain active.

| First case | Commands | Cycle | Scope | Review | Fee | New R/I |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Maps-only commissioned control |33|62|26/30|6.4|$5,199.60|0/0|
| Expanded portfolio, commissioned |35|64|30/30|7.8|$6,000|+15/+15|
| Same expanded portfolio, self-owned |34|64|30/30|7.8|None|0/0|

The ownership pair matches exact initial state/RNG, production/review, raw launch sales, Fans and final RNG. Its cash/arrears difference equals the full fee. Comparing expanded versus Maps-only portfolios includes different costs/calendar exposure. The original miss repeats and remains evidence.

Cold Continue into the **second commission** preserves the complete prior final state/RNG:29commands, cycle83, **30/30 Scope, Review8.6, another$6,000 and +15/+15**. Both completed sources persist; duplicate event retries change no fee, standing, state or RNG.

## Caps, misses and the final witness

The original repeat sequence finishes at cycle178/release11 in149commands, with R100/I90. Commission6 misses29/30 Scope and correctly earns$5,799.60/no standing. The original study stops; its two unsupported hypotheses (all seven full, both caps reached) remain in `analysis-complete.json`.

The separately predeclared same-policy follow-up also misses:29/30 Scope, Review5.7, $5,100/no standing,31commands to cycle197. It stops as planned; its two unmet cap expectations remain in `analysis-complete-v2.json`. Full portfolio ownership does not guarantee every Feature is played under fixed short hand budgets.

The separate10/10/10 production-time route then finishes in **{last['commands']}commands at cycle{last['cycle']}**, delivering **{final['scope']}/{final['required']} Scope, Review{int(final['review_tenths'])/10:.1f}, $6,000**. Its trusted production event requests **+15R/+15I** and credits **0R/+10I**, bringing both measures to100. No historical fee/award is changed and neither miss gains retroactive standing.

{table}

Nine commissioned completions contain seven full deliveries and two retained misses. Final cash is **${last['cash_cents']/100:,.2f}**, arrears **${last['arrears_cents']/100:,.2f}**. This is a legal reachability witness, not approval of its effort, profitability or pacing. The final policy uses more time; it must not be portrayed as a5/7/6 success or a matched estimate of improvement. Sprites/General Combat are a demonstrated route, not new contract prerequisites.

## Verification and retained failures

- Seven campaign cases across five bundles complete within their declared bounds; no gameplay rejection, process timeout or source-capture retry. Five exact fresh-process replays cover first full delivery, second completion, repeat history, same-policy miss and final production-time witness. Telemetry, final state/RNG and all four cold starting boundaries match.
- Completed-source audits verify actual proportional grades, one fee receipt and one event per commission, independent clipping, no-op retries, publisher-owned sales exclusion, exact typed save/hydrate and rejection of altered/duplicate/missing award history. The first full launch additionally passes37 strict-source checks and13 observer/duplicate-launch checks. The final audit verifies both actual capped production credits.
- Focused P1 ledger fixtures also test independent caps and zero credit at cap. They remain explicitly distinct from legal production and cannot enter its resolver.
- [Final actual-grade analysis]({rel}/analysis-complete-v4.json): **{len(a['checks'])} checks /0 invariant failures**. [Source/evidence verification]({rel}/verification.json): **{len(v['checks'])} checks /0 failures**. The original failed hypotheses remain separately recorded. The sealed v2 source packet still matches this unchanged candidate.
- Initial source-neutral audit parse failure retained in `first-audit/gate.log` and original `gate_audit.gd`; no assertions executed there. V2 fixes only a type annotation. Later audit versions check actual grades instead of assuming all deliveries are full. All versions and failed expectations remain. No failed gameplay tape required reduction. Godot cleanup warnings remain; leak-free teardown is not claimed.

## Exact commands and evidence

Python: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`. Helpers are under `{rel}/`.

`run.py first`, `second`, `caps`, `recovery`, `readiness` record full `tools/simulate.py run --variant ... --config ... --output ... --godot ... --timeout 600` arguments, exits and outputs in their stage `*.command.json`. `checks.py <stage> replay` records exact fresh replay commands in stage replay folders. Focused commands: `checks.py first audit` (parse failure retained; other jobs pass), `first auditfixed`, `second audit`, `caps audit`, `recovery audit`, `readiness audit`. The caps audit includes the maintained P1 verifier. Analysis revisions1–4, `verify.py` and [execution record]({rel}/EXECUTION.md) preserve original hypotheses and later coverage separately.

Reports: [first](sims/sidestreet-full-delivery-first-20261023-v1/run-report.json), [second](sims/sidestreet-full-delivery-second-20261023-v1/run-report.json), [repeat](sims/sidestreet-full-delivery-caps-20261023-v1/run-report.json), [same-policy follow-up](sims/sidestreet-full-delivery-recovery-20261023-v1/run-report.json), [production-time witness](sims/sidestreet-full-delivery-readiness-20261023-v1/run-report.json). Retain complete frozen bundles/tapes/profiles/manifests.

## Recommendation and limitations

Close the private Gate0 evidence gap and proceed with the [v3 adoption addendum](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md). Keep all approved terms. PN Implementation must reproduce the source-compatible full/repeat/cap witness on reconciled canonical source and finish transaction hardening, named migration, native/exported UI and populated ownership acceptance. This one Sports seed does not establish broad accessibility, human comprehension or final balance. P4 and broader tiers remain OPEN. No canonical activation, commit or push is claimed.
'''
write(T/'SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md',finding)
handoff='''# SideStreet P2/P3 adoption addendum — v3

2026-10-23. **APPROVED bounded scope; HANDED OFF. Private Gate0 implemented and verified. Canonical implementation/activation acceptance remains pending.**

## Exact delta and authority

No new gameplay delta or value change. Adopt the original twelve paths in the [sealed v2 packet](handoffs/sidestreet-p2-p3-20261023-v2/HANDOFF.md), candidate `0d7276b32153e9184f25c4cacaa75e520a3119988af64262068741b245cb2567`, under the [approved trial terms](SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md). This addendum supersedes only the unproven private Gate0 evidence status in [v2 adoption](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md); all tasks A–E remain. Reconcile current source; never replace it wholesale from the archived project.

## Verified evidence and remaining tasks

- **Implemented and verified privately:** legal Sports1112 release4 R29.37; Maps/Sprites/General Combat research at$450/one productive cycle each; ordinary Sports/Fantasy preparation; frozen Scope30/Review6/$6,000 quote; Feature-first5/7/6 yields30/30, Review7.8, exact$6,000/+15R/+15I. Cold second completion yields Review8.6. Saved source history, idempotence and actual Reputation clipping pass.
- **Implemented and verified privately:** original seven-commission study and one-case follow-up stop with retained misses/R100/I90. A separately predeclared10/10/10 production-time experiment legally reaches full delivery and credits0R/+10I from a requested15/15, reaching both100 caps. All prior records remain unchanged. Five fresh exact replays and focused source/save/observer/cap checks pass. Do not present the final result as the original shorter-policy outcome.
- **Approved and handed off:** reproduce full delivery, positive award, repeat completion and both caps on reconciled canonical mechanics. Regenerate legal prefixes if compatibility changes; preserve source/RNG fences and Studio-only Continue. Complete production transaction planning, named P1 player/world migration, native Brief/quote/confirmation/result and owner-aware Finance, populated Studio/Founder isolation, actual disk Continue and exported acceptance from v2 tasks A–E.
- **Proposed/Open:** guidance distinguishing owned Scope supply from actually played Scope may help players. The researched trio and final hand budget are evidence routes, not new prerequisites or recommended pacing. No price, target, reward or gameplay hand-limit change is approved. Broader accessibility, balance, human comprehension, P4 support and other tiers remain OPEN.

## Matching evidence

[Findings](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md), [original plan](studies/sidestreet-full-delivery-20261023-v1/PLAN.md), [same-policy follow-up](studies/sidestreet-full-delivery-20261023-v1/FOLLOWUP-PLAN-v2.md), [separate production-time plan](studies/sidestreet-full-delivery-20261023-v1/READINESS-PLAN-v3.md), [final actual-grade analysis](studies/sidestreet-full-delivery-20261023-v1/analysis-complete-v4.json), [verification/hashes](studies/sidestreet-full-delivery-20261023-v1/verification.json). Failed route expectations, audit parse failure, original sources and sealed packet remain intact. No commit, push, chat dispatch or canonical activation occurred.
'''
write(T/'SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md',handoff)
log=f'''# Contracts full-delivery gate session

2026-10-23, America/Los_Angeles. Branch main, HEAD `{v['head']}`; dirty worktree and `.codex-godot-temp` preserved. Canonical identity `{v['canonical_identity']}`. Private v3 unchanged. No canonical gameplay/tests/assets/configuration edit, commit, push or chat dispatch.

Read current state/TODO, local workflow, simulator usage/variants, publisher authority and relevant findings/source before work. User authorized completing the remaining gate. [Findings](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) and [handoff](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) retain exact commands/source identities, outcomes and acceptance boundaries. Three predeclared experiments preserve their separate stopping conditions; no prior seed, budget or result was silently changed.

Changed: new `{rel}/` study scripts/plans/configs/audits/results, five isolated run bundles (seven cases), five replay bundles, versioned findings/adoption, thread README/HANDOFF, this log and one narrow TODO paragraph. Queue edit receipt proves unrelated bytes preserved. Existing sealed artifacts remain intact.

PASS: legal full30/30 Scope Review7.8/$6,000/+15R/+15I, cold second full completion Review8.6, source/receipt/rights/history/observer/idempotence, both actual production caps, five fresh replays. Final actual-grade analysis {len(a['checks'])}/0 failures; final verification {len(v['checks'])}/0 failures. Final10/10/10 policy is an explicit reachability experiment, not changed gameplay or approved pacing.

Retained: Maps-only26/30 control; two29/30 misses under5/7/6; original/follow-up failed cap expectations; source-neutral audit parse failure and corrected harnesses; cleanup warnings. No campaign rejection/timeout. Both misses retain their proper partial fees and zero standing.

Private Gate0 is complete at recorded scope. Remaining work belongs to canonical adoption: reproduce on reconciled source, transaction hardening, named migration, native/exported flows, populated ownership and human comprehension. Broader accessibility/balance/P4 remain OPEN. No release-readiness claim.
'''
write(T/'SESSION-LOG-2026-10-23-sidestreet-full-delivery-v1.md',log)
for filename,paragraph in [
('README.md','**2026-10-23 SideStreet private Gate0 PASS.** [Findings](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) and [adoption v3](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) prove legal full delivery, positive R/I, cold second completion and both production caps. Earlier5/7/6 misses remain; the final cap witness uses a separately predeclared10/10/10 policy. Five fresh replays pass. Candidate gameplay and approved terms are unchanged. Canonical migration/UI/export/ownership acceptance remains queued; P4 stays OPEN.'),
('HANDOFF.md','## 2026-10-23 private Gate0 closure\n\n**Implemented and verified privately; approved adoption handed off:** [v3 addendum](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) closes full-delivery, positive-award, repeat-completion and actual cap evidence. Original shorter-policy misses remain; the final witness uses the separately recorded production-time experiment. No gameplay delta beyond the existing sealed v2 candidate. Canonical transaction/migration/native/export/populated ownership acceptance remains PN Implementation work.')]:
    p=T/filename;s=p.read_text(encoding='utf-8');pos=s.index('\n')+1;p.write_text(s[:pos]+'\n'+paragraph+'\n'+s[pos:],encoding='utf-8')
# Reread shared TODO immediately before minimal mutation.
p=R/'docs/codex/TODO.md';before=p.read_bytes();s=before.decode('utf-8')
matches=[x for x in s.splitlines(keepends=True) if x.startswith('**2026-10-23 SideStreet P2/P3 —')]
assert len(matches)==1,'Review concurrent queue change'
old=matches[0];needle='**Before activation, demonstrate a legal full-Scope/Review6 delivery, positive production +15R/+15I with caps/Continue, and a second commission completion.**'
assert needle in old,'Review changed gate wording before editing'
new=old.replace(needle,'**Private Gate0 now PASS:** [v3 adoption addendum](threads/contracts/SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) and [full/repeat/cap findings](threads/contracts/SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) prove legal30/30 Scope, Review7.8, full$6,000/+15R/+15I, cold second completion and both actual production caps. The original shorter-policy misses remain; the final cap witness uses a separately predeclared10/10/10 production policy. Five fresh exact replays pass. Reproduce on reconciled canonical source and finish existing transaction/migration/native/export/populated ownership acceptance before activation.',1)
new=new.replace('Current fixed routes verify','Earlier fixed routes verify',1).replace('none earns a full award.','those earlier routes earned no full award; new legal routes close that evidence gap.',1)
assert p.read_bytes()==before,'TODO changed during narrow edit'
after=s.replace(old,new,1).encode('utf-8');assert after.decode('utf-8').replace(new,old,1).encode('utf-8')==before;p.write_bytes(after)
write(H/'queue-edit.json',json.dumps(dict(before_sha256=hashlib.sha256(before).hexdigest(),after_sha256=hashlib.sha256(after).hexdigest(),before=old,after=new,unrelated_bytes_preserved=True),indent=2))
print('Recorded private Gate0 PASS and updated only its TODO paragraph; canonical acceptance stays pending.')
