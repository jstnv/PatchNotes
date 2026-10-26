# Old-world market migration validation boundary — design decision, 2026-10-18

## Status and authority

**SELECTED qualitative rule under the user's delegated AI Competitors design review.** The [save revision decision](2026-10-18-market-save-revision-decision-v1.md) requires exact named old inputs and a validated whole-pair conversion. The [integrated v26 finding](2026-10-18-market-integrated-migration-finding-v1.md) proves raw old Studio, sales and Fanbase validation on its tested fixtures. This decision specifies what counts as a validated old *world*. It does not approve market coefficients or canonical adoption.

## Selected boundary

1. Before adding market fields, require the exact old world root key set for its named source family, including the permitted Founder version, and the expected old rival-row and active-project field shapes. Validate the raw old Studio payload for the player and every rival, including old sales and Fanbase accounting. Keep the original bytes and source identity unchanged.
2. After converting a copy, fully restore the player and world with the current catalog and validators before Store inspection may call the generation **valid**. A schema decode alone is insufficient. The full restore must reconcile release history with owner Studios, active projects, Founder finance and the world calendar. Continue must use the same conversion and semantic checks. Any rejection leaves the old generation untouched and follows the ordinary invalid/incompatible/recovery distinction.
3. An independent duplicate of the complete old-world semantic decoder is not required if the exact raw shape/source gate, old Studio preflight and full current restore all pass. The old-field world decoding rules should be checked against each admitted old source family during implementation review. A new source family requires its own legal fixture and compatibility proof.

## Alternatives recorded

| Alternative | Disposition |
|---|---|
| Treat current `world_codec.validate` as sufficient after conversion | Rejected. It decodes fields but does not reconcile release history or Founder finance; a checksum-valid old world with a changed history Review can inspect valid yet fail Continue. |
| Copy and maintain a complete old-world semantic decoder for every source | Deferred as unnecessary duplication while the exact old shape/source gate and full current restore cover the old-world invariants. Reconsider if a source family has old semantics that current restore cannot preserve. |
| Trust only the Store envelope checksum and source ID | Rejected. They prove transport and named origin, not semantic consistency of embedded world data. |

## Acceptance and remaining work

The private v26 candidate has **not** satisfied this boundary: its adapter ends with `world_codec.validate`, while full history and Founder checks occur in `restore`. A later private version should test schema-valid altered/duplicate/missing release history and a Founder finance mismatch, then rerun the passing Store/Coordinator and cold Continue cases. Keep failures in the dated finding. Integrated presentation-source coverage, old executable Store production, canonical reconciliation, graphical/exported Continue and numerical market rules remain **OPEN**. A passing private check does not approve balance.

**Later 2026-10-18 private result:** The [v29 finding](2026-10-18-market-full-restore-migration-finding-v1.md) satisfies the exact old shape and full catalog-backed Store restoration mechanism for its tested sources, including altered history, Founder owner and missing hand-card negatives. V27's false-valid inspection remains retained. The raw root/row guards were source-inspected, while a direct root/row mutation and a Founder finance mismatch were not run. Other named source families, canonical reconciliation, graphical/exported Continue and market numbers remain **OPEN**; the [sealed v29 packet](handoffs/market-save-review-20261018-v1/HANDOFF.md) is for design review, not gameplay adoption.
