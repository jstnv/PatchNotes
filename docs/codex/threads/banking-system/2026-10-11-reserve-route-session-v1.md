# Banking reserve route session — 2026-10-11

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` before and after. The shared worktree was already dirty; contemporaneous edits in other threads and `.codex-godot-temp` were preserved. No canonical `patch-notes/` gameplay edit, commit, push, export or computer control. The unchanged private `education-bank-quote-v3` candidate was used only through isolated `tools/simulate.py run --variant` copies.

## Changed Banking-owned files and shared handoff

- Added [predeclared v1](2026-10-11-reserve-route-plan-v1.md) and [v2](2026-10-11-reserve-route-plan-v2.md) plans; versioned admission/pair policy/config builders and outputs under `simulations/reserve-*`.
- Added [source-pinned finding](2026-10-11-reserve-route-finding-v1.md) and [design handoff](HANDOFF-RESERVE-ROUTE-v1.md); appended the thread README.
- Minimally appended one DESIGN status entry to `docs/codex/TODO.md` after a fresh read. No PN Implementation task or adoption packet was added.

## Exact checks and results

The finding records every full simulator, reporter, replay and reducer command with executable paths. `reserve-admit-run-v1`: two valid five-action c16 Studio prefixes, each `command_bound`, $833.77 cash and no overdue bill; the overall run exited 1 because the release target was intentionally unmet. `reserve-pairs-run-v1`: 6/6 completed second releases, one-hand Reviews 0.0–0.5. `reserve-two-hand-run-v2`: 4/6 completed, two $500 `rejected_policy_action` cases at c22 with $176.92 rent/Bank arrears; $1,000 arms completed c24/Review1.9 with $666.64 principal outstanding. All eight pair reporter calls exited 0, checked same source/fork state/RNG and telemetry; the two $500 two-hand pairs remain incomplete. Six representative `simulate.py replay` calls exited 0 with telemetry verified, including a rejected tape. One `reduce_simulation.py --kind rejection` call exited 0 and fresh-confirmed the $500 rejection from an exact Studio restore. The unchanged private v3 project's six focused verifier results were carried as prior source evidence, not rerun or described as new checks. No timeout.

Read-only UI inspection covered `patch-notes/scripts/ui/studio_finances.gd`, `feature_store.gd` and `finance/feature_spending_guidance.gd`; current Bank schedule and Store Research/spending guidance are present. Human comprehension/exported interaction was not tested. Local Markdown link resolution for four new docs passed. `git diff --check` reports unrelated pre-existing trailing whitespace in Contracts files; no new Banking whitespace finding was produced.

## Blockers and next step

The headless fixture did not show a meaningful-quality game-two benefit from borrowing or prove that Scripted AI was drawn/played. The accepted delayed first-game 6.2/bankruptcy pressure and latest-source exported late/partial debt acceptance remain separate. Next Banking DESIGN work requires a predeclared realistic production/card-use route and common post-release sales checkpoint; any Bank amount/capacity/UI change needs an explicit ruling before implementation. No canonical change is ready for PN Implementation from this session.
