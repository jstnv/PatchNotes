# Active-market checkpoint revision boundary — design review, 2026-10-18

## Status and authority

**SELECTED qualitative rule under the user's delegated AI Competitors design reviews.** The user asked this thread to finish private save-compatibility acceptance before an implementation handoff. The [original whole-pair migration rule](2026-10-18-market-migration-boundary-decision-v1.md) still governs historical sales, Fanbase, frozen Reviews and old player-only worldlessness. The [player-only Store finding](2026-10-18-market-player-store-migration-finding-v1.md) shows why a new content revision is necessary. This record selects the discriminator and atomic publication contract, not numerical market terms or canonical gameplay adoption.

## Selected boundary

1. A new active-market sales/checkpoint schema receives a **new Studio content revision**. The exact hash must be derived and pinned from implementation source/data; the private `sales2` marker and `614b…` hash are test identifiers, not fixed public save authority.
2. A worldless pre-market Studio generation has no gameplay source ID. Only an explicitly named prior `content_revision` with the exact corresponding old encoded field shape may enter a migration adapter. The tested old `dd095…` revision is the first candidate allowlist member; other prior player-only revisions require their own legal fixtures and validation. Never infer a missing source ID or accept arbitrary missing market fields.
3. A world-backed generation additionally requires an exact supported old world `source_identity` and shape, paired with an allowed old player revision. Preserve Founder version/ownership constraints for each named family. Validate the *whole* migrated player/world pair, Fanbase, finance, historical earned units/cents, release metadata and RNG before publishing any new generation. Historical factors and active project standards follow the [selected prospective migration rule](2026-10-18-market-migration-boundary-decision-v1.md).
4. Store inspection and Coordinator Continue must apply the same deterministic in-memory conversion. Pure Continue leaves the original generation bytes and number unchanged. The next committed Studio save publishes one new-revision generation atomically; a failed write leaves the old valid generation intact. A damaged current generation exposes a backup only through the existing explicit recovery path, and an incompatible current generation remains incompatible. Old player-only Continue remains worldless.

## Alternatives recorded

| Alternative | Disposition |
|---|---|
| Keep the pre-market content revision for new market sales records | Rejected: old/new record shapes share an identifier, so normal Store validation cannot distinguish an eligible old worldless save from an incomplete new one. |
| Require an old gameplay source ID on player-only Store generations | Rejected: the original Store payload does not contain one. |
| Accept any missing `market_factors` field as a legacy save | Rejected: weakens new-schema validation and permits mixed/partial histories. |
| Rewrite the old generation during Continue | Rejected: loses original evidence and bypasses atomic next-commit publication. |
| Create January rivals for a worldless old save | Rejected by the prior activation decision; the player continues without a world. |

## Evidence and remaining approval gates

The private [v21 Store study](2026-10-18-market-player-store-migration-finding-v1.md) passes 26/0 focused, 7/0 cold and 58/0 whole-pair regression checks. The [f8 Coordinator study](2026-10-18-market-coordinator-finding-v1.md) passes normal generation, interrupted write, explicit recovery and fresh Continue at its exact source. Six [named world source shapes](2026-10-18-market-source-migration-finding-v1.md) pass direct migrated validation and cold restore. These are independent private versions until a combined candidate is tested. Original old executable player-only Store I/O, broader old worldless revisions, earned-sales Founder cases, current canonical integration, Gameplay/exported Continue and active-market numeric policy remain **OPEN**. A passing private adapter is not approval of market balance or a general migration guarantee.
