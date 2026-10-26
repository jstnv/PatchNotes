# v0.03 save fixes — GitHub publication

Publication scope, authorization, checks and exclusions are recorded in the [dated session](../../logs/2026-10-25-github-save-fixes-v1.md).

- `publish-inputs.json`: explicit publication inventory and the 388 tested runtime/import hashes.
- `verified-export-presets.cfg`: byte-exact tested source preset; the newer local preset is preserved separately in the worktree.
- `prepare_publication.py`: bounded inventory and credential/size/hash checks; it requires an initially empty Git index.
- `paths.nul`: local staging aid only; not a product or simulator input.

The actual runtime, save safety and package evidence are in [background checkpoint findings](../background-checkpoint-20261025-v1/README.md). Source publication does not close the separately recorded release acceptance limits.
