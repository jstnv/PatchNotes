# Repository update — 2026-11-07

The user requested a repository push. The starting branch was `main` at `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`, with 154 tracked modifications and no pre-staged changes. GitHub's `main` was checked and matched that commit. Existing worktree edits, `.codex-godot-temp`, simulation outputs, test profiles and player saves were preserved.

The commit selection comprises the tracked project changes, new runtime scripts and visualizer data, maintained debug verifiers, simulator tools and tests, and dated logs and cleanup manifests. Generated simulation outputs, exports, caches and private profiles were not staged. Some records link to local-only evidence or other worktrees and those links do not become portable merely by pushing this commit.

The fresh EXE autosave results and their limits are documented in [the autosave verification](2026-11-07-autosave-fresh-exe-headless-v1.md): the normal pack booted headlessly and audited test bootstrap packs passed 27/27 Studio, 3/3 cold Continue and twice 22/22 Contract checks. Normal-pack interactive and device acceptance remain open. Other performance and warning work remains open as recorded in TODO.

`git diff --cached --check` with `core.whitespace=cr-at-eol` identified a trailing blank line in the new debug-only `verify_actual_prior_private.gd`. The first simulator-tool unit-test attempt could not use the sandbox's default temporary directory (`PermissionError`); rerunning `python -m unittest tools.tests.test_simulate tools.tests.test_simulator_variant` with workspace-local temporary storage passed 43 tests in 103.965 seconds. The GitHub comparison needed network access outside the sandbox after the default DNS lookup failed.
