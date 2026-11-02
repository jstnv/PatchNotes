# Engine Feature Implementation Tree layout — 2026-11-01

Implemented locally in the canonical checkout. User selected the floating-controls v2 layout and explicitly required the current Engines workflow, with an **Implementation Queue** and **Implement** action instead of Research.

The selected task was present in the isolated UI worktree's TODO, not the canonical TODO at intake. [Original candidate authority](authority/2026-11-01-feature-store-floating-controls-candidate-v2.md) and [source pin](authority/source-pin.json) are retained. Only its presentation was reconciled onto current Engine implementation; its historical global Store/Research code was not copied wholesale.

## Result

- The graph fills the Store surface. Back/title/library summary and the engine-labelled Implementation Queue float above it; zoom/Show all/Debug/help/legend float at the bottom.
- Individual controls/text retain opaque backgrounds; labels have outlines/shadows. Empty gaps allow map gestures. Opening view is74%; Show all fits the complete graph.
- Back uses the common Studio-relative `(28,24)` position and returns to the same engine detail. The standalone global Store remains retired.
- Queue contents belong to the viewed engine; the Studio-wide FIFO head still governs completion. Another engine at the head disables completion. Empty queues cannot open a meaningless dropdown or select a null Feature. Long engine names wrap in the summary and cannot stretch the queue outside the viewport; the combo tooltip retains full engine identification.
- Current engine quotes, deposits, familiarity, one-cycle completion and automatic future supply remain authoritative. Public/licensed fixed libraries stay read-only. No Stage/Commit UI or second transaction was introduced. Legacy `research_*` internal API/field names remain compatibility plumbing, not player-facing terminology.

No catalog values, topology, dependencies, financial rules, project/Contract pools, RNG or Studio-only Continue change. Concurrent Audio files and GameplayHUD cue were not edited. An engine-aware starter-gate correction appeared in the shared FeatureStore during the work; it is preserved, and tests now follow proprietary-engine gates rather than the legacy global starter gate.

## Verification

- **817/817 headless and817/817 native** focused checks:1152×648,1280×720 and900×600; graph/chrome/long-name bounds; engine filtering/FIFO; pointer-driven exact payment/one-cycle completion/engine-only auto-supply; public read-only; empty queue; zoom/Debug clicks and wheel shielding; actual panning through a chrome gap; complete passive state/finance/RNG preservation. [Headless](pointer-headless-v5/result.json) · [Native](pointer-native/result.json).
- **24/24 actual native Studio/Engines/tree/Back checks** at1152×648 and1280×720, including pointer Back, selected-engine detail/reopen, common position and exact passive state. [Receipt](studio-native/result.json).
- Maintained Engine workflow, Store, Store copy54/0, grid views, radial/Show all, navigation, Studio Management and marketplace checks pass in the [eight resolved receipts](resolved-suite-results.json). [Initial suite](suite-results.json) · [selected final reruns](final-suite-results.json) · [final copy](copy-final/result.json) · [final navigation](navigation-final/result.json) · [final Store](store-final/result.json). These are separate focused runs, not one uninterrupted release gate.
- **11/11 genuine previous-ZIP compatibility/negative checks** pass after adding exactly published runtime `5d27b061021aac5944f855395ab011b9f3de844e4145f17c857bdac88f2f01eb` to the existing strict modern predecessor group. Entire player/world matches except executing-source stamp; missing annual/budget/engine/capacity/source/RNG/calendar still reject. [Receipt](old-zip-green/result.json).
- Native captures were inspected: [actual1152 Studio tree](studio-native/studio-tree-1152.png), [1280 Studio tree](studio-native/studio-tree-1280.png), plus focused three-size captures under `pointer-native/`. Graph/node placement and readable individual floating controls are retained.
- Independent read-only review reports no remaining Critical/Important issue after checking the delta and addressing pointer/long-name/fixture coverage. Native817 passes after that review; critical runtime hashes match the review/headless/native fences.

Retained failures: initial missing-layout36; missing fixture Theme/backing12; actual long-name overflow8 (fixed by clipping the queue combo, not the graph); initial inference error; unbalanced injected wheel events that retained GUI mouse focus (fixture corrected to balanced press/release); radial's obsolete initial-fit-all expectation; and navigation's unconfirmed implementation dialog. That navigation fixture assumed Text was owned in a new empty engine; it now legally queues/completes Text before checking an owned-button no-op. The later Tutorial/Pointer/Escape checks pass without changing routing to conceal failures. One Studio Management attempt crossed a concurrent source edit; its stable rerun passes. Copy's obsolete first-game gate expectation was updated to the current engine-scoped rule and54 checks pass.

## Source and limits

Branch `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`, shared dirty checkout. [Intake hashes](baseline.json), saved `before/` sources and `turn-production.diff` pin reconciliation. Production: `ui/feature_store.gd`, `ui/feature_store_map.gd`, one exact source addition in `market/rival_world_checkpoint.gd`. Maintained fixtures: `debug/verify_feature_store_navigation.gd`, `verify_feature_store_radial.gd`, `verify_feature_store_copy.gd`. Engine transaction/model/browser and Studio navigation sources retain their intake hashes. Existing edits and `.codex-godot-temp` preserved.

No commit, push, EXE/ZIP rebuild or Drive synchronization. The previously delivered ZIP is unchanged. Automated native software-event coverage does not establish human/controller/device, release export, balance or broader UI-suite acceptance. Historical unrelated failures remain at their prior status.
