# Patch Notes v0.02 Windows package — 2026-10-24

User requested an EXE named **Patch Notes v0.02**, preferably available with a ZIP in this chat. Read CURRENT_STATE/TODO/README, release-engineering records and the current export helper/preset/source. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty checkout (1,848 status entries before this log), inherited edits and `.codex-godot-temp` preserved. No canonical project edits, commit or push.

## Delivery

- ZIP: `C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02.zip`,42,214,225 bytes, SHA256 `004987fedd87596d6b6de8780ab0f89a039a7cc6c23f0c0f17b6b603f348e947`.
- Single EXE: `C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02/Patch Notes v0.02.exe`,113,773,920 bytes, SHA256 `8a3f4d6dca58e8935ea76d41941c9dd1c8e387ce53d82fa094df80ca7533ecf2`.
- ZIP contains that EXE, README and the original Tiny5 font OFL license. Game resources are embedded; no companion PCK/console wrapper is needed. Local artifact links provide access from the desktop chat; no external hosting/upload or GitHub release was created.

## Build and verification

`python -X utf8 docs/codex/findings/build-v002-20261024-v1/build.py` — **PASS**, final canonical source unchanged. [Machine receipt](../findings/build-v002-20261024-v1/result.json), [source manifest](../findings/build-v002-20261024-v1/source.json), [build inputs/templates/artifacts](../findings/build-v002-20261024-v1/build-manifest.json). Raw build/import caches and profiles stay at `C:/Users/64jus/AppData/Local/Temp/pn-build-v002-20261024-v1/`.

- Existing pinned official Godot4.7.1 template archive SHA256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` and matching editor are verified by the existing helper. Fresh allowlisted source copy, clean import and release export pass, errors0.
- Build-local overrides only: version0.02; Windows product/file metadata0.0.2.0; versioned preset/output name; embedded PCK; no console wrapper. Application name remains **Patch Notes** to preserve its existing save/settings folder. Canonical export preset/project files are unchanged.
- The build-local world reader additionally recognizes exactly the measured canonical editor identity `8c8ef44726aae9dbd4a7967f8a750702a0ab5887f582b7880d65a77cb0f74944`, with all existing current-content/player/rival validation. No schema, gameplay, economy or AI rule changes. The exact two-release editor world is recaptured under its actual immutable source, then restored from the compiled package with every field/RNG equal; unknown source still rejects.
- Separately exported validation PCK passes383-entry runtime inclusion/exclusion, project.binary ECFG and every payload MD5. Loading the actual embedded EXE through Godot verifies all383 payload SHA256 values against that audited pack. [Embedded result](../findings/build-v002-20261024-v1/embedded-result.json).
- Actual delivered-format release EXE starts both headlessly and with native OpenGL on this computer,30 frames each,exit0/errors0, private profiles; no live player-save access. [Headless command](../findings/build-v002-20261024-v1/headless-startup.command.json) · [native command](../findings/build-v002-20261024-v1/native-startup.command.json).
- ZIP CRC check passes, and its EXE bytes match the audited executable. Canonical source hashes and every canonical export input are unchanged at completion. Driver Python compilation passes.

Compiled runtime identity is `57d64e0f6a00e04918e78445f0d46caf212a900c367d4b14d794d0a9c85e0d83`; retain this measured identity for future named-source save compatibility. The editor→this-package bridge is verified; reverse/future-version migration is not inferred. Full gameplay, audible, device and clean-machine acceptance were not rerun, and `release_ready:false` remains explicit.
