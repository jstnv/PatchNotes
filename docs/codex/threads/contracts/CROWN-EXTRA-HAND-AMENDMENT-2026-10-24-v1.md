# Crown extra-hand audit amendment v1

2026-10-24. Added during the frozen, predeclared cohort; no experiment inputs changed.

The first aggregate audit of three finished pairs stopped at `AssertionError: common runner`. Simulation 4522 used runner SHA-256 `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193`; subsequent batches used `3a7db22dd14747bce423f5031f85d92bc8e0aa1d20155e106b6fa3601e57da0b`. Another thread added `.ico` to `SOURCE_SUFFIXES` in the shared isolated runner between batches. Both original runner files remain in their raw bundles.

The [retained diff](studies/crown-extra-hand-20261024-v1/runner-ico.diff) contains exactly that one allowlist addition. The [audit](studies/crown-extra-hand-20261024-v1/runner_audit.py) accepts only those two full-file hashes and proves byte-for-byte equality after removing that exact addition from the second runner. It also requires identical actual mechanics and non-import frozen manifest identities. The ordinary bundle/source/input/telemetry checks and same starting state/RNG comparison remain mandatory. Any further runner change fails this explicit exception.

This permits combining otherwise compatible pairs; it does not label runners identical. The original failing assertion and each pair's runner identity are retained in [runner-compatibility.json](studies/crown-extra-hand-20261024-v1/runner-compatibility.json). There was no associated runtime rejection. Seeds, policies, starts, rewards, gameplay, command bounds, output folders and stopping conditions are unchanged. The original plan and its hash remain intact.
