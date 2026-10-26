# First-release Studio actions — 2026-10-25

**FIXED locally and in a separate Windows EXE.** User reports disabled Post Game Summaries and Contracts after the first release in an older EXE. The same defect was reproduced directly against the shipped Paper Icon EXE; the corrected EXE passes those regressions and actual native pointer navigation.

## Cause / scope

`Gameplay._replace_beta_with_launch()` prevalidates a Studio scene with `prepare_only=true` before atomically committing the release. `StudioPhase.setup()` consequently cached the pre-release action states. After commit, `_ready()` refreshed the release list/results but omitted the action buttons. The permanent release already existed; the cached buttons stayed disabled and the caption remained Produce First Game.

- `scripts/phases/studio_phase.gd`: one `_refresh_dashboard_actions()` derives Summary/Contracts/Next Game state from the authoritative RunState. Called both during setup and after the committed scene mounts. No repeat registration, payout, release, clock tick or RNG draw.
- `scripts/market/rival_world_checkpoint.gd`: admit the exact preceding UI editor identity under existing content guards; actual old state/RNG restoration verified.
- `scripts/debug/verify_beta_finalization_and_launch.gd`: two new assertions exercise the real preflight → commit → mount path and catch the previously missed disabled-button states.

[Exact patch](scoped-delta.patch) · [source delta](source-delta.json) · [build source manifest](source.json) · [aggregate verification](verification.json). No scoring, finance, eligibility, one-shot Contract or Continue-boundary rule changed. The newer Contracts Search handoff remains queued separately; this fix does not adopt that policy.

## Evidence

| Check | Result |
|---|---|
| Actual old Paper Icon EXE | **RED**, exactly two new action-state failures; [receipt](receipts/red-exe/receipt.json) |
| Fixed actual EXE, identical launch regression | **PASS**, [receipt](receipts/fixed-exe-launch/receipt.json) |
| Native actual EXE first-release flow | **18/18 PASS**:12 legal headless Design/Alpha commands, two actual native Beta hands, normal live launch, then pointer Continue → Summary → Back → Contracts; [receipt/log](receipts/played-fixed-exe/run.log) |
| Passive browsing | Only the expected first-visit Contract tip acknowledgement changes; every other saved field and RNG remains exact |
| Maintained regressions | **Nine passing receipts**: Beta finalization/launch, Continue loading, history, release menus, tutorial invitation, folder UI, Primitive Contract, Contract presentation and Studio checkpoint; [six-suite result](receipts/green/result.json), [three-suite supplement](receipts/supplement/result.json) |
| Prior UI editor world | Exact player/world/RNG restore, unknown/mixed source rejection; [result](receipts/restore-ui/result.json) |
| Actual older EXE world into fixed EXE | Exact player/world/RNG restore, unknown/mixed source rejection; [result](receipts/exe-prior-save/result.json) |
| Matched model fixture | Same seed/policy,36 legal commands/two releases: every player/world/RNG field identical before/after this presentation fix, excluding the source identity; [comparison](model-comparison.json) |
| Clean export/package |410 entries, every payload hash/exclusions, embedded current-editor save, six native PE icon frames, actual headless/native startup and ZIP integrity pass; [build result](result.json) |

Native captures from the **actual fixed EXE**,1280×720: [dashboard](captures/first-release-dashboard.png), [first Summary](captures/first-release-summary.png), [eligible Contract](captures/first-release-contracts.png). Enabled actions and Next Game caption were inspected. This is a hybrid legal simulation/native acceptance route, not a claim that Design/Alpha were played manually through the GUI or that every game system was reaccepted.

## Build / delivery

**Patch Notes v0.02 — Studio Fix**, includes the current Theme/Main Menu/Studio Creation foundation and paper icon. Existing saves/settings directory stays `Patch Notes`; previous packages are preserved. Select Continue in the new build to use an existing compatible Studio.

- [Windows EXE](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Studio Fix/Patch Notes v0.02 - Studio Fix.exe>):116,984,592bytes, SHA256 `0eaef68329723f86f42816906e0482c84db4924ec5031ff62d640e39354f2ef4`.
- [ZIP](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Studio Fix.zip>):44,246,929bytes, SHA256 `5822a0b86d1df42a9271b1c386ef3edb80b727bca89143c5edc4e9c96dc83afe`.

Editor runtime `874feab75c9d0221fc22dce1ac844a812f8a610bd58c12e203f9080c9c370392`; compiled runtime `57da40e29af0d492f12109030c79b549e64814faaeefba0528ce195dfc0baeac`. Build-local version/name/embedded-data overrides and the exact editor compatibility bridge are recorded in [manifest](build-manifest.json). Build reports `canonical_unchanged:true`, `export_inputs_unchanged:true`. Prior Paper Icon EXE remains byte-identical to its recorded SHA256.

## Reproduction / retained failures

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, inherited dirty work and `.codex-godot-temp` preserved. Godot4.7.1. Raw snapshots/profiles: `C:/Users/64jus/AppData/Local/Temp/pn-studio-release-actions-20261025-v1`; raw export: `C:/Users/64jus/AppData/Local/Temp/pn-studio-fix-build-20261025-v1`.

Exact commands, script hashes, private profiles and exits are retained in receipts. `checks.py` uses the existing isolated runner, `supplement.py` reuses the immutable imported runtime, `build.py` records its base/generated builder hashes, and `collect.py` validates receipts/source bounds. [Dated session / command list](../../logs/2026-10-25-studio-release-actions-v1.md).

The initial matrix requested three nonexistent historical verifier names, so its overall result is false despite six executed suites passing. The three real corresponding suites pass separately. Its canonical fence also records six newly generated `.import` files; no runtime code or font/image input changed during checks. The supplement and aggregation keep this distinction; there was no uninterrupted nine-suite all-green command.

Native helper attempts retained a missing explicit Dictionary type, a visible planning overlay, incorrect synthetic input scaling, then an overly strict assertion that included the legitimate first-visit tip acknowledgement. Corrected fixtures keep those failures and explicitly test the acknowledgement while requiring exact remaining state/RNG. Existing verifier shutdown warnings are retained. No test error was filtered to obtain a pass.

No remaining blocker for this reported defect. Whole-release, clean-machine/device/audio acceptance and the separate queued Contract Search implementation remain separate. No player save was edited, committed or pushed.
