# Headless Simulation Engine proposal review — 2026-10-10

## Useful additions and alterations

1. **Separate audit from extraction.** The supplied prompt's first deliverable is an architecture assessment. Make the first milestone a source-pinned dependency map and a minimal parity seam proposal; no runtime refactor is implied by approval of the audit.
2. **Define action-level contracts.** Represent a legal command with explicit initial state, ordered decisions, RNG state, result state and ordered events. Invalid, canceled and unaffordable actions must preserve state, RNG, cash, calendar, ownership and checkpoint bytes. Distinguish committed mechanics events from optional presentation cues.
3. **Preserve the actual save boundary.** The current checkpoint is Studio-only. Headless in-memory snapshots may cover active hands for testing, but they must not silently become player Continue support or change checkpoint compatibility.
4. **Choose one authority per calculation.** Reuse or extract production resolution, Review, finance and settlement once; prohibit a second independently maintained simulator formula. Compare event order and intermediate state as well as final Review or cash.
5. **Make RNG ownership explicit.** Audit current run-owned streams and draw consumption. A seed alone is insufficient for parity: capture stream identity/state and ordering at each action boundary. Give competitors independent streams without granting policies a look at future draws.
6. **Scope parity in layers.** Start with a representative Design or Alpha hand, including the new hand-local Balanced Production redistribution and a retrigger case. Then cover phase exit, Beta, release, monthly finance, Store and complete runs. Keep current legal edge cases, such as finite Features and zero-cycle transitions.
7. **Keep policies out of mechanics.** A policy selects from publicly legal actions; the resolver validates and commits. AI shopping/planning details still OPEN in the AI Competitors thread must remain configurable research questions, not default approved rules.
8. **Clarify benchmark units.** Measure a fixed source/hash, seeds, horizon, machine, warmup, repeated samples, peak memory, elapsed time and worst calendar tick. The 10/50/100/500 cohort is a target matrix after functional parity; do not treat an unmeasured CPU budget as approved.
9. **Keep output reproducible.** Version JSON/CSV schema and event vocabulary; record source revision, dirty-file manifest, definitions revision, policy version, seeds/stream states and scenario inputs. Avoid personal paths and volatile timestamps inside deterministic result records.
10. **Bound integration.** No scene, UI, audio, release, checkpoint migration or AI world changes in the first architecture pass. Later integration needs explicit gates and the repository's one-overlapping-gameplay-implementation rule.

## Current-source anchors

`run_state.gd` and `project_state.gd` own mutable run/project data; `gameplay.gd` and `phases/` coordinate scene actions. `cards/`, `finance/`, `persistence/`, Store and Fanbase scripts require dependency inspection before a module split. Existing `scripts/debug/verify_*.gd` run headlessly, but that does not demonstrate a reusable full-run engine. Current Studio-only checkpoint, run-owned RNG, cycle settlement and invalid-action behavior are described in `design/core-and-studio.md` and `design/release-engineering.md`. The 2026-10-10 Balanced Production and playtest changes mean older parity fixtures may be stale. The AI Competitors thread has approved structure and OPEN numerical/policy gates; it should be a consumer of a shared legal resolver, not an authority for new values here.

## Recommended first implementation milestone

Produce a source-pinned audit with an action/dependency graph, proposed state/command/event contracts, module boundaries, parity fixture plan, and one narrow extraction candidate. Do not edit gameplay in this milestone. The next implementation slice should be separately reviewed against that audit.
