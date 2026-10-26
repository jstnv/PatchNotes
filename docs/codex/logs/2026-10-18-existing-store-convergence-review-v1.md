# Existing Feature Store nodes: two-parent review

2026-10-18, America/Los_Angeles. **OPEN recommendations, not approved dependencies.** Direct user request: look at the other Feature Store trees for existing nodes that could require two parents. PN Implementation owns this assessment; the Feature Pools thread's own records are read-only here.

## Source and scope

Inspected `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree; reviewed current state, internal TODO, provenance README, relevant design, catalog/ledger diffs, lane membership, Decision009, Proposal021, Decision019 and the preceding implementation log. Current source already has Difficulty Levels requiring Turn-Based Combat AND Scripted AI. Older Feature Pools records that still say verification pending predate that implementation result.

[Source hashes and computed graph assessment](../findings/store-existing-convergence-20261018-v1/source-and-graph-review.json) pin the actual local inputs, including uncommitted code. Existing edits and `.codex-godot-temp` were preserved. No gameplay, shared TODO, approvals, commit or push changed.

## Selection rule

Both parents should contribute distinct capabilities, occupy separate branches in the same tree, and be neither ancestors nor descendants of each other. Preserve the existing first parent as layout anchor. A pair should explain the child's identity; an attractive connector alone is insufficient. All proposals use existing nodes and retain their printed effects/prices.

| Tree / existing child | Proposed ordered parents (AND) | Recommendation and meaning | Added acquisition burden |
| --- | --- | --- | --- |
| Visuals / **Colored Text** | **Text + 4-Color Palette** | **Strongest fit.** Text content joins color capability. It connects the two current Visual roots without requiring an advanced palette. | 4-Color Palette: $300 / 1 action. |
| Story & World / **Multiple Endings** | **Branching Dialogue + Character Development** | **Strong narrative fit.** Choices and character progression converge into different outcomes. This chooses a character-driven identity for the existing Feature; it is a game-design prerequisite, not a claim that all multiple-ending games need character development. | Character Backstories + Character Development: $2,000 / 2 actions. Save Files and Simple Story are already in the old ancestry and are counted once. |
| Story & World / **Secrets** | **Exploration + Maps** | **Optional.** Exploration joins authored geography to support hidden places. Less universal for nonspatial secrets. Also overlaps the same candidate pair proposed for future Fog of War in Proposal021; review their identities together before adopting both. | Maps: $450 / 1 action; shared Levels counted once. |
| Technology & Tools / **Branching Nodes** | **Save Files + Menu System** | **Optional, best current Tools candidate.** Persistent state joins a choice interface if this Feature represents selectable branching choices. Generic branching logic need not use a menu, so this would narrow its interpretation. | Menu System: $450 / 1 action. Also delays unowned Branching Dialogue and Multiple Endings through ancestry. |
| Audio / **16-Bit Music** | **8-Bit Music + Recorded Sounds** | **Defer.** Plausible only if interpreted as music enhanced by recorded samples; bit depth alone does not explain that requirement. Too much extra branch investment to add solely for topology. | Sound Effects + 8-Bit Sound + Recorded Sounds: $2,450 / 3 actions. |
| Visuals / **Multi-Directional Scrolling** | **Scrolling + Sprites** | **Defer.** Movement plus displayed objects is understandable, but sprite rendering is not intrinsic to scrolling in multiple directions. Colored Text has a clearer reason for convergence. | 4-Color Palette + Sprites: $750 / 2 actions. |

Burden figures compare each proposal independently against the current graph, from no ownership of its newly required ancestors. They sum undiscounted ancestor base prices and assume post-start one-action research. They exclude the child's unchanged price, bills, play fees, sales and project timing. Specialty grants/existing ownership reduce missing purchases; initial optional Primitive purchases may cost zero cycles; earned familiarity changes installments. These are static graph deltas, not simulated affordability or balance findings. Combined choices must deduplicate ancestors again; adding Menu System also affects the Multiple Endings route.

**Recommended first pair of changes for a later approval:** Colored Text and Multiple Endings. Keep Secrets and Branching Nodes as secondary choices. No strong Audio convergence is justified by the current node names alone.

## Existing gates to preserve

- Branching Dialogue already requires Dialogue AND Branching Nodes.
- Character Development already requires Character Backstories AND Save Files.
- Character Classes already requires General Combat AND Save Files.

These cross-tree gates are meaningful existing dependencies. Do not add a third parent or replace Save Files merely to create another same-tree join. Do not make Split Screen require both Keyboard & Mouse and Controller: that would turn alternative input approaches into mandatory purchases. Avoid pairing an existing ancestor with its descendant, such as Sprites and 4-Color Palette for Animated Sprites; current Sprites ownership already gates new acquisition through the palette path.

## Checks, limits and next step

**PASS, read-only static analysis:** parsed all 42 live Features; existing graph is acyclic. Each of the six proposed pairs uses two distinct existing nodes in the child's tree, neither parent is an ancestor of the other, and each individual proposal is acyclic. Applying all six to an in-memory graph also remains acyclic. Computed newly required ancestors and downstream affected nodes with shared ancestors counted once. This diagnostic does not execute the Godot purchase path.

**NOT RUN:** candidate campaign simulations, Godot runtime acceptance, new map geometry/native rendering, migration or human comprehension. No source adoption was requested; existing successful tests are not evidence for these unimplemented proposals.

When exact pairs are selected, implement one bounded dependency revision, retaining current grants/ownership and admitted paid queues. Verify admission, quotes, both parents' familiarity under the shared cap, pre-change Studio/active-world restores and both-size map connectors. Multiple Endings/Secrets are Primitive acquisition overrides, so their generic named-parent representation also needs deliberate coverage. No new balance values or unrelated tree nodes are approved by this review.

Changed files in this pass: this session/assessment note and `docs/codex/findings/store-existing-convergence-20261018-v1/source-and-graph-review.json`. Focused whitespace and saved-source hash checks passed at closeout.
