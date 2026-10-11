# E4 independent compatibility acceptance preparation

Prepared after old fixture generation and before reviewing the new education implementation. No new native run or main edit. Writer/root must coordinate the next native test slot.

## Source mapping at the pinned old boundary

- `scripts/studio_traits.gd`: `evaluate_traits(ids,version)` supports3/4/5; both education IDs are previews, zero refunded points, no active ID. Existing optional traits keep their version-specific evaluation.
- `scripts/run_state.gd`: public `create_studio_with_traits` obtains the default canonical selection, then `_commit_studio_creation` creates funding/roster/identity. Fixtures pass the existing explicitly versioned canonical selection to that same commit path.
- `scripts/persistence/studio_checkpoint.gd`: `capture` encodes the current typed root then calls `validate`; `validate` verifies canonical saved trait selection and whole finance provenance; `hydrate` validates before restoring.
- `scripts/persistence/studio_checkpoint_store.gd`: `inspect` requires valid envelope and payload, reports unsupported bytes without replacing them. `save` generates a new validated generation. The fixture producer used only its own48971 lease.
- `scripts/persistence/checkpoint_codec.gd`: schema1 envelope contains exact payload UTF-8 and SHA256; encoded integers remain canonical strings. Fixture manifests retain exact hashes of both layers.

## Review and later tests

1. Confirm the new reader explicitly supports the actual pinned `c7f6f...` revision rather than assuming old `previous_revision()` still denotes the right Fanbase/Starwave build. Unsupported revisions must remain preserved; broader historical compatibility is not required.
2. For each of the six preview fixtures and ordinary control, copy immutable bytes to a unique test profile. Use real store/Continue in a fresh process; retain original envelope/hash and record the resulting canonical snapshot. No regenerated/new-runtime legacy source payload.
3. Legacy trait version stays3/4/5, IDs stay present/inactive and canonical, refund stays0, original$200 point receipt stays once, cash stays570000c, RNG/run identity/ownership/finance history match. Any new education state is an explicit empty/inactive representation, not a principal account. Do not silently promote previews merely because their IDs are recognized.
4. Save the successfully restored old state under the new schema and Continue in another fresh process. Verify no second receipt, seed/account creation or new bill; the original copied bytes are still available as an older generation or explicitly retained source. Do not confuse a content migration with a newly confirmed Studio.
5. Compare a newly confirmed active-version Dropout/Graduate separately:580000/600000c and the approved point refund/account. These are active creation controls and must never be substituted for the actual old fixtures.
6. Active education boundaries, month12/firstdue/partial/Bank-overlap/payoff/finaldue, require separate genuine new-state evidence owned by the writer. Creation-only old fixtures do not cover debt schedule/payment behavior. To verify old previews stay inactive beyond grace, use supported productive transitions or clearly labeled component progression, without editing their serialized version or principal.
7. Corrupt/unsupported copies must reject atomically without rewriting current/backup bytes, cash, RNG or finance. After any rejection, a valid fixture must still restore. Distinguish rejection preservation from supported migration.
8. Verify source and test provenance, exact input/output hashes, error classification and no default production writer collision. No CU/visible export interaction before the user's overnight window.

Acceptance remains pending until these new-runtime tests and source review actually occur. The seven completed pre-education producers establish only the authenticity/validity of the legacy inputs.
