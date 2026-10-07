# Core gameplay and Studio

Authority: cumulative §§1–53,60–63 and current source; refreshed 2026-10-06. [Cross-system decisions](../DECISIONS.md) govern economy/time boundaries.

## Locked rules and implementation

RunState persists across scenes; ProjectState contains the active project's finite supply, production, Bugs and frozen outcomes. Studio creation is atomic; Pre-Development selects title/Genre/Theme. Successful Begin Development costs one run cycle while the project starts at project cycle0. Browsing/editing/cancel/failed starts cost none. Duplicate release names append their actual release year.

Design implements finite Features before Alpha production; Alpha provides production/playtest and finalizes Bugs; Beta plans QA/Marketing/Insider priorities and resolves Search before Debug, Marketing, competitor/market research and host playtest. Review, Awareness, market context, units and revenue freeze at successful launch; registration/history and automatic Studio entry cost zero cycles. Zero/Pass-only work cannot generate a sales-bearing release. Under-required-Scope work may launch with the warning/finite-positive-Feature guard; it does not qualify SideStreet.

Seven candidate instances, four-card hands; finite Feature exhaustion and renewable Passes. Committed hand direct costs/effects and the central cycle consequences preflight atomically. Invalid/failed actions preserve state/RNG. Design/Alpha balanced and primary-Core specializations and Beta QA/Marketing specializations exist. Keep scoring/Review unchanged during this migration.

Shared redraws: cap4, each productive cycle +1, zero-cycle one-card replacement consumes1 and clears replaced selection. Successful development phase entry refreshes to4 once. Current gameplay also refreshes on new/returned Studio entry; historical §37 “no Launch-to-Studio refill” is superseded by the later Studio-entry change recorded in the live queue. Reconstruction/passive navigation must not mint refills. Design/Alpha Core replacement is equal-class50/50 when both legal classes exist, otherwise sole-class fallback; no immediate same definition. Beta/Contract rules remain their own eligibility logic.

Changed committed priorities cost one productive cycle and keep the existing candidate pool. Retained-candidate implementation replaces played slots while preserving unplayed candidates and selection consistency; sorting is visual and must not remap native slots. Card animations/input guards must preserve authoritative transaction ordering.

User presentation ruling, 2026-10-06: Beta uses a single **Sort** action grouping QA, Marketing and Insider, followed by corrective Core Passes. Design/Alpha/Contract keep the Category / descending Scope toggle. A chosen sort remains active for that fan: after a redraw or played hand, retained instances return from below and replacements enter from above before the complete pool animates into its current sort. No chosen sort preserves arrival order. Input remains blocked through the sorting motion. [Implementation and checks](../logs/2026-10-06-campaign-pool-ui-v1.md).

## Current Studio capabilities

Store, owned-pool summary, Pre-Development, release history/detailed Review, per-title monthly reports/campaigns, publisher profiles and cash Contracts. Cash HUD opens Finances and Bank. Tutorial, progressive/contextual tips, hand sorting/animations, priority overlays and spending advice are implemented. Guidance does not create hidden productive actions; no free Wait or offline earnings is approved.

## Rationale and open work

One time/cash owner avoids phase-specific settlements, duplicate payouts and scene reconstruction exploits. Finite positive work prevents empty-release income loops while preserving legitimate under-Scope launches. Retention prevents unplayed opportunities disappearing after every hand.

Local free Alpha-exit repair separates valid zero-cycle transition from affordability of a hypothetical next cycle; productive actions remain finance-checked. The migration-discovered nondeterministic downstream test is resolved with controlled native QA versus Insider-income deals. The free exit preserves the cycle28 / $141.61 debt; QA rejects, while a real $1000 Insider receipt legally pays that debt during a productive action. See the [149-check follow-up](../logs/2026-10-06-campaign-pool-ui-v1.md); the historical [migration audit](../findings/migration-audit-2026-10-06.md) remains unchanged.

Theme-specific content, broader competitor consequences and final tutorial/visual QA are future work. Durable checkpoints and run-owned deterministic RNG are release gaps, not provided by in-memory reconstruction.

Source: ../../../patch-notes/scripts/gameplay.gd, run_state.gd, project_state.gd and phases/; verifiers under scripts/debug. Relevant historical evidence: candidate-pool-repair-v1, organize-pool-v2, card-motion-v2, spending-advice-v1 and alpha-exit-arrears-v1 in local design-logs (ignored by Git).
