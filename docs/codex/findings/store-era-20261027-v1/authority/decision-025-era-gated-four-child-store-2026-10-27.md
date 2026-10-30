# Decision 025 — era gate, then four child Features

2026-10-27 America/Los_Angeles. **APPROVED design for PN Implementation; not implemented at this record.** The user first selected “Era gate, then four children (Recommended)” and then answered “Approve design as written (Recommended)” to the approval question for [Proposal 025](proposal-025-era-gate-and-four-child-features-2026-10-27.md). Approval expressly makes its terms an implementation scope, **not final balance**. This decision resolves the OPEN choices in Proposal 025 for this bounded package; its earlier draft labels remain historical.

## Approved sequence and access

1. Build the versioned era receipt, access quote, locked reasons and old-save migration first. Then add the four child cards and Store map positions. Stage A must pass its own checks before Stage B exposes content.
2. A qualifying release is a distinct successfully committed **Studio-owned player** release with positive frozen required Scope and frozen played Scope at or above it. Publisher-owned commissions, failed/cancelled/duplicate releases and present-day owned Scope do not count.
3. Allocate eligible releases in `(release_cycle, release_id)` order, one non-reused release to each successive era slot: 1984, 1990, 2000, 2010, 2020, 2026. Pre-year release banking is allowed, but calendar year remains a separate necessary gate. Only the 1984 receipt governs the four-card package; future slots acquire no cards in this handoff.
4. Preserve current untagged Features, old owned/paid Research, all roster versions and frozen active-project supply. Reconstruct old receipts only from revision-aware validated frozen Scope/ownership facts; unknown evidence creates no entitlement. New qualifying releases may earn a missing receipt. Persist and commit receipt identity atomically with release publication.

Decision 018's year **and** qualifying-release shape remains **LOCKED**. The exact one-release assignment/migration policy above is **APPROVED for this implementation scope**. Future rebalancing or other era content still needs separate approval.

## Approved four children for an ACTIVE/TRIAL first content slice

| ID / Feature | First ordered parent → second AND parent | Lane and minimum access | Printed identity |
| --- | --- | --- | --- |
| `player_level_editor` / Player Level Editor | `save_files` → `levels` | Technology & Tools; 1983 first-era, no later-era receipt | Design; Technology 4 + Design 1; Scope 2; persistent local build/save/reload/test, no sharing |
| `ability_gated_exploration` / Ability-Gated Exploration | `exploration` → `power_ups` | Story & World; 1984 receipt and 1986 | Alpha World Design; Graphics 2 + Design 3; Scope 2; retained ability opens a return route |
| `switchable_protagonists` / Switchable Protagonists | `character_backstories` → `controls` | Story & World; 1984 receipt and 1987 | Alpha Story; Technology 3 + Design 2; Scope 2; distinct controllable characters/routes, no combat-class prerequisite |
| `character_skill_checks` / Character Skill Checks | `character_development` → `exploration` | Story & World; 1984 receipt and 1988 | Alpha Story; Design 4 + Technology 1; Scope 2; developed skill changes a world interaction/route |

All four have **temporary ACTIVE/TRIAL terms once implemented**: $1,700 base, $0 later committed-play fee, existing one-action Research, existing half-base admission and installment/familiarity rules. They are finite Store Features, not starter/Contract grants. Ownership affects only projects begun afterward; draw/play is never guaranteed. No direct platform tag is added in this slice. These values are approved to implement and observe, **not locked final prices or balance**.

## Execution boundary

[Handoff 020](handoff-020-era-gate-four-child-store-implementation-2026-10-27.md) carries source pins, implementation order and acceptance. PN Implementation owns canonical source changes and checks. This thread records the decision and handoff; no gameplay code, simulation, test, commit or push was performed here. The internal TODO may queue this approved scope with a minimal reference. No Innovation victory, Genre/Theme or Pass entitlement, platform registry, unrelated price, or human Store acceptance follows from this decision.
