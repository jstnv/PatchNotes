# SideStreet Reputation Brief accessibility and pacing — findings v1

2026-10-23 (America/Los_Angeles). **PROPOSED P2 design evidence; bounded headless study complete.** P1 is separately approved and undergoing canonical adoption. No P2 rule, award, gate or balance is approved by these simulations.

## Recommendation

Retain the existing candidate two-hand promise for a bounded trial: full completion at Scope10 / each Core3, no redraw, full promise through Scope10, half at11, zero at12+. Keep useful partial Reputation and release-paced opportunities. The [proposed recommendation](SIDESTREET-REPUTATION-BRIEF-RECOMMENDATION-2026-10-23-v1.md) explains the player loop, exact candidate R10 formula, proposed R20 access and remaining approval/integration gates.

The useful progression target is **two excellent briefs or three graded briefs**, not two compulsory perfect results. In this screen, every take route reached R20 by its third opportunity. A softer Scope8 target increased full-result counts in shadow arithmetic but did not improve three-opportunity access. The more material concern is the cost of Reputation-only work and the value/visibility of the eventual commissioned-game benefit.

## Predeclared setup

[Plan](studies/sidestreet-access-20261023-v1/PLAN.md), [policy](studies/sidestreet-access-20261023-v1/policy.gd), [fixed inputs](studies/sidestreet-access-20261023-v1/input-hashes.json), [case-level analysis](studies/sidestreet-access-20261023-v1/analysis.json).

- Eight specialties: Action, Adventure, Role-Playing, Strategy, Simulation, Puzzle, Sports and Racing; fixed seeds1104,1108,1112. These are24 deterministic starts, not a random player-success sample.
- Legal fresh Studios, identical ID/name/specialty/traits/seed across arms; granted starter cards only, no purchases, research, loans, injected cash/cards or player saves. Fantasy, visible Features-first development. First game3/5/4 phase hands; later games2/2/2. Introductory Ironclad completed after game1 using visible finite cards first.
- Three candidate arms: **balanced**, prioritizing first-hand Core coverage then Scope near5; **completion**, maximizing current capped completion; and **skip**, ignoring Relationship Briefs. Both take policies enumerate only the35 currently visible four-of-seven choices, select the best attainable final grade on hand2, never redraw and finish partial results. They do not inspect future draws. No perfect-grade rejection is used.
- Four-release horizon, at most160 commands per case. Take arms attempt three distinct briefs after releases1–3 even when R20 was reached earlier. Stop at Studio after release4. No active-phase Continue or edited checkpoint identity.
- Scope8 is **shadow arithmetic on the same committed outcomes**, using `(4*min(S,8)+sum(min(H_i,6)))/56` with the original promise. It is neither an implemented alternative nor an optimized Scope8 policy.

## Source identities and concurrency boundary

Checkout: dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; [initial Git state](studies/sidestreet-access-20261023-v1/git-before.json). Existing edits and `.codex-godot-temp` were preserved. The [canonical controls](sims/sidestreet-access-canonical-20261023-v1/run-report.json) captured a source containing P1 adoption files during ongoing work; their success is not completion of P1 acceptance.

Private [sidestreet-access-v1](simulators/sidestreet-access-v1/variant.json) is an unchanged gameplay descendant of `publisher-progression-market-v1`; only the external observation policy differs for this study. Its original canonical baseline and ancestry remain intact:

| Identity | Exact value |
| --- | --- |
| Original canonical baseline | `5edfa7878cd17904281d7cf7f2cf907e67b5f40edb4d9db83b3f99580f2aa415` |
| Candidate source manifest | `d3af2d474037d412feaa0d457b36fa72e7d853fb081d3be32262f38dad15ffbd` |
| Candidate runtime mechanics | `4b8d388b6e1e3324dae947322af0ce5335efd459caad41f46cf773edecbeb8c7` |
| Candidate frozen project with study policy | `49a296bc98f6d85e96733ac4010c711a31713aaf410f61f37572d204f88444f8` |
| Canonical-control frozen project | `56b1397e43b4a0680e5f89b11811cf35c5e8be03f796da5fce6bffdf4777749c` |
| Isolated runner SHA-256 | `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193` |
| Godot4.7.1 executable SHA-256 | `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef` |

Each bundle retains executable identity, policy/input hashes, full source manifests and actual commands. All six gameplay bundles share the candidate/frozen identities above, while their observed canonical drift identities change as P1 progresses ([per-bundle source identities](studies/sidestreet-access-20261023-v1/source-identities.json)). [Source drift](studies/sidestreet-access-20261023-v1/source-drift.json) is explicit: this older prototype uses its own private Reputation dictionaries and save schema, **not P1's adopted ledger**. Never transplant them into P1. The candidate's starter roster, card ledger and development fixture are byte-identical to the canonical control ([hash comparison](studies/sidestreet-access-20261023-v1/starter-source-check.json)). Other code differs; no cross-revision state parity is claimed.

Within the candidate comparison, initial state/RNG and the complete pre-Brief telemetry trace match for all24 starts. Both take policies also match through the first Brief's opening deal before making their own card choices. Their Contract commands differ in all24 starts, so these are distinct strategies. Later states are intentionally different; comparisons use the same fourth-release endpoint, not a claim of continuing RNG/state equality.

## Results

| Measure | Balanced | Completion-first | Skip |
| --- | ---: | ---: | ---: |
| Completed original case recipes |24|24|24|
| Accepted commands in those final records |2352|2352|1992|
| Completed briefs |72|72|0|
| Full / partial / zero rewards |48 /24 /0|48 /24 /0|—|
| R20 after two briefs |10 /24|10 /24|0|
| R20 after three briefs |24 /24|24 /24|0|
| Reputation after three |25.30–30.00|25.00–30.00|0|
| Median Reputation after three |29.06|29.06|0|
| Fourth-release productive cycle |42|42|36|
| Final overdue-balance cases |0|0|0|

R20 was observed at cycle26 in the20 combined two-perfect-result routes, and cycle35 in the other28 take routes. These calendar results depend on the declared short later games; longer development schedules will delay opportunities. Brief rewards range5.93–10.00 for balanced and5.00–10.00 for completion-first. Neither strategy dominates: Racing/1112 earned30.00 with balanced but25.00 with completion-first; both still passed R20.

Each strategy encountered24 second-hand deals with no available quartet that could earn a full result **from its selected first hand and observed second deal**. All still completed with useful partial rewards. This does not prove those seeds universally prevent full completion. The earlier [full-only R20 screen](PUBLISHER-R20-ACCESS-FINDINGS-2026-10-22-v1.md) used a different purchased pool and rejected non-perfect routes; these new cohorts are not a controlled numeric before/after comparison with that historical screen.

Saved offers also follow the proposed cadence: take routes retain three completed briefs and one newly pending offer; skip routes retain one pending offer rather than accumulating one per release. No immediate replacement appeared after completion before a new release. Once-only results, distinct source releases, projected/actual hand scores and runtime awards were checked during the routes and analysis.

### Opportunity cost

At the same fourth-release milestone, taking all three briefs leaves **$1,444.06–$1,486.01 less cash**, median **$1,465.04**, and consumes six additional productive cycles. Both take policies have the same paired cash differences. This is the realized net cash difference including intervening production/calendar/sales effects; it is not an acceptance fee, pure rent charge, profit estimate or direct reward adjustment.

These policies intentionally take the third brief even if R20 was reached after two. The result is not the minimum cost of reaching R20. Skipping that last optional brief and choosing existing SideStreet cash work instead are separate economic policies, not simulated here. No exact comparison against the foregone SideStreet cash payout is claimed.

### Scope8 sensitivity

On these same outcomes, each take strategy would have56 full results instead of48 and13 two-brief R20 starts instead of10. Three-brief access remains24/24. This does not establish actual Scope8 gameplay behavior, choices, finances or difficulty. It provides no reason to soften targets solely to make R20 reachable in this cohort.

## Verification and retained failures

- Eight fresh canonical controls completed four releases/Ironclad,664 accepted commands, before the private screen was assessed. They do not award Reputation.
- All72 fixed candidate recipes ultimately completed,6696 accepted commands in their final retained records,144 Brief results and288 releases. The initial timeouts are not converted into successful invocations.
- **948 analysis checks PASS,0 FAIL**: source/initial identity, complete pre-Brief state traces, opening-deal matching, completed case counts, offer/source uniqueness, saved pending-offer counts, two-cycle completion, and matching retained timeout observation prefixes. [Machine-readable checks](studies/sidestreet-access-20261023-v1/analysis.json).
- Representative fresh-process replays **PASS**: lowest total Reputation [racing-1112-completion](sims/sidestreet-access-replay-1-20261023-v1/run-report.json), highest total with lexical tie-break [action-1108-balanced](sims/sidestreet-access-replay-2-20261023-v1/run-report.json), and fixed control [sports-1104-skip](sims/sidestreet-access-replay-3-20261023-v1/run-report.json). They reproduce98/98/83 exact steps and final states, plus99/99/84 verified telemetry samples, using each original frozen source and separate profiles. [Exact replay commands and source bundles](studies/sidestreet-access-20261023-v1/replay-results.json).
- Two original setup attempts ([balanced](sims/sidestreet-access-balanced-20261023-v1/run-report.json), [completion](sims/sidestreet-access-completion-20261023-v1/run-report.json)) correctly rejected changing canonical provenance while P1 edited shared source; no candidate gameplay ran in either. [Operational amendment and stability check](studies/sidestreet-access-20261023-v1/SETUP-RETRY-AMENDMENT.md).
- The subsequent balanced/completion/skip batches each hit their unchanged600-second process cap after20/20/23 complete case results. Their partial attempts and full logs remain. Under the [predeclared timeout recovery amendment](studies/sidestreet-access-20261023-v1/TIMEOUT-COVERAGE-AMENDMENT.md), only the missing4/4/1 recipes restarted in separate outputs with unchanged seeds, policies and gameplay bounds. All9 recovered cases completed; prior partial observation prefixes match. [Recovery jobs](studies/sidestreet-access-20261023-v1/recovery-jobs.json) and [case-to-bundle coverage](studies/sidestreet-access-20261023-v1/coverage.json).
- No gameplay rejection occurred in the completed case records. No timeout was relabeled a game failure or erased. Partial-at-timeout commands are not added to the final-record accepted-command total.
- Some completed processes reported six ObjectDB instances leaked at exit; no Script Error or gameplay failure was recorded. [Retained warnings](studies/sidestreet-access-20261023-v1/process-warnings.json). Leak attribution was not investigated in this study.

## Exact commands and evidence map

Repository-root PowerShell command prefix used for runs:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/sidestreet-access-v1 --config <CONFIG> --output <OUTPUT> --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 600
```

`CONFIG` is under `docs/codex/threads/contracts/studies/sidestreet-access-20261023-v1/`; `OUTPUT` is under `docs/codex/threads/contracts/sims/`. Canonical control used this exact command **without** `--variant`.

| Config | Output basename | Result |
| --- | --- | --- |
|canonical.json|sidestreet-access-canonical-20261023-v1|PASS8/8|
|balanced.json|sidestreet-access-balanced-20261023-v1|source-capture rejection|
|completion.json|sidestreet-access-completion-20261023-v1|source-capture rejection|
|skip.json|sidestreet-access-skip-20261023-v1|TIMEOUT;23 complete cases|
|balanced.json|sidestreet-access-balanced-20261023-v2|TIMEOUT;20 complete cases|
|completion.json|sidestreet-access-completion-20261023-v2|TIMEOUT;20 complete cases|
|recovery-1.json|sidestreet-access-recovery-1-20261023-v1|PASS4/4 balanced suffix|
|recovery-2.json|sidestreet-access-recovery-2-20261023-v1|PASS4/4 completion suffix|
|recovery-3.json|sidestreet-access-recovery-3-20261023-v1|PASS1/1 skip suffix|

The named variant was created with `tools/simulator_variant.py create --id sidestreet-access-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/publisher-progression-market-v1 --output docs/codex/threads/contracts/simulators/sidestreet-access-v1`. The standard library scripts [setup](studies/sidestreet-access-20261023-v1/setup.py), [bounded recovery/replay orchestration](studies/sidestreet-access-20261023-v1/finish.py) and [analysis](studies/sidestreet-access-20261023-v1/analyze.py) are retained. Each automated recovery/replay has its exact argv and exit record in that study folder; every runner bundle also records its actual inner Godot commands.

## Limits and next gate

This is a fixed-seed starter-pool screen with a strong visible-combination policy and short later development schedules. It does not estimate player success rates, test broad purchased pools, traits, poverty/arrears rescue, redraw penalties, late Reputation caps, interacting rival worlds, P1-based integration, commissioned-game delivery/profit, native cold disk migration, UI, export or human comprehension. No longer-horizon pacing or final balance approval follows.

Next: review the bounded P2 terms and rebuild the approved slice against the **final verified P1 revision**. Use the [P2 integration requirements](studies/sidestreet-access-20261023-v1/ADOPTION-NOTES.md); repeat legal prefix/offer/award checks on that revision. Existing cash Contracts and the separately selected independent-client cash Brief keep their scope. Shared TODO and canonical gameplay were not edited by this study; no commit, push or release-readiness claim.
