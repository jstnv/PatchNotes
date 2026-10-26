# AI Competitors G4 choice-policy session — 2026-10-11

## Checkout and preserved work

`main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared worktree dirty before edits. Read `CURRENT_STATE.md`, `TODO.md`, `README.md`, relevant Genre/G4 decisions and simulator usage/version docs; inspected status/diff. During the session, another task edited canonical soundtrack/audio/HUD paths, causing one source-drift preflight rejection. Those paths and `.codex-godot-temp` were preserved. No canonical gameplay, TODO, player save, commit, push or computer control action by this thread.

## Files and versions

Added [predeclared study plan](2026-10-11-g4-choice-policy-plan-v1.md), [16-case config](2026-10-11-g4-choice-policy-v1.json), [opening/continuation auditors](2026-10-11-g4-choice-policy-audit-v2.py) and [finding](2026-10-11-g4-choice-policy-finding-v1.md), plus [review disposition](2026-10-11-g4-choice-policy-review-v1.md). Four v1 and four v2 per-case continuation configs and their combined configs remain thread-owned evidence. Updated this thread's README/working notes and a concise current-state entry. The existing TODO item 22 remains DESIGN review needed.

Created `simulators/g4-choice-policy-v1` from the existing G1a private candidate, preserving baseline and ancestry, then added only `project/scripts/simulation/rival_trial_policy.gd`. Created `simulators/g4-choice-policy-v2` from v1 and added only its generated `rival_trial_policy.gd.uid` to fix import source stability; policy/gameplay script bytes were unchanged. Neither version edited another candidate or `patch-notes/`. V1 and v2 frozen run bundles, audits, failures and replays are linked in the finding.

## Exact checks and results

The [finding's command section](2026-10-11-g4-choice-policy-finding-v1.md#exact-commands-and-artifact-contract) records the exact executable, runner, variant and output arguments; each bundle retains the complete command array. V2 16-case run: 16/16 completed first legal releases within 60 commands/240 seconds. Opening audit: 9/9 checks, including equal opening state/RNG within each four-arm group and exact reproduction of the prior medium reference. V1-to-v2 comparison: 16/16 opening initial/final state/RNG digests identical. V2 import-source changes: empty. Focused archive wrapper: import passed, 29/29 verifier checks, `source_unchanged=true`. Two opening replays passed with 24 and 23 telemetry samples.

V2 four-case Studio-only continuation: 4/4 completed second releases within 70 **additional** commands/240 seconds. Continuation audit: 5/5 checks for exact Studio source/RNG fence, releases, legal cash/arrears and archive persistence. V1-to-v2 second-route initial/final state/RNG: 4/4 identical. Two continuation replays passed with 24 and 27 verified telemetry samples. No rejected gameplay command or incomplete case occurred. Private v1's 16 first releases and four continuations also completed but its focused wrapper found the import-generated UID; v1 focused assertions themselves passed 29/29.

Retained technical failures: `sims/g4-choice-continue-v1` stopped at source capture because canonical source changed concurrently; the same four declared continuations succeeded in a new v2 output without seed/budget changes. The v1 combined continuation JSON was corrected before execution after a literal trailing `\n` was detected; no invalid gameplay run was submitted. The v2 continuation's helper-injected supplied policy generated its own UID on import, recorded in that run; checkpoint source/RNG and replay fences passed. Godot logs include the environment's certificate-store error and two ObjectDB leak warnings; result statuses and audits passed.

## Follow-up

The [dated review](2026-10-11-g4-choice-policy-review-v1.md) rejects this numerical rank/floor for adoption. A next private candidate needs an exact read-only current-hand cost and known-dues quote before benefit/cash selection; retain an explicit blocked/defer reason, fixed bounds and second-project opportunity-cost comparison. G1a cohort values, G2/G3 integration, hand/exit numbers, Theme/later Genre, entrants, G5 news/CPU and market Review effects remain OPEN. No adoption packet or TODO entry is appropriate for this rejected exact candidate.
