# Folded-paper application icon — 2026-10-25

**IMPLEMENTED locally and packaged.** User approved the simpler folded-paper icon after the full wordmark became unreadable on the Windows taskbar. Later scope clarification: **icon only for now**; the pasted UI overhaul was not implemented in this pass.

## Files and artwork

- `patch-notes/assets/branding/patch_notes_paper.png`:1254×1254 transparent RGBA master, generated with the built-in image tool and copied without visual postprocessing. Cream page, single charcoal outline/fold and three orange lines. [Exact prompt](prompt.txt); references were the existing full logo and the user's cropped paper screenshot.
- `patch-notes/assets/branding/patch_notes_paper.ico`:six32-bit DIB frames,16/32/48/64/128/256px. Pillow format conversion only. [Input hashes, bounds and frame hashes](asset-result.json).
- `patch-notes/project.godot`:paper PNG project icon and paper ICO native Windows icon.
- `patch-notes/export_presets.cfg`:paper EXE/console-wrapper icons. Existing ICO include filter retained.
- Full `patch_notes_logo.png` and old `patch_notes.ico` are preserved. Wordmark PNG SHA256 remains `110208b457be9323ccdeb3aaa97b6a25e1ef00dc1c71ce0f702aea725d9d2302`.

[Small-size light/dark comparison](icon-comparison.png) was visually inspected at16/32/48/64/128px; the paper silhouette and orange bars remain recognizable. [256px preview](paper-icon-preview.png). These previews are not project assets.

## Verification

- Clean Godot4.7.1 import and release export: **PASS**, no recorded errors.
- PCK audit: **PASS397 entries**, every payload MD5, runtime completeness/exclusions and embedded SHA256 verified.
- Actual embedded package probe: **PASS**, paper PNG/native ICO settings and transparent corners; full wordmark resource remains loadable; genuine current-editor Studio/world/RNG restores exactly; unknown source rejects.
- Actual PE resources: **PASS**, all six frames match the new ICO pixel-for-pixel, including alpha. [Receipt](pe-icons.json).
- Actual headless and native EXE startup: **PASS**, exit0, no recorded errors.
- ZIP CRC and embedded EXE SHA256: **PASS**.
- Both older v0.02 and v0.02 Logo EXE/ZIP pairs remain byte-identical. Full source fence reports `canonical_unchanged:true` during export/verification.

The first probe incorrectly tried hashing the original PNG through FileAccess inside the PCK. Godot exports it as an imported/remapped texture. That verifier assertion timed out; [failure log](initial-probe-failure.log) and original command receipt are retained. Corrected probe loads the texture; source input bytes remain independently hashed. `resume.py` verifies the exact immutable export inputs/three build-only overrides and completes validation without rebuilding or relabeling saved fixtures. The final probe passes; this fixture failure is not described as a gameplay failure or passing attempt.

## Delivery and source

Under `C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/`:

- `Patch Notes v0.02 - Paper Icon/Patch Notes v0.02 - Paper Icon.exe`:116,438,928bytes; SHA256 `1d509c0dd14a8e2c9e3adf12b5ef4fb398ac2d8672a39c466e93d3ad6f049fe0`.
- `Patch Notes v0.02 - Paper Icon.zip`:43,722,154bytes; SHA256 `55ce472dd0087ca69114629290d484ad77f3021e8fc826bdabeb25376ba5e01c`.

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree preserved. [Source manifest](source.json), [build manifest](build-manifest.json) and [result](result.json) pin actual inputs. Exported runtime `0b0443b989c38ddd34b943846617d8bebdab3ee0cbe4e7b2dd6885f456202488` accepts the exact editor fixture `900d63cc8e8ce4f2928ec127c3cb9d87e1ca6b5ec3ba18555ac49294fc7c2c1c` through its recorded build-only bridge. Version/name/embedded-data metadata and that bridge are confined to the immutable export copy; no canonical gameplay/save schema changes.

Raw build records: `C:/Users/64jus/AppData/Local/Temp/pn-paper-icon-build-20261025-v1`. Original assets/export packages, player saves and `.codex-godot-temp` are preserved. No full-gameplay gate rerun, clean-machine/audio acceptance, external upload, commit, push or whole-release-readiness claim. Restart an editor-launched play session or use the new named EXE to load the new icon.
