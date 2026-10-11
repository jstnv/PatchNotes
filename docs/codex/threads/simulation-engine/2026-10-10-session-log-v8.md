# Simulation Engine session — 2026-10-10, v8

## Authorization and source

User: “Go ahead” following the proposed Launch/Review and multi-project Studio extraction. Branch `main`; before/after HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Broad existing dirty work preserved. CURRENT_STATE/TODO read first, then repository workflow, architecture, relevant Core/Studio, lifespan, Fanbase and AI records plus live source/diff. No TODO change, commit, push, export, computer use or subagent work.

## Changes

- New `simulation/launch_settlement.gd`, `begin_project.gd`, `campaign_session.gd`.
- Gameplay now delegates launch-stage ordering and Begin Development. Shared replay accepts campaign state projections.
- Added campaign CLI and three focused extraction/session verifiers. New imports retain their generated `.gd.uid` files where generated.
- Updated Simulation Engine README and CURRENT_STATE; saved [implementation report](2026-10-10-extraction-m3a.md), archive, manifests, turn-only patch, tests and audit under `m3a-v1/`.
- No card, economy, data-ledger, checkpoint-schema, music or animation rule changed. `.codex-godot-temp` was not modified or removed.

## Exact checks and results

Tools used Python at `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` and Godot console4.7.1 at `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.

1. `m3a-v1/prepare.py`: archived248 script/data/state paths before implementation; captured status/diff/HEAD and original Gameplay oracle.
2. `run.py import m3a-import-v1`: import exit0; expected generated-import source changes. No script errors.
3. Launch v1:9 original/live/headless fixtures pass. Campaign v1:81 commands/55 reentrant attempts pass; first fresh-session replay passes.
4. Begin v1:3 controlled-roll mismatches. Diagnosis: the test called the existing pre-tree-only control API after tree entry and ignored its false return. Corrected fixture timing plus assertion; Begin v2:all6 fixtures pass. This was not a production RNG fix.
5. `m3a-v1/checks.py`: first19-suite batch and fresh-process CLI passed. Added observation identity fields plus a policy-from-observation test, then reran against final source using `checks.py m3a-accepted`.
6. Final19-suite batch:all exit0, no unexpected errors, source/driver manifests unchanged during each check. Exact names and commands: [check-results.json](m3a-v1/check-results.json) and each `m3a-accepted-*` command.json/output.log.
7. Final campaign tape:81 steps,61 accepted/20 rejected,3 complete legal projects,55 reentrant rejection checks. Separate-process CLI matches the full replay report and final digest exactly.
8. `m3a-v1/audit.py`:pass; confirms9+6 original/live/headless fixtures,19 suites, fresh-process replay, unchanged data/TODO/HEAD, and exactly9 changed/new GDScript files for this turn. [Acceptance](m3a-v1/acceptance.json).
9. Focused `git diff --check`:pass. The full shared dirty diff was not reformatted or cleaned.

The known Windows root-certificate diagnostic is excluded by the established runner. The existing two-ObjectDB-instance exit warning appears in some scene-free verifiers/CLI, also in M2d's baseline; no leak-free or scaling claim is made. All earlier evidence remains retained.

## Limits and next step

Launch fixtures cover constructed finalized states; Begin fixtures normalize only HUD tutorial-read acknowledgments. The complete three-project route is legal headless execution plus exact fresh-process replay, not a continuous original/live full-campaign parity claim. Live staged view-failure retries remain distinct from campaign command preflight rejection.

Next implementation seam: Contract hands and the remaining explicit Studio command families, followed by checkpoint continuation parity. Studio-only Continue is intact. Persistent competitors, their OPEN policy values, large/cohort performance and exported/human playtesting are not certified here.
