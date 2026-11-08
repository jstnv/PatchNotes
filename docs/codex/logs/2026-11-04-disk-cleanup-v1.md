# Disk cleanup before audit — 2026-11-04

The user requested removal of unnecessary disk data and then explicitly required at least 20 GB to be freed before the visual/performance audit resumes. Cleanup is **in progress**; do not equate current free space with deleted bytes because Windows disk usage changes independently. Preserve `.codex-godot-temp`, real saves, worktrees, source, unique user files and retained evidence. Working tree began on `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`, with the previously documented uncommitted audio, UI and performance changes intact.

Verified deletions (decimal bytes; duplicates removed in the prior portion of this same cleanup):

- Three SHA-256-identical temporary Demo executables, keeping a verified identical fourth copy and surrounding evidence: 327,336,960 bytes.
- The old `2025.8.8.1141` Chrome downloadable on-device model cache, with the newer selected `2025.8.21.1028` retained: at least 4,269,932,544 bytes of model weights. Chrome may redownload a component if needed.
- 37 old, unlocked Adobe-generated `.cfa` audio cache files, with source media untouched: 2,048,393,216 bytes. Adobe can rebuild them.
- 23 old, unlocked official Unity registry `package.tgz` download-cache files: 578,911,294 bytes; and, in a separate checked action with Unity closed, the old official expanded registry package cache: 1,084,614,808 bytes. Unity may redownload packages.
- One old Overwolf crash dump and one old, signed temporary OneDrive installer, each checked and unlocked: 561,462,649 bytes.

Verified total at this point: **8,870,651,471 bytes (8.87 GB)**. As of the last sample C: had roughly 9.89 GB free; that free-space figure is not a deletion counter. The 20 GB target remains unmet, so do not resume the audit. Protected `.codex-godot-temp` and simulation evidence were not deleted.

Further verified removals: an old signed Obsidian updater installer, retaining the installed application (341,331,008 bytes); 35 old Roblox Studio download-cache files, retaining its applications and user data (417,420,535 bytes); and the obsolete GitHub Desktop 3.6.3 version, retaining the current 3.6.6 installation and package (754,030,671 bytes). Applications and updaters were checked for running processes, and exact paths, ages and contents were checked before removal. These bring verified removals to **10,383,433,685 bytes (10.38 GB)**. C: subsequently showed approximately 11.32 GB free; disk consumption can change independently. The required 20 GB removal remains unmet and the audit remains on hold.

Recent Patch Notes crash dumps were identified and preserved for the later investigation. Active Chrome, Edge, Discord, Steam and Overwolf processes were detected; their live caches were not cleared. NVIDIA shader cache was retained to avoid affecting later performance measurements. Unity Hub's pending installer and an installer with an indeterminate signature were also retained.

Further read-only checks of user and system caches found no additional clearly disposable multi-gigabyte target. A duplicate-file scan identified identical version-labeled game executables and Codex temporary indexes; these were retained because their provenance and active use were not established. No audit runs were started. The existing follow-up remains gated on the verified 20 GB cleanup target.

An attempt to remove two old Adobe installer scratch folders stopped on Windows ACL denial before any file count/bytes changed; both remained at their original combined 1,474,914,629 bytes. No ACLs, power settings, pagefile or hibernation settings were altered. Previous versioned simulation archives and distinct releases remain, as do browser site data and Codex worktree/session data. Additional candidates must be independently verified as unnecessary and safe before deletion.
