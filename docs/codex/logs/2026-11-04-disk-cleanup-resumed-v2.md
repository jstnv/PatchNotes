# Disk cleanup resumed — 2026-11-04

The user resumed disk cleanup with a goal of 20 GB free on C:. Started on `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`, preserving existing tracked and untracked work. DriveInfo reported 11,147,636,736 bytes free at intake. The earlier cleanup removed 10,383,433,685 verified bytes; the earlier, separate audit condition requiring 20 GB actually removed remains unmet.

Additional verified removals:

- One 36,106,145-byte top-level duplicate of `patch-notes-startup-loop-v4.mp4`, after verifying SHA-256 `6412c3da60431791bca691e304a0fcbf2ca38011d338f9d4fbba78165610428b` for both copies. The identical file under `Downloads/Patch Notes Design Folder/` remains.
- 53 unlocked NitroSense application logs older than 90 days, 111,152,031 bytes in total. Newer logs and application data remain.

These actions removed 147,258,176 bytes, bringing the two cleanup passes to 10,530,691,861 verified bytes removed. A later DriveInfo reading showed 11,289,948,160 bytes free; the 20 GB free-space target is unmet. Free space fluctuates independently of deletions.

Read-only checks found 4,249,237,384 bytes of local OneDrive personal media whose Cloud Files metadata reported not in sync; these were not dehydrated or deleted. Unity Editor 2022.3.53f1 and 6000.3.16f1 measured approximately 6.64 GB and 8.30 GB respectively, but Unity Hub associates both with existing projects, so neither was removed. Photoshop, After Effects and Media Encoder are also installed creative tools, not disposable cache. The older NVIDIA shader cache was retained while Godot was running and because clearing it would introduce recompilation into subsequent performance checks. Browser caches in active profiles, project and simulation evidence, `.codex-godot-temp`, saves and worktrees were preserved. Previous Adobe installer scratch cleanup hit a Windows ACL denial as documented in `2026-11-04-disk-cleanup-v1.md`; no access settings were changed.

No safe independently verified candidates found in this pass could close the remaining gap. The game audit was not resumed. No source, save, installed application, system configuration, commit or push was changed.
