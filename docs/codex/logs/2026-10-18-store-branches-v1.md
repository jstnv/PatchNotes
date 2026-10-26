# Store branches and specialty review — 2026-10-18

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree retained. Handoff015 is implemented locally; Handoff016 is a completed DESIGN review with recommendations still OPEN. No commit/push.

## Implementation

- FeatureStoreCatalog owns the four Primitive acquisition parents and validates the entire graph, including missing/self/cyclic definitions. Card ledgers/printed values and prices are unchanged. RunState quotes, zero-cycle starter purchase, later Research admission and conditional acquisition paths use it. A queued parent is insufficient. Owned grant/legacy children and already-admitted historical research remain usable without retroactive costs.
- Five-region map retains library, nodes, colored borders, AND links and navigation; every root reserves two fan-out tracks plus outward expansion space. Siblings grow on separate diagonal/horizontal arms; all18 actual connectors avoid unrelated card/name/header/gate footprints. Overview zoom can fit the enlarged map. A revealed stale scroll-range bug is fixed by settling layout before applying the final focus camera.
- Primitive blocker/grant text now explains actual ownership requirements. Save rules advance to branches1, retaining named preceding revisions and the exact actual preceding rival source. Unknown sources still reject; historical state is not recomputed.
- Runtime files: `scripts/cards/feature_store_catalog.gd`, `scripts/run_state.gd`, `scripts/ui/feature_store.gd`, `scripts/ui/feature_store_map.gd`, `scripts/persistence/studio_checkpoint.gd`, `scripts/market/rival_world_checkpoint.gd`. Debug additions: `verify_primitive_branches.gd`, `primitive_branch_cold_probe.gd`, `capture_primitive_branches.gd` (+UIDs); existing Store/radial expectations updated. No specialty roster mutation.

## Verification

Commands use the private-profile runner [run.py](../findings/queue-20261018-v1/run.py), Godot4.7.1 and fresh immutable project snapshots.

- `before`: actual preceding-source Founder/rival capture30/30; separate old executable captures all eight founding Studios and one admitted parentless Dialogue queue.
- `store-final-v1 verify_primitive_branches primitive_branch_cold_probe verify_queue_source_migration verify_legacy_world`:171/171 branch checks,5/5 separate-process continuation checks,8/8 exact prior-world migration,30/30 Founder/world. All exit0 without script/errors. Includes all four absent/queued/owned parent gates, atomic rejection, original cents/cycles/rent, invalid graphs, shared ancestor, retained supply, exact legacy fields and fresh project commands.
- `store-v2`: existing parent65/65. `store-ui-v1`: existing Feature Store and radial navigation pass. `store-render-v3`: 183 rendered assertions,15 captures at900×600/1152×648/1280×720, Store copy52/52, productive-cycle purchase, eight specialty and Studio checkpoint suites, Founder30/30 pass. Representative branch/locked/AND/overview captures inspected; native PNG dimensions asserted.
- Early failures retained: fixture initially omitted second-cycle rent and passed a raw player payload where a simulation envelope was required; corrected. One stale14-edge assertion became18. First900 capture was clamped to1152 by Settings; stress harness now removes that minimum. One overview-to-detail jump exposed the real scroll-range issue above; final capture checks explicitly require the selected card onscreen.
- Existing six-ObjectDB exit warning also appears on the unmodified baseline; no new script/error remains. No human comprehension, balance or refreshed export inference from these Store checks.

## Specialty review

[Exact eight-roster inventory and proposal](../findings/queue-20261018-v1/SPECIALTY-REVIEW.md). Strategy, Simulation and Sports are the only Maps-without-Levels exceptions. Compare parent addition, substitution and explicit exception. Recommend future-start-only Maps→Levels substitution preserving count/Scope; printed Tech−2/Design+2 and optional-access consequences are explicit. Requires a separate approval and implementation handoff. Existing Studios retain exact ownership; no roster rollout performed.
