# Overnight exported acceptance attempt — 2026-10-09

Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; shared dirty worktree preserved. No gameplay edits, commit or push.

The user explicitly authorized overnight computer control, superseding the previous hold. The Computer Use skill was read and its supported `@oai/sky` runtime initialized. Desktop enumeration worked. The fresh isolated export could not be driven: `sky.launch_app` returned **Windows failed to launch app (ShellExecuteW returned 5)**. This is a launch access-denied error, not an observed gameplay failure or an automatic approval-review rejection. No security setting was changed.

## Checks performed

- `python docs/codex/findings/overnight-export-v1/build.py`: clean import and release export exit0, no matched script/export failure markers. Official matching4.7.1 templates retain pinned checksums.
- `python docs/codex/findings/overnight-export-v1/launch.py`: actual225-entry PCK audit passes all payload hashes/allowlist checks. A fresh-profile executable started and logged OpenGL plus Loaded40cards. This is startup evidence only. Shell-launched process89984 was absent from two desktop enumerations; only that owned test process was stopped. Root-certificate-store warning was present.
- `python docs/codex/findings/overnight-export-v1/prepare_ui.py`: dedicated-profile release export exit0,225-entry package audit passes. Only build-local app name/save-directory configuration differs; gameplay source stays unchanged. Final export manifest and package inspection are in [overnight-ui-v1](../findings/overnight-ui-v1/). The final source hash comparison found zero drift across all allowlisted source files.
- Desktop launcher call for that exact executable returned access denied before any observed game interaction. Existing debug game/editor windows were left untouched. No player saves were loaded or injected.

The initial output EXE/PCK directory was reused for the profile variant; use the final `overnight-ui-v1/build-manifest.json` hashes for the retained artifact, not the initial manifest. Runner scripts, command logs and initial rendered startup logs remain under [overnight-export-v1](../findings/overnight-export-v1/).

## Open work

Current Fanbase/Starwave/Education rendered interaction, Crown/Neon next-launch Promotion, current Bank/Continue acceptance and supported-resolution input/settings checks remain open. Computer control is authorized but blocked by the desktop launch failure. These are not closed by package/headless checks. AI Competitors separately still needs the explicit G1 opening-rule ruling. Approved audio remains missing. No release-ready claim.
