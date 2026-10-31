# Cycle-0 Market visibility probe — 2026-10-30

**Scope:** Current canonical two-rival new-save behavior only. The eight-rival 1977 prelude remains a held private candidate. This probe changes no gameplay or shared Market rules.

## Hypothesis and comparison

At a legal January 1980 new Studio, the two trial rivals own four frozen historical records, but the live release index and Market Browser projection expose zero rows. The world Market snapshot also has zero active facts. Compare these four views in the same state: `historical_archive`, rival release ledgers, `MarketReleaseIndex.query`, and `MarketBrowserModel.query`. A missing historical row in the archive is a different failure from an intentionally excluded archive row in the browser.

## Cases and bounds

- Two ordinary fresh Studio recipes, seeds `4417` and `5607`, specialty Action, no Traits, no arbitrary grants or altered checkpoint. Both start at player/world cycle 0. No player or rival productive cycle is advanced.
- Use a fresh `ai-competitors` private variant cloned from current canonical source. The only variant change is a diagnostic script. `simulate.py run` takes one legal fixture command per seed solely to freeze source, with release target one and a one-command cap; its expected `INCOMPLETE` result is retained and is not a gameplay pass. Probe the frozen project in a separate isolated Godot process and profile, twice.
- Measure rival count, archive rows and Reviews, live owner releases, active Market facts, index rows, browser rows, source identity, errors and process exits. Require matching exact results across the two fresh processes.
- Time limit: 240 seconds per source-freeze or probe process; stop on source capture drift, script error, malformed world, mismatch between source identities, or unexpected nonempty active facts/rows. Do not alter seeds, bounds, or rules to make the result pass.

The diagnosis will inform a separate historical presentation handoff. It does not approve founder candidate activation or fold frozen records into active sales/saturation.
