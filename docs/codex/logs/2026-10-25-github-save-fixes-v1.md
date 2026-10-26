# GitHub source publication — 2026-10-25

## Authorization and starting state

User requested updating GitHub with the completed save fixes. Branch `main`, local and remote base `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; index empty before staging. Existing shared changes and `.codex-godot-temp` are preserved. No gameplay changes in this publication pass.

## Publication scope

Publish the tested v0.03 canonical runtime and its supporting tests/tools, shared design/session records and retained save-performance findings. This includes the prior uncommitted runtime dependencies required by the tested build, rather than an incomplete patch containing only the writer. Candidate simulator project copies, private profiles, caches and generated EXE/ZIP packages remain local. Publishing a design record does not adopt its OPEN or candidate gameplay values.

The exact input list and SHA256 inventory are in [publication inputs](../findings/github-save-fixes-20261025-v1/publish-inputs.json). The full source changes and measurements are described in the [background-save session](2026-10-25-background-checkpoint-v1.md) and [findings](../findings/background-checkpoint-20261025-v1/README.md).

## Checks

- PASS: `git branch --show-current`, `git rev-parse HEAD`, `git status --short --untracked-files=no`, `git diff --stat`, `git diff --cached --stat` inspected before publication; remote base verified by `git ls-remote origin refs/heads/main`.
- PASS: publication inventory verifies all 388 runtime/import inputs against the Smooth Saves build manifest, checks selected file sizes and scans source/text for credential patterns. No oversized Git objects or credential-pattern matches.
- Existing exact-source evidence: 24/24 final focused suites; 197 strict-validation assertions; 36 cold-restore assertions; compiled lifecycle 25/25, native functional 30/30, headless gameplay 28/28; new-game/four-release/calendar96 replay and package integrity passed. These are retained receipts, not newly rerun suites during publication.
- PASS (publication continued 2026-10-26): staged Git blobs match all 388 build-manifest hashes plus four changed uppercase scene aliases. Explicit-path inventory contains no generated EXE/ZIP/PCK or simulator project copies; the newer local export preset is byte-preserved. [Staging receipt](../findings/github-save-fixes-20261025-v1/staged-check.json) records the verified source tree before adding the receipt and this final log update. Normal fast-forward push only; remote SHA must equal local HEAD before reporting publication complete.

## Preserved local export settings

The local export preset changed after the verified build (SHA256 `94d04050ad54f780e043b18be5fe16415864e8451f5cfc13f269a4d7e64293bb`). It remains untouched. The Git index uses the exact tested preset (`833fbfcd71cf25e371dae17afe938da61612b8288a3ebfe13de288e39ea23c78`), recovered from the build snapshot and hash-verified after reversing its four known build-only overrides. The recovered bytes are retained alongside this publication's inventory. Thus the intentional local preset change will remain unstaged after publication.

## Limits and follow-up

Native sustained frame budget remains NOT_ESTABLISHED. This publication does not establish whole-release, human/audible/device or final-balance acceptance, nor update Drive. Git commit history and the final verified remote response establish publication identity; the build and earlier historical records retain their original pre-publication statements.
