# Active market integration review — 2026-10-19

## Scope and source

Independent review of the canonical market delta against `before-source.zip`; branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty checkout preserved. Current editor mechanics identity computed from the runtime's source inputs: `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`. This is a source assessment; current-source execution results belong to the separately pinned runs.

## Correctness assessment

- The player plans the next month before committing its productive action. Rivals consume that committed snapshot. Even/odd cycle handling admits prior-cycle launches at the next boundary; the 12-cycle window excludes old releases.
- New projects freeze their targets and explanation. Review reads those targets. Sales preserve one factor for both earning halves of each release-age month; monthly reports replay those saved factors. Player-only sessions retain neutral factors and Genre base targets.
- Fan gains use actual crowded sales. The existing Review-neutral loss shadow remains unchanged.
- Frozen world history is checked against reconstructed month snapshots from retained owner release facts. Named migration origins limit neutral historical earnings to the migration boundary and historical project targets to originally active project IDs. Subsequent completion or Founder handoff preserves those project identities.
- The current-revision checkpoint decode fast path still uses the strict current schema. Historical payloads continue through the frozen migration validator.

## Findings addressed during review

1. **Frozen provenance:** originally arbitrary snapshot IDs, future cycles, internally consistent false counts/targets, and invented historical exemptions could pass too far through validation. Identity shape, earning-month dates, reconstructed facts, and `market_origin` now close these cases. The refreshed current-source negative run passes **31/31**, exit 0, with input bytes and validation inputs unchanged; see `provenance-pinned.json` and `provenance-pinned-run.json`. It used the actual `acceptance-pinned-action-war.json.checkpoint.json`, completed in 7.845 seconds wall / 7.063 seconds Godot CPU, and reported no script errors. The existing six-instance ObjectDB shutdown warning remains recorded. Earlier `provenance-origin.json` is retained as prior-source evidence.
2. **Player explanation:** How to Play no longer says rivals cannot affect targets or crowd sales. Studio/monthly projections distinguish future crowding from factors already frozen.
3. **Export source fence:** the earlier fingerprint ignored `.gdc` and `.gd.remap`, reducing compiled-pack identity to data plus a missing query source. Current code hashes actual compiled scripts/remaps and the compiled query. Editor and exported identities remain distinct; the prior weak pack identity must not be treated as proof of exact executable source.

## Bank preservation

**PASS by byte comparison:** all six files under `scripts/finance/` and `scripts/ui/studio_finances.gd` match their pre-integration SHA-256 values. `run_state.gd` changes only market preflight/provider state, frozen release details, and factors passed into sales; its Bank methods and finance-plan arguments are unchanged. Full before/current hashes are in `bank-source-preservation.json`. This establishes unchanged Bank rules, not unchanged future balances when market sales differ.

## Evidence limits

No further concrete correctness issue was found in the reviewed paths. This assessment does not establish final balance, long-campaign challenge, large-population CPU limits, audible/human comprehension, or current exported Continue. Corruption checks are structural/accounting validation, not cryptographic protection against rewriting an entire consistent save. Player-command rejection checks do not claim rollback after an unexpected error halfway through rival advancement. Use the final run records for execution and release-acceptance claims.

Review artifacts only were authored by this reviewer; no canonical runtime, Bank, TODO, commit or push changes were made.
