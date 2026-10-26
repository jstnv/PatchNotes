# AI market density trial — bounded finding, 2026-10-18

## Disposition

**PASS within the private v31 scope; ACTIVE/TRIAL design selection, canonical adoption pending.** A real rival Action release entered the next month snapshot and raised a later legal player Action project's saved four-Core targets from `[40,26,40,26]` to `[42,28,42,28]`. The real Theme-only crowding route retained its 9700-basis-point age-month factor and exact units/cents. The v31 historical Store/world fixtures passed focused and cold Continue checks. This does not demonstrate a completed player Review under raised standards, player challenge over a campaign, visible explanations, or current canonical integration.

The [predeclared plan and repair addendum](2026-10-18-market-density-trial-plan-v1.md) specify the hypothesis, cases, seed, limits and stop rules. The [dated trial decision](2026-10-18-market-density-trial-decision-v1.md) selects values for implementation review, not final balance.

## Versions and starting conditions

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree. No canonical gameplay file was edited by this study. The neutral current-source control was frozen with canonical identity `e2f6a3a128e50bbd36bbdff1557d6a5ff981ea92c2273b857c1d76bc100a2721`. The final [private v31 variant](simulators/market-density-20261018-v31/variant.json) has candidate identity `ee2f33ac564f088eed8d816dc012539b16318e0938f97a06fd1d845a5de2d477`, original baseline `89d52a809a9f25613ecc7e269f28914d9c7edc8f4849aee31393170996cdc82c`, parent v30 identity `5a4fe680df36fd7846a259d0ea00b20139a05e7aa082a32617b6a01285230208`, and v29 ancestor `30508dba9e2d25cd701519defe814bc064759ceaf51eac4a59aa041ba1b932bd`. The frozen run reports `baseline_drift=true`; v31 was not rebased onto later Store, Contracts, roster or rival-synergy work. The player experiment's gameplay source identity is `8d2527db9f2879e40819c42e3d76eea35730a7884dfb0326544098a86e3ffdc8`. V30 and v31 differ only in the test verifier's synthetic row order, not market gameplay.

Godot 4.7.1 console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`; Python 3.12.14. Fresh player starts used seed `4417`, no Traits, a legal Action/Fantasy 2/2/2 hand policy, a 50-command/one-release cap, and no cross-revision checkpoint transplant. The world verifier used two real January 1980 incumbent sessions, ten player productive idle cycles, at most four rival releases, then one legal player Action begin; every process had a 240-second ceiling. Current neutral and v31 fresh player starts differ in saved schema and whole-state digest. Their initial/final RNG maps, first release metadata, cash `404000` cents and Fans `0` matched; equal seeds alone were not used as parity proof. The world verifier used a separate legal prefix for v31. Its synthetic strong and missing-Core rows are arithmetic fixtures, not evidence of real strong rivals.

## Exact commands and retained evidence

From the repository root in PowerShell:

```powershell
$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $py tools/simulate.py run --config docs/codex/threads/ai-competitors/2026-10-17-foundation-smoke-v1.json --output docs/codex/threads/ai-competitors/sims/market-density-current-20261018-v1 --godot $godot --timeout 240
& $py tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/market-density-20261018-v31 --config docs/codex/threads/ai-competitors/2026-10-17-foundation-smoke-v1.json --output docs/codex/threads/ai-competitors/sims/market-density-v31-player-20261018-v1 --godot $godot --timeout 240
& $py docs/codex/threads/ai-competitors/run_market_density_verifier_v1.py --bundle docs/codex/threads/ai-competitors/sims/market-density-v31-player-20261018-v1 --output docs/codex/threads/ai-competitors/sims/market-density-v31-world-20261018-v1 --godot $godot --script verify_market_density_trial.gd --test-port 48032 --timeout 240
& $py docs/codex/threads/ai-competitors/run_market_density_verifier_v1.py --bundle docs/codex/threads/ai-competitors/sims/market-density-v31-player-20261018-v1 --output docs/codex/threads/ai-competitors/sims/market-density-v31-cold-20261018-v1 --godot $godot --script verify_market_density_trial.gd --profile docs/codex/threads/ai-competitors/sims/market-density-v31-world-20261018-v1/profile --test-port 48033 --timeout 240
& $py tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/market-density-v31-player-20261018-v1 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/market-density-v31-replay-20261018-v1 --godot $godot --timeout 240
& $py docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/market-density-v31-player-20261018-v1 --output docs/codex/threads/ai-competitors/sims/market-density-v31-historical-focused-20261018-v1 --godot $godot --script verify_market_historical_sources.gd --profile docs/codex/threads/ai-competitors/sims/market-density-v31-historical-input-20261018-v1/profile --test-port 48035 --timeout 240
& $py docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/market-density-v31-player-20261018-v1 --output docs/codex/threads/ai-competitors/sims/market-density-v31-historical-cold-20261018-v1 --godot $godot --script verify_market_historical_sources.gd --profile docs/codex/threads/ai-competitors/sims/market-density-v31-historical-input-20261018-v1/profile --test-port 48036 --timeout 240
```

The historical input profile was new and contained only the two immutable `market-founder1-original.json` and `market-world1-original.json` files copied from the v26 original-fixture profile. SHA-256 before and after copied input: Founder `6EAB99D004E0BB7844BB03FC0CD24147C02226103CAEB3316AC08A6FB6B2B67B`; world `EFCCB72B51D1E29D515E68BDEDE5540705577FC33496D47D6FBCA12FABD3765E`. The verifier generated all migration and semantic Store artifacts in that new profile.

| Evidence | Outcome |
|---|---|
| [Current player control](sims/market-density-current-20261018-v1/experiment-report.json) | PASS 18/18 legal commands, one first release. Neutral Review targets; no live rival world in this scene-free player run. |
| [V31 player](sims/market-density-v31-player-20261018-v1/experiment-report.json) and [fresh replay](sims/market-density-v31-replay-20261018-v1/replay-report.json) | PASS 18/18 and exact replay of 18 accepted steps with the same final state. |
| [V31 world](sims/market-density-v31-world-20261018-v1/rival-verifier.log) | PASS 122/122 checks, two real rival releases on cycle 7, cycle-8 snapshot with two owner facts, one real Action other-studio publication, legal player begin under `[42,28,42,28]` at cycle 10, rival advance to cycle 11. |
| [V31 cold Studio Continue](sims/market-density-v31-cold-20261018-v1/rival-verifier.log) | PASS 8/8; frozen source, snapshot and age-month factor history restored. Exit-only ObjectDB warning retained. |
| [V31 original old Store/world fixtures](sims/market-density-v31-historical-focused-20261018-v1/rival-verifier.log) and [cold repeat](sims/market-density-v31-historical-cold-20261018-v1/rival-verifier.log) | PASS 73/73 and 51/51; original bytes and generation preserved, valid pairs restored, corrupted history/active-card cases rejected. |
| [Prior v29 benchmark-only transaction](2026-10-18-market-transaction-finding-v1.md) | Real rival Reviews 2.2/2.7 caused no Review lift under the ≥7.0 benchmark. Matched real Theme-only sales reduced earned units by 11/13 and entitlement cents by 7692/9091. Historical, different source. |

The world checks include tentative preflight rollback, one committed snapshot, fact provenance, same-month and release-age month boundaries, 9700 Theme-only factor, exact cumulative units/cents, two-title population cap, own-studio exclusion, missing-Core counting, expiry, and strong-benchmark max aggregation. The strong benchmark and two-title cap use synthetic rows. The released rivals' old Cores and Review did not qualify as strong benchmarks. The legal Action begin, not a finished second release, establishes the player-facing target effect.

## Rejected and incomplete cases

- The first v30 verifier call failed at the wrapper argument parser because the new script name was not allowed; Godot did not start. The thread-owned `run_market_density_verifier_v1.py` allows that script only.
- [V30 focused world](sims/market-density-v30-world-20261018-v2/rival-verifier.log) completed 122 checks with **one failure**: synthetic release facts were supplied out of the snapshot's lexical identity order. V31 changes only that fixture ordering and repeats the full route. Do not count v30 as passing.
- [Current-source rival activation control](sims/market-density-current-world-20261018-v1/rival-verifier.command.json) timed out at 240 seconds after its cycle-13 log line. It is **INCOMPLETE**, not a behavioral parity result. This was an extra current-world check; the predeclared current neutral player control passed. Retain and investigate its runtime during integration.

## Recommendation and limits

Queue the selected ACTIVE/TRIAL formula and transaction/save mechanism for a **reconciled** canonical implementation, not a wholesale v31 copy. The v31 packet descends from an older baseline and includes debug verifiers and pre-market migration adapters. The implementation owner must review each changed path against current Store, Contracts, roster, synergy and checkpoint work. Add visible explanations and reverify the exact current source. No canonical adoption, final coefficient approval, leaderboard, or release readiness follows from these private checks.

Acceptance still needs legal Genre-only, pair and disjoint multi-title sales; a completed player second release with raised targets; a strong player release that affects a rival's next target; repeat/expiry and longer campaign behavior; current-source named-save fixtures including old executable Store generation, corrupt/mixed-source rejection, write failure and backup recovery; graphical/exported Continue; UI comprehension; and CPU/save bounds at intended rival population. The timed-out current control is a specific runtime follow-up. Track those as gates, not as secretly passing results.
