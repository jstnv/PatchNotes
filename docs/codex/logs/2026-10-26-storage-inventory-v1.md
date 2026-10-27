# Storage inventory — 2026-10-26

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; shared tree already dirty. Read CURRENT_STATE, TODO, README and inspected status/diff before the inventory. Existing work, source and `.codex-godot-temp` preserved.

Created `docs/codex/findings/storage-cleanup-20261026-v1/{inventory.py,inventory.json,cache-candidates.json,README.md}` and this log only. No deletion, compression, move, gameplay/source change, TODO edit, commit or push.

Checks:

- Bundled Python `-X utf8 .../inventory.py`: completed after 121.422s; 1,127,270 files; 86,799,065,249 logical bytes. 1,554 inaccessible paths retained in report. Sandbox inode values all zero invalidated physical/hard-link totals; guard corrected and report explicitly marks those totals unavailable. Not a complete physical disk accounting.
- `git count-objects -vH`: 29.97 MiB loose /818.68 MiB packed; zero garbage.
- `git ls-files -- '**/.godot/*' '**/__pycache__/*'`: no tracked `.godot` files; six tracked Python caches, preserved.
- Reviewed `.gitignore`, source selection in `tools/simulate.py`, variant identity/archives in `tools/simulator_variant.py`, and evidence-retention contract in `VARIANTS.md`.
- Candidate manifest: 984 `.godot` directories beneath docs older than 48 hours; 3,032,868,888 logical bytes. Current project and protected temp excluded. This is a proposal, not proof that all paths are currently inactive or unreferenced.
- Final branch/HEAD unchanged; current shared status/diff inspected. No gameplay verification applicable.

Follow-up: authorize and preflight a bounded cache cleanup; separately verify archival/restore of obsolete experiment bundles before removing originals. Actual reclaimed disk space remains UNMEASURED.
