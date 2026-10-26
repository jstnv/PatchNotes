# Proportional rival Beta hands: first legal comparison — 2026-10-24

**COMPLETE bounded DESIGN finding; no adoption.** The user's proposed direction is to scale Beta hands with prior Design/Alpha hands. One third, rounded up with a two-hand minimum, was tested as a private ratio against the current two-Beta-hand policy. It is not approved gameplay or final balance.

## Source and declared comparison

The [pre-run plan](2026-10-24-proportional-beta-study-plan-v1.md) fixed the hypothesis, seed order, Action/Fantasy route, player-command/release/cycle and process bounds, metrics and stop. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty worktree and `.codex-godot-temp` preserved. No canonical gameplay changed. The independent [control](simulators/rival-proportional-beta-control-20261024-v1/variant.json) and [candidate](simulators/rival-proportional-beta-20261024-v1/variant.json) have the same recorded base identity `b208a690798577094d632eadaffec32dc42a0e4d02973b609b481411093aa0e5`; the only differing project file is `scripts/market/rival_trial.gd` (control SHA256 `97b14cf370e02e142306eda602f88d2cc31349e231f6eb861cbe306dd7f3a293`, candidate `46547cb738c9edfa68ea962f292c4bdd564e97f0c583f43175c6172c10470bd1`). No Beta card, Review, market, cash or roster rule changed.

Control gameplay source identity `5da7bc70f45fc63d33e6f5293e77338992038810b84a2c964ff47aff7a2b1a64`; candidate `091b874b35e3ad186fab9506f8850f4e8b18cb90cb2c8bda43c777de48b128db`. Both worlds have identical initial full state digest and typed RNG. They diverge after actual policy actions, as expected. The candidate adapter computes Design+Alpha accepted hands from project productive cycles minus Beta hand revision; this is exact for the current trial policy, which never redraws or host-playtests. It is **not** a future general action ledger.

## Outcome at the fixed player cycle-56 horizon

Both seed-4417 worlds legally complete 144 player commands and eight player releases; [control](sims/rival-proportional-beta-control-4417-20261024-v1/world-run.json) passes 11,015 checks, [candidate](sims/rival-proportional-beta-candidate-4417-20261024-v1/world-run.json) 10,331, with zero failures/source drift. The [read-only audit](sims/rival-proportional-beta-audit-20261024-v1.json) independently counts distinct accepted hand sequence IDs and verifies every completed candidate project used `max(2, ceil((Design+Alpha)/3))` Beta hands.

| Fixed-horizon measure | Two-hand control | Proportional candidate |
| --- | ---: | ---: |
| Actual rival releases | 10 | 8 |
| Beta hands per completed project | 2 | 3–4 |
| Mean rival Review | 5.00 | 4.96 |
| Rival Reviews at least 6.0 / 7.0 | 1 / 0 | 1 / 1 |
| First rival release cycle | 10 | 11 |
| Player earned units | 1,860 | 1,948 |
| Player final cash | $2,196.95 | $2,812.32 |
| Player final Fans | 2 | 2 |
| Studio/world checkpoint bytes | 714,916 | 696,934 |

The candidate's Arcade Foundry opening release improves 5.9→7.2 and remaining Bugs 6→1 after four rather than two Beta hands. Wayfinder's opening improves 3.4→3.6 with Bugs 8→7. Subsequent projects no longer share identical pre-Beta states because the extra months and card RNG change the full world. The eight completed candidate projects play their intended quotas; at the horizon both Studios have active, right-censored next projects (Wayfinder Beta and Arcade Alpha). Control has Arcade in Studio and Wayfinder Design. The player's +88 earned units and +$615.37 final cash indicate easier measured market pressure. A single seed cannot establish a general cadence or Review distribution.

Fresh-process [candidate replay](sims/rival-proportional-beta-candidate-4417-replay-20261024-v1/world-run.json) passes 144 commands/10,415 checks with exact state and RNG. Separate [Studio-only Continue](sims/rival-proportional-beta-candidate-4417-restore-20261024-v1/world-run.json) passes eight checks. The actual control/candidate world wall times are 48.55/52.95 seconds on a shared host; Windows process CPU counters were implausible and are excluded from performance conclusions. No larger-population CPU run was performed for this rejected simple ratio.

## Retained commands, failures and limits

Run with Python `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe` and Godot console `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe` (SHA256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`). The [candidate smoke](sims/rival-proportional-beta-smoke-20261024-v1/run-report.json) and [control smoke](sims/rival-proportional-beta-control-smoke-20261024-v2/run-report.json) each pass 18 legal commands/one player release. The first [control capture](sims/rival-proportional-beta-control-smoke-20261024-v1/run-report.json) failed because canonical source changed during drift recording; its output is retained, and the v2 control is the successful frozen comparison. Exact [control](sims/rival-proportional-beta-control-4417-20261024-v1/world.command.json), [candidate](sims/rival-proportional-beta-candidate-4417-20261024-v1/world.command.json), [replay](sims/rival-proportional-beta-candidate-4417-replay-20261024-v1/world.command.json) and [restore](sims/rival-proportional-beta-candidate-4417-restore-20261024-v1/world.command.json) command receipts include full arguments, source identities and timeouts. Audit command: `python docs/codex/threads/ai-competitors/2026-10-24-proportional-beta-audit-v1.py` → PASS all seven declared checks. The private variant creation commands and original-source ancestry are retained in their `variant.json` manifests.

Seed `4418` is **NOT RUN**. The declared early design stop applies: in seed4417 the simple ratio lowers publication count without a meaningful aggregate Review or 6.0+ gain and eases the player's market. Do not silently generalize from the one 7.2 title, and do not queue this candidate. The user's proportional-Beta idea remains **OPEN**; next design work should test whether additional Beta hands are actually used for Search and Debug, possibly with a legal QA-aware opportunity rule, and measure title density and player pressure together. A future general rule also needs a saved authoritative hand count rather than this current-policy cycle adapter. One-to-two scaling would add still more months in these starts and was logged as an untested alternative, not rejected by direct simulation. No TODO implementation handoff, commit, push or canonical change follows.
