# SideStreet take/skip through Game 3 settlement — finding v22

2026-10-11 (America/Los_Angeles). **Completed bounded existing-rule headless study.** This extends [v21](FINDINGS-v21-sidestreet-take-skip.md) beyond the previously unsettled Game 3 and adds one separate-source legal pair. [V4 predeclaration](PLAN-v4-sidestreet-postsettlement.md), [v5 fixed-seed screen](PLAN-v5-sidestreet-neighbor-seeds.md), and [v6 source-stratified pair declaration](PLAN-v6-sidestreet-new-source-pair.md) record choices before their respective runs. No gameplay code, asset, rule or candidate simulator version changed in this thread.

## Source and protocol

Both source snapshots came from dirty `main` HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; the HEAD alone **does not** identify their different working-source bytes. Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. The runner preserved isolated project/import/profile copies, source manifests, dirty diff, inputs, commands and raw logs.

| Source stratum | Mechanics identity | Frozen source identity | Policy SHA-256 | Evidence |
|---|---|---|---|---|
| V4 Sports/1104 | `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f` | `8df0a86961a062e6b9f98a87701b9d67a0df05b1b966d6756ea565db2004cdae` | `ba7869ac9f1f020c7a980d52b503fc7156d1d1dea5d2345131ef7f6f8e9d821e` | [run report](sim-v20/study-v4-run-01/run-report.json), [source hashes](sim-v20/study-v4-run-01/snapshot-manifest.json) |
| V5 prefix / V6 Sports/1106 | `62cfd4f1686a6cc6302616d98aab421f2db511971fc5655cf5b6d9e743f612c4` | `7d4b78b85fdbe6ebc9dd1a976d590c77ec833c09481e0c4c26ca3933661a1aae` | same policy SHA as V4 | [v5 prefix](sim-v20/prefix-v5-run-01/run-report.json), [v6 pair](sim-v20/pair-v6-run-01/run-report.json), [source hashes](sim-v20/pair-v6-run-01/snapshot-manifest.json) |

Between source snapshots, Studio Traits moved to version8 with a 20-Fan Cult trial, Studio checkpoint rules/revision changed, and three verifier scripts changed. No-trait Sports was used in both, but **the source revisions are not treated as identical**. The v5 pair preparer refused the old v4 mechanics identity; the v6 preparer then pinned the v5 checkpoint to its own source. We compare **Take versus Skip within each source**, never pool their raw dollar levels or restore a v4 checkpoint on v6 mechanics.

Each pair begins from its own identical Studio checkpoint bytes and RNG, with two real releases, committed Ironclad, a pending SideStreet entitlement and a pending Crown first offer. Take completes SideStreet then the first visible Crown/Neon publisher; Skip leaves SideStreet pending and completes that publisher. Both use the same visible Feature-first Sports/Fantasy Game3–4 development policy (5/6/6 hands), target four releases, max220 commands, 240-second timeout. No Starwave acceptance, loan, Store purchase/research, hiring, campaign, redraw or artificial wait in the paired continuation. New prefix cases retained their separately declared max180 command bound. Only actual shared run cycles and same-release milestones are compared; endpoint dollars at different calendars are not a matched result.

## Retained runs and validation

- **V4 source:** Sports/1104 Take 64 accepted commands to cycle72/Game4, Skip 59 to cycle70/Game4. Both reached Game3 at **exactly the same state digests** as their v21 Game3 endpoint tapes; the v4 policy copy did not change the earlier route. [Paired comparison](sim-v20/study-v4-comparison-01/comparison.json) verified common initial state/RNG/source despite the [four-case run](sim-v20/study-v4-run-01/run-report.json) reporting overall `ok:false` for the retained 4417 rejection. Separate [Take replay](sim-v20/study-v4-sports-1104-take-v4-replay-01/replay-report.json) and [Skip replay](sim-v20/study-v4-sports-1104-skip-v4-replay-01/replay-report.json) exactly reproduced 64 and 59 steps/telemetry. [Independent audit](sim-v20/audit-v4.json) passed its stated assertions.
- **V4 access probes:** Adventure/1104 completed two releases (56 accepted commands, cycle32), but Game2 Review6.6 missed Crown and Awareness113 missed Neon; [fresh replay](sim-v20/study-v4-adventure-1104-prefix-v4-replay-01/replay-report.json) matched. Sports/4417, using a slower 5/6/6 first game, stopped on command23 at cycle12 before launch with cash$0, $80 original rent overdue and `financially_blocked=true`; the rejected Beta action said “The run calendar cannot advance safely.” [Exact rejection](sim-v20/study-v4-run-01/cases/sports-4417-prefix-v4/result.json) and [reduction](sim-v20/study-v4-4417-reduction-02/reduction-run.json) retain a 20-command suffix from the last restorable Studio boundary, confirmed in a fresh process. The first reducer attempt lacked the Godot executable flag and is retained in `study-v4-4417-reduction-01`; it is tool setup failure, not a game outcome.
- **V5 fixed neighboring seeds:** Sports/1105 and 1106 both completed the legal two-release/committed-Ironclad prefix at cycle32. Seed1105 had Game2 Review5.6 and Awareness120, with no first publisher offer. Seed1106 had Game2 Review7.0 and Awareness132, with both Crown and Neon pending plus SideStreet; it was the first eligible declared neighbor. [Prefix run](sim-v20/prefix-v5-run-01/run-report.json) and [1106 fresh replay](sim-v20/prefix-v5-1106-replay-01/replay-report.json). The v5 preparer stopped on source identity drift as declared; no envelope was altered.
- **V6 source-stratified pair:** Sports/1106 Take 64 accepted commands to cycle72/Game4, Skip 59 to cycle70/Game4. [Comparison](sim-v20/pair-v6-comparison-01/comparison.json) verified common checkpoint/state/RNG within this source. [Take replay](sim-v20/pair-v6-take-replay-01/replay-report.json), [Skip replay](sim-v20/pair-v6-skip-replay-01/replay-report.json) and [independent audit](sim-v20/audit-v6.json) passed. No paired arm rejected, timed out or accrued sampled arrears. Both had genuine rent and monthly sales settlements.

## Economic observations

All cash differences below are **Take minus Skip at the same calendar cycle**, with both Game3 titles at least two actual monthly settlement boundaries old by cycle60. The standard telemetry captures cash/arrears and release milestones at each command boundary; the endpoint release records verify cumulative per-title settled sales at an equal **18 title-age cycles**. They do not emit an individual title's first two payment rows, so those exact two title-specific amounts are not separately asserted here.

| Measure | Sports/1104, v4 source | Sports/1106, v6 source |
|---|---:|---:|
| SideStreet earned direct cash | $1,125 Take; $0 Skip | $1,125 Take; $0 Skip |
| Crown total receipt / Promotion, Take vs Skip | $1,276.36 / 7 vs $1,759.09 / 10 | $1,920 / 12 vs $1,920 / 12 |
| Take−Skip cash at shared cycle60 | **+$256.25** | **+$705.98** |
| Take−Skip cash at last shared cycle70 | **+$418.50** | **+$992.14** |
| Game3 Review, Take/Skip | 7.3 / 7.3 | 7.7 / 7.7 |
| Game3 cumulative settled sales at equal age18, Take vs Skip | $12,363.62 vs $12,489.49 (**−$125.87**) | $13,328.65 vs $13,328.65 (equal) |
| Game4 Review, Take/Skip | 6.6 / 6.6 | 6.7 / 6.7 |
| Game3 / Game4 launch cycle, Take vs Skip | 54/72 vs 52/70 | 54/72 vs 52/70 |
| Starwave first offer after Game3 | Take pending; Skip absent | Take pending; Skip absent |
| Sampled overdue and financial block in paired arms | $0 / none | $0 / none |

In v4, SideStreet's $1,125 receipt was accompanied by a $482.73 lower Crown receipt and three fewer Crown Promotion points; its Game3 same-age settled sales were $125.87 lower. In v6, both Crown hands reached the $1,920/12 cap and the Game3 title had identical same-age settled sales, so that Crown/sales cost did **not** recur. In both routes, SideStreet advanced the three-distinct-completion Starwave gate while leaving its offer unaccepted, and delayed Games3 and4 by two productive cycles. At cycle70 Skip had just launched Game4 while Take had not, so even matched cash is a **strategy-path observation**, not equal project progress. Cash deltas also fluctuate as different launch and settlement dates cross; the cycle70 lead does not establish long-run dominance. Neither pair tested a survival rescue, actual arrears, Starwave payout or Game4 settlements.

## Recommendation and decision boundary

**Retain the current SideStreet choice and Crown/Neon/Starwave ACTIVE/TRIAL terms; no numerical or access-rule change is supported.** The extra cash and earlier Starwave eligibility are real in these two legal source-stratified routes, while their Crown/Promotion and sales cost varies. SideStreet remains LOCKED/implemented, Crown/Neon/Starwave remain ACTIVE/TRIAL, and final publisher balance stays OPEN. A user design ruling can close this strategic review as “retain current behavior” or commission a broader specialty/low-cash/player-understanding pass. [Versioned design-review handoff v2](HANDOFF-SIDESTREET-v2.md) carries those alternatives; no implementation delta exists.

## Reproduction commands

PowerShell from repository root, with `$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'` and `$godot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'`:

```powershell
& $py docs/codex/threads/contracts/sim-v20/prepare_v4.py
& $py tools/simulate.py run --godot $godot --config docs/codex/threads/contracts/sim-v20/study-v4.json --output docs/codex/threads/contracts/sim-v20/study-v4-run-01 --timeout 240
& $py tools/compare_simulations.py --bundle docs/codex/threads/contracts/sim-v20/study-v4-run-01 --left sports-1104-skip-v4 --right sports-1104-take-v4 --output docs/codex/threads/contracts/sim-v20/study-v4-comparison-01
& $py tools/reduce_simulation.py --godot $godot --bundle docs/codex/threads/contracts/sim-v20/study-v4-run-01 --case sports-4417-prefix-v4 --kind rejection --output docs/codex/threads/contracts/sim-v20/study-v4-4417-reduction-02 --timeout 240 --max-commands 1000
& $py docs/codex/threads/contracts/sim-v20/prepare_v5.py
& $py tools/simulate.py run --godot $godot --config docs/codex/threads/contracts/sim-v20/prefix-v5.json --output docs/codex/threads/contracts/sim-v20/prefix-v5-run-01 --timeout 240
& $py docs/codex/threads/contracts/sim-v20/prepare_pair_v6.py
& $py tools/simulate.py run --godot $godot --config docs/codex/threads/contracts/sim-v20/pair-v6.json --output docs/codex/threads/contracts/sim-v20/pair-v6-run-01 --timeout 240
& $py tools/compare_simulations.py --bundle docs/codex/threads/contracts/sim-v20/pair-v6-run-01 --left sports-1106-skip-v6 --right sports-1106-take-v6 --output docs/codex/threads/contracts/sim-v20/pair-v6-comparison-01
& $py docs/codex/threads/contracts/sim-v20/audit_v4.py
& $py docs/codex/threads/contracts/sim-v20/audit_v6.py
```

`tools/simulate.py replay --godot $godot --bundle <respective-run-bundle> --case <case-id> --output <new-folder> --timeout 240` was run for each paired arm, Adventure/1104 and the eligible Sports/1106 prefix; exact replay folders are linked above. The written preparation/audit scripts refuse to overwrite their saved output. To reproduce, use new output paths rather than deleting these retained bundles.
