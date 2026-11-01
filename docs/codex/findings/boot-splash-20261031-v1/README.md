# JooceBox native boot splash — 2026-10-31

User supplied the original JooceBox PNG and requested the studio identity above a smaller Godot icon in place of the default large engine splash. Branch `main`, intake HEAD `49d769235474a880a73d996499cefa72beec63e5`. Preserved the concurrent Annual Awards edit in DECISIONS and both protected temporary directories.

## Implementation

- `patch-notes/project.godot`: native custom PNG splash, black background, aspect-preserving fit, linear filtering, visible image, 1200ms minimum. Existing main-scene UID, app name, icon, audio/autoloads and gameplay are unchanged.
- `patch-notes/assets/branding/joocebox_logo.png`: byte-identical copy of the user-supplied artwork; SHA256 in `asset-provenance.json`.
- `patch-notes/assets/branding/joocebox_boot_splash.png`:1920x1080 engine-rendered composition: original logo, centered JooceBox Studios title, MADE WITH caption and smaller existing Godot mark. Existing Chakra Petch font and its license remain in the project.
- `tools/build_boot_splash.gd`: repeatable asset renderer, outside canonical gameplay and never executed during normal startup. Run the installed Godot executable with `--path patch-notes --script` followed by its absolute path; requires native rendering, not the headless dummy driver.

This uses the engine's boot image directly, with no new startup scene or music transport calls. The brief minimum keeps the artwork readable; longer initialization remains covered by the native splash.

## Verification

- `settings-check/result.json`:11/0 headless checks of all six splash settings, app name/icon/main scene, PNG decode/dimensions and unchanged authoritative gameplay runtime identity `ef14cc34682dbe4ab3e739ea13396da9979c3a8efb9c057c7c8cfa25d78980f6`.
- `native-1152/result.json`, `native-1280/result.json`: actual canonical game launched with isolated profiles, Dummy audio and finite lifetimes at1152x648/1280x720; both exit0, zero ERROR/SCRIPT ERROR. Computer Use observed the actual native boot image at both sizes and the subsequent1280 Main Menu; screenshot observations are in the chat's native tool history. Existing user windows were excluded from selection.
- `builder-v2-result.json`: final GPU rendering exits0 without errors; both image rectangles assert their authored bounds. Final PNG visually inspected.
- `before-source.json`/`after-source.json`: only project.godot and the two new PNGs differ within canonical source inventory. The supplied original and copied logo SHA256 are equal. All gameplay scripts, data and frozen certificates are unchanged.

The first renderer output exposed TextureRect's texture minimum-size clamp: assigning bounds before `EXPAND_IGNORE_SIZE` left both images too large. Corrected property order; retained `layout-before-size-fix.png` and original builder receipt. This was caught during visual verification before acceptance. Historical ObjectDB warnings in some runs are retained rather than hidden.

No broad gameplay suite, packaged EXE/ZIP rebuild, human listening, commit, push or release-readiness claim. Existing packaged EXEs require a new export to contain the splash.

Primary engine reference: [ProjectSettings boot splash](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html#class-projectsettings-property-application-boot-splash-image); PNG-only custom image and the aspect-preserving stretch enum were checked against official docs and the running4.7.1 engine.
