# Old player-only earned-sales migration study — predeclared plan, 2026-10-18

## Question and design status

The named-source world-pair v18 candidate passes three legal pairs, but the old player-only fixture has no player sales. Test whether the same exact pre-market source can restore a **worldless** committed player Studio checkpoint after real earned sales, without changing historical units, cents, Fans, cash, Review metadata or RNG. The qualitative migration boundary is selected in `2026-10-18-market-migration-boundary-decision-v1.md`; market coefficients remain OPEN/TRIAL. This is a private simulator test, not canonical adoption.

## Source, legal prefix and comparison cases

Use the unchanged old audit variant `simulators/market-migration-old-fixture-20261018-v1`, source `f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de`. Continue its retained seed-4417 Action/Fantasy 2/2/2, no-Traits, one-release Studio envelope from `sims/market-migration-old-player-20261018-v2/cases/foundation-legal-action-4417/studio_checkpoint.json`. The same finite legal policy will make a second release; its committed Studio envelope is the earned-sales player-only fixture. This continuation is a new old-source output and does not edit checkpoint bytes or source identity.

Create `simulators/market-migration-pair-20261018-v19-player-only` from v18, preserving ancestry and original baseline. Add only a private player-only import/check path and focused verifier in that version's `project/`. The candidate shall accept exact old source and original old field shape, add neutral historical age-month factors to all actual released-game records and Fanbase shadows, validate the upgraded player with the candidate Studio codec, and retain **no rival world**. The empty-sales cycle-8 player-only fixture is a control. An unknown source, missing old sale field, and changed historical earned units/cents are rejection cases. The original old save/envelope remains unchanged.

## Measurements and limits

Measure old/new encoded equality after removing only new factor fields; old and migrated sale age, units, entitlement and settlement cents; Fanbase, cash, metadata, RNG; world absence; half-earned age-month factor continuity; and current-source recapture plus fresh-process Studio-only restore. Validate the old envelope through its original runner/codec before importing it. Use exact old/candidate source identities and file hashes, unique outputs/profiles and the documented isolated runner. Replay the second-release old prefix and one fresh candidate case.

Keep seed 4417, Action/Fantasy 2/2/2 finite policy, at most 50 additional player commands, two total player releases, at most two post-import productive cycles, and 240 seconds per process. Stop on failed old-source checkpoint validation, no earned sales, source/RNG mismatch, invalid new codec, changed historical fields, created rival world, original-byte mutation, failed cold restore or unsupported source. Retain failures; do not change seed, caps or source allowlist to obtain success. No `StudioCheckpointStore` writer lease is needed for this scoped codec test. Founder/current-presentation sources and atomic generation/backup recovery remain separate OPEN cases.
