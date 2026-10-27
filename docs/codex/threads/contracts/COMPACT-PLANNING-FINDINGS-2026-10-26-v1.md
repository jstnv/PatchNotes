# Crown paid-work planning — isolated policy findings v1

2026-10-26. **24/24 bounded careers completed; design values remain PROPOSED.** [Preregistered plan](studies/compact-planning-20261026-v1/PLAN.md) · [full outcomes/Pareto choices](studies/compact-planning-20261026-v1/analysis.json) · [source delta](studies/compact-planning-20261026-v1/source-before.json) · [verification](studies/compact-planning-20261026-v1/verification.json).

## Question, source and scope

Does two-hand planning make the proposed Compact Feature Package's Scope ceiling useful? User authorized this work and a TODO update while preserving existing rewards. A named private variant tests **policies on unchanged Crown Brief runtime**, scoring hypothetical cash-package objectives separately. It does not implement or pay a new cash Contract.

- Inspected main HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; shared checkout already dirty and changing concurrently.
- Parent `early-brief-affordability-20261025-v1`, full identity `f7de61169758dcd874972c59e584c7b6a9a36f1fedc4f24b2398f6a2edfdf60f`; preserved original canonical baseline `434971b9525f09fab3fa0846ed094f53d6ee778f76ae8b97740a136c7b0fda3f`.
- New owner-contracts variant `compact-planning-20261026-v1`, full identity `2fef789cd84078d309459d8ad17856b7bcfa1073f84aebbea3dcc19ebfb7c44e`; only added path `scripts/debug/compact_planning_policy.gd`, SHA256 `abc53a80ce852db1d85bc3fa44157539fd24693d2e1a8e15871ca1025d635ca7`.
- Unchanged runtime mechanics identity `9dd1e4551338d38894dace6eb98bc635c38b7e6ec47427b4078cf0ccfe8b0bd6`. All six earned Studio envelopes are accepted without identity edits. Four arms per route have equal actual starting state/RNG and first candidates. Current canonical runtime parity is not claimed.

The six routes are Puzzle4417/4418/4521/4522 with retained Sound+Sprites research, Action4417 and Simulation4417. Earned starts are at Games3/4, not bare new Studios. Each takes one paid Brief and reaches one additional release under its original production policy. No extra Research, cash work, hired employees, Bank change or redraw is introduced. Every case has the same120-command cap and horizon. Search/hand costs and actual Reputation settlement retain the parent rules.

## Planning protocol

Control uses the existing public-mean256 two-hand planner with no size limit. `greedy9` uses only the current hand and ceiling9/fade4. `plan9` and `plan10` enumerate35 first-hand choices,256 deterministic public weighted-pool scenarios and35 final choices per scenario. Models retain unplayed cards, finite exclusion, public priorities and specialization; they never inspect hidden future RNG or consume the gameplay stream.

The diagnostic objective maximizes expected `min(base completion,balance,size)` with original tie breakers. This is a policy preference, **not** the proposed payment rule: base cash remains completion-only, bonus remains min(balance,size). Without payment caps there is no justified cash-optimal planner. The analysis reports both components and Pareto choices rather than hiding the tradeoff in a single score.

Existing behavior tested first: all six controls exactly reproduce historical first-Brief chosen tokens, visible cards, projected scores, actual award, cycle, cash and redraw count. [Control check](studies/compact-planning-20261026-v1/control-check.json).

## Results

| Arm | Careers complete | Mean base completion | Mean bonus grade | Full bonus | Zero bonus | Full base and bonus |
|---|---:|---:|---:|---:|---:|---:|
| Two hands, no ceiling control | 6/6 | 78.275% | 20.833% | 1/6 | 4/6 | 0/6 |
| Current hand only, ceiling9 | 6/6 | 78.780% | 8.333% | 0/6 | 4/6 | 0/6 |
| Two hands, ceiling9 | 6/6 | 78.275% | 20.833% | 1/6 | 4/6 | 0/6 |
| Two hands, ceiling10 | 6/6 | 78.275% | 20.833% | 1/6 | 4/6 | 0/6 |

920 accepted campaign commands total. All24 finish the next release; maximum observed arrears0; lowest command-boundary cash$1,980.41. These are unchanged Brief careers, not package income/affordability evidence. Each actual final selection is nondominated in base/bonus among its35 visible legal quartets;840 final alternatives were inspected across24 different reached states.

Ceiling9 two-hand planning chooses the same first hands as control in all six routes and reproduces all six final state/RNG pairs exactly. Ceiling10 changes Simulation4417's first hand and subsequent state, so only5/6 final state/RNG pairs equal control. It changes neither that route's normalized grades nor aggregate performance. No reached final hand changes its best ranked choice because of the active ceiling. This is limited evidence of **weak size differentiation**, not proof the cap is globally inert.

### The meaningful tradeoff

Puzzle4521: greedy delivers64/66 base completion (96.97%) with25% bonus; two-hand planning delivers60/66 (90.91%) with100% bonus. Puzzle4418 gains base completion from72.72% to75.75% without changing its25% bonus. The other four routes retain zero bonus from imbalance.

For Puzzle4521, if a future package had base cap A and cash-bonus cap B, ignoring cent floors and any Promotion value, the two-hand result would pay more only when `B/A > 8/99` (about8.08%). **This is a symbolic comparison, not a proposed or approved payout ratio.** It demonstrates why a higher diagnostic grade is not automatically more profitable. No actual cash reward was added or tuned.

The earlier [compatibility screen](COMPACT-PACKAGE-FINDINGS-2026-10-26-v1.md) found three joint-full paths within18 Briefs spread over three attempts per route. This study isolates the first attempt from each earned start; none is joint-full. Those results concern different horizons and do not contradict each other. Do not infer guaranteed entry success or a mandatory Research path.

## Execution and evidence

Raw immutable bundles are under `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/compact-planning-20261026-v1/`, with separate control/greedy9/plan9/plan10 directories and profiles. [Driver](studies/compact-planning-20261026-v1/run.py), per-invocation `*-command.json`, `*-exit.json` and driver logs retain exact CLI arguments, paths and timing. [Evidence manifest](studies/compact-planning-20261026-v1/evidence-manifest.json) pins outcomes, tapes, telemetry and Studio checkpoints.

From repository root, using Python `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`:

```text
run.py setup
run.py run control
analyze.py control
run.py run greedy9
run.py run plan9
run.py run plan10
analyze.py all
verify.py replays
verify.py cold
verify.py seal
```

All scripts above are in `docs/codex/threads/contracts/studies/compact-planning-20261026-v1/`. `run.py` invokes the documented isolated `tools/simulate.py run --variant ... --timeout 600 --godot ...`; every output is new. Bundle elapsed times: control221.77s, greedy9 197.28s, plan9 166.93s, plan10 371.37s. No seed/budget changes, campaign rejections, incomplete cases or timeouts occurred. A premature control-log read failed while the runner was active; after completion the same check passed. [Retained operational notes](studies/compact-planning-20261026-v1/OPERATION-NOTES.md). No gameplay failure reduction was applicable.

**PASS:** representative exact fresh-process replays for control Puzzle4417, ceiling9 Puzzle4522 and ceiling10 Action4417; separate32-command Studio Continue from the completed ceiling9 Puzzle4522 case restores the exact final state/RNG and completes one additional release. Variant source and original pinned plan/policy remain unchanged. Details are in the verification receipt. No native/rendered UI, export, human play or new cash settlement/migration was tested.

## Recommendation

**Hold the extra Scope ceiling from the first paid-work pilot recommendation.** Keep the composite as a future candidate; neither tested ceiling earns its extra rule complexity in this small cohort. Consider a simpler balanced paid-work package first, preserving independent base completion and bonus. Exact new rewards/advance/Promotion and the Reputation gate still need review before any canonical implementation or profitability claim.

This updates the prior research preference for ceiling9/10; it does not approve a replacement catalog or change the existing Crown Brief. [Versioned design review handoff](COMPACT-PACKAGE-HANDOFF-2026-10-26-v2.md) specifies the remaining decisions. Approved grade-feedback implementation proceeds independently. Redraw research remains parked.
