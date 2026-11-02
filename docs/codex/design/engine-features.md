# Engine Feature implementation — Phase 1

**2026-11-02 proprietary capacity revision — IMPLEMENTED locally.** Current paid proprietary engines use25/30/35 Scope at foundation/complete I/complete II, through the existing Skill Tree. Version3 migration updates only future engine capacity and preserves paid implementation queues, supply/configuration journals and existing project/Contract freezes. Public and rival libraries/terms remain fixed. Feature prices, cards and implementation mechanics are unchanged. [Scope/progression authority](engine-skill-tree.md) · [checks](../logs/2026-11-02-engine-progression-launch-v1.md).

## 2026-11-01 workflow supersession — IMPLEMENTED locally, verification in progress

The user-authorized **Engine Feature Store Migration & Workflow Fixes** brief supersedes Phase 1's separate staging, commit and respec workflow for all new player actions. Studio Management → Engines opens an overview; an owned proprietary engine detail opens its Feature Implementation Tree. Public and licensed engines show frozen libraries on read-only details. The global Studio Feature Store entry and engine selector in the tree are retired. Engine creation is available on the overview and its own creation page, never on an engine detail.

Implementation still uses the original quote, half-price down payment, FIFO queue, familiarity discount and one productive completion cycle. Completion now atomically adds the paid Feature to that engine's `implemented` and normalized future `committed` supply. Active projects and accepted Contracts retain frozen pools. Studio-wide familiarity, Feature definitions, prices, era gates, card values and Skill Tree effects are unchanged. The retired Stage and Commit commands cannot be submitted for new play; the old configuration journal remains available for provenance validation.

`engine_features` version 2 validates automatic supply against the original implementation/payment and configuration receipts. Version 1 checkpoints remain accepted. On hydration, a version 1 record is upgraded only when its effective future supply needs reconciliation: previously staged active Features and paid but uncommitted Features become available without a second charge or cycle. A Feature explicitly removed in a historical configuration remains held unless it was later configured or staged again; this preserves deliberate old respec choices. No unpaid Feature is granted. The old journals, staged field, queue, license and royalty records are retained. A version 1 record with no effective change keeps its old version until the next implementation admission or completion; that action upgrades it to version 2 before settlement. This avoids rewriting unaffected old saves.

The Phase 1 sections below are historical implementation evidence where they describe Stage/Commit UI, committed-only supply or AI configuration policy. The current code and this dated supersession govern the new workflow.

## 2026-11-01 Scope and starting root follow-up — IMPLEMENTED locally

Each new proprietary engine exposes the existing Text, 4-Color Palette and 8-Bit Sound catalog cards as root implementation options during first-game setup. They have no Feature parents, but they still enter that engine's paid FIFO queue and require the usual productive completion cycle. The Skill Tree's four free technology foundations do not implement Feature cards. Descendants keep their catalog prerequisites, printed Scope and Core; public/rival libraries remain read-only.

New projects freeze the selected engine's capacity and Feature supply. Design and Alpha card selection and command preflight add printed Scope across the whole selected hand and reject a hand that exceeds remaining capacity. ProjectState also checks the same capacity at the atomic write. A rejected hand does not change Scope, Core, cash, cycles, draw RNG, Pass Budget or Feature exhaustion. A 20-Scope engine can reach exactly 20; the 30-Scope Review requirement and its completion factor remain unchanged. Generation I/II purchased-node milestones raise future projects to 25/30; active projects keep their frozen cap. [Exact checks and remaining legacy-suite failures](../logs/2026-11-01-proprietary-scope-roots-v1.md).

**2026-10-31: IMPLEMENTED locally; final evidence is recorded in the linked session log.** User brief: Engine System Implementation Phase 1, with confirmed whole-price80% familiarity cap, grandfathered paid queues, and respec charging only removed Features. This record governs Feature implementation/configuration; existing Engine Marketplace terms remain governed by `engine-marketplace.md`. No new marketplace, creation economy, fixed-library proposal or Skill Tree is activated.

## Authoritative data and transactions

The existing54 definitions (including four retained retired rows) remain the only Feature catalog. Base prices, Core/Scope values, prerequisites, era gates, phase rules, finite exhaustion, seven-candidate draws,2/K8, Genre Fit and synergies remain unchanged.

RunState owns `_engine_features` version1, keyed by engine ID. Each record distinguishes kind, frozen initial access, permanent implementations, committed configuration, free staged additions, capacity and configuration revision. Implementation and configuration journals bind engine/Feature IDs, exact finance receipts and productive cycles. The old `_owned_features` and `_feature_research` remain legacy provenance, not selected-engine authority. Studio-wide `_familiarity` and per-project credit evidence remain singular.

- `scripts/engines/engine_feature_state.gd`: pure registry, supply normalization, prices, provenance/binding validation.
- `scripts/engines/engine_feature_actions.gd`: fresh quote comparison and existing atomic cash/calendar transactions.
- `RunState`: scoped getters and mutators; committed-only future supply. Definitions are shared, never copied per engine.
- `CheckpointSchema` / `StudioCheckpoint`: typed records, current-build required registry, immutable receipt/ownership/capacity validation and old-save hydration. Schema construction stays outside the pure model to avoid a circular preload.
- `BeginProject` / `ProjectState`: frozen engine ID, capacity and configured supply. Zero capacity metadata is reserved for grandfathered catalog-engine snapshots with their original cap behavior.
- Campaign commands, finite policies and optimized rival observations use the same transactions. AI explicitly stages then commits; acquisition itself never inserts a new card into a future pool.
- Feature Store keeps the established map/design and adds engine selection, implementation status, free stage/unstage, one-cycle commit and shared-style respec confirmation. Help pages describe the new rules.

## Pricing and familiarity

Accepted Feature plays earn one credit per Feature/project, including after permanent implementation or through fixed engines. Existing parent-credit pricing is retained:10% per parent-project credit, capped80% against the whole new implementation base. Upfront payment is half that discounted total, rounded up to the cent. Completion may use improved familiarity only to reduce unpaid balance; it never refunds or increases a paid deposit. Resourceful keeps its independent existing up-to$100 final-balance saving per release window, with exact claim provenance.

Implementation on A never implements on B. Prerequisites must be implemented in the quoted engine; familiarity is shared across the Studio. Existing paid queues preserve their original half-base admission, at-most50% unpaid-installment familiarity rule, FIFO and automatic future-supply completion terms.

## Configuration and respec

Staging implemented additions costs no cash or time and can be canceled. A batch commit spends exactly one productive cycle and ordinary bills. New implementations remain out of future draws until committed. Existing committed cards remain available until an explicit removal.

A removal/replacement costs10% of the sum of removed Features’ original base implementation values, rounded up once to the cent; familiarity does not discount respec and no implementation is refunded or lost. Additions carry no separate respec fee. Upgrades cannot bypass removal fees by silently replacing an ancestor. Empty configurations are valid and grant no Features. Stale, forged, unaffordable, duplicate and reentrant transactions reject. Legacy queues finish before legacy-engine configuration commits; initial setup retains its original purchase boundary.

Public/licensed records are read only. Debug unlock rebases only the selected proprietary library inside the existing disposable debug session; normal-save publication remains blocked.

## Explicit migration boundary

The user selected preservation of existing access and deferred the proposed27-Scope public/licensed libraries. Old owned Features derive explicit `legacy-access-v1` implementation/configuration snapshots with the same effective future supply, including existing upgrade/retirement normalization. Historical IDs remain retained. Existing licensed instances freeze that previous access; existing creator-owned engines remain proprietary. A new purchase on the already-existing marketplace freezes the buyer’s current configured access under the same compatibility boundary; it does not grant a proposed vendor library or alter$7,500/20%/25-Scope terms.

The immediately preceding versioned Pass Budget source `dabfdcc4484b44727f7cc0f772811346c13655c617ee0564562a110d723ef692` is admitted narrowly with its existing content/rules pair. Existing older migrations and certified-opening raw-byte pins remain intact. Current world records require frozen engine fields; custom engines cannot fall back to zero capacity. Current Studio records cannot omit the registry. Active projects and accepted Contracts keep their frozen pools; player Continue remains Studio-only.

## Phase 2 / OPEN

Proprietary creation economics and player-facing creation; approved globally versioned public/licensed manifests; Skill Tree identities/costs/thresholds/effects; support/technology expansion; Generation II rounding; engine-switching AI strategy and broad balance; export/release and additional hardware/listening acceptance. The private empty proprietary registration seam is a structural fixture, not an active free-creation economy.

See [implementation and exact evidence](../logs/2026-10-31-engine-features-phase1-implementation-v1.md) and the [pre-edit migration plan](../threads/engine-system/2026-10-31-feature-implementation-phase1-plan-v1.md).


## 2026-10-31 Phase2A supersession for new Studios

[Public Action Engine](public-action-engine.md) now governs new-Studio defaults: explicit public access to the approved fixed17-Feature/27-Scope library,$0 upfront,30% external-provider royalty,and no legacy/proprietary engine at creation. Earlier default/library deferrals remain historical for this public subset; existing version1 saves preserve their exact legacy access and frozen terms. Other proposed licensed libraries,creation and Skill Tree work remain outside Phase2A.
