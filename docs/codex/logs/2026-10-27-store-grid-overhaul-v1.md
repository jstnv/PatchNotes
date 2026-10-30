# Feature Store022 — completed approved slice, 2026-10-27

**COMPLETE locally at Handoff022 implementation and focused automated/native acceptance scope.** Handoff023 remains DESIGN review; no new cards, phases, upgrades, Alpha draw gates or candidate values were adopted. No commit, push, public EXE/ZIP, whole-release gate or performance claim.

Shared `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; inherited dirty work and `.codex-godot-temp` preserved. Navigation-slice baseline runtime `a5c5d543474d24a1dc6ee2c901f4446380b1d0e572ddb414fe63e5d173439328`; final runtime **`0c86786e04d95976d42933e18e1b37580bca4dba88d27818d4560376394997f6`**. [Full manifest and exact ledger delta](../findings/store-grid-graph-20261027-v1/source.json). Original022 source/requirements and six screenshots were reconciled against current source, not treated as proof of existing behavior.

## Implementation and bounded rulings

- `ui/feature_store_layout.gd` owns all46 integer cells with one212px pitch and explicit occupied/unknown-cell rejection. The map uses one shared translation, not category-dependent offsets or merge shifts. Technology roots are Menu System, Keyboard & Mouse, Controller; Save Files follows Menu System and Branching Nodes follows Save Files. Visuals follows the specified relative cells. Branching Dialogue and Character Development have distinct neighboring rows.
- Every one of43 named-parent edges, including cross-tree AND arms, has a deterministic precomputed half-cell corridor route. All vertices have10px clearance inside scrollable bounds; segments avoid every card/name rectangle, including endpoints, and category headings. Four neutral connectors also avoid cards/headings. Routing runs during map construction, not Research refresh/drawing; no gameplay RNG is consumed.
- `cards/feature_store_catalog.gd` adds ordered Primitive parent sets without changing Split Screen's ID, effects, phase, Scope, price or Primitive status. Split Screen requires Branching Nodes AND Scrolling. Ledger changes are exactly Save Files→Menu System and Colored Text→Text AND4-Color Palette; every other card/value field is byte-value equivalent after JSON parsing.
- `persistence/studio_checkpoint.gd` recognizes only the exact preceding catalog hash `55c76c86c19363228be5138af752b038961a61655eb2fba4bc9a3a0961803dcf`. Persisted schema/meaning are unchanged: replace only that known content revision, then apply the complete ordinary current validator. Historical purchases are not reinterpreted as new acquisitions. Paid FIFO queues finish despite newly missing parents; no free ancestors or refunds. Existing older adapters remain unchanged.
- `market/rival_world_checkpoint.gd` pairs exact former current-rule sources with that old catalog revision for the player AND every rival before hydration. Unknown sources and mixed content pairs reject. Begun rival projects, frozen supply/hands, finance/history and RNG survive exactly; player Continue remains Studio-only.
- `ui/feature_store_map.gd` retains the verified one-parent direct focus/two-parent chooser behavior and lifecycle cancellation repair. Final viewport refitting accounts for a budget-warning row appearing after selection. Details use available width and a bounded scrolling explanation; Back/Missing remain visible. Wheel, keyboard/controller directions and Page/Home/End scroll explanation without moving the map. This preserves full date/qualifying-release reasons instead of deleting them to fit.
- **Layout reconciliation:** Proposal028 puts both Animated Sprites and Multi-Directional Scrolling directly left of Sprites, which cannot occupy one unique cell. The narrower022 brief requires both to be left. Animated occupies the adjacent left cell; Multi-Directional occupies the next outward cell on that row. No progression/value ruling follows from this presentation choice. Current fixed rosters and incumbent grants remain exact.

## Focused verification

[Evidence folder](../findings/store-grid-graph-20261027-v1/) includes exact commands, exit/error records, probe copies, before-source snapshots, owned diffs and retained failures. Final-source helper receipts explicitly pin runtime identity before/after execution. Prefix for table commands: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe docs/codex/findings/store-grid-graph-20261027-v1/run.py`; each label below points to its `*-run.json` with full script/arguments/private profile configuration.

| Final-source receipt | Observed outcome |
| --- | --- |
| `graph-maintained` / `verify_store_grid_graph.gd` |32 checks, exact AND eligibility/rejection, old paid/owned checkpoints, legal old queue completion, no ancestor grants, corrupt/unknown rejection |
| `grid-source-final` / `verify_store_common_grid.gd` |61 checks, global lattice/unique footprints, exact placement, all43 bounded obstacle-safe paths and heading clearance, no RNG use |
| `old-world-source-final` / `verify_world_restore_file.gd` |8 checks, every persisted old player/rival/active-development/history/RNG field exact; unknown and both older/mixed current content pairs rejected |
| `checkpoint-final` / `verify_studio_checkpoint.gd` |95 assertions, complete checkpoint/future RNG behavior |
| `latency-old-save` / `verify_latency_restore.gd` |83 historical restoration assertions; no timing conclusion |
| `focus-source-final` / `verify_store_focus_lifecycle.gd` |9 lifecycle/frame/cancellation assertions |
| `era-ui-source-final` / `verify_store_era_access.gd` |69 separate year/qualifying-release and admission/UI assertions |
| `links-source-final`, `links-native-final` / `verify_store_prerequisite_links.gd` |57 headless and57 native pointer/Enter/chooser/toggle/Escape/state assertions, three sizes |
| `focused-final-900`, `focused-final-1152`, `focused-final-1280` / `verify_store_grid_views.gd` |22 native assertions each; seven focused targets per size, all passive |
| `radial-native-final` / `verify_feature_store_radial.gd` |225 native assertions; overview, categories, detail/back, all-node footprint/header bounds and passive browsing |
| `detail-native-final` / `verify_store_detail_bounds.gd` |30 native assertions; actual1152/900 long-description bounds, buttons, full lock text, wheel/keyboard scrolling with fixed selection/zoom |
| `gestures-native-final` / `verify_feature_store_navigation.gd` |86 native assertions; actual1152/900 jitter/click, arrows/repeat, pan/clamp, zoom/focus, popup, Tutorial/Pause routing and zero-cost browsing |

All listed checks exit0 with no reported failures or script errors. Final24 overview/focused images retained; representative captures across all five categories, Story's two distinct cards and each supported/stress size inspected. Show-all is intentionally an overview (roughly6–9% in these windows); reading individual cards uses focus/zoom. At short viewports long explanations require scrolling. Some captures include the existing transient Studio-saved toast. Shared route segments can coincide; named prerequisite actions remain available. Visual preference, ease of following dense routes and human/device acceptance remain judgment, not an automated all-clear.

Earlier passing graph-source receipts, before the final UI fit/input repair, separately cover229 current rosters,220 historical rosters,71 parent/familiarity checks,117 Primitive branch checks,119 historical Gameplay branch/migration checks, Research integration/UI, ordinary Store rules and87 transparent-toolbar checks. They are not represented as one fresh final-source full regression gate. The sole late production delta after those checks is the map presentation repair; graph/data/persistence bytes remain unchanged.

## Fresh beginning-of-game smoke and replay

`tools/simulate.py run --config docs/codex/threads/simulation-engine/examples/finite-fixture.json --output docs/codex/findings/store-grid-graph-20261027-v1/fresh --timeout 240 --godot C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe` passes one normal unfunded Action founder, seed4417,36 accepted commands/two releases/cycle14. The frozen project's runtime files match the final manifest exactly. This finite two-hand-per-phase smoke policy is a test fixture, not a rival policy or balance recommendation.

`tools/simulate.py replay --bundle docs/codex/findings/store-grid-graph-20261027-v1/fresh --case action-4417 --output docs/codex/findings/store-grid-graph-20261027-v1/fresh-replay --timeout 240 --godot <same executable>` passes all36 recorded commands in a separate process/profile and the exact final-state digest. It does not establish new live/headless parity or late-save performance. Current/old checkpoint checks above separately exercise Studio restoration and frozen active-rival state.

The new pending/owned predecessor fixture was produced before source changes using three legally queued and completed pre-change purchases from a normal unfunded founder. Provenance hashes are checked by the maintained release-gate binding; the migration test cannot silently skip its fixture. Python syntax/binding and scoped CRLF-aware diff checks pass.

## Retained failures and review

- Initial graph test failed six intended rule/rejection assertions; lattice test failed11 intended geometry/routing assertions. Both are retained before GREEN receipts.
- Old maintained checks expected Save Files to be a root and33 same-tree edges. Updated them to the specified Menu chain and43 actual named-parent edges, retaining real geometry/interaction checks. Invisible category reservation areas are not obstacles; actual cards/names/headings are checked.
- One historical Gameplay run omitted its required prior-save fixture; supplied the pinned fixture and reran119 assertions. A Research fixture now queues Menu System before testing that queued ownership does not unlock Save Files.
- Native900 exposed clipped name footprints when the warning toolbar changed height after the camera target was computed. Keyboard traversal exposed a276px era description escaping its available view. Refitting the settled viewport and bounding the explanation repaired those cases; failures/screenshots remain.
- Some early pointer fixtures dispatched press/release without intervening frames or silently inherited the Settings minimum instead of900px. They now dispatch motion/frames, force/record actual dimensions and dismiss unrelated initial guidance. Failed intermediate receipts are retained; only the final pinned native runs above close acceptance.
- Read-only review found no graph/migration/teardown correctness defect and identified a P2 keyboard accessibility gap in the new explanation scroll. RED8 failures, focus-only4 failures, then explicit key/controller handling and final native30 checks resolve it. Current bounds checks also cover endpoints/arrow margin after review. Review is evidence, not design approval.
- Some fixtures retain the previously observed six ObjectDB instances warning at exit. No warning/leak repair is claimed.

## Remaining

Handoff023 needs its source-pinned design/compatibility table and unresolved phase/value selections before canonical adoption. AI item22 still has no new approved legal-opening adoption packet; do not adopt the$25,000 candidate or other study values. Existing extended late-Research performance, human/device, final balance and release/export gates stay OPEN. Keep the authorized follow-up active while waiting for a new approved AI packet; no unchanged tests need routine rerunning.
