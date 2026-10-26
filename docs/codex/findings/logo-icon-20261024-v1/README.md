# Transparent Patch Notes logo / EXE icon — 2026-10-24

**IMPLEMENTED locally; separate refreshed Windows build created.** Direct user request uses the attached logo with its background removed and a thin outline. Built-in image generation performed the background extraction; [asset provenance](asset-provenance.json) retains the exact prompt/input/output hashes. PNG master is 1254×1254 RGBA, square with transparent space around the full wordmark. Cream lettering, cyan pixels/underline and orange document details remain. No opaque rectangular backing.

## Integration

- `patch-notes/assets/branding/patch_notes_logo.png`: transparent source, copied without visual postprocessing.
- `patch-notes/assets/branding/patch_notes.ico`: format conversion into six 32-bit frames, 16/32/48/64/128/256px. [Godot Windows icon requirements](https://docs.godotengine.org/en/stable/tutorials/export/changing_application_icon_for_windows.html).
- `patch-notes/project.godot`: PNG project icon and ICO Windows native icon.
- `patch-notes/export_presets.cfg`: EXE/console icon plus raw ICO include filter.
- Existing clean-export allowlist and simulator snapshot suffix set now preserve `.ico`; existing snapshot preservation test includes it. Inherited edits in those tools are preserved.

No canonical gameplay script or main-menu layout was changed for this task. No commit/push. Main-menu logo placement was not part of this icon change.

## Verification / delivery

[Result and exact file hashes](result.json), [frozen exported source](source.json), [export input manifest](build-manifest.json), [actual embedded PE icons](pe-icons-final.json).

- PNG alpha/corners verified; inspected on white/dark backgrounds. [Proof sheet](icon-proof.png) is preview-only; it is not the game asset. Full-wordmark text naturally becomes tiny at 16/32px; no replacement monogram was invented.
- Fresh official Godot4.7.1 template clean import/export PASS. 392 PCK entries pass every payload MD5, completeness and include/exclude checks.
- Actual embedded EXE verifies PNG/ICO settings, raw ICO availability, loaded PNG size/transparent corners, all packaged SHA256 hashes and exact preceding editor Studio/world/RNG restoration. Unknown source rejection stays strict.
- Read actual Windows PE resources without executing them: all six frames match the ICO **pixel-for-pixel**, including transparency. Headless and native EXE startup both exit0 without errors.
- ZIP CRC and embedded EXE SHA256 PASS. Original v0.02 EXE/ZIP hashes remain unchanged.
- 43 Python simulator/variant/export-tool tests PASS using task-owned temporary storage. First run failed in the sandbox's default temporary directory before test setup; original log retained.

Delivery under `C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/`:

- `Patch Notes v0.02 - Logo/Patch Notes v0.02 - Logo.exe` — 115,446,048bytes; SHA256 `066170bdb8228da2c8cae625f18bdbae355e2bd66eae311a823016db4b045683`.
- `Patch Notes v0.02 - Logo.zip` — 43,190,243bytes; SHA256 `3772325b75f0f5c3d3938d2fd22929745c839bd2b22d93a056a9cea11bf87fa9`.

This refresh includes the guided tutorial and icon. README/font license accompany the standalone EXE. No external upload was requested or performed.

## Source boundary and retained failure

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty checkout. The initial driver passed export/package/save/startup/PE/ZIP checks but then rejected its whole-tree source fence. An asset import descriptor/excluded verifier appeared and separate `rival_trial.gd`/`rival_world.gd` work changed while packaging. Those parallel edits were preserved. [Original driver output](original-driver.log) remains retained.

[finalize.py](finalize.py) verifies the already-built **immutable export snapshot**, every original shipped input (apart from the three explicit build-only version/save-bridge overrides), actual artifact hashes and its package/smoke receipts. Branding/configuration still match current source; `result.json` pins the two newer rival files separately and explicitly says `canonical_unchanged:false`. Exported runtime identity is `bbb4858fa8929ac68c98faa7c7931df3011c1de6cb47cc3c120e8413fa5faf64`; its exact source-editor save identity is `12fe049927a7e7fb0c953e74dfc0329112a801ea2946a9200bb95a5dc3db5ad3`. It does **not** claim to contain the subsequent AI edits.

Raw evidence: `C:/Users/64jus/AppData/Local/Temp/pn-logo-icon-20261024-v1/`. [build.py](build.py) records the original build recipe and hardens future metadata/debug drift reporting; use fresh output/delivery names for a new export. This is bounded branding/package verification, not whole-gameplay or release-readiness approval. Existing text-driver/old artwork UID fallback warnings are retained; no gameplay/human/device acceptance was inferred.
