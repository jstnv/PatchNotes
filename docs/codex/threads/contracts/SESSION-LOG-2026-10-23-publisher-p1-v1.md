# P1 relationship foundation session

2026-10-23 (America/Los_Angeles). User: "Ill let you cook" following the recommendation to prepare/test the relationship foundation privately. Authority: existing design-thread simulator permission and concrete TODO review handoff workflow; no canonical adoption or numerical ruling inferred.

## Result

Prepared [specification](PUBLISHER-P1-FOUNDATION-SPEC-2026-10-23-v1.md), [experiment plan](studies/publisher-p1-20261023-v1/PLAN.md), two private candidate revisions, [findings](PUBLISHER-P1-FINDINGS-2026-10-23-v1.md) and [sealed review handoff](handoffs/publisher-p1-foundation-20261023-v1/HANDOFF.md). Final v2 has13 source changes, no canonical drift/conflicts at packaging. Added a fresh-read minimal DESIGN review entry to TODO and updated only thread README/HANDOFF indexes. Existing gameplay and shared design/CURRENT_STATE authority remain unchanged.

`main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty tree preserved. [Before status/diff](studies/publisher-p1-20261023-v1/git-before.json), [canonical/parity audit](studies/publisher-p1-20261023-v1/audit-final.json) and [supplemental evidence hashes](studies/publisher-p1-20261023-v1/evidence-index.json) pin the work. Canonical source hashes are unchanged; `.codex-godot-temp` untouched. At close disk free was101,302,489,088 bytes, above20GiB floor. No commit, push, player-save access or cross-chat dispatch.

## Commands and evidence

Executables used throughout:

- Python: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`
- Godot: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`

From repository root, creation commands were `tools/simulator_variant.py create --id publisher-relationships-foundation-v1 --owner contracts --output docs/codex/threads/contracts/simulators/publisher-relationships-foundation-v1`, then the same command with v2 IDs/paths plus `--from-variant docs/codex/threads/contracts/simulators/publisher-relationships-foundation-v1`. Baseline archive/metadata were never rewritten. The thread-owned `integrate.py` and `revise_v2.py` record the private deltas.

All run invocations used `tools/simulate.py run --config docs/codex/threads/contracts/studies/publisher-p1-20261023-v1/cases.json --timeout 240 --godot <Godot path>` and these exact additions:

| Scope | Additional arguments |
| --- | --- |
| Baseline | `--output docs/codex/threads/contracts/sims/publisher-p1-baseline-20261023-v1` |
| V1 | `--variant docs/codex/threads/contracts/simulators/publisher-relationships-foundation-v1 --output docs/codex/threads/contracts/sims/publisher-p1-candidate-20261023-v1` |
| V2 | `--variant docs/codex/threads/contracts/simulators/publisher-relationships-foundation-v2 --output docs/codex/threads/contracts/sims/publisher-p1-candidate-20261023-v2` |

Replays used `tools/simulate.py replay --case action-4417 --timeout 240 --godot <Godot path>` with baseline bundle/output `publisher-p1-baseline-20261023-v1` / `publisher-p1-baseline-replay-20261023-v1`, and final candidate bundle/output `publisher-p1-candidate-20261023-v2` / `publisher-p1-candidate-replay-20261023-v2`, all under the same thread `sims/` directory. Both36-step replays pass.

Every focused Godot invocation has its exact argv, exit and output in [checks](studies/publisher-p1-20261023-v1/checks/), executed through `focused.py` with a frozen run project and isolated profile. Full P1 v2 checks40/0; challenge regression52/0; world migration16/0; fresh-world continuation16/0; native decoded parity/source audit80/0; final Python audit22/0. Earlier baseline/native/migration checks and expected red/failing cases retain their own boundaries. There were13 focused invocations within the amended14 limit and five run/replay invocations within six. No timeout. Both final campaigns completed36 commands/two releases/cycle14.

Handoff command used `tools/simulator_variant.py handoff` with v2 `--variant`, the P1 specification as `--design-record`, final v2 run as `--evidence`, and output `docs/codex/threads/contracts/handoffs/publisher-p1-foundation-20261023-v1`. The exact submitted summary and six acceptance strings are preserved in its `handoff.json` and `HANDOFF.md`; tool result: success,13changes, baseline_drift=false, conflicts=[], evidence_count=1. Supplemental focused/replay evidence is referenced by the finding and indexed separately.

## Failures, review and limits

Retained expected missing-API red check, historical-fixture shape failure, whole-world source rejection, external probe type error and aborted Python tape audit. V2 corrects both private source issues without broad source-fence bypass. See finding for precise fixes and artifact links. Read-only fresh review found the world gap and verified its v2 correction; no remaining blocker identified in dormant P1. Unknown sources and two specifically tested mixed predecessor content pairs reject; no claim that every mixed source/revision combination rejects.

Nonzero credits are pure fixtures. Production successful award settlement/reentry, main-menu cold disk Continue, production writer contention/crash recovery, populated Founder transitions, broader historical world/export acceptance and UI/human review remain unverified. The current six-instance ObjectDB exit warning persists. No newly proposed amount or cap is promoted to ACTIVE/TRIAL. P2-P4 need their own rulings and integration; the old support candidate still has its separate second-deal failure.

Next: review P1 specification/packet and adopt only the approved structural scope through PN Implementation, completing the listed native/world acceptance. Then connect the first separately approved relationship-bearing producer. No further broad balance sweep is needed for P1.
