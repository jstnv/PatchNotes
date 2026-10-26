# Runner setup retry, 2026-10-25

The initial prefix-puzzle-a attempt exited 1 before gameplay with `Canonical source changed while recording drift; retry in a new output`. Its raw run-report and driver/command/exit records are retained. The following puzzle-b and others bundles completed successfully without policy or variant changes.

Retry the identical prefix-puzzle-a config in fresh `prefix-puzzle-a-retry1`. No seed, command/time budget, gameplay source, policy, or starting state changes. Analysis/orchestration uses that explicit replacement path while preserving the original failure. This is a concurrent-source snapshot safeguard, not a simulated affordability failure.
