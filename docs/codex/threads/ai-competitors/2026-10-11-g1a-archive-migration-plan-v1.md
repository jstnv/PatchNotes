# 2026-10-11 G1a archive migration addendum

**Status: predeclared v3 private simulator check; no new design approval.** v2 demonstrated legal opening and Studio continuation but its changed checkpoint schema rejects the prior current-rule Studio envelope. Preserve v1/v2 evidence and create a new v3 from v2.

## Hypothesis and cases

Adding a version-aware decode with empty archive/snapshot defaults for previously valid Studio checkpoints will preserve the exact old save payload and allow the first post-migration project through legal commands. The migrated Studio retains its actual one live release, cash, Fans, RNG and finance journal. It gains no historical titles, Features, money or Fans. A new v3 incumbent still retains its archive through normal capture/restore.

- Migration arm: use the immutable baseline bundle's `g1a-control-4417/studio_checkpoint.json` from current rules source `4162c70c...`. Prepare a Studio-only continuation with the same finite policy, seed already inside the checkpoint, 60 further commands, target two total live releases. A changed rules identity is expected and must be decoded through the explicit old revision; no identity patching.
- Fresh incumbent arm: reuse seed 4417, Action/Fantasy, trait-backed cash/Fans, three extra Features and two frozen titles from the v2 positive fixture. One live release, 60 commands.
- Invalid prior envelope: use a copy of the old checkpoint with a wrong content revision; reject at initialization. This is a fixture copy only, never a player save.

Run fresh output directories through `simulate.py run --variant`, with 240 seconds per import/run, and exact fresh-process replay of migration plus fresh incumbent. Stop after those cases regardless of Review. Retain failures and timeouts. Compare migration initial cash/Fans, live release count, old live title, RNG/checkpoint validity, finance, archive count, subsequent legal commands/release. This tests only previously supported Studio checkpoints; it does not establish compatibility with unsupported pre-Fanbase saves or any player UI state.
