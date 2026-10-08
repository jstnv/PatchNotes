# Promotion magnitude and timing sensitivity — read-only findings

2026-10-07, America/Los_Angeles. **Analysis complete; numerical caps remain candidates.** This is a narrow follow-up to [Task 34](../FINDINGS-v3-task34-advances.md), not a gameplay change or a new rule approval.

## Source, setup and assumptions

The exact gameplay source is isolated main `b84d1a5b4e4957b044b4b52c41553cf611aff3ae` in the existing Task 34 copied project. Its [source manifest](../sim-v3/source-manifest.json) lists 1,046 copied project files. The independent audit rechecked 1,045 unchanged files against that manifest; the excluded original analysis file is Task 34's declared preparation hook. Both Task 34 Contract/continuation harnesses and the two typed native captures matched their predeclared SHA-256 hashes. [Predeclaration](PREDECLARATION.md), [runner](run.py), [native sweep](promotion_sweep.gd), [raw Crown result](crown.json), [raw Neon result](neon.json) and [independent audit](audit.json) reproduce the work.

Two previously legal legacy-$5,500 Action/ordinary routes were fixed before this sweep: Crown after the first Review 7.0 release and Neon after the first frozen Awareness 129 release. Each route also supplies a legal after-Game-4 checkpoint. Crown uses its same two successful native hands at Scope target 9, ordinary choice, seed `200929001`, candidate $150 advance and $1,920 total direct cash. Its completion fraction is 594/594. Neon uses target 10, ordinary choice, seed `200929000`, $0 advance and $1,487.44 direct cash; its fraction is 820/860. Candidate hand choice, direct cash, rent, credit, original production actions and later launch timing stay fixed within each cap comparison.

The only varied input is the conditional Promotion cap: Crown `0/6/12/18` and Neon `0/10/20/30` Awareness points. Actual award is `floor(cap × completion fraction)`. The award is applied once to the next successful launch's frozen Awareness in the Task 34 analysis layer; native month-one units, per-title earnings, settlement and finance planners then run across the recorded action suffix. Cap 0 is the same-Contract **cash-only** control. No projected Game 5 sales were credited.

## Early acceptance: next launch and realized settlement

Amounts below are incremental to the same Contract with cap 0, at the route's observed end (Crown cycle 88; Neon cycle 89). End cash rose by exactly the incremental settled amount in these runs; arrears and credit remained identical across cap arms.

| Publisher | Candidate cap | Awarded | Next launch cycle | Launch Awareness | Month-one units | Extra earned | Extra settled |
|---|---:|---:|---:|---:|---:|---:|---:|
| Crown | 0 | 0 | 52 | 111 | 677 | $0 | $0 |
| Crown | 6 | 6 | 52 | 117 | 690 | $195.81 | $195.81 |
| Crown | 12 | 12 | 52 | 123 | 703 | $405.60 | $405.60 |
| Crown | 18 | 18 | 52 | 129 | 716 | $601.40 | $601.40 |
| Neon | 0 | 0 | 53 | 111 | 677 | $0 | $0 |
| Neon | 10 | 9 | 53 | 120 | 697 | $307.69 | $307.69 |
| Neon | 20 | 19 | 53 | 130 | 718 | $629.37 | $629.37 |
| Neon | 30 | 28 | 53 | 139 | 738 | $937.06 | $937.06 |

The current candidate caps, 12/20, exactly reproduce Task 34's same-route awards and settled deltas. In this narrow route pair, raising Crown from 12 to 18 adds another $195.80 by the horizon; raising Neon from 20 to 30 adds $307.69. Both are later sales receipts, not acceptance liquidity. The comparison measures deterministic magnitude on these hands; it does not identify an optimal cap.

## After Game 4: launch is visible, earnings are censored

Both later Contracts complete and consume their Promotion on the next successful **Game 5 launch** (Crown cycle 88; Neon cycle 89). At that very launch, Crown month-one units move `967/986/1005/1025` across caps `0/6/12/18`; Neon units move `967/996/1028/1057` across `0/10/20/30`. The recorded native route ends at launch, before Game 5 has a productive earning cycle. Thus **extra earned, extra settled and extra cash are all $0** for every after-Game-4 cap at the observed horizon. The new units show a potential future sales effect only; they are not spendable money here. No additional action or earning cycle was invented to extend the route.

## Cross-publisher eligibility interaction

The pinned `RunState` refreshes publisher unlocks after registering a release, using its frozen review snapshot; Neon requires that snapshot's Awareness to be at least 125. Crown's early checkpoint has Neon still locked. Under the future design direction that Promotion enters committed launch Awareness, the next launch would reach Awareness **123 at Crown cap 12** and **129 at cap 18**. The latter crosses Neon's unlock gate, while 0/6/12 do not. The after-Game-4 Crown launch reaches at most 120, so it never crosses in this sweep.

On this one full-completion Crown hand, cap 14 would be the first integer cap that reaches 125 (111 + 14). That threshold is an arithmetic inference between tested caps, not another simulated arm.

This is a **conditional rule interaction**, not an observed unlock or offer. The analysis layer recalculated a sales record; it did not mutate `RunState` release metadata or create Crown/Neon offers. A future implementation must verify that Promotion is present in the same committed Awareness snapshot used by publisher unlocks and that a first-unlock Neon offer is issued exactly once. Neon was already unlocked before its own selected route, so its next-launch 125 crossings do not create a new Neon unlock in this study.

## Checks, limits and recommendation

Both Godot runs exited 0 with **1,600 native checks each**, no failures. The independent [audit](audit.json) passed **1,205 checks**, including copied-source hashes, capture and harness identity, legal fixed hands, exact award floors, same accepted action calendars, once-only consumption, complete native finance replay, the Task 34 current-cap parity and frozen Neon gate interpretation. [Summary CSV](summary.csv) contains all 16 cap/timing observations in exact cents. The Godot root-certificate and case-path warnings in [Crown](crown.log) and [Neon](neon.log) logs did not fail these headless runs; they are unrelated to a visual/export acceptance gate.

The sample is two deterministic routes, one draw seed and hand policy per publisher, and a fixed action suffix. It excludes player adaptation, multiple pending or stacked Promotions, failed-launch preservation, post-Game-5 earnings and later Fanbase effects. The pinned source predates other uncommitted economy work in the shared worktree. Cross-publisher threshold value could be much larger than the observed sales delta, but this sweep does not quantify it.

**Recommendation:** retain 12 Crown / 20 Neon as the *center of a bounded pilot candidate*, with the accepted one-shot next-successful-launch direction. Do not numerically lock or implement from this sweep alone. Keep Crown 18 and Neon 30 as sensitivity arms; Crown 18 specifically requires an explicit cross-publisher unlock decision and test. Before a final amount ruling, observe at least one legal post-Game-5 earning/settlement window and test the Promotion-to-committed-Awareness unlock path on an approved implementation. No value is marked approved here.
