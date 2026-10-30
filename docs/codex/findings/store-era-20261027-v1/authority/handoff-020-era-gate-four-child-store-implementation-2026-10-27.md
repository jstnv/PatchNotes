# Feature Store Era Gate and Four Child Features Implementation Plan

> **For PN Implementation:** Execute this source-pinned handoff task by task in the authoritative project. Read [Decision 025](decision-025-era-gated-four-child-store-2026-10-27.md) and [Proposal 025](proposal-025-era-gate-and-four-child-features-2026-10-27.md) first. The implementation thread owns code, verification and its own result log. This design thread does not dispatch another chat, commit or push.

**Goal:** Add a durable year-plus-release era gate, then four finite child Features with the approved trial definitions and existing paid Research behavior.

**Architecture:** Keep era qualification and receipt assignment as a pure catalog-adjacent rule, integrate it with atomic release planning and strict Studio checkpoints, and gate Store quotes centrally. After the foundation passes, add the four entries to the finite ledger and static five-lane map. Project supply continues to freeze at Begin Project.

**Tech Stack:** Godot/GDScript, JSON Store ledger, typed Studio checkpoint schema, maintained `verify_*.gd` checks, isolated Godot profiles and the existing release gate.

**Spec:** [Decision 025](decision-025-era-gated-four-child-store-2026-10-27.md) and approved [Proposal 025](proposal-025-era-gate-and-four-child-features-2026-10-27.md).

## Global constraints

- **Source baseline:** `main` at `f3e0f2b5d35270c879327bc297b389748571feb4`; exact file hashes in [source-identity-025.json](source-identity-025.json). Reconcile any drift before editing; preserve concurrent work and `.codex-godot-temp`.
- **Stage order:** era foundation and its migration/locked-condition checks first; four cards second. Do not temporarily expose 1986–88 cards without the release gate.
- **Era rule:** qualifying release is committed, Studio-owned, with frozen positive required Scope and frozen played Scope ≥ required; distinct IDs sorted `(release_cycle, release_id)` assign one non-reused receipt per 1984/1990/2000/2010/2020/2026 era, with pre-year banking. 1984 threshold is cycle 96. Publisher-owned commission/failed/duplicate/ambiguous old evidence does not qualify.
- **Child definitions:** exact IDs, parents, phases, departments, Core, Scope, years and effects are in Decision 025; the first listed Core is primary for each card. 1983 Editor remains first-era; the 1986/1987/1988 children require the 1984 receipt. All four: base 170000 cents, proposed trial play fee 0, one existing Research action, half-base admission, finite, no starter/Contract grant or direct platform tag.
- **Compatibility:** current 42 IDs, all roster versions, historical ownership/paid queue, old project snapshots, Studio-only Continue, sale/Review facts and present AI policy remain intact. No Innovation victory, Genre/Theme, Pass, platform registry or general balance change.
- **Release:** this handoff does not authorize commit, push, deployment, new player EXE or final balance claims. Record actual source, failures and accepted checks in PNI's own log.

## Review focus

1. A historical release with malformed or absent Scope/owner fields must not mint a receipt; test revision-aware known/unknown migration in Task 2.
2. A release accepted by a detached plan but rejected before commit must not publish a receipt; test rollback/stale plan in Task 2.
3. A year-ready Studio without a qualifying release, or a qualified Studio before the year, must see separate locks; test both in Task 3.
4. A paid or queued parent is not owned; test exact parent AND gates and preserved old queues in Task 4.
5. A newly completed card must not enter a project already begun; test project supply and cold Continue in Task 5.

**Exact boundary examples for the focused verifiers:** frozen `scope=29, required_scope=30` is not a receipt; `30/30` is; `31/30` is; any `required_scope=0` is not. Two eligible committed Studio releases ordered by `(cycle, id)` assign the first ID to 1984 and the second to 1990 even if both precede 1984; neither unlocks 1984 cards at cycle 95. At cycle 96, a Studio with no 1984 receipt remains locked. The Editor is year-locked at cycle 71 and may unlock at 72 with both parents and no era receipt; Ability-Gated Exploration is still year-locked at cycle 143 even with a receipt and may unlock at 144. The 1987/1988 boundaries are cycles 168/192. At zero familiarity each card's 170000-cent base yields an 85000-cent admission and one nominal 85000-cent installment; affordability rejection changes no state.

## Files and ownership map

| Responsibility | Expected source |
| --- | --- |
| Pure qualification/ordered receipt validation | Create `patch-notes/scripts/cards/store_era_eligibility.gd` (or one equivalently focused Store rule file) |
| Era metadata validation and parent graph | Modify `patch-notes/scripts/cards/feature_store_catalog.gd` |
| Central quote, Research admission and atomic release integration | Modify `patch-notes/scripts/run_state.gd` |
| Typed save field, exact predecessor conversion and cold restore | Modify `patch-notes/scripts/persistence/checkpoint_schema.gd` and `studio_checkpoint.gd`; coordinate `checkpoint_coordinator.gd` only if needed |
| Four finite definitions | Modify `patch-notes/data/feature_store_ledger.json`; leave `card_ledger.json` and founding rosters unchanged |
| Visible locks, lane membership and child placement | Modify `patch-notes/scripts/ui/feature_store.gd` and `feature_store_map.gd` only where necessary |
| Source-focused verification | Add focused `patch-notes/scripts/debug/verify_store_era.gd` and `verify_store_four_children.gd`; extend maintained Store/checkpoint/UI verifiers as needed |

---

### Task 1: Pure era rule and ledger metadata

**Files:** Create `scripts/cards/store_era_eligibility.gd`; modify `scripts/cards/feature_store_catalog.gd`; test `scripts/debug/verify_store_era.gd`.

**Interface:** `StoreEraEligibility.qualifies(meta: Dictionary, known_studio_owner: bool) -> bool`; `StoreEraEligibility.assign(qualified: Array[Dictionary]) -> Dictionary` returns version 1 plus `year -> release_id` assignments in fixed era order. Catalog entries may specify `min_year` and optional `era_year`; absent fields retain current behavior. Validate known era IDs, year order and parent graph before quoting.

- [ ] Write failing pure checks for positive frozen required Scope, below/equal/above played Scope, publisher exclusion, duplicate IDs, `(release_cycle, release_id)` ordering, one non-reused assignment per era, pre-year banking and malformed catalog era metadata.
- [ ] Run the focused verifier with the documented isolated Godot profile; capture the expected failure before adding the rule.
- [ ] Implement the pure rule and optional catalog metadata without changing existing entries or Research arithmetic.
- [ ] Rerun the focused verifier; require zero errors and unchanged existing catalog validation.

### Task 2: Atomic release receipts and strict save migration

**Files:** Modify `scripts/run_state.gd`, `scripts/persistence/checkpoint_schema.gd`, `studio_checkpoint.gd`; test `verify_store_era.gd` plus a separate-process cold continuation verifier.

**Interface:** `RunState.get_store_era_status(era_year: int) -> Dictionary` returns `year_reached`, `receipt_id`, and `eligible`; persist a versioned `_store_era_receipts` dictionary. `RunState.RELEASE_FIELDS`, Studio snapshot/hydration and typed schema carry that field. New release registration computes receipt assignments on the detached plan and publishes them with the same atomic release commit.

- [ ] Write failing transaction checks for first qualifying Studio release, publisher commission exclusion, duplicate/stale/rejected release, equal/below threshold, early banked receipt and exact no-mutation rollback.
- [ ] Write failing save checks for current and genuine prior payloads, known/unknown frozen Scope and owner semantics, malformed stored assignments and unknown receipt version. Treat a missing historical `owner` as Studio only under a known validated revision; current checkpoint shape alone does not validate the Scope facts.
- [ ] Add receipt state to release planning, checkpoint schema, serialization/hydration and a narrow exact-predecessor conversion; do not reconstruct from raw release count. Validate stored assignments against qualified immutable release IDs and non-reuse.
- [ ] Run focused transaction/checkpoint verifiers and separate-process cold Continue; verify exact release, cash, ownership, paid queue and RNG fields match the control apart from the newly justified receipt field.

**Stage A stop gate:** no Stage B catalog edit until Tasks 1–3 pass and PNI has evidence that receipt state survives actual release publication, failure rollback, old/current cold saves and quote/locked-condition behavior.

### Task 3: Central access quote and visible locked conditions

**Files:** Modify `scripts/run_state.gd`, `scripts/ui/feature_store.gd`; test `verify_store_era.gd` and maintained Store/navigation checks.

**Interface:** `get_feature_store_offer(id)` includes separate `year_reached`, `era_qualified`, `missing_parents` and ordinary price/affordability fields for era-tagged entries. `get_feature_research_quote(id).can_admit` is false unless the era, own year and owned-parent gates hold. Initial optional Primitive buying and old untagged offers are unchanged.

- [ ] Write failing quote/UI checks with synthetic era-tagged definitions for year-before/release-before/both, minimum card year after 1984 receipt, missing parent plus missing receipt, affordability, queued parent and visible future locked prospect.
- [ ] Implement central quote legality, then present each unmet condition in Store details and disabled action copy without conflating ownership, project supply or platform compatibility.
- [ ] Run the focused verifier and existing Store navigation/spending tests at both supported sizes; browsing and rejected admission must leave cash, cycle, queue, release history and RNG unchanged.

### Task 4: Four child entries and five-lane graph

**Files:** Modify `data/feature_store_ledger.json`, `scripts/ui/feature_store.gd` and map layout only as necessary; test `verify_store_four_children.gd` plus maintained catalog/map checks.

**Interface:** Add precisely `player_level_editor`, `ability_gated_exploration`, `switchable_protagonists`, `character_skill_checks` with the exact Decision 025 definitions. For each, `purchase_parent` equals the first element of `purchase_parents`. Add each to exactly one `LANE_MEMBERS` list; the first owned parent is the visible branch anchor, and every additional AND parent remains inspectable. No startup, Contract or platform tag addition.

- [ ] Write failing catalog checks for exact stable IDs, phase/department/Core/Scope/price/year/era, no duplicate or missing parent, no cycle and correct 1983 versus 1986/87/88 access.
- [ ] Add the four definitions, lane membership and child placement. Keep current Feature IDs and old saved ownership/queues valid across the catalog revision.
- [ ] Run catalog, Store/parent, card-frame and map/navigation checks; inspect native captures at both supported sizes for visible child arrows, AND links, focus and nonoverlap.

### Task 5: Integrated paid Research, supply and replay acceptance

**Files:** Extend `verify_store_four_children.gd`, relevant cold/checkpoint and UI verifiers; no additional gameplay file is presumed.

- [ ] Add cases for $850 admission, one current installment with earned familiarity/Resourceful adjustment, insufficient cash/bills rejection, FIFO parent queue versus completed ownership, and each child's first legal year/receipt boundary.
- [ ] Add a legal release→1984 receipt→later card-year→queue→Research→next-project route, retaining a started project's original supply and confirming finite draw/play is possible but not guaranteed.
- [ ] Verify all eight v4 specialty starts, historical roster saves, AI no-bypass behavior, cold Studio Continue and representative exact fresh-process replay. Retain rejected, timed-out and incomplete cases.
- [ ] Run the affected maintained verifiers on source-matched editor and native builds. Then run `python tools/release_gate.py --godot <absolute Godot executable> --output <new unique output directory>` only after focused checks pass; record its actual exit and any human/export limits. Do not label a passing gate final balance or release readiness.

## Source and result handoff

PNI should record the reconciled starting commit and file hashes, every changed canonical file, exact commands/results, failures, migration coverage and remaining human/balance limits in its own dated log. Update shared TODO status from QUEUED to the actual achieved state only after evidence. If the source changes during execution, pin a new baseline and rerun affected checks. No implementation result is claimed by this handoff.
