# AI Competitors quality/cadence session — 2026-10-23

## Source and scope

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The shared worktree was heavily dirty before this study; its existing edits and `.codex-godot-temp` were preserved. No canonical gameplay, player save, commit, push or computer-control action was made. Current source and private variant identities, exact runner commands and output links are in the [finding](2026-10-23-rival-quality-cadence-finding-v1.md).

## Changed files

- Added dated plans, input configs, read-only audit scripts/results, one failed v1 selector variant, corrected v2 selector variant, v3 interleaved-world variant, isolated run bundles, a source-context correction, a [direction](2026-10-23-quality-cadence-direction-v1.md) and [finding](2026-10-23-rival-quality-cadence-finding-v1.md) under this thread. Variant edits affect only their private `project/scripts/market/rival_trial.gd` copies.
- Updated this thread's `README.md` and `working-notes.md` with the new target/finding.
- Added one design-status entry each in `docs/codex/DECISIONS.md` and `docs/codex/CURRENT_STATE.md`, and one minimal item-22 paragraph in `docs/codex/TODO.md` after immediately re-reading the live queue.

## Checks and results

- Independent ordinary-roster 2/2/2 control: four legal cycle-7 releases, Review 1.3–2.3. Longer Feature-first 12-case screen: all legal, cycle11/13/16 as declared. 5/11/3 ceiling: four legal cycle-20 releases; representative Adventure exact fresh replay passed 31 commands.
- Selector v1: **FAILED** 16/16 at command zero because integer-valued JSON input materialized as float. Retained unchanged. Selector v2: 16/16 completed; within-source equal-start/RNG audit passed; synergy/Beta choice improved all eight paired Reviews by 0.4–1.3 at unchanged observed cycle/cash. Action and Adventure exact fresh first-release replays passed 27 and 31 commands. Four same-source Studio-only second-release continuations passed legal/no-arrears checks.
- Actual-cohort interleaved worlds: A and B in seeds 4417 and 4418 had equal complete initial state/RNG within seed; all four completed 144 legal player commands, eight player releases through cycle 56. A had 16 rival publications; B had five. A world checks passed 15,174 each; B passed 8,316 each. B 4417 exact fresh world replay passed 144 steps/8,400 assertions; B 4418 Studio-only restore passed eight fresh-process checks. B raised rival Reviews but increased player earned units by 266/263 and settled cash by $1,860.12/$1,839.16.
- Provenance correction: current `run_factory.gd` ignores the old independent fixture's `incumbent` member; absolute independent Reviews describe ordinary specialty rosters. Actual world A/B uses real `RivalTrial.create_world` incumbent grants. Original inputs and failures are retained.
- Final documentation check: `git -c core.whitespace=cr-at-eol diff --check -- docs/codex/CURRENT_STATE.md docs/codex/DECISIONS.md docs/codex/TODO.md docs/codex/threads/ai-competitors/README.md docs/codex/threads/ai-competitors/working-notes.md` passed. Four new narrative docs have no trailing whitespace; finding, direction, audit and fresh replay/restore links exist. The unadjusted `git diff --check` reports pre-existing CRLF line endings in the thread README as whitespace, so the CRLF-aware result is the relevant check.

## Disposition and follow-up

The exact fixed 5/7/3 Action + 5/11/3 Adventure mix is rejected for adoption. The user target remains at least ten productive cycles and generally 6–7 Reviews, but no exact new rival policy is approved. The next bounded study must retain enough actual recent publications to avoid easing the player's fixed-horizon market, while making legal rivals stronger. Test a shorter quality-aware plan/Feature supply and then bounded entrants or separately designed market presence. Phase numbers, solvency thresholds, population CPU, Genre/Theme choice, news, leaderboard and final market coefficients remain OPEN. No implementation handoff is ready.
