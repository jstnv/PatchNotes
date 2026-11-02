# Launch Engine Progression Tree and25-Scope base — 2026-11-02

Implemented locally; requested progression and scoped native/headless acceptance PASS. Main at`5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`, existing dirty work preserved. No commit, push or EXE/ZIP rebuild.

## Authority and implementation

`REQUEST.md` is the user's full authorized brief. Current state, TODO, engine/Feature/Skill/UI designs, current source, branch/HEAD/status/diff were inspected first. `intake-source-manifest.json`, `before/`, `runtime-delta.patch`, `PLAN.md` and `REVIEW.md` pin the work. One overlapping canonical gameplay implementation was used; unrelated edits and`.codex-godot-temp` were preserved.

The existing Phase3B mechanics were already connected to accepted Design/Alpha hands. This pass activates their clear normal navigation destination and revises only the paid proprietary Scope base:

| State | Maximum supported Scope |
| --- | --- |
| Foundation |25 |
| All four Generation I nodes purchased |30 |
| All four Generation II nodes purchased |35 |
| Generation III / IV |40 /45 shown, unavailable; no nodes or purchases |

Game requirement remains30. Creation stays$100, zero cycles, empty Feature pool, four free technology foundations, zero royalty. Public27/30% and current rival marketplace economics/immutable libraries remain unchanged.

Studio Management → Engines → selected paid proprietary engine → Skill Tree. Entry appears before long details. The existing vertical folder renderer now occupies its own scrollable page, showing all four foundations/branches, I/II challenges and node states, requirements/prices/effects, current/completed/next automatic Scope milestones and unavailable III/IV. Independent branch successors do not wait for a whole generation. Page entry resets scroll; keyboard focus follows; Back/Escape returns to that engine's detail. Creation controls remain outside individual engine pages. Public/licensed engines have no Skill Tree entry.

Existing thresholds/costs/effects remain ACTIVE/TRIAL and unchanged: I thresholdsG5/S5/T6/D3,$125; II G10/S10/T12/D6,$250. I contributes20% matching printed Feature Core to the Pass Budget numerator; II gives Graphics/Sound10% Pass marginal production and Technology/Design15% category-only Feature bug prevention. Versioned Pass Budget baselines/scoring and card values are unchanged.

## Changed source files

- `patch-notes/scripts/engines/proprietary_engine_state.gd`: version3 and25 base; validate historical1/2 against20-based terms; update future capacity during hydration without rewriting the ledger/progress; bounded historical frozen-cap helper.
- `patch-notes/scripts/engines/engine_feature_state.gd`: permit35 for formally paid proprietary bindings; public/license bounds stay fixed.
- `patch-notes/scripts/persistence/studio_checkpoint.gd`: pass the decoded independent Feature state to the validated migration.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: preserve legal earlier frozen proprietary limits up to current capacity; exact public/licensed equality remains. Append only verified intake source`07ce9e0e59fcd60944fc4a117890c0d9ce4a2f437fa4c3b9375693db5908455d`, captured by`red-launch/fixture.json` before edits. Modern protected fields remain mandatory.
- `patch-notes/scripts/ui/engine_market_browser.gd`: dedicated owned-engine Skill Tree entry/page, reused I/II renderer, milestones/foundations/costs/effects/locked future, visible entry and Back/focus/scroll handling.
- `patch-notes/scripts/debug/verify_engine_skill_tree.gd`, `verify_proprietary_engine_foundation.gd`, `verify_engine_skill_world_continue.gd`: update current25/30/35 oracles; keep an explicit historical20-based version1 migration fixture.

No changes to RunState's purchase/credit logic, hand commands, effects, Pass Budget calculator, card/Feature data, AI policy, finance formulas or marketplace catalogs. Source audit identifies exactly these8 files since intake. Canonical state/TODO/DECISIONS, current engine/Skill/Feature/UI design records and the dated session log are updated separately.

## Save compatibility

Typed historical proprietary versions1/2 validate their old20/25/30 capacity/progress/receipt relationships before migration to version3. Only capacity (+5 per paid engine) and version change. Purchased nodes, partial challenges, milestone IDs, supplies, queues, finance, histories and RNG are retained. Current3 saves load idempotently. Earlier active projects retain frozen20/25/30 limits rather than changing their results. Current fresh projects support25/30/35. Unknown/greater-than-current/non-milestone frozen values reject; this relaxation applies only to the paid proprietary origin. No arbitrary-source bypass or schema-field removal is used.

The genuine exact intake player/world fixture checks complete player equality except the authorized version/capacity delta, and complete rival-world equality except source stamp. A second, explicitly constructed version2-format fixture uses legally earned current nodes/partial progress and real finance receipts, and restores to the exact current state. These are distinct evidence classes; no claim that a synthetic format fixture is an actual published old save.

## Verification receipts

All selected final invocations exit0, zero classified errors, stable full-source fences; exact argv/profile/log/manifests are in each output directory. All run with Godot4.7.1 and private APPDATA/LOCALAPPDATA. The fresh review reports no findings; no tests/files were changed by the reviewer.

| Output | Result |
| --- | --- |
| `final-launch` |26/0: new100-dollar25-Scope engine, version boundary, normal UI destination and all required labels, public restriction, actual preceding Studio/world migration |
| `native-navigation` |15/0: physical Owned/Skill Tree/Back clicks and Escape/focus at1152×648,1280×720,1906×932, using the actual1152×648 canvas. Entry starts within view; captures visually inspected |
| `compatibility` |27/0: exact whole-state migration, seven protected source/schema/RNG/calendar negatives, wrong-version capacities, invalid frozen limits and unavailable III/IV |
| `career-effects` |555/0 player-only real-action scenario: public games fund paid Features, ordinary draws and accepted hands, eight UI purchases,25→30→35, actual I/II effects, independent second engine/partial progress, exact current save and progressed-v2-format migration |
| `recorded-world-canonical` |451/0: reproducible actual eight-rival career to35 and complete current cold player/world equality |
|12 maintained names below | PASS,0 failures |

Maintained names: `verify_engine_skill_tree`, `verify_proprietary_engine_foundation`, `verify_engine_skill_world_continue`, `verify_engine_marketplace_flow`, `verify_public_action_engine`(93 checks), `verify_pass_budget`, `verify_predevelopment`, `verify_engine_feature_workflow`, `verify_engine_scope`, `verify_studio_checkpoint`, `verify_checkpoint_runtime`, `verify_engine_entitlements`. Final reruns of the first three use`final-<name>`; all other names use their own output folder.

### Actual-gameplay completion evidence

The original actual eight-rival run reached35 at cycle92 through normal public-engine funding games, paid implementation of Text/Palette/8-Bit Sound/Keyboard & Mouse/Menu/Score/Timer/Main Theme, ordinary candidate draws and accepted Design/Alpha hands. It counts primary and secondary printed Core, carries challenges across phases/games, buys each eligible node, and reaches Sound II before the other II branches. No injected challenge counters, granted Features, fake payouts or debug cash.

`recorded-world-config.json` pins that run's real fresh Studio checkpoint after its recorded$100 engine creation, with25 capacity, no games and no Skill progress, plus its actual accepted-command/UI-purchase trace. The final verifier restores that ordinary initial state, recreates the canonical eight-rival opening, and replays the175 legal commands through the existing campaign/purchase APIs, stopping at the requested35-Scope Studio boundary. All92 productive cycles advance all8 rivals. Cash and cycle count match every original command; final cash41760 cents, eight node purchases. It captures the full current paired world/player and cold-restores exact actors, node/Scope state, finance/history and RNG. `recorded-world-canonical/final-world-pair.json` retains the result.

This is reproducible recorded-state headless gameplay acceptance, not an optimal strategy, broad balance result, live/native numerical parity claim or proof of every seed. Native acceptance covers actual screen input/navigation; full EXE/device careers remain separate. Annual awards state participates in the world, but ceremony presentation is not exercised by this headless career.

## Retained failures and limits

- `red-launch`: four expected missing25/version/entry/migration failures. `green-launch`: initially lacked35 roadmap text; fixed.
- `red-verify_engine_skill_tree`/`red-verify_proprietary_engine_foundation`: old20/25/30 expected values and the implicit old-capacity fixture failed; updated only scoped current expectations and made old20 explicit.
- Initial career fixture indentation and Alpha-private exhaustion-field assumptions failed; corrected test code uses accepted Feature observations. No gameplay patches inferred from those errors.
- `native-entry-first`: three offscreen-entry failures; click/Back/Escape otherwise passed. Entry moved above long detail text and page scroll reset; final15/0 passes.
- Early directories named`career-world` and`career-world-financed` were actually player-only: the runner intentionally strips inherited PN_* variables. They are not eight-rival evidence. Explicit`world-config.json` and asserted world size/tick counts fixed this test setup; the premature chat claim was corrected.
- Actual eight-rival stochastic stress scenarios in`career-eight-rivals`, `career-eight-rivals-funded` and`career-eight-rivals-complete` include genuine cash depletion/Calendar-cannot-advance failures with the deliberately small11-Scope library. Some reach35 before later optional probes; another runs short earlier. A normal Bank-financing attempt is retained. No founding-capital, rent, loan, review, AI or sales changes were made to make those pass. They remain economic/strategy observations, not balanced-play acceptance. The requested completion path is independently preserved and proven by the recorded legal175-command replay.
- First replay failed because JSON lost integer/enum types in quotes; one subsequent test indentation error is retained. Lossless counter/ID reconstruction fixes the transport; final451/0 exact cash/cycle replay passes without repricing or changing any command outcome.
- Existing20-ObjectDB exit and missing-art warnings are recorded, not represented as leak/artwork acceptance.

The original live checkpoint275 referenced by earlier provenance rotated outside these private tests; its final on-disk checksum cannot be rechecked. No test writes to that save directory. All original fixture bytes and provenance remain. Other active-owned-engine legacy world varieties, Godot4.4, listening/device usability, broad economic balance, full exported careers and performance remain outside this scoped acceptance.

## Reproduction

Use the exact Godot/Python paths and argv in each`result.json`. New outputs only:

`python docs/codex/findings/large-save-20261101-v2/run.py --script res://../docs/codex/findings/engine-progression-launch-20261102-v1/verify_recorded_world.gd --fixture docs/codex/findings/engine-progression-launch-20261102-v1/recorded-world-config.json --output <new-directory> --fence --timeout 240`

Native UI: same runner, `--script res://../docs/codex/findings/engine-progression-launch-20261102-v1/verify_native.gd --native --fence --timeout 120`. Detailed independent effect/multiple-engine case is`verify_career.gd` without a world fixture; explicit world mode is the separate bounded strategy study, not the deterministic completion receipt. See the dated log and final audit for source/whitespace state.
