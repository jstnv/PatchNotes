# Session — paid-work planning and TODO design handoff

2026-10-26, America/Los_Angeles. User delegated stronger two-hand planning research and explicitly requested a TODO update on completion. Existing rewards remained unchanged. Branch `main`; inspected HEAD `087df09d653858b72c6e2dc344352237433dd3ac`. Shared gameplay/UI/employee/Store/docs edits were already present and continued during this work; start/finish status, diff and HEAD snapshots are retained in the study folder.

## Changes owned by this thread

- New private simulator `simulators/compact-planning-20261026-v1/`, created through the documented variant tool from the frozen earlier Brief version. Preserves original baseline and ancestry. Only added private project source is `scripts/debug/compact_planning_policy.gd`; no canonical gameplay change.
- New `studies/compact-planning-20261026-v1/`: preregistered PLAN; setup/run/analyze/verify/publication scripts; exact command/exit/driver receipts; source, evidence and input manifests; control/analysis/verification/publication receipts; preserved operational errors; queue/index preimages and git snapshots. Raw run/replay profiles and immutable bundles are in the corresponding Contracts Simulator Evidence directory in the authorized Downloads workspace.
- New [findings](COMPACT-PLANNING-FINDINGS-2026-10-26-v1.md), [review handoff v2](COMPACT-PACKAGE-HANDOFF-2026-10-26-v2.md) and this session log. Prepended the current disposition to thread README/HANDOFF, retaining previous contents.
- Inserted one **DESIGN review needed** paragraph in the internal TODO. Fresh read and exact inverse-byte comparison preserve every other entry, including the approved grade-feedback task and concurrent work. [Publication receipt](studies/compact-planning-20261026-v1/publication.json).

## Exact execution and verification

All Python commands used `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` from repository root. Script directory: `docs/codex/threads/contracts/studies/compact-planning-20261026-v1/`.

1. `run.py setup`: variant create succeeds; only one debug policy added. Plan and policy hashes pinned before the first run.
2. `run.py run control`, then `analyze.py control`: all six historical first-Brief card/score/award/cycle/cash paths reproduce exactly. An earlier premature evidence-read attempt failed while the run was active; retained in OPERATION-NOTES, no run restart or experimental change.
3. `run.py run greedy9`, `run.py run plan9`, `run.py run plan10`, `analyze.py all`:24/24 careers complete,920 accepted commands, matched actual starting state/RNG and first candidates across all four arms, no redraws/rejections/arrears. All final selections Pareto-nondominated for their visible base/bonus choices.
4. `verify.py replays`: three exact fresh-process replays PASS; control Puzzle4417, plan9 Puzzle4522, plan10 Action4417. The independent `verify.py cold` was started while the final replay ran, using a separate completed plan9 envelope/output/profile. It passes32 commands, exact initial state/RNG restoration and one additional release.
5. `verify.py seal`: PASS; original variant source/pins unchanged, all run/replay receipts successful, evidence hashes retained. [Verification](studies/compact-planning-20261026-v1/verification.json).
6. `publish.py`: PASS; minimal TODO addition, pre-existing index bodies and unrelated TODO bytes preserved, all outgoing handoff/finding/queue links resolve. Approval boundaries remain explicit.

Runner invocations, including exact absolute paths, Godot version, timeout600 run/240 replay arguments and new output directories, are preserved in `*-command.json` and raw `run-report.json`. No seed or budget adjustments. No gameplay failures, incomplete cases or timeouts; reducer not applicable. Current canonical source was not modified by this task, and the historical private runtime is not claimed to match current canonical mechanics. Player saves, .codex-godot-temp, tests, assets and configuration were preserved.

## Outcome and follow-up

Two-hand planning improves average bonus grade8.33→20.83% while average base completion falls78.780→78.275%. Both size caps leave grade outcomes unchanged versus the no-ceiling planner. Ceiling10 changes one route's cards/state without grade benefit; ceiling9 matches all six control final state/RNG pairs. Four of six first Briefs still have zero bonus; none attains joint-full.

Recommend holding the extra ceiling and reviewing a simpler balanced paid-work pilot with independent base/bonus. Exact new payment/advance/Promotion and Reputation gate remain OPEN. The TODO requests design review, not gameplay adoption. Future cash economics, current-source integration, named source/migration, UI/export and human acceptance remain untested. No commit, push, cross-chat dispatch or Drive synchronization occurred.
