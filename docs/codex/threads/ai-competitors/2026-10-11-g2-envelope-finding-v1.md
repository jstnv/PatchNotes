# 2026-10-11 finding: finite Design/Alpha hands on a legal next project

**Status: bounded existing-behavior evidence; G2 hand count, cash allocation and legal-mix search remain OPEN.** [Predeclared plan](2026-10-11-g2-envelope-study-plan-v1.md). No canonical gameplay or private variant source was changed. The tested policy is the simulator's existing finite **test** fixture, not approved rival AI.

## Source and comparison validity

- Checkout at capture: `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, dirty shared worktree. Both isolated bundles froze identical project identity `577f46fd83d5a1e2bd21d017c40eba0b20a543faf9c2301cd6316d48aa394533` and mechanics identity `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f`.
- Policy `finite-development-fixture` v1 SHA-256 `e168d3a6ea700eed8cad3b02a276003a359048d0c04e620b9e285f19b5197a00`; Godot 4.7.1 console executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`; Python 3.12.14. These are exact run-report identities, not a claim that this dirty checkout is a release build.
- Two legal one-release prefixes completed at cycle 7 and emitted Studio checkpoints. All six arms used the source-compatible checkpoint envelope for their own seed; within each seed, all three `initial_state` hashes and serialized initial RNG sets match (4417: `936a1afc3054…`; 90210: `9f6387428ef8…`). The pair reporter accepted all four adjacent comparisons and telemetry integrity. Equal seeds across the two independent recipes are not claimed as the same state.
- All six next-project cases completed at Studio, with no rejected command, no arrears and no financial block. Representative fresh-process replays passed: 4417 3/3 (20 commands, 21 telemetry samples) and 90210 1/1 (16 commands, 17 samples). No timeout, incomplete case or failure reduction was needed. The retained bundles contain every arm, including all original commands and source copies.

## Results

Each arm used the same Action specialty, Action project Genre, Fantasy Theme, no traits, no Store action and the public-candidate `features_first` policy. Beta stayed at two hands. Hand columns count planned productive Design/Alpha hands. Core order is Graphics/Sound/Technology/Design. Cash is each arm's own launch endpoint, so the [matched-calendar comparisons](sims/g2-envelope-compare-4417-d1a1-d2a2-v1/comparison.md) are needed for a time-aligned cash statement.

| Seed | Design/Alpha | Next release cycle | Achieved Core | Scope / 30 | Review observed | Own-end cash | Arrears |
|---|---:|---:|---|---:|---:|---:|---:|
| 4417 | 1/1 | 12 | 13/0/17/10 | 14/30 | 0.5 | $3,929.92 | $0 |
| 4417 | 2/2 | 14 | 18/9/31/15 | 27/30 | 2.6 | $2,944.82 | $0 |
| 4417 | 3/3 | 16 | 31/11/32/16 | 29/30 | 3.6 | $2,389.78 | $0 |
| 90210 | 1/1 | 12 | 5/5/22/11 | 16/30 | 0.6 | $5,183.70 | $0 |
| 90210 | 2/2 | 14 | 18/8/29/18 | 26/30 | 2.2 | $4,322.58 | $0 |
| 90210 | 3/3 | 16 | 23/11/36/20 | 29/30 | 3.2 | $3,734.54 | $0 |

Additional planned hands increased each sampled four-Core vector and Scope, and moved launch two cycles per step. All six launches remained under required Scope 30 and were legal with positive Feature work. This supports the selected finite-plan/legal-exit structure and demonstrates that a `2/2` fixture count is not a neutral capability constant. It **does not** show that `3/3` is optimal, that an under-Scope project should be the rival policy, or that its Review merits a news threshold. Draws, finite supply, monthly receipts, and the later calendar differ after the arms diverge. At matched cycle 14, 3/3 had $90 less cash than 2/2 for seed 4417 and $1,130 less for 90210; see the reporter's exact samples. Those deltas include different phase/release timing, not just card cost.

## Recommendation and OPEN boundary

Keep the G2 hand number **OPEN**. The next private candidate should make the hand envelope configurable and enumerate **jointly** legal Design/Alpha vectors from a frozen owned pool and one fresh next-project state, with finite Feature use and cash after known dues. Compare at least the observed `2/2` and `3/3` envelopes under the same Store target and exact proportional-gap rule; retain `1/1` as a low-horizon control. A candidate that cannot finish the bounded search must defer shopping. This is a proposal for the next study, not approval of a hand count or CPU limit. The G3 due snapshot and no-prerequisite-only dead-end check still depend on that planner. No exact Store candidate comparison, Genre variation, rival world, incumbent cohort, Fanbase effect, news cadence or market Review effect was tested here.

## Commands and retained evidence

Run from repo root in PowerShell. `$py` and `$godot` resolve to the exact binaries above; the commands below reproduce the recorded arguments into **new** output paths if rerun (existing evidence folders must never be reused):

```powershell
$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $py tools/simulate.py run --godot $godot --config docs/codex/threads/ai-competitors/2026-10-11-g2-envelope-prefix-v1.json --output docs/codex/threads/ai-competitors/sims/g2-envelope-prefix-2026-10-11-v1 --timeout 240
& $py docs/codex/threads/ai-competitors/prepare_g2_envelope_v1.py docs/codex/threads/ai-competitors/sims/g2-envelope-prefix-2026-10-11-v1 docs/codex/threads/ai-competitors/2026-10-11-g2-envelope-arms-v1.json
& $py tools/simulate.py run --godot $godot --config docs/codex/threads/ai-competitors/2026-10-11-g2-envelope-arms-v1.json --output docs/codex/threads/ai-competitors/sims/g2-envelope-arms-2026-10-11-v1 --timeout 240
& $py tools/compare_simulations.py --bundle docs/codex/threads/ai-competitors/sims/g2-envelope-arms-2026-10-11-v1 --left g2-next-4417-d1a1 --right g2-next-4417-d2a2 --output docs/codex/threads/ai-competitors/sims/g2-envelope-compare-4417-d1a1-d2a2-v1
& $py tools/compare_simulations.py --bundle docs/codex/threads/ai-competitors/sims/g2-envelope-arms-2026-10-11-v1 --left g2-next-4417-d2a2 --right g2-next-4417-d3a3 --output docs/codex/threads/ai-competitors/sims/g2-envelope-compare-4417-d2a2-d3a3-v1
& $py tools/compare_simulations.py --bundle docs/codex/threads/ai-competitors/sims/g2-envelope-arms-2026-10-11-v1 --left g2-next-90210-d1a1 --right g2-next-90210-d2a2 --output docs/codex/threads/ai-competitors/sims/g2-envelope-compare-90210-d1a1-d2a2-v1
& $py tools/compare_simulations.py --bundle docs/codex/threads/ai-competitors/sims/g2-envelope-arms-2026-10-11-v1 --left g2-next-90210-d2a2 --right g2-next-90210-d3a3 --output docs/codex/threads/ai-competitors/sims/g2-envelope-compare-90210-d2a2-d3a3-v1
& $py tools/simulate.py replay --godot $godot --bundle docs/codex/threads/ai-competitors/sims/g2-envelope-arms-2026-10-11-v1 --case g2-next-4417-d3a3 --output docs/codex/threads/ai-competitors/sims/g2-envelope-replay-4417-d3a3-v1 --timeout 240
& $py tools/simulate.py replay --godot $godot --bundle docs/codex/threads/ai-competitors/sims/g2-envelope-arms-2026-10-11-v1 --case g2-next-90210-d1a1 --output docs/codex/threads/ai-competitors/sims/g2-envelope-replay-90210-d1a1-v1 --timeout 240
```

Primary retained evidence: [prefix run](sims/g2-envelope-prefix-2026-10-11-v1/run-report.json), [six-arm run](sims/g2-envelope-arms-2026-10-11-v1/run-report.json), four [4417 1→2](sims/g2-envelope-compare-4417-d1a1-d2a2-v1/comparison.md), [4417 2→3](sims/g2-envelope-compare-4417-d2a2-d3a3-v1/comparison.md), [90210 1→2](sims/g2-envelope-compare-90210-d1a1-d2a2-v1/comparison.md), [90210 2→3](sims/g2-envelope-compare-90210-d2a2-d3a3-v1/comparison.md) comparisons, and [4417 long](sims/g2-envelope-replay-4417-d3a3-v1/run-report.json) / [90210 short](sims/g2-envelope-replay-90210-d1a1-v1/run-report.json) replays. Raw cases, telemetry, source manifests and logs remain inside the run folders.
