# Accepted smooth seven-pixel Main Menu wave, 2026-11-02

User accepted the subpixel preview ("Looks better") and explicitly requested that the main implementation queue adopt this version. Status: USER-ACCEPTED isolated implementation; QUEUED for canonical reconciliation and adoption. This publication changes documentation only.

## Accepted behavior

- All five native Main Menu buttons gently wave horizontally between their original layout position and 7px to the right. The original position is a turning point; buttons never drift left of it. Keep the 3.6s cycle and 0.7-radian row stagger.
- Hover holds that button's saved wave phase, including position and direction. Ease both edges outward until the hovered button spans from its original left edge to its normal right edge plus 7px. Stretch/compression durations are 0.16s/0.18s. Other buttons keep moving.
- On pointer exit, compress to normal width at the exact saved wave position, then resume in the saved direction on the following frame. Rapid re-hover during compression retains the saved phase. Keyboard/controller-directed focus uses the same hold behavior; automatic initial focus does not freeze the wave. Preserve disabled Continue and native click/focus behavior.
- Render continuous subpixel motion. The title controller temporarily sets `Viewport.gui_snap_controls_to_pixels=false` while active, restoring its previous value when inactive or removed. Do not quantize to a quarter-pixel grid: existing continuous idle displacement is already about 0.102px maximum per frame at 60fps. Rendered 0.25px differences are verified.
- Preserve container layout on resize, suspend motion when the title is inactive, and preserve the current Onyx/Russo theme, navigation, save detection, current soundtrack/loading and live labels. This supersedes v1's 14px/percentage stretch and v2's whole-pixel rendering.

## Exact candidate and evidence

Candidate root: `C:/Users/64jus/.codex/worktrees/613f/PatchNotes`, detached baseline `3a61522f18db7a2bae892cb8c5be1fee68cd4100`, with existing uncommitted work. Only the following motion sources are proposed:

| File under candidate root | SHA-256 |
| --- | --- |
| `patch-notes/scripts/ui/title_button_wave.gd` | `23f726e50feaef70bd314a40cfeb409066ec85166418fd283c459f8e85dfe032` |
| `patch-notes/scripts/phases/main_menu.gd` (motion binding/process delta only) | `e995ccdaf6a2daaac588c1182cc3651dcb487b6cb1cfff72e4cc1a7f60584983` |
| `patch-notes/scripts/debug/verify_title_button_wave.gd` | `f572de57060e3a173bcadb263e0023c47868a1a3cb087501ef870a250b0d2218` |
| `patch-notes/scripts/debug/verify_title_subpixel.gd` | `0fec76394752d68390b64f165ed0bda39dbbcbe288e3cc73c559ceddc2039984` |

[Cumulative four-file motion patch](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/findings/title-button-wave-20261102-v3/main-menu-wave.patch) · [source manifest](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/findings/title-button-wave-20261102-v3/source-manifest.json) · [accepted 60fps preview](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/findings/title-button-wave-20261102-v3/main-menu-wave-60fps.mp4) · [exact checks and retained failure evidence](C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/logs/2026-11-02-title-button-wave-v3.md).

Recorded native Godot4.7.1 evidence: subpixel verifier 12/12; wave/hover verifier 53/53; Onyx presentation 83/83; total 148 passing checks. Includes quarter-pixel raster comparisons, viewport restoration, 7px endpoints, stored phase/resume, pointer activation, disabled Continue, keyboard/simulated-controller events and 1152×648/1280×720/1920×1080 layouts. Earlier RED run failed 6/12 against v2. Preview is 540 frames / 9s / 60fps, with hover at 2.25–3.75s. Source/preview hashes and receipts were rechecked at publication; runtime suites were not rerun for this documentation-only update.

## Canonical reconciliation and acceptance

Shared checkout inspected at `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`. Its current records already mark Onyx/Russo presentation, four-group Studio navigation and floating Feature Store controls adopted. This is a separate motion addition, not a request to repeat or replace those implementations. Current shared `main_menu.gd` SHA-256 at inspection: `dff0bf8989bf4ea9988ac550700122a8943d7317773bacd352b37199578b833b`; no title-wave component exists there yet. Re-read current source/ownership before editing; the main implementation chat owns adoption.

Merge only the wave component, five-button binding and per-frame active-title call into current Main Menu. Reconcile the patch rather than replacing the older candidate's whole Main Menu file. Preserve newer shared navigation/audio/loading and all unrelated Studio/Engine/Store work. Reconcile viewport-setting ownership with any intervening rendering changes; preserve prior settings and teardown.

Run `verify_title_subpixel.gd` and `verify_title_button_wave.gd` natively after adoption, adapting only genuine current interface differences. Rerun the current canonical presentation/navigation/loading/audio gates at supported sizes; inspect the actual wave and hover, Back/settings/setup/Continue, input focus, disabled Continue and resize behavior. Isolated results do not establish canonical acceptance. Actual controller-device and release/export acceptance remain separate. No chat dispatch, commit, push or rebuild is requested by this queue publication.
