# Feature Store local session v5

Date: 2026-10-06 (America/Los_Angeles). Branch `main`; HEAD `553d1a46f33d59641efa4c2e4ff141f958c1230d` before and after both cohorts. Existing edits by other design threads and the central TODO were preserved. No gameplay code, tests, assets, configuration, implementation authority, or shared TODO edit was made here. No commit or push claimed.

Changed in this thread folder: `sim-v2/` exploratory driver/runner/analysis, compressed traces/logs and serial-rerun provenance; `sim-v3/` corrected driver/runner/analysis/audit, predeclaration, 21 compressed native traces/logs, report and summary; `FINDINGS-v5-timing-pilot.md`, `README.md`, `HANDOFF.md`, and this log. The copied drivers register candidate cards only in their Godot process and output only to their own thread subfolder.

Checks and results:

1. `& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B docs/codex/threads/feature-store/sim-v2/run.py`: initial 21-route threshold screen. A $1,500 reserve bought immediately; latest-release-at-post-launch settlement condition never bought. One output-file-open failure timed out while a stale pilot trace occupied that path. `finalize_rerun.py` verified the successful serial rerun, preserved the failed first attempt and updated its raw hash. This first screen is methodological evidence only.
2. `& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B docs/codex/threads/feature-store/sim-v3/run.py`: 21/21 corrected native routes exit 0 and valid, zero unexpected errors or route discrepancies, no tracked source changes; exact commands/profiles/hashes in `sim-v3/run-report.json`.
3. `& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B docs/codex/threads/feature-store/sim-v3/analyze.py`: generated per-route `summary.csv`; four settled-stronger Action routes purchased after Game 3 and played the card in Game 4; six reserve routes abstained.
4. `& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B docs/codex/threads/feature-store/sim-v3/audit.py`: passed 21 trace hashes, startup/finance/native ledger checks, tracked-source hashes, purchase/supply/play, stable HEAD and driver. `git diff --check` exited 0; only line-ending warnings for concurrently edited files.

Limitations/follow-up: one seed, $5,700 starts only, trial cards with current temporary zero later-card fee, four-release horizon ending before Game 4 settlement. Conservative reserve makes no purchases; delayed threshold is a tested candidate, not an approved rule. The shared Task 2 read-only comparison still needs the wider cohort and economic payoff review before any Store design decision.
