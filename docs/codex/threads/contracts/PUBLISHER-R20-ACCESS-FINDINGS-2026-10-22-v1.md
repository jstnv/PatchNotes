# SideStreet R20 legal access — findings v1

2026-10-22 (America/Los_Angeles). **PROPOSED publisher progression, bounded private-simulator evidence; no design approval or canonical gameplay implementation.** The question was whether the candidate SideStreet two-hand Relationship Brief can award 10 Reputation points twice on distinct release-paced offers, opening the proposed tier-1 commission gate at R20. [Fixed-route plans v1](PUBLISHER-R20-PROGRESSION-PLAN-2026-10-22-v1.md) and [v2](PUBLISHER-R20-PROGRESSION-PLAN-2026-10-22-v2.md), then the [predeclared eight-seed screen](PUBLISHER-R20-SEED-SCREEN-PLAN-2026-10-22-v1.md), specify policies, legal starts and bounds. This finding retains failures as failures.

## Source and exact commands

All runs used dirty `main` at HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, Godot 4.7.1 executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`, runner SHA-256 `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193`, and the observation-only [R20 policy](publisher_r20_progression_policy_v1.gd) with source identity `b760b9dc2f1dcce66bb9d10aa85c3d76f4e97283411f0823232350032a687f86`. Each private variant has its own project, import cache and profile. The policy uses only visible seven-card deals, selects four legal cards, never redraws, and explicitly rejects a hand when no visible combination finishes the full Scope/Core promise. No player save, card, cash, Bank loan or market factor was injected.

- [Older private candidate](simulators/publisher-progression-v1/variant.json): base identity `798e8be69bf595922096064807a0164e6be7911bec8f4595b99d19c40e9a68e3`, candidate `06ad9f4616e1e624577bb3b29239fa019cef7bf1a32d6d4ef4c9b9eb677cfb89`, [frozen source](sims/publisher-r20-progression-20261022-v1/run-report.json) `e1632b7ec43197f679c36c2f474b46fb5c28b8a16ade77849e12f5ebd256470f`. It is **not** current-market evidence.
- [Current-market-based private candidate](simulators/publisher-progression-market-v1/variant.json): base identity `5edfa7878cd17904281d7cf7f2cf907e67b5f40edb4d9db83b3f99580f2aa415`, candidate `d3af2d474037d412feaa0d457b36fa72e7d853fb081d3be32262f38dad15ffbd`, [frozen source](sims/publisher-r20-market-20261022-v1/run-report.json) `708b6f7b354bd5078b54b504c37a77d766f38720f1f3f5f2498338d2bd3d4c87`; the screen captured the same frozen source identity. **`baseline_drift=true`** at both R20 captures: the shared canonical checkout changed after this variant's baseline was made, on `scripts/audio/soundtrack.gd`, two pause verifiers, `scripts/market/rival_world_checkpoint.gd` and `scripts/ui/how_to_play_content.gd`. The variant and replays remain exact at their frozen source, but these runs are **not** a byte-current canonical parity test; the rival checkpoint drift especially requires reconciliation before an adoption claim. The earlier [Brief matrix](PUBLISHER-BRIEF-MARKET-FINDINGS-2026-10-22-v1.md) recorded no baseline drift at its separate capture. Exact input hashes, project deltas and process command records reside in each bundle.

The three requested invocations, in execution order, were:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/publisher-progression-v1 --config docs/codex/threads/contracts/publisher-r20-progression-v1.json --output docs/codex/threads/contracts/sims/publisher-r20-progression-20261022-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 360
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/publisher-progression-market-v1 --config docs/codex/threads/contracts/publisher-r20-progression-v1.json --output docs/codex/threads/contracts/sims/publisher-r20-market-20261022-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 360
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/publisher-progression-market-v1 --config docs/codex/threads/contracts/publisher-r20-market-seed-screen-v1.json --output docs/codex/threads/contracts/sims/publisher-r20-market-seed-screen-20261022-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 360
```

Each case was a fresh no-trait Sports/Fantasy Studio with legal `sprites/general_combat/levels` starter purchases. Game 1 used Design/Alpha/Beta hands 3/5/4, later games 2/2/2, target three releases, max 300 commands and 360 seconds. The short later games were chosen to test issuance timing; they are not a recommended strategy or proof that a future commissioned game can meet Review 6.0 and required Scope.

## Results, including rejected cases

Both [older](sims/publisher-r20-progression-20261022-v1/experiment-report.json) and [current-market](sims/publisher-r20-market-20261022-v1/experiment-report.json) Sports/1104 fixed routes gave a **full first Brief**, 1,000 Reputation basis points, Game 2 and a **distinct second Brief** sourced from Game 2. At its second hand the policy found no visible four-card set that could complete exact Scope 10 and every Core at least three points. Both runs ended `rejected_policy_action`, 57 accepted commands plus a rejected command, two releases, cycle 25, R1000. The error text `Contract remains active` is the simulator's rejection of the deliberate unsupported stop action, not a completed Contract. [Current-market exact replay](sims/publisher-r20-market-20261022-v1-replay-rejection/run-report.json) passed 58 recorded steps including the unchanged final state after rejection (`909dd64ab68d6f782722c3102de7a034a948e43fb3a5c2f987065f5414f6a543`) and 59 verified telemetry samples. The older run was not separately replayed.

The subsequent [retained-deal audit](PUBLISHER-R20-VISIBLE-DEAL-AUDIT-2026-10-22-v1.md) decoded the exact tape and frozen card ledger. Neither observed 1104 Brief-2 deal contained a Graphics contributor, so **that observed no-redraw deal path** could not reach the required Graphics 3, regardless of second-hand selection. Changing the first hand could change replacement draws; the audit did not test that counterfactual.

The [eight-case current-market screen](sims/publisher-r20-market-seed-screen-20261022-v1/experiment-report.json) returned overall `ok=false` because six declared cases rejected. It still retained **two completed R20 routes**. There were 381 accepted commands and 13 final player releases across the independent cases; this is an access screen, not an estimated success probability.

The same [visible-deal audit](PUBLISHER-R20-VISIBLE-DEAL-AUDIT-2026-10-22-v1.md) found decisive limits in each rejected case's **observed** two deals: seeds 1105, 1106, 1110 and 1111 had total visible positive Scope at most 9, while 1107 and 1109 could not reach the Sound Core minimum. Replacement draws can depend on earlier card choices, so these bounds do not prove that every strategy for those seeds fails.

| Seed | Actual result | Accepted commands | Releases / cycle | Distinct full Briefs |
| ---: | --- | ---: | ---: | ---: |
| 1105 | rejected at Brief 1, second visible hand | 34 | 1 / 16 | 0 |
| 1106 | rejected at Brief 2, second visible hand | 57 | 2 / 25 | 1 |
| 1107 | rejected at Brief 1, second visible hand | 34 | 1 / 16 | 0 |
| 1108 | **completed R20 route** | 77 | 3 / 33 | 2 |
| 1109 | rejected at Brief 1, second visible hand | 34 | 1 / 16 | 0 |
| 1110 | rejected at Brief 1, second visible hand | 34 | 1 / 16 | 0 |
| 1111 | rejected at Brief 1, second visible hand | 34 | 1 / 16 | 0 |
| 1112 | **completed R20 route** | 77 | 3 / 33 | 2 |

For **1108**, [event log](sims/publisher-r20-market-seed-screen-20261022-v1/experiment.log) records Brief 1 Scope 10/Core half-units 10/10/32/14 and Brief 2 Scope 10/Core 20/10/10/14, no redraw. Their different offer IDs refer to releases 1 and 2; R2000 was observed at Studio cycle 26, cash `831045` cents. The third release reached Studio cycle 33 with cash `642374` cents, 9 Fans, Credit 618 and no overdue/rent balance or Bank loan. Final state digest `f824876129584ad23f86944b8b96049601e84636060cfb7e7d8d62f797607f3c`.

For **1112**, the corresponding two full outcomes were Scope 10/Core half-units 14/24/6/18 and Scope 10/Core 14/14/10/16. R2000 appeared at Studio cycle 26, cash `778174` cents. The third release reached Studio cycle 33 with cash `599796` cents, 26 Fans, Credit 615 and no overdue/rent balance or Bank loan. Final state digest `5d9a151bb7dc57a333924c3b030dca9babad579e08ff80e4afc14fe12f1f5e2a`.

Fresh-process exact replays used the screen's **frozen** source and independent profiles:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-r20-market-seed-screen-20261022-v1 --case sports-1108-two-full-briefs-r20 --output docs/codex/threads/contracts/sims/publisher-r20-market-seed-screen-20261022-v1-replay-1108 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 360
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/publisher-r20-market-seed-screen-20261022-v1 --case sports-1112-two-full-briefs-r20 --output docs/codex/threads/contracts/sims/publisher-r20-market-seed-screen-20261022-v1-replay-1112 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 360
```

Both [1108](sims/publisher-r20-market-seed-screen-20261022-v1-replay-1108/run-report.json) and [1112](sims/publisher-r20-market-seed-screen-20261022-v1-replay-1112/run-report.json) replays exited 0, verified all 77 exact accepted steps and 78 telemetry samples, and reproduced the final digests. The six rejected seed-screen cases were retained but not each replayed; their policy decisions do not become passing routes through the successes.

## Recommendation and limits

The candidate R20 gate is **legally reachable in at least two sampled current-market starts** after two different full Briefs. Legal reachability is uneven under this strict no-redraw/exact-Scope policy. Five screen seeds failed the first Brief's second visible hand and one failed the second; the 1104 fixed route also failed the second. A separate audit should inspect whether earlier visible first-hand ranking left a potentially better completion path; these failures prove the **tested policy** stopped, not universal impossibility of those starts. The two successful prefixes may now be **regenerated under a descendant private commission variant**; their final checkpoints cannot be relabeled across revisions. Match same-revision Studio state/RNG before a commission-vs-self-publication economic comparison.

This study did not implement or exercise a commission or support deal, test Review 6.0/Scope delivery, establish an attractive fee, prove broad specialty feasibility, validate graphical/exported UI, or approve candidate Brief numbers. The eventual independent-client cash Brief remains the user-selected first new Contract type. P1–P5 stay **PROPOSED** pending a design adoption ruling and further legal runtime evidence. No canonical gameplay, shared TODO, commit or push was changed by this study.
