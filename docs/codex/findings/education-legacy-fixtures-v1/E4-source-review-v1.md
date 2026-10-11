# E4 independent source review

2026-10-09. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, existing dirty integrated work preserved. **No confirmed source defect found in the reviewed compatibility path. Native compatibility acceptance remains pending.** This review does not freeze the writer's source or replace the planned fresh-process tests.

`E4-source-review-v1.json` binds the nine reviewed runtime files and all seven unchanged fixture records to their SHA256 hashes. A separate calculation from the prior rules string plus sorted current data paths/hashes produces the fixtures' exact `c7f6f3165ea85f7afd5070042d053ce581f84338437640c3e4b6de787c1f5a5b` revision. All pinned data hashes remain unchanged. Every original fixture file still matches its pre-education manifest.

## Findings

- `StudioCheckpoint.validate` explicitly admits the immediate pre-education revision. It does not mistake the older pre-Fanbase `previous_revision()` for that revision. Unsupported revisions remain incompatible.
- The prior path decodes through `CheckpointSchema.root(false)`. Its closed record unions and strict codec reject new education fields, unknown fields, duplicate keys and noncanonical integer values before reconstruction. Only saved trait versions3–5, or the supported empty earlier selection, enter this conversion.
- `StudioTraits.evaluate_traits(ids, saved_version)` retains the old active IDs, costs and refunds. Education is active only for version6. Full canonical selection equality and the education owner/trait check prevent an inactive preview from acquiring a debt account. Startup receipt identity checks require the original saved-version point/Family receipt exactly once and at creation.
- `upgrade_v5` replays the prior journal into finance6 with an empty education field, then removes only that field and restores the schema number for exact equality with every original finance field. Subsequent full `_is_valid` replay checks each action's cash-before continuity as well as the complete journal. No old cash, Bank bill, credit entry or other financial field is intentionally rewritten.
- The codec builds new dictionaries, and the adapter hydrates the converted values in memory. Store inspection/Continue perform no file write. The coordinator retains the loaded payload, marks restored Studio unmodified, and writes the current schema only on a later pending checkpoint. Its first new generation preserves the original prior generation; normal later retention remains the newest two valid generations.
- Unsupported/corrupt inspection preserves bytes and does not silently load a backup. The isolated fresh-process probe must still demonstrate rejection followed by valid recovery, unchanged original bytes, and a new-schema save followed by another cold Continue.

## Remaining acceptance

Await the writer's source freeze and coordinated native slot. Run the seven actual old envelopes through real store/coordinator Continue on isolated port48971, then save and cold-load their new-schema generations. Compare complete state, RNG, canonical trait records, original receipt counts and zero education state. Exercise corrupt/unsupported copies separately. These creation fixtures do not prove active education payment schedules or every later gameplay boundary; the writer owns those separate checks.

No native tests, Computer Use, user-save access, runtime edits or shared status edits were performed by this source-review pass. Only this findings note and its hash record were added.
