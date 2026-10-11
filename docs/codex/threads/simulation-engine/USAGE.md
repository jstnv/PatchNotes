# Run a headless simulation from any implementation or design thread

2026-10-11. This interface runs the existing authoritative campaign commands in an isolated copy of the current project. It needs Python 3.10+ and the matching Godot executable; no extra Python packages, exports, browser, native-window control or player-save access are required.

## Quick start

From the repository root in PowerShell, set your installed executable once:

```powershell
$env:GODOT_BIN = 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe'
python tools/simulate.py run --config docs/codex/threads/simulation-engine/examples/finite-fixture.json --output docs/codex/threads/my-system/sims/first-run --timeout 240
```

Alternatively supply `--godot <executable>` on each command or put `godot`/`godot4` on PATH. Use the locally available Python executable if `python` is not on PATH. The executable version and SHA-256 are recorded; replay also enforces the simulator's runtime and rules identity fences.

The example explicitly chooses a finite **test policy**, two hands per phase, two releases, seed 4417 and a 100-command bound. It is a usage fixture, not a recommendation or approval for AI strategy or game balance. Every study must state its own cases and horizon.

The output directory must be new. Existing directories are never reused or deleted. Each invocation gets its own copied project, `.godot` import cache and user profile. Separate threads can run concurrently with different output paths and without a shared checkpoint port. If source changes during snapshot capture, the tool fails and keeps the partial evidence; retry into a new directory. After capture, later workspace edits do not affect the running experiment.

## Inputs and policy contract

Copy either [finite-fixture.json](examples/finite-fixture.json) or [custom-policy.json](examples/custom-policy.json) into your thread folder. `schema_version` is the string `"1"`. Specify one policy declaration and an explicit `cases` array; seeds are decimal **strings** to preserve 64-bit values. Every case needs a unique safe `case_id`, one `initial.recipe` or `initial.checkpoint`, `max_commands`, an absolute `target_release_count`, and `policy.config`.

- `recipe` requires schema version **number** 1, stable Studio ID/name, permanent specialty, explicit trait IDs and a seed string. It creates a legal current-rules Studio; it does not grant arbitrary money, cards or scores.
- `checkpoint` is the existing source-pinned simulation Studio envelope. Active-phase snapshots and player save files are not accepted as arbitrary starting states. Continue remains Studio-only.
- A release target is an absolute total. Starting from three releases and targeting five requests two additional releases.
- Multiple cases are independent campaigns. Each gets a fresh policy instance. A batch is not a shared-calendar AI world and does not measure interactive rival scheduling.
- Policy `id` and `version` are caller-declared provenance. The runner fills each case's `source_identity` with the copied policy file's actual SHA-256; a supplied mismatching identity is rejected. The complete frozen project manifest pins its dependencies.

Policies implement `static func factory(config: Dictionary) -> Callable`. The returned callable receives a detached `CampaignSession.observation()` and returns `{ "type": <command>, "payload": <dictionary> }` (payload can be omitted). Commands remain subject to the existing legality, counter, affordability and RNG rules. A rejected or malformed decision fails that case and is retained; the runner does not silently retry, change the seed, increase budgets or edit rules.

`policy.script` can be an existing `res://...gd` path or a filesystem `.gd` path relative to the input JSON. An external policy is copied into the frozen project's debug folder. Only that single file is copied: dependencies must already exist at `res://` paths in the frozen project. Use one self-contained script or existing project dependencies; external adjacent files and relative filesystem imports are unsupported. [custom-policy.gd](examples/custom-policy.gd) shows the contract.

Policies are **trusted local executable code**, not sandboxed plug-ins. They must not load the live workspace, player saves, use network services, mutate rules, or inspect hidden future state. The runner isolates ordinary project and `user://` paths; it cannot restrict malicious GDScript or prove that an arbitrary policy uses only its observation.

## Exact replay

```powershell
python tools/simulate.py replay --bundle docs/codex/threads/my-system/sims/first-run --case action-4417 --output docs/codex/threads/my-system/sims/first-replay --timeout 240
```

Replay verifies and copies the original bundle's frozen source rather than current workspace source, imports a new cache, then runs the existing campaign replay CLI in a fresh process/profile. It initializes from the lossless `case.variant.json`, and checks the replay's final state and command count against the original result. When telemetry is present, it also verifies its file hash and recomputes every sample in a second independent session. Keep the whole original output folder. Exact tapes pin initial state, command results, ordered events, RNG state and rules/runtime identities. Replays cannot reconstruct policy reasoning or a malformed decision; for those cases they verify the recorded prefix only. A command rejected in the original tape can replay successfully when the same rejection and unchanged state match.

## Continue a completed Studio case

A case ending in Studio writes `cases/<id>/studio_checkpoint.json` and names it in `result.artifacts.studio_checkpoint`. Copy that entire readable codec envelope into the next case's `initial.checkpoint`. Do not use `final_state.variant.json` as a checkpoint or edit checkpoint fields. When a case ends outside Studio, the checkpoint artifact name is empty and no continuation envelope is produced.

The third example prepares a continuation from your own freshly generated evidence, without embedding an old source checkpoint:

```powershell
python docs/codex/threads/simulation-engine/examples/prepare-continuation.py --bundle docs/codex/threads/my-system/sims/first-run --case action-4417 --case-id action-4417-next --target-release-count 3 --max-commands 100 --output docs/codex/threads/my-system/sims/continue-input.json
python tools/simulate.py run --config docs/codex/threads/my-system/sims/continue-input.json --output docs/codex/threads/my-system/sims/continued-run --timeout 240
```

The helper preserves the original explicit policy/config, copies its pinned source file path and selects the existing Studio envelope. Its target is **three total releases**, so a case starting with two releases requests one more. The helper does not approve that policy or extend any study's authorized budget. A changed rules/runtime revision rejects an incompatible checkpoint; preserve the failure and rebaseline the study deliberately. Ordinary exact replay already uses the original bundle's source and remains available after workspace changes.

## Read the evidence

| Path in output | Meaning |
|---|---|
| `run-report.json` | Overall status, runtime/runner identity, failure reason or compact results |
| `experiment-report.json` | All deterministic per-case results and separate measured timings |
| `cases/<id>/result.json` | Case status, source/input/policy/RNG identities, counters and outcomes |
| `cases/<id>/metrics.json` | Measured setup, policy/observation, execution/tracing and artifact costs |
| `cases/<id>/telemetry.json` | Optional initial and post-command measurements linked to exact tape state hashes; cents and Fans are decimal strings |
| `cases/<id>/case.variant.json` | Lossless exact input; the readable `case.json` is a companion |
| `cases/<id>/replay.tape.json` | Lossless command/event/state replay tape |
| `cases/<id>/initial.json` | Explicit recipe or simulation Studio checkpoint for restart |
| `cases/<id>/final_state.variant.json` | Exact canonical final state; load with `DevelopmentReplay.load_tape`, not ordinary JSON traversal |
| `cases/<id>/studio_checkpoint.json` | Readable existing Studio codec envelope, emitted only at a valid ending Studio boundary |
| `inputs/` | Original request plus materialized policy/hash configuration |
| `project/` | Retained frozen runtime source/assets and private import cache |
| `workspace-source-manifest.json` | Exact working source hashes at snapshot capture |
| `snapshot-manifest.json` | Hashes after clean import and policy injection |
| `git-provenance.json`, `source.diff.patch` | Branch/HEAD, dirty status and tracked diff; copied source also preserves untracked runtime files |
| `*.command.json`, `*.log` | Exact commands, process status, timeout/error scan and raw output |

`result.outcome` is the readable analysis surface: `cash_cents`, `fans`, `calendar` (`year`, `month`, `half`, `label`), `phase`, `in_studio`, `releases` (each title's `id`, `metadata`, `sales`), `finance`, `employees`, `owned_features` and `research_queue`. Use those values for plots and comparisons. Preserve `final_state.variant.json` for exact types and large-integer analysis: JSON companions do not by themselves guarantee lossless typed 64-bit reconstruction. The final state is an inspection artifact; only the separate Studio envelope is an accepted continuation boundary.

Import and simulation each have the requested wall-clock timeout. A hung synchronous policy is terminated at the process boundary; completed cases and raw input/source/logs are retained, but an in-progress case may not have a completed tape. Use smaller batches when per-case diagnosis matters. Exit 0 means this bounded experiment or replay succeeded; nonzero means inspect retained evidence. Warnings and any explicitly ignored environment-only certificate-store errors remain in logs.

The tool preserves `.codex-godot-temp` and all source saves/caches. It never updates TODO, commits, pushes, exports, chooses unresolved AI rules or promotes findings to balance approval. A simulator can test mechanics, legal routes and numerical outcomes; audible playback, visual readability, input feel and user comprehension still require their respective playtests.

## Paired studies and comparison reports

The [Store study template](examples/store-study.md) starts with a legally played first release, then compares researching one explicitly selected Feature now against deferring acquisition while developing the next game. Both arms use exactly the same Studio checkpoint, RNG state, development policy configuration and horizon. It does not fabricate a free wait action or fund an unaffordable purchase. The helper preserves locked or unaffordable attempts as rejected results.

Prepare the pair using the template, then use the emitted case IDs:

```powershell
python tools/compare_simulations.py --bundle docs/codex/threads/my-system/sims/store-4417 --left store-PAIR-research_now --right store-PAIR-defer --output docs/codex/threads/my-system/sims/store-4417-comparison
```

The reporter runs without Godot and writes `comparison.json` and `comparison.md` into a new folder outside the input bundle. All deltas are **right minus left**. It verifies frozen source/input/policy hashes, pair provenance, equal initial state/RNG and horizons, and telemetry integrity. Run exact replay separately to recompute the measurements; file consistency checks alone do not prove gameplay outcomes.

- **Same calendar:** compare the last recorded boundary at each cycle shared by both arms, retaining zero-cycle actions in the raw telemetry. Do not extrapolate through missing cycles or beyond an arm's stopping point.
- **Same release:** compare the first post-launch sample attaining each new release ordinal. Initial checkpoint releases are listed separately. Launch date differences remain visible.
- **Cash lows:** report command-boundary lows and the minimum before/after each newly appended finance transaction separately. Past transactions inherited from the starting checkpoint are excluded. Neither measure observes a transient state absent from the finance journal.
- **Arrears, Fans and blockers:** report peak observed arrears, Fans, first financially blocked sample and first rejected request. Unavailable finance is unknown, not zero. Failed or bounded arms remain incomplete; missing releases are never invented and no winner is selected.

For other study templates, set `telemetry: true` on each case and `study: {"pair_id": "declared-pair", "arm": "distinct-arm"}` plus your declared study provenance. Use the same initial state and bounds in both cases. Telemetry is optional because measurements incur additional observation/artifact work, recorded separately in `metrics.telemetry_us`; prior performance timings without telemetry do not predict this cost.

To check a gameplay change, regenerate the declared prefix and pair against current source into new folders, then compare and replay both arms. Replaying an old frozen bundle verifies that old revision only. `verify_store_study.gd` is a maintained mechanics regression for the representative legal pair and is picked up by the normal `verify_*.gd` gate. Broader strategy, balance and AI population claims need separately declared studies.

## Thread checklist

1. Read current design authority and define the question, comparison cases, seeds, policy, limits and stopping condition before execution.
2. Run into a fresh folder owned by the requesting thread. Keep failures and out-of-budget routes.
3. Inspect status/outcomes and replay a retained representative case. Never use a failed/incomplete run as a successful comparison.
4. Write a dated finding with source identities, exact commands, accepted scope and remaining limits. Findings do not approve new numerical values or gameplay changes.

## Candidate versions and simultaneous runs

Use the [design-thread version workflow](VARIANTS.md) when testing a proposed rule addition. `tools/simulator_variant.py create` records a baseline and makes an editable private project; `tools/simulate.py run --variant <folder>` freezes that version independently for each experiment. Different threads and different versions can run simultaneously with unique output paths, caches and profiles. There is no shared runner lock; available CPU, memory and disk still bound practical concurrency. A single batch remains a sequence of independent campaigns, not a shared-world competitor simulation.

Create a review packet with `simulator_variant.py handoff`, then add its concrete adoption request to the internal TODO. Include design status, original base, candidate changes, retained evidence, acceptance criteria and unresolved decisions. The implementation thread reconciles drift and adopts approved changes. Candidate creation, running and packaging never update canonical gameplay or TODO automatically. The existing paired reporter requires matching mechanics identities; it does not silently treat two different rule versions as an ordinary matched-policy pair.

## Stress coverage and failure reproduction

Maintained `verify_campaign_stress*.gd` suites exercise declared multi-release routes through the authoritative command API. A separate seeded test-policy RNG makes decisions without consuming gameplay randomness. Checks cover rejection atomicity, ordered event/transaction identities, exact cash reconciliation, calendar/cycle progression, append-only release history and legal Studio restores. Coverage is recorded from actual actions; an unreached feature is not a passed test. Native/headless comparisons live separately in `verify_campaign_live_parity.gd` and `verify_campaign_seeded_parity.gd` because a replay of the same headless runner is not independent live-path parity evidence.

To reduce a recorded failure from a retained M4d-or-later run bundle:

```powershell
python tools/reduce_simulation.py --bundle docs/codex/threads/my-system/sims/failed-run --case my-case --kind rejection --output docs/codex/threads/my-system/sims/reduced-failure --timeout 240 --max-commands 1000
```

Choose the condition explicitly:

- `rejection`: first command returning an unsuccessful result, including an intentionally illegal probe.
- `divergence`: first result or canonical state differing from the recorded tape.
- `invariant`: first violation of the maintained campaign invariants while replaying commands.

The tool verifies and copies the original frozen project and exact input/tape, removes commands after the first requested failure, and tries earlier legal Studio checkpoints from latest to earliest. It preserves the remaining commands byte-for-byte as typed data, including quote tokens and counters. Full restored state and the failure signature must match, including the actual result/state digests. It then confirms the saved reduced case in another process and profile. Inspect `reduction-run.json`, `reduced/reduction.json`, both exact case/tape files and the process logs.

Exit 0 means the requested failure reproduced and was reduced successfully; it does not mean gameplay passed or a defect was repaired. A clean case, changed source/evidence, unsupported older bundle, earlier unrelated tape divergence or absent requested failure is reported explicitly. Failed attempts and original evidence are retained. The minimum is the shortest reproducing suffix among exact-restorable **Studio** boundaries; it is not global command minimization and does not create mid-phase Continue saves. A malformed decision that never produced a recorded command cannot be reduced this way.

Focused stress verifier artifacts are raw exact cases/tapes, not normal batch bundles. To diagnose those, use `campaign_reduce_cli.gd` with `--case`, `--tape`, `--kind`, `--max-commands` and a new `--output` in the matching source-pinned project/profile; `--result` is only for the normal batch result format. Preserve that project and inputs before running. The Python bundle wrapper supplies this isolation and fresh-process confirmation automatically for ordinary runs. Native-only signal, presentation or adapter mismatches still require their native verifier; the reducer's divergence mode compares headless results with the stored tape and cannot substitute for that oracle.
