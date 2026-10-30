# Highest versus same-seed lowest 8+ title: Pass and synergy trace — 2026-10-27

**Status: DESIGN diagnostic; no gameplay or balance adoption.** The [predeclared trace plan](2026-10-27-pass-synergy-trace-plan-v1.md) compares the 9.1 Role-Playing game to one of the tied lowest 8.0 games: Simulation in seed `4423`, project 2, both released at cycle `37`, Scope `39/30`, zero Bugs. It answers hand frequency, not a causal estimate of the Review gap.

## Source and method

Checkout `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; concurrent shared edits and `.codex-godot-temp` preserved. The [private trace variant](simulators/rival-pass-synergy-trace-20261027-v1) is a child of the [G specialty-only diagnostic](simulators/rival-specialty-only-ceiling-20261027-v1), with the same original baseline/ancestry. Its only source delta adds observation of the four selected candidate card definitions/types and pure synergy classification before accepted Design, Alpha and Beta `play` commands. It changes no choice, command, Review, finance or RNG rule. [Isolated bundle](sims/rival-pass-synergy-trace-bundle-20261027-v1) manifest SHA-256 `41431013163c78b522e8b04d87d05ba16aa8431485d6be7cc7043f0aed54dd2f`; Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. The gameplay source identity emitted by the probe is `d3d6202082c59e297d35cc29b5d4ef9171fdc3e82786fcb0c11ec5bb86fcb9be`, matching G because only the probe changed.

The 50-command smoke completed 18 actual commands. The [seed-4423 trace](sims/rival-pass-synergy-trace-4423-20261027-v1/prestart-shadow.json) reached cycle72/300-decision-per-studio bound with 24 releases, zero failures, zero blocked waits and no timeout; source/run details are in its `prestart-shadow.command.json` and `prestart-shadow-run.json`. Removing only the added `hand_trace` field made its **entire JSON result equal** to [the original G seed-4423 result](sims/rival-specialty-G-4423-20261027-v1/prestart-shadow.json), including all eight studios' initial state, action events, releases, cash and final state. The [cold repeat](sims/rival-pass-synergy-trace-4423-repeat-20261027-v1/prestart-shadow-run.json) matched result SHA-256 `4fb6c03382546f97acf0008129d5faba70e4e2a015f0601e7b08058e0f2688ac`; [fresh 18-step replay](sims/rival-pass-synergy-trace-replay-20261027-v1/replay-report.json) passed. No rejected/incomplete case occurred.

Exact commands (PowerShell from repo root):

```powershell
$pnPython='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $pnPython tools/simulator_variant.py create --id rival-pass-synergy-trace-20261027-v1 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/rival-specialty-only-ceiling-20261027-v1 --output docs/codex/threads/ai-competitors/simulators/rival-pass-synergy-trace-20261027-v1
& $pnPython tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-pass-synergy-trace-20261027-v1 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-pass-synergy-trace-bundle-20261027-v1 --godot $pnGodot --timeout 240
& $pnPython docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/rival-pass-synergy-trace-bundle-20261027-v1 --output docs/codex/threads/ai-competitors/sims/rival-pass-synergy-trace-4423-20261027-v1 --seed 4423 --godot $pnGodot
& $pnPython docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/rival-pass-synergy-trace-bundle-20261027-v1 --output docs/codex/threads/ai-competitors/sims/rival-pass-synergy-trace-4423-repeat-20261027-v1 --seed 4423 --godot $pnGodot
& $pnPython tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/rival-pass-synergy-trace-bundle-20261027-v1 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/rival-pass-synergy-trace-replay-20261027-v1 --godot $pnGodot --timeout 240
```

## Observed project hands

| Game | Design Pass cards / hands using Pass | Alpha Pass cards / hands using Pass | Production synergies | Beta synergies |
| --- | ---: | ---: | --- | --- |
| Role-Playing 9.1 | 7 / 3 of 5 | 6 / 2 of 5 | Design: 1 Balanced; Alpha: 3 Specialization — **4 of 10 production hands** | 2 QA, 3 Marketing, 2 none — **5 of 7 Beta hands** |
| Simulation 8.0 | 7 / 3 of 5 | 6 / 2 of 5 | Design: none; Alpha: 1 Specialization — **1 of 10 production hands** | 2 QA, 3 Marketing, 2 none — **5 of 7 Beta hands** |

Each used **13 Pass cards across 40 Design/Alpha card slots**, in five of ten production hands; the other 27 selected slots were Features. Neither used an all-Pass production hand. Both took five Design, five Alpha and seven Beta hands. Beta card definitions and synergy classes were identical between these two projects. Synergy labels are calculated from the selected four-card hand using the same pure Production/Beta classifiers as the simulator; the unchanged release/action parity checks guard the trace against changing play.

Role-Playing's final Core was `28/30/43/50` against project standards `20/26/40/46`; Simulation's was `23/29/41/42` against `20/20/59/33`. Both had Scope `39/30`, zero Bugs and the same release cycle. Simulation's Technology was 18 below its target, while Role-Playing exceeded all four of its targets. The extra production synergies coincide with a better Core fit, but this paired observation does **not** isolate their causal effect from different chosen Features, Genre targets, prior studio state or ordinary variance.

The starting 27-Primitive grant was synthetic and unpaid. These are neutral solo 1980→1983 duration proxies with forced specialty Genre, not legal 1977–1980 histories or current live AI. No selected balance change, TODO implementation handoff or claim about eight-rival shared Market/player challenge follows from this trace.
