# Simulation Engine session v10 — campaign parity and batch foundation

Date: 2026-10-11 (America/Los_Angeles). User authorized the next implementation with “Go for it.” Branch `main`; HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Existing large dirty worktree inspected and preserved; no commit/push. `patch-notes/.codex-godot-temp` untouched. No TODO edit, gameplay rule/data change, export or computer control.

## Work

Read CURRENT_STATE/TODO, repository provenance, Simulation Engine brief/review/architecture/M3b records, relevant core/checkpoint design and current AI Competitors handoff. Saved the pre-turn source archive, hashes, status and diff in `m4-v1`. Used a disjoint batch implementation subagent and read-only native/API/artifact reviewer; no concurrent overlapping gameplay edits. Source was frozen before accepted recordings.

Added six scripts: simulation `run_factory.gd`, `campaign_batch.gd`, `finite_fixture_policy.gd`; debug `campaign_batch_cli.gd`, `verify_campaign_batch.gd`, `verify_campaign_live_parity.gd`. Updated only the existing replay CLI's bootstrap delegation. Generated six script UIDs. Added M4 evidence/reproduction, this log and the [implementation assessment](2026-10-11-extraction-m4.md); updated the Simulation Engine README and high-level CURRENT_STATE after acceptance. The complete seven-script patch and file hashes are in `m4-v1`.

## Commands and results

Python used: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`.

Godot used: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe` (4.7.1 stable official).

1. `docs/codex/findings/card-presentation-v2/run.py import m4-import-01` — exit 0, no parse errors; import generated new UIDs, so source-change flag is expected for this import only.
2. `.../run.py m4-live-01 verify_campaign_live_parity.gd` — passed 94 boundaries; superseded for acceptance after new batch files changed the source identity.
3. `.../run.py m4-batch-01 verify_campaign_batch.gd` — failed four dependent assertions because the returned object-method Callable did not retain its RefCounted policy. No gameplay defect or economic retuning; original evidence preserved.
4. `.../run.py m4-batch-02 verify_campaign_batch.gd` — repaired fixture closure plus reviewed evidence protections; **34 checks pass**. Same source used by all accepted checks below.
5. `docs/codex/threads/simulation-engine/m4-v1/run_checks.py focused` — eight more suites pass; nine accepted focused suites total including `m4-batch-02`. Continuous native campaign comparison: **94 boundaries**, full mechanical state/RNG/signal parity on two declared seeds. Existing campaign, development, Contract and checkpoint suites pass.
6. `.../m4-v1/run_checks.py fresh` — **12 separate Godot processes, 208 recorded commands** replay exactly. Includes six native-comparison segments and six batch success/failure prefixes; the malformed-policy case has an empty prefix, and the rejected-policy case replays its one rejection without state mutation.

Each behavior process uses isolated APPDATA/LOCALAPPDATA, the maintained checkpoint wrapper and a 240-second external timeout. Accepted processes exit zero with no unexpected errors and unchanged source/harness hashes. The harness's pre-existing root-certificate-store error filter is unchanged; missing artwork/preview diagnostics and the existing two-object exit warning remain recorded. No audible, rendered or leak-free acceptance claimed.

## Performance and audit

Exact pilot commands, configurations, timings and hardware are recorded in `m4-v1/m4-pilot-*.check.json`, `m4-pilot-*.config.json` and the [acceptance report](m4-v1/acceptance.json). Timing includes replay hashing and evidence writes. The pilot runs independent campaigns serially, not concurrent rivals on a shared world clock.

All three commands pass, with one warmup and three measured repeats each:

```text
.../m4-v1/run_pilot.py m4-pilot-10x3 10 3
.../m4-v1/run_pilot.py m4-pilot-50x2 50 2
.../m4-v1/run_pilot.py m4-pilot-3x10 3 10
```

Median sample times: 16.514 seconds (10 × 3), 47.934 seconds (50 × 2), 46.108 seconds (3 × 10). All 252 cases including warmups reach their targets. The ten-release workload has lower instrumented throughput (11.71 commands/s versus 32.70/37.55); observation/policy and execution/trace costs remain separately bounded combined buckets. All measured cases have zero retained Godot object-count delta. Static allocation peak reaches 106,111,277 bytes; OS RSS and live rival scale are unmeasured.

`.../m4-v1/audit.py` passes the source/acceptance audit: every accepted run matches the current source, the seven-script allowlist matches, data/TODO/HEAD are unchanged, all parity rows match and measured repeats are deterministic. `git diff --check` passes; existing line-ending conversion warnings are not gameplay changes.

## Follow-up boundary

The generic observation/policy adapter and recoverable batch runner are usable for explicit experiments. Rival strategies, cohort starting resources, later Genre/Theme rules, world tick ordering and population/performance budgets remain OPEN in the AI Competitors handoff. The architecture's M4 is only partially fulfilled; shared-world M5 and actual rival-scale M6 remain. Further scenario matrices should answer specific questions rather than repeat completed grids.
