# AI Competitors Action historical-standard spike — session log, 2026-10-28

**Branch/HEAD:** main / f3e0f2b5d35270c879327bc297b389748571feb4. The shared worktree was dirty before this session and remains so; canonical gameplay, TODO and .codex-godot-temp were untouched. No commit, push or release claim.

## Work and source boundary

Read CURRENT_STATE, TODO, README, Genre design, selected AI decisions/findings, simulator VARIANTS/USAGE, v10 private source and relevant market/project/checkpoint code; inspected branch, HEAD, tracked status and diff. Wrote [pre-run plan](2026-10-28-action-typed-standard-prototype-plan-v1.md). Created private v11 then v12 using simulator_variant.py, preserving v10 ancestry and original baseline. Only the private project files scripts/market/historical_standard_trial.gd, scripts/market/market_transaction_trial.gd, scripts/project_state.gd and scripts/debug/one_action_prelude_probe.gd were edited. New thread-owned wrapper and audit scripts: run_one_action_typed_standard_v1.py, analyze_action_typed_standard_v1.py and analyze_action_typed_standard_v2.py. Wrote [finding](2026-10-28-action-typed-standard-prototype-finding-v1.md) and this log. The private v12 source differs from current canonical; no adoption packet.

## Checks/results

- v11 isolated smoke: PASS; N5601 c80: PASS; M5601: FAIL at Game3 Begin c34 because source ID JSON decoding lost integer type. Retained [failure](sims/one-action-typed-midpoint-5601-20261028-v11/prelude.json). Fixed only in new v12 with typed Variant-byte encoding.
- v12 isolated smoke via tools/simulate.py run: PASS, one release in 18 commands; [bundle](sims/one-action-typed-standard-bundle-20261028-v12/run-report.json). Its smoke fixture is a runner/import check, not a historical-standard comparison.
- Four seeds 5601/5607/5613/5619 × N/M through the frozen v12 bundle and separate profiles: 8/8 PASS to c80, no rejected commands, complete source validation/tamper/early-boundary/neutral-sales checks, full-Scope releases. [Audit v2](sims/action-typed-standard-analysis-20261028-v12-audit-v2.json) reports zero problems.
- First audit v1: FAIL six assertions because it assumed Game2 could not start at the effective boundary. Preserved [rejected audit](sims/action-typed-standard-analysis-20261028-v12.json); boundary-aware v2 passes.
- Fresh-process exact replay: [N5601](sims/one-action-typed-none-5601-replay-20261028-v12/replay.json) PASS, [M5613](sims/one-action-typed-midpoint-5613-replay-20261028-v12/replay.json) PASS. [M5613 independent repeat](sims/one-action-typed-midpoint-5613-repeat-20261028-v12/prelude.json) has identical report SHA-256 to original. Python py_compile for audit v2: PASS.
- Numeric result: all four paired first releases identical; first Reviews 7.0/6.9/6.8/6.9. Pre-1980 8+ titles N=2, M=4 across alternative solo Action careers. M changes later actual Reviews, including a 9.7. One c72 Beta and three c72 Design projects; M c72 rent has no late/unpaid bill or Bank loan.

The exact version creation, smoke, career and audit commands are in the [finding](2026-10-28-action-typed-standard-prototype-finding-v1.md#exact-commands). Every run folder retains prelude.command.json, log, report, frozen project, profile and source manifest. Replay command lines are retained in their own folders.

## Follow-up

Keep M OPEN. Source-matched current Store rebaseline, compact persistent source/archive validation, c72 January projection, old sales/Fans closure, shared Market/player effect, eight-Genre legal cohort and CPU/save/Continue remain required before a QUEUED implementation handoff. No TODO edit was made because these acceptance gates are incomplete.
