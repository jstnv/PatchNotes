# Cult Following 20-Fan adoption — 2026-10-11

**Implemented and verified locally as ACTIVE/TRIAL.** Fresh Studios use trait version8: Cult costs one positive point and seeds20 ordinary Fans once. Version7 saves retain their40-Fan provenance and accumulated history. Versions3–6 retain inactive Cult previews. Final balance and current exported/human acceptance remain OPEN.

Authority: [approved v2 handoff](../../threads/studio-traits/handoffs/2026-10-11-cult-seed20-trial-adoption-v2.md). Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, pre-existing dirty worktree preserved; no commit/push. Current runtime-copy identity (all `simulate.py` copied source/assets, not a mechanics-only digest): `4162c70c12bf3d6af7587e5879759b54b127280c4ff224f4970ed7f8c2b895df`.

## Implementation and source boundary

- `studio_traits.gd`: new default version8; truthful20-Fan creation copy; saved active7→40, active8→20, inactive/non-Cult→0. Point costs and all other effects unchanged.
- `persistence/studio_checkpoint.gd`: new traits8/cult2 revision; exact immediately prior Cult revision accepted. Old version7 already excluded audio credits, so its historical revision continues excluding them. New version8 cannot masquerade as old content. Saved trait versions stay unchanged through Continue and future saves.
- `run_state.gd` and creation menu already derive the seed/copy from `StudioTraits`; no changes needed. Fanbase, Awareness, finance, sales, card rules and all JSON data unchanged.
- Focused Cult/trait verifiers updated; stress fixture now expects20. [Audited delta](canonical-delta.patch), [audit](audit.json), [after manifest](after-source-manifest.json), and before/after source archives retain the source.

Capture disclosure: initial `old-project/` copy detected a concurrent verifier edit and aborted; its partial files remain. Successful `old-project-02` and `before-source.zip` were captured before gameplay edits, but after the two verifier edits had begun. For the pre-change runtime's editor import, those two debug tests alone were restored from the prior M4d archive; gameplay/data were untouched. `old-project-03` uses that genuine old runtime with the corrected evidence probe. This is not a claim that every debug file in the first archive predates this task.

## Focused checks

[Exact commands, durations, hashes and diagnostics](focused-checks.json) retain the maintained harness results. Editor import plus all seven suites passed with unchanged source/driver hashes:

| Suite | Observed passing scope |
|---|---|
| Cult Following |181 checks: new seed/price, duplicate/invalid creation, both old/current Fan domain behavior and checkpoint provenance |
| Studio Traits |385 PASS lines, creation and copy at1280×720 and1920×1080 |
| Fanbase checkpoint |50 PASS lines |
| Studio checkpoint |93 PASS lines |
| Primitive Awareness |39 PASS lines |
| Campaign Cult stress |196 checks,87 commands,4 releases,7 Studio restores,5 intentional rejection probes |
| Campaign live parity |94 native/headless boundaries |

The stress route includes research, two Contract hands, hiring/ten payroll dues and borrowing/payoff/three Bank dues. It starts20 Fans and ends4 at cycle31, with$3,941.40. That is test-route evidence, not a balance verdict.

A separate [constructed Awareness/Promotion probe](cult20_awareness_probe.gd), derived from the maintained publisher verifier, passes19 checks. Cult8+Buzz+Unknown starts20 Fans and freezes5 Fan Awareness; first launch total123 includes Marketing25, organic100, Fans5, Buzz3 and Unknown−10. Later keyed Crown/Neon Promotion is previewed/consumed once; history and sales retain the same frozen value. Its prepared development states are explicitly constructed domain fixtures, not claimed legal played hands. [Command](awareness-stage-order-01/probe.command.json) · [summary](awareness-stage-order-01/summary.json).

## Real separate-process Continue matrix

[Driver v2](restart_v2.py) and [probe v2](restart_probe_v2.gd) ran **34 processes /629 checks**, all passing. [Summary and exact source hashes](restart-summary.json). Each case has its own profile; old/new runtime writers create normal storage generations, and independent new-runtime readers call the actual `CheckpointCoordinator.load_current()`.

- Both runtimes: no-trait two releases; Cult creation; Cult first launch; Cult two releases/monthly sales; Cult+Buzz; Cult+Graduate. The first runtime uses version7/40, the second version8/20.
- Old Cult two-release save is explicitly saved again under current content, then reloaded in another process: traits7, Fans, finance, releases and RNG preserved.
- Versions3–6 are constructed inactive historical fixtures, each written and read separately:0 Fans/$5,700 retained.
- Every read compares the whole saved payload, with only the content revision normalized. Passive Continue leaves save bytes unchanged. Tampered Fans, injected seed, mismatched active version and unsupported pre-Fanbase content cannot replace the good save or mutate the attached state.

An independent [audit](audit.py) passes348 assertions. The36-command/two-release no-trait control is exactly equal between old/new runtimes except the intentionally new trait version/content revision; all six paired routes end with identical RNG states. Cult-only creation is$5,650 with40 or20 Fans according to its saved version. The two canonical mechanics edits and unchanged data are verified against the captured baseline.

## Failures retained and limits

- First `restart.py` probe incorrectly queried a nonexistent stored `fanbase.seed` after legally playing/saving. Godot logged that assertion error and the driver timed out at90 seconds. Original scripts, `old-restart-control/`, logs and saves remain. The v2 probe correctly derives the seed from the saved trait version and reruns the whole matrix in new folders. This was a harness defect, not a gameplay failure.
- Expected environment root-certificate diagnostics and Godot shutdown ObjectDB warnings are retained. Native parity also records missing artwork/incomplete Alpha-selection refresh warnings; no game/script errors were recorded in passing runs.
- These are focused local checks, not a refreshed full export gate or audible/human playtest. Earlier exported acceptance predates this change. The new read-only post-adoption study is separate; Game4 settlement and broader balance are not inferred from these fixtures.

## Reproduction

`prepare.py`, `restart_v2.py`, `awareness_probe.py` and `audit.py` preserve exact inputs. They deliberately create unique evidence folders and fail if reused; use a new versioned output folder for a rerun. Godot executable and every process command/profile are recorded beside outputs. `.codex-godot-temp` remains intact. Simulator envelopes still enforce their original exact source identity; player-save compatibility here does not bypass that fence.
