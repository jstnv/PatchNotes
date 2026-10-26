# P1-backed SideStreet commission implementation and experiment plan

> Execute inline using the executing-plans workflow. User-owned variant isolation replaces a worktree; no commits. A fresh-context source review follows the bounded checks.

Goal: test the approved first commission against P1's event ledger and a legally earned Reputation gate, preserving baseline saves/source and avoiding parallel standing storage.

Spec: [bounded approval](../../SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md) and [terms/acceptance](../../SIDESTREET-P2-AND-FIRST-COMMISSION-PROPOSAL-2026-10-23-v1.md).

Architecture: fork `sidestreet-p1-gate-v1` with `simulator_variant.py create` as Contracts-owned `sidestreet-commission-p1-v1`. Retain current canonical baseline/ancestry. Pure commission rules grade frozen project terms; RunState owns binding, once-only settlement and P1 events. Raw title sales stay intact; financial entitlement filters publisher-owned titles. Typed completed-deal saves validate both source events and aggregate sales rights. Native presentation and named canonical predecessor migration remain adoption work.

## Tasks and files

- [ ] Existing behavior/API RED: use the prior frozen P1-backed campaign source and a focused probe requiring a commission quote API; record the expected missing API without activating rewards. Recheck canonical/source identities.
- [ ] Add `scripts/contracts/publisher_commission_trial.gd`: strict frozen terms, exact integer grade, result/source validation and rights-to-finance validation. Modify private `publisher_relationship_rules.gd` to resolve commission completion from committed results/receipts via P1.
- [ ] Modify private RunState: code-owned quote for explicit prepared project name/Genre/Theme; bound deal before BeginProject cycle notifications; preplan release fee/standing; commit coherent release rights, finance, Fans, Promotion and result before signals. Reject bad quotes/stale states without side effects. No new parallel Reputation/Investment fields.
- [ ] Modify private BeginProject/CampaignSession adapters: expose detached quote requests; atomic binding to the exact chosen project; preserve Studio-only Continue and source/RNG compatibility. Frozen terms include selected setup.
- [ ] Modify private checkpoint schema/adapter and per-title report: serialize completed commission source, reconstruct awards, validate fees and aggregate Studio earned/settled excluding publisher-owned streams. Disclose raw versus Studio entitlement. Do not claim native UI or old-save migration.
- [ ] Run bounded legal campaigns and focused rejection/roundtrip/observer checks; retain failures and create a new variant revision for source repairs after a run. At most three candidate revisions before reporting an unresolved blocker. Source-neutral harness corrections use new output folders and preserve original failures.
- [ ] Fresh-context review, source-pinned findings, sealed adoption handoff, minimal TODO update after rereading. QUEUED only approved bounded scope with unresolved acceptance explicitly listed; no canonical activation claim.

## Predeclared experiments

Hypotheses: a legally earned R20 can bind a commission; longer production can fully deliver while short production underdelivers; a flat launch fee trades early liquidity for all subsequent Studio title sales; source-derived P1 awards cannot be replayed or forged.

Use legal fresh Sports1112 and Action1108, no traits, the previous balanced visible-card Brief policy and stop at R20. First game3/5/4 hands; later2/2/2 through four releases. Only granted starter Features, no injected money/cards/standing. Two prefixes, max200 commands each,600second process cap. Current Sports roster already contains Levels; Maps research is attempted through actual visible legal quotes only if absent. Preserve any inaccessible or unaffordable result.

From the new revision's entire Sports1112 Studio prefix: same exact state/RNG long-production commission versus self-owned control,5/7/6 hands; Maps ownership/research policy identical in both. Target5 total releases, max180 commands. From Action1108's exact Studio prefix: short2/2/2 commission and medium3/4/3 commission, target5/max180. These are predeclared policy cases, not seed/hand-budget retries to force success. A miss remains a miss.

Continue each completed long-production arm from its own unchanged source-pinned Studio checkpoint to release6 using2/2/2 hands, max100 commands, to observe actual title earning/settlement and cold restore. Starting states then intentionally differ due to prior ownership/fee; report that distinction.

Total maximum8 campaign cases:2prefix,4delivery,2continuation. At most two concurrent processes, each600seconds. Replay the long ownership pair and short miss in fresh isolated processes; additional focused observer replay only if needed to test publication atomicity. Baseline API probe and focused arithmetic/rejection/save tests are not campaign accessibility samples.

Measure commands/cycles, exact initial state/RNG equality for the paired intervention, complete prefix before ownership divergence, cash/fees, delivered/required Scope and Review, R/I requested/credited events, raw units/entitlement/settlement, Studio earned/settled and Bank inputs, Fans, rent/arrears, post-launch campaign exclusion, checkpoint hashes and replays. Include constructed fee cases6.0/full=$6000,5.0/full=$3000,5.9/full=$5700,4.0=$0 and partial Scope. No formula/seed/budget changes based on favorable outcomes.

Stop on an unchanged blocker after three candidate versions, source-capture drift (retain and one fresh-folder retry),10GiB free-space floor,600seconds per process or command limits. Failure reduction applies to recorded command failures; native/fixture setup failures have no campaign command to reduce. No computer control, player saves, canonical gameplay/config/tests/assets, commit or push.

## Review focus

1. Quote request must not advance RNG/serials or bind a different prepared project.
2. Observers cannot see fee without rights/standing or reenter during begin/release publication.
3. A duplicate launch cannot duplicate fee/standing; a zero fee cannot accidentally award trust.
4. Save edits cannot relabel publisher raw sales as Studio/Bank receipts or detach a ledger event from its source.
5. Repeat completed offers and cap clipping cannot invalidate prior events; no fabricated support eligibility promise.

## Execution closeout — 2026-10-23

All seven work packages above have been performed through the private v3 candidate and versioned v2 adoption packet. The original checklist and limits are retained as the pre-run plan; the [revision ledger](REVISION-LEDGER.md) records the explicit case-budget changes, repairs and source-capture stop/reopening.

- PASS: existing-behavior RED retained; private rules, RunState, adapters and typed persistence built; independent review fixes verified; twelve bounded campaign cases and five exact fresh-process replays completed.
- PASS at declared scope: partial/zero settlement, observer coherence, completed saves, later publisher/Studio sales separation and frozen quote behavior.
- NOT SUPPORTED: the planned long route did not fully deliver. Scope was 26/30 at Review 6.4. No current-source legal positive Reputation/Investment award is claimed.
- PENDING adoption acceptance: legal full delivery and positive production award, a second commission completion, production transaction hardening, named P1 player/world migration, populated ownership checks and native/exported acceptance.

See [v2 findings](../../SIDESTREET-P2-P3-FINDINGS-2026-10-23-v2.md), [v2 adoption](../../SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md), `verification-complete.json` and `queue-edit.json` for final evidence and the narrow shared-queue update. No canonical gameplay changes, commit or push were performed by this study.
