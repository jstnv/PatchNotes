# Operational notes retained with the experiment

2026-10-26. The control driver was still running when an early call to `analyze.py control` attempted to open `control/experiment.log`. The runner publishes this captured log after the experiment finishes, so the read failed with `FileNotFoundError`. No experiment was restarted, no case removed, and no policy/seed/budget changed. After `control-exit.json` recorded exit0, the identical analysis command passed for all six controls. This was a premature evidence read, not a campaign rejection.

An exploratory read also requested an absent old study README, and a path-wide search matched the word `early` in every filename's parent directory. Narrow source-file reads supplied the intended context. These lookup errors did not alter files or simulation coverage.

The new private variant differs from its parent only by `scripts/debug/compact_planning_policy.gd`. The policy limits the study dose to one Brief, adds diagnostic size-aware planning, and retains the original grade function for actual award validation. It does not add cash work or a new settlement formula. The analysis/verification scripts are outside the gameplay project and may be corrected independently without editing a running variant.
