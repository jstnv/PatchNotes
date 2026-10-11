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

User-approved card presentation, 2026-10-09: the attached symmetric kit uses native240×336 cards with one complete frame over background/artwork, then the lifecycle icon and Godot text. Primary/secondary score pairs bind existing data; absent secondary fields are empty while the frame remains symmetrical. Score-type abbreviations GFX/TECH/MKTG, measured two-line names and one-line Departments fit the fixed rectangles; full wording remains in tooltips. Nearest filtering and integer local placement are explicit; scoring, selection and fan motion are unchanged. All51 current cards fit; native/displayed captures and focused checks are recorded in the [integration finding](../findings/symmetric-card-frame-v1/README.md).

User-approved presentation timing, 2026-10-07: played cards bounce left to right at **140 BPM** (60/140 seconds per bounce). A specialization spans **four bounces per full cycle** (12/7 seconds); its four bonus bounces use the same beat as base scoring and exit bounces. Score callbacks occur at bounce peaks. Transitions use whole or half beats. This changes no productive-cycle costs or scoring rules. [Implementation checks](../logs/2026-10-07-card-tempo-v1.md).

Store, owned-pool summary, Pre-Development, release history/detailed Review, per-title monthly reports/campaigns, publisher profiles and cash Contracts. Cash HUD opens Finances and Bank. Tutorial, progressive/contextual tips, hand sorting/animations, priority overlays and spending advice are implemented. Guidance does not create hidden productive actions; no free Wait or offline earnings is approved.

## Rationale and open work

**First-release Review balance, 2026-10-09 — prior universal gate SUPERSEDED:** The user's initial [AI Competitors opening revision](../threads/ai-competitors/2026-10-09-opening-rule-revision-decision-v1.md) requested a below-10.0 bound for every legal player first release. The [current-source Action witness](../findings/ai-competitors-gates-v1/README.md) reaches 10.0. The user's [later scope ruling](../threads/ai-competitors/2026-10-09-first-game-gate-withdrawal-decision-v1.md) removes a formal first-game balance test and rebalance from the AI Competitors handoff: human playtests have not produced a perfect first game, while the constructed legal exception remains documented. Current scoring and the ordinary 10.0 cap remain unchanged. No universal impossibility claim or gameplay edit follows from this practical playtest expectation.

One time/cash owner avoids phase-specific settlements, duplicate payouts and scene reconstruction exploits. Finite positive work prevents empty-release income loops while preserving legitimate under-Scope launches. Retention prevents unplayed opportunities disappearing after every hand.

Local free Alpha-exit repair separates valid zero-cycle transition from affordability of a hypothetical next cycle; productive actions remain finance-checked. The migration-discovered nondeterministic downstream test is resolved with controlled native QA versus Insider-income deals. The free exit preserves the cycle28 / $141.61 debt; QA rejects, while a real $1000 Insider receipt legally pays that debt during a productive action. See the [149-check follow-up](../logs/2026-10-06-campaign-pool-ui-v1.md); the historical [migration audit](../findings/migration-audit-2026-10-06.md) remains unchanged.

Theme-specific content, broader competitor consequences and final tutorial/visual QA are future work. Durable checkpoints and run-owned deterministic RNG are release gaps, not provided by in-memory reconstruction.

Source: ../../../patch-notes/scripts/gameplay.gd, run_state.gd, project_state.gd and phases/; verifiers under scripts/debug. Relevant historical evidence: candidate-pool-repair-v1, organize-pool-v2, card-motion-v2, spending-advice-v1 and alpha-exit-arrears-v1 in local design-logs (ignored by Git).

2026-10-09 readability correction: user-reported pixel-text breakup under fan scaling/rotation is addressed with Godot fallback distance-field text and linear text sampling; pixel frame/art remain nearest-filtered. Inset background/art8px under the complete frame prevents rectangular corner bleed. Exact field bounds and scoring remain unchanged. This supersedes Tiny5 display for cards; bundled kit originals remain preserved. [Verification](../logs/2026-10-09-card-readability-v1.md).

## Presentation revision — 2026-10-10

User requested card taps and removal whooshes, a readable separate selected fan, and removal of the redundant post-synergy victory wave. Implemented: one140/min music subdivision after the popup before bonus cards; four bonus bounces retain4:1 timing, then direct group removal. This supersedes the earlier specialization exit-bounce behavior above. Popup/bonus labels follow corrected soundtrack playback time. Selected cards occupy a larger exposed upper-left fan, remaining pool lower-right; scoring unchanged. [Checks and listening limits](../findings/card-presentation-v2/README.md).

## Playtest correction selection — 2026-10-10

User-approved and implemented: Alpha and Beta Host Playtest choose the two Core categories with the lowest current score divided by that project Genre’s Review standard. Ratios are uncapped. Equal ratios retain Alpha’s higher-priority then fixed Core-order tie break, and Beta’s fixed Core order. Pending selections remain snapshots; costs, cycle use, injection and +2 Pass effects are unchanged. Projects without predevelopment identity use the existing equal33 baseline. [Verification](../logs/2026-10-10-playtest-percentages-v1.md).

## Balanced Production redistribution — 2026-10-10

User-approved replacement, implemented locally in Design/Alpha: evaluate this hand’s unmodified primary plus secondary Core contributions, not accumulated project scores or Genre ratios. Require positive total and each of the four categories within inclusive ±15% of the hand mean. Existing at-least-one-Feature eligibility and Specialization precedence remain. Replace the former ×1.20 reward with division of the original hand total by four; distribute integer remainder in Graphics, Sound, Technology, Design order (21→6/5/5/5). No points created or discarded. Scope, printed Bug Pressure, cash/cycle costs and finite/renewable rules remain unchanged.

Presentation shows printed card gains first, then Balanced popup, then one signed score redistribution one140/minute music subdivision later. No second card bounce wave; gameplay commits once before visual playback. Historical releases are not recalculated. The previous cumulative ±20%/×1.20 rule is SUPERSEDED. [Implementation checks](../logs/2026-10-10-balanced-production-v1.md).
