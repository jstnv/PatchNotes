# Contract search — acceptance and evidence addendum

2026-10-25. **Required acceptance detail for the already queued feature; no new balance or publisher activation.** Read with [CS1–CS8](CONTRACT-SEARCH-HANDOFF-2026-10-25-v1.md). User explicitly requested updating TODO with remaining needs while search is being implemented. Preserve the active implementation's ownership; no cross-chat dispatch or duplicate implementation task.

## CS9 — reachable when no offer exists

Current inspected `patch-notes/scripts/phases/studio_phase.gd` `_open_contracts` returns immediately when `get_pending_contract_choices()` is empty; its button refresh disables Contracts with no active/introductory/pending work. That behavior is valid for the existing offer list but cannot be the only route to a search action. The recent first-release button fix preserves existing eligibility and does not implement Search.

Acceptance under CS7:

- With an unlocked searchable publisher but no pending offers, the player can open the search/catalog view from Studio. No existing offer or new release is required merely to browse.
- After completing/dismissing the last short Contract or Brief, the same route remains usable. Also verify it after Studio-only cold Continue and after returning from a committed release.
- Free browsing stays distinct from action eligibility. If the current search is unaffordable, locked by standing, or blocked by another project/deal, show the reason without charging a cycle or hiding existing owned offers. Do not bypass active-run guards to search.
- At R20 with no released game, short work remains discoverable while commission search explains its remaining release prerequisite. At lower standing, do not imply that a disabled commission button means all publisher work is unavailable.
- Native and current exported checks should cover empty list → successful search → pending offer → acceptance/completion → empty list/search again; keyboard/back navigation and repeated opening cause no duplicate receipts/cycles.
- Integrate with the current shared UI and first-release refresh fix. No broad menu redesign or older private UI overwrite is authorized.

## CS10 — enough evidence to evaluate the new career path

CS1/CS7/CS8 already require source receipts and headless parity. Include the following in the evidence/report, using existing observation/receipt/telemetry facilities where available. This does not require a new player-facing diagnostics panel or a separately expanded logging subsystem.

| Evidence | Why this thread needs it |
|---|---|
| Search availability per publisher/work type and blocker | Distinguish unavailable catalog, standing gate, missing release, pending work and affordability |
| Search receipt ID, template/terms version, pre-search standing, generated offer ID and cycle | Verify one paid discovery and the actual Reputation-gated selection |
| Offer source, pending/active/completed state, commission invitation consumption | Verify repeatability, legacy preservation and cancellation/Begin behavior |
| Search/hand/Begin/release actions, cycle, cash, overdue balance, credited standing | Separate discovery cost from play cost and normal economic processing |
| Saved Studio checkpoint plus exact case/config/source/seed/policy provenance | Reproduce legal starts and fresh-process Continue without player-save access |

Do not weaken the serialization or public-information boundary for convenience. Read saved trusted records when a diagnostic does not belong in gameplay observations. Preserve rejected, incomplete and timed-out runs with precise causes. Unchanged controls and legacy cases must retain their original semantics; update an old release-cadence test only where the explicitly approved prospective acquisition rule changes its expectation.

## After implementation acceptance — research dependency, not another gameplay feature

Once the new source and structural gates are stable, this design thread can compare a Contract-led route, a release-led route using optional searches and a route ignoring new searches. Predeclare legal starts, policies, seeds, command/release/calendar bounds and failures before execution. Measure R20 timing, search count, required releases, cash lows/arrears, full/partial/zero results and commission access separately. Include low-resource entry conditions; the previous wealthy Crown prefixes cannot establish search affordability.

The old six-cycle lower bound for two perfect searched Briefs remains arithmetic, not a pacing guarantee. Do not execute a stale-identity continuation, rewrite an old checkpoint identity, or silently adopt a new reward/redraw policy to obtain better results. Regenerate legal prefixes when new search rules change mechanics compatibility.

This follow-up is **DESIGN work after source acceptance**, not a blocker requiring reward tuning before the search foundation can be accepted. Current structural/UI/export gates remain CS1–CS10. Headless success does not replace human comprehension or broader balance decisions.
