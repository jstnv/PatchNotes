from pathlib import Path
import json,hashlib
root=Path.cwd();out=root/'docs/codex/findings/overnight-ui-v1'
m=json.loads((out/'build-manifest.json').read_text())
drift=[p for p,h in m['included'].items() if hashlib.sha256((root/'patch-notes'/p).read_bytes()).hexdigest()!=h]
assert not drift,drift
report={'source_drift':drift,'package_entries':225,'desktop_launch_error':'Windows failed to launch app (ShellExecuteW returned 5)','exported_interaction_verified':False,'limitations':['Shell-launched rendered process not returned by sky.list_windows on two observations; stopped only owned PID89984.','Dedicated-profile desktop launch failed; no user windows controlled.','Initial export artifact was replaced by dedicated-profile export; final hashes are in overnight-ui-v1/build-manifest.json.']}
(out/'acceptance-result.json').write_text(json.dumps(report,indent=2))
text='''# Overnight exported acceptance attempt — 2026-10-09

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
'''
(root/'docs/codex/logs/2026-10-09-overnight-export-attempt-v1.md').write_text(text,encoding='utf-8')
p=root/'docs/codex/TODO.md';s=p.read_text(encoding='utf-8');start=s.index('**Computer Use preference,');end=s.index('\n',start)
s=s[:start]+'**Computer Use overnight dispatch, 2026-10-09:** now explicitly authorized by the user. Fresh current-source export and225-entry package audits pass, but desktop launch fails with `ShellExecuteW returned 5` (access denied). Current Fanbase/Starwave/Education and publisher exported interaction remains OPEN with this capability blocker; no longer held by user preference. [Attempt, artifact hashes and limits](logs/2026-10-09-overnight-export-attempt-v1.md). No scheduler was created.'+s[end:];p.write_text(s,encoding='utf-8')
p=root/'docs/codex/CURRENT_STATE.md';s=p.read_text(encoding='utf-8').replace('No refreshed export.','Fresh export/package audit now pass; actual desktop interaction is blocked as recorded below.',1);marker='## Current queue execution\n';s=s.replace(marker,marker+'\n2026-10-09: overnight computer control is now user-authorized. Fresh export including card-frame/modal fixes passes225-entry package audit; zero allowlisted source drift. Desktop launch fails with `ShellExecuteW returned 5` (access denied), so current integrated interactive acceptance stays open. [Attempt record](logs/2026-10-09-overnight-export-attempt-v1.md).\n',1);p.write_text(s,encoding='utf-8')
p=root/'docs/codex/design/release-engineering.md';s=p.read_text(encoding='utf-8');s+='\n## Overnight control dispatch — 2026-10-09\n\nThe user has now authorized desktop acceptance. Fresh current-source export and225-entry PCK audits pass, but the supported desktop launcher returns `ShellExecuteW returned 5` (access denied). This supersedes the user-preference deferral above; exported interaction remains open due to the launch blocker. [Exact attempt and retained artifact manifest](../logs/2026-10-09-overnight-export-attempt-v1.md). No human playtest or release-readiness inference.\n';p.write_text(s,encoding='utf-8')
print(json.dumps(report,indent=2))
