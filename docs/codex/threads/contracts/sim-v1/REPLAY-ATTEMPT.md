# Focused Task 34 replay attempt

2026-10-07 (America/Los_Angeles). **Blocked before route execution.** The read-only replay predeclaration is [PREDECLARATION.md](PREDECLARATION.md). Branch `main`, HEAD `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`; `git status --short -- patch-notes` was empty before and after the attempt. No gameplay source, tests, assets, configuration or shared queue was edited.

The exact historical route is [`task32_strong_probe_v1.gd`](../../../../../patch-notes/analysis/task32_strong_probe_v1.gd), not the Task 32 batch route. Historical output `patch-notes/design-logs/task32-v1/strong_probe.json` reports Action specialty, synergy policy, seed 4417, existing `recorded_sounds` Store purchase, genuine old $5,500 start, Game 1 Review 3.8 at cycle 12, Game 2 Review 9.0 at cycle 32, and final cash $0 with $147.65 rent arrears. That is historical evidence only; no current $5,700 replay has been produced.

Before adapting the route, a minimal [external script](load-probe.gd) was run with Godot 4.7.1 (`a13da4feb`) using [this exact command record](load-probe.command.json). It exited `-1073741819` (signal 11 / access violation) before printing its success marker. The [crash output](load-probe.log) contains a Godot backtrace and no route data. As instructed, the attempt stopped at the external-script load failure. No current-source Contract or finance behavior was inferred from this crash.

Relevant current SHA-256 source identity:

| Path | SHA-256 |
|---|---|
| `patch-notes/analysis/task32_strong_probe_v1.gd` | `920C338AE40EBB5E592AC0FA1559772C88BD3C82EE2AA369C2B9455198B470FD` |
| `patch-notes/analysis/feature_store_rebaseline_v1.gd` | `38B4F19022617E25BA6C8912F0468CDB18F896E3F2321B048A281F894B8AB109` |
| `patch-notes/scripts/phases/main_menu.gd` | `4173AB675110178CE15B3277831C6F731890950901591183B727B49F7D1250C6` |
| `patch-notes/scripts/gameplay.gd` | `AB79F724D3510C63CC918AFD16B1184B0F083E2CB52FAC9B2A7D80BA503AC09F` |
| `patch-notes/scripts/run_state.gd` | `DDAE87856F7D5BD4DBBD424A9774E6DEB420390A1CE6A9CA384E98F0A9F33B84` |
| `patch-notes/scripts/finance/studio_finance_ledger.gd` | `12EC0733C2B17FA4C3EC5377F3022E9744C392D2AF2D1D3E06296DF424FEAF82` |

An isolated project copy within this folder is now the authorized follow-up execution path. Its result will be recorded separately. The $0/$150/$200/$300 advance grid remains unrun and all amounts remain candidates.
