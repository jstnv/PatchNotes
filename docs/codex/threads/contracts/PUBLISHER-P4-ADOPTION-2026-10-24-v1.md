# SideStreet P4 support pilot — approval and adoption v1

**Canonical implementation reconciliation,2026-10-24: COMPLETE locally at this approved bounded trial scope.** P2/P3 actual EXE acceptance completed first. [Source, R2–R5 acceptance, retained failures and remaining human/device/balance limits](../../findings/publisher-p4-20261024-v1/README.md), [dated closeout](../../logs/2026-10-24-publisher-p4-closeout-v1.md). The original approval/handed-off statuses below retain their intake context; no broader publisher/tier or default rival policy approval is inferred.

2026-10-24. **APPROVED bounded trial; handed off through TODO after current SideStreet P2/P3 acceptance. Canonical implementation and activation pending.**

## Authority and scope

Direct user ruling: “I approve the P4 pilot. Go ahead and queue it for PN Implementation after the current SideStreet work.”

This approves the SideStreet support package and earned-result renewal in the [review handoff](PUBLISHER-SUPPORT-RENEWAL-HANDOFF-2026-10-23-v1.md), [renewal design](PUBLISHER-SUPPORT-RENEWAL-DESIGN-2026-10-23-v1.md) and its referenced support/finance specifications. It supersedes their PROPOSED labels only for this bounded P4 slice. Historical documents and the sealed packet retain their original status at capture. Approval comes from the user, not simulation outcomes. Values are approved trial terms, not final balance locks or a claim that canonical P4 is active.

## Approved package

- SideStreet support is offered for a Studio-owned game at Investment >=15, subject to existing publisher unlock and legal project/start checks. One game deal per project; no retrospective or mid-project support.
- Quote against the pre-start Studio snapshot. Store Investment in hundredths. Budget in cents is `min(300000, 50000 + 2500 * floor(investment_bp / 100))`. Nominal cash is `floor(budget * 8000 / 10000)`; marketing Awareness points are `floor((budget - nominal_cash) / 3500)`; actual funding is `budget - 3500 * marketing_points`. Thus I15 quotes $700 funding and 5 marketing points within an $875 budget; I25 quotes $915 and 6 within $1,125.
- Funding commits once with the productive project start; marketing applies once at launch. Funding is nonoperating cash, not sales, profit or Bank underwriting income. Funding may make a start affordable, but the whole funded-start transaction must be planned and committed atomically.
- Assess frozen Review >=7.0 AND actual cumulative units >=1,000 at the sixth earning cycle. Success grants +10 Investment, clipped at100, while retaining a qualifying committed success even at zero credited gain. Misses grant zero new Investment; no debt, funding clawback or standing loss.
- Studio retains ownership. Publisher recoup is 20% of that title's cumulative raw net, floored in cents and capped at the full frozen budget, through earning age24. Preserve cumulative accounting and settlement timing. Unrecouped balance is written off; no claim on other titles or later earnings.

## Approved renewal

First support has empty prior-support and qualification IDs. For later offers, the latest supported title must have launched and its assessment must be committed; current Investment remains >=15 and a later Studio-developed release must exist after the previous acceptance (the supported title suffices).

Require a new qualifying result committed after previous acceptance: passed support assessment or full same-publisher commission. Briefs, partial commissions, ordinary releases and other publishers do not qualify. Choose the earliest valid event using canonical P1 ordinals. Freeze `previous_support_id` and `qualification_event_id`. A full commission earned while the old assessment is unresolved may qualify once assessment finishes. Acceptance advances the boundary; earlier extra successes do not become banked offers. Preview, Back and rejected/stale confirmations preserve eligibility. Start-cycle outcomes cannot retroactively qualify or improve the accepted quote. Allow cap100 success; a cap-level miss alone does not qualify. Permit old-title recoup alongside a new deal, but only one unresolved assessment per Studio/publisher.

## Execution order and acceptance

**Dependency:** finish the current [SideStreet P2/P3 adoption](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) and its canonical acceptance gates first. The latest [implementation ledger](../../logs/2026-10-23-sidestreet-p2-p3-plan-v1.md) still records final-source work in progress. Do not interrupt or combine that source freeze with P4. Re-read current state/TODO/source at intake; maintain one overlapping canonical gameplay implementation.

| Item | Status | Work and acceptance |
| --- | --- | --- |
| R0 historical private study | **implemented and verified privately** | Retain [findings](PUBLISHER-SUPPORT-RENEWAL-FINDINGS-2026-10-23-v1.md) and failures; these do not establish current canonical acceptance. |
| R1 bounded P4 ruling | **approved** | This explicit user decision covers the package and renewal above. |
| R2 event/transaction integration | **handed off — approved scope** | Implement against current Studio-owned P1 events/ordinals and accepted P2/P3. Freeze all terms before start, publish coherent observers only after commit, and reject stale/unaffordable starts without state/RNG/finance mutations. |
| R3 durable repeated history | **handed off — approved scope** | Preserve every deal, assessment and title-rights row; reconstruct Investment at each acceptance and exact funding/action history. Reject forged/reordered/reused events, changed outcomes, duplicate/missing funding and inconsistent rights atomically, retaining the last valid disk generation. |
| R4 current-source adoption | **handed off — approved scope** | Regenerate legal prefixes on reconciled mechanics. Prove first support success -> second support miss -> full commission -> third support, with exact fresh-process saved-state/RNG replays. Verify named predecessor migration without retroactive deals/awards; populated Studio/Founder/active-rival isolation; actual disk Continue; owner-aware Finance; playable quote/Back/confirm/result/availability UI; both supported sizes and exported behavior. |
| R5 edge coverage | **handed off — approved scope** | Cover Review-only/units-only misses; cap success and miss (label constructed fixtures); positive earnings at age23/24/25 and settlement boundaries; funding-rescued due-bill start and still-unaffordable rejection. Record human-comprehension acceptance separately; automation cannot claim it. |

Preserve existing cash Contracts/challenges and approved P2/P3 behavior. Broader publishers/tiers, P5, exclusivity, deadlines, standing losses and final balance remain OPEN.

## Source and evidence boundary

Queue inspection: branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree. HEAD alone does not identify current gameplay. PN Implementation must capture its post-P2/P3 source before adapting P4.

The [sealed historical packet](handoffs/publisher-support-renewal-20261023-v1/HANDOFF.md) remains immutable. Its candidate manifest is `c83714a675a200344418140475c13d5199844750fcd1ecfe6bfcb84ff62d5194`; mechanics `d7508cf9337ebb247a1b88f9874bddacf5180891335b89db5b231c32714347e5`. Use the [five-path parent-relative delta](studies/publisher-renewal-20261023-v1/scoped-delta.patch) as a reference, together with inherited support mechanics. The complete packet contains48 inherited changes and nine conflicts at its captured canonical source; re-evaluate current drift and do not transplant it wholesale. The old scalar relationships and starter pool must not replace canonical P1/P2/P3.

Historical evidence:297 accepted candidate commands,166 focused checks,95 analysis checks and fresh replays. Six durable Studio envelope/RNG boundaries match; raw historical replay sessions differ at unsaved market scratch. Cap evidence is constructed and current pacing untested. Retain failures and compatibility checks; no identity bypass. This approval/queue update runs no new gameplay checks and establishes no implementation, export, commit, push or release-readiness result.
