# Banking and Computer Use status recheck — 2026-10-10

Read-only response to the user's note that implementation should be done. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; the shared worktree remains dirty. No source, shared TODO, gameplay, commit or push change in this review. This log and its README link are the only edits.

## Confirmed scope

- Banking loan acceptance, installment and payoff paths remain present in `patch-notes/scripts/finance/studio_finance_ledger.gd`; typed education servicing and payoff are present there too. The current exported route independently observed $500/12-month loan acceptance, cold Continue, $46.67 first installment, $458.33 payoff and later Continue. College Dropout creation, zero-cycle grace-period payoff and fresh Continue also passed. The source-pinned evidence is `docs/codex/findings/export-interaction-20261010-v2/README.md` and its `audit-result.json` (3,304 checks, 66 captures, no retained runtime errors).
- The earlier Design verifier failure was reconciled as a stale assertion for deferred presentation; the focused check and complete 108/108 maintained suite gate passed on the recorded source. Clean export, 237-entry PCK audit and isolated headless startup also passed. Evidence: `docs/codex/findings/release-gate-noninteractive-20261010-v1/README.md` and `completion-audit.json`.
- T9 Cult's bounded visible route is complete. Crown/Neon and Starwave core interaction routes passed at bounded scope; their full both-size keyboard/continuation matrix remains partial. The shared TODO and CURRENT_STATE already distinguish these statuses. This is implementation/observed-route verification, not a release or final balance approval.

## Current-source limit

The later Alpha/Beta playtest-percentage change is implemented and its focused Alpha/Beta checks passed in `docs/codex/logs/2026-10-10-playtest-percentages-v1.md`. It postdates the 108-suite gate and four exported routes. Exact SHA-256 comparisons against the gate's `source.json` now differ: Alpha `efc233f69f9c1901e9de1afcacb310fae00e456d28c30515dccd657f9da0ed64` versus current `c93c7dfe44216ea9f288b51cb99a247fef080f52459bfbfb990855a5398d0cb1`; Beta `7ce1aada512d669e3e5476336f5e372c75ff9f49e52be85c5ef9c4960425d26d` versus current `b3b20bb4aa8a71a2bb7e496ea0ab33f3075b364b37dbff594cc497c531d6600a`. A fresh full gate/export is required before claiming acceptance on the exact latest source.

Remaining visible acceptance is the full publisher presentation matrix, positive-sales/second-launch Promotion observation, and late/partial education, Graduate and older-preview migration routes. Audible and human playtesting also remain separate. These are acceptance gaps; they do not reverse the implemented Banking or bounded T9 results.

Checks in this review: read current source, TODO, design and findings; inspected branch/HEAD/status/diff; verified `audit-result.json`, `completion-audit.json`, and the two current file hashes. No test process was rerun.
