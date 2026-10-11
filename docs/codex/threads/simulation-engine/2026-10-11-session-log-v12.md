# Simulation Engine session v12 — M4c paired studies

Date: 2026-10-11, America/Los_Angeles. Branch `main`; HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Dirty worktree on entry and exit; existing edits and `.codex-godot-temp` preserved. No TODO edit, commit, push, export or computer control.

## Request, scope and files

The user authorized the suggested follow-up to make simulation studies reusable by other threads. Read CURRENT_STATE and TODO, then README provenance, relevant Store/Simulation Engine records and current source. Inspected branch/HEAD/status/diff and archived the starting source before edits. Added optional detached campaign measurements, exact measurement replay, paired Store preparation/policy, comparison reports and maintained coverage. Disjoint agents handled Store tooling/integration, report tooling/review and verifiers; root handled telemetry/replay integration, final focused checks and documentation.

[M4c implementation record](2026-10-11-extraction-m4c.md) lists changed files and evidence limits. Existing commands, finance/card rules, catalog and Studio-only Continue remain unchanged. No candidate strategy or balance value was promoted to approval.

## Exact checks and results

Python: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`. Godot: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.

- `python docs/codex/threads/simulation-engine/m4c-v1/prepare.py`: archived 273 initial files, HEAD, status and tracked diff.
- `python docs/codex/findings/card-presentation-v2/run.py import m4c-import-01` and `... import m4c-import-02`: exit 0, no unignored errors. First import overlapped a revision of the new debug-only telemetry verifier; other differences are generated UIDs. Second import and all focused checks use the completed verifier, with stable source during those checks.
- `python docs/codex/findings/card-presentation-v2/run.py m4c-telemetry-01 verify_campaign_telemetry.gd`: 374 checks, zero failures, source unchanged.
- `python docs/codex/threads/simulation-engine/m4c-v1/run_checks.py`: four further maintained suites pass with unchanged source: Store study 230 checks; campaign batch 38 checks; native/headless parity 94 matching boundaries; continuation 23 suffix commands and nine financial comparisons. The same script runs `python -m unittest discover -s tools/tests -v`: 38 tests pass. Exact subprocess commands, timings and warnings are retained in [focused-checks.json](m4c-v1/focused-checks.json), harness folders and `python-tests-command.json`/`python-tests.log`.
- `python docs/codex/threads/simulation-engine/m4c-v1/run_store_study.py`: two declared first-release prefixes and four legal research/defer arms, without retuning/retries. Four fresh source-isolated replays match 76 commands and independently recompute 80 telemetry samples. Exact CLI argv are in [store-study-commands.json](m4c-v1/store-study-commands.json), with process/import logs retained per bundle.
- Two `python tools/compare_simulations.py --bundle ... --left ... --right ... --output ...` runs generate both real reports; exact commands are in `store-comparison-commands.json`.
- `python docs/codex/threads/simulation-engine/m4c-v1/audit_store_study.py`: 90 checks pass, including unchanged origin/RNG, quoted/recorded Store payments, actual ownership timing, deferral and full replay.
- `python docs/codex/threads/simulation-engine/m4c-v1/negative_telemetry.py`: a one-cent altered measurement with the original state digest is rejected by semantic replay at step 1 with exit 1. This intentional negative fixture bypasses the file-hash layer only to exercise full recomputation; original bundle/source hashes remain unchanged.
- `python docs/codex/threads/simulation-engine/m4c-v1/audit.py`: final scope/source/results audit, unchanged TODO/data/HEAD and before/after source archives. [Acceptance](m4c-v1/acceptance.json).
- Focused `git diff --check` and added-file whitespace audit: results retained in `m4c-v1/diff-check.json`.

## Findings and limits

Both declared Store pairs complete at the second-release Studio horizon. Research adds one cycle and improves the two sample Reviews from 2.0 to 2.4/2.2, with lower cash; there are no Fans/arrears/blockers in these cases. Live familiarity changes the second seed's completion charge. These examples establish usable tooling and mechanics evidence, not balanced pricing or an AI shopping recommendation. The reports separate calendar from release milestones and retain failure/unknown states.

No implementation test required a repair or a changed study input. Negative fixtures intentionally exercise rejection. The first two final-audit attempts assumed only UID additions, then a newly created verifier, during import. The recorded hashes instead establish a revision of the separately authored telemetry verifier during the first import. The audit now permits that exact debug path and original hash only when its new bytes match tested final source; this did not alter or rerun study results. Fresh runner copies precede the final debug-only Store regression verifier; mechanics/data/assets match final source. Native parity logs retain missing-artwork and intentionally invalid Alpha-action warnings; the environment certificate-store error is filtered by the established harness, and ObjectDB shutdown warnings remain. No full gate, leak-free, visual, audible, export, shared-world AI or performance conclusion is claimed.

The [usage guide](USAGE.md) now tells other threads how to prepare/report/replay pairs and regenerate them after source changes. Further system studies require their own declared question and policy. AI decisions still marked OPEN and shared-world scheduling remain follow-up work.
