# Matched Store research versus deferral

This is a bounded **test strategy**, not an approved AI shopper or balance recommendation. The example tests one currently live Feature, `recorded_sounds`, after a legally played first release. Action's starter roster owns its `8_bit_sound` parent. The current catalog base is $1,700; the actual admission and completion quotes remain authoritative. No money, familiarity, ownership, RNG state or scores are injected.

## Prepare and run

Run from the repository root with `GODOT_BIN` set as described in [the run guide](../USAGE.md). Choose a new folder owned by your thread on every run.

```powershell
python tools/simulate.py run --config docs/codex/threads/simulation-engine/examples/store-prefix.json --output docs/codex/threads/my-system/sims/store-prefix --timeout 240
python tools/prepare_store_study.py --bundle docs/codex/threads/my-system/sims/store-prefix --case action-4417 --feature recorded_sounds --target-release-count 2 --max-commands 100 --output docs/codex/threads/my-system/sims/store-4417.json
python tools/simulate.py run --config docs/codex/threads/my-system/sims/store-4417.json --output docs/codex/threads/my-system/sims/store-4417 --timeout 240
```

Repeat the two preparation/run commands for prefix case `action-90210`, changing both output paths. These are two explicit examples, not a broad seed sweep or success-rate estimate. Keep failed cases and the original command bounds. Do not select a replacement seed or Feature after seeing an unfavorable result.

Each pair has exactly identical `initial.checkpoint` data, including all current RNG states, plus equal absolute release targets and command bounds. `research_now` attempts the selected Feature's current admission quote, then its FIFO research quote before creating the next project. It does not bypass denied quotes. `defer` performs genuine development through the stated horizon, with no Store admission or acquisition, artificial wait, free calendar advance or undocumented recovery. Both arms use the same explicit development configuration, while their resulting draws and legal actions may diverge after acquisition changes the pool.

The prefix must have completed at Studio, have at least one release and an empty research queue, and not own the selected Feature. Feature identity is mandatory; the helper never picks an alternative. If the target exists but is locked or unaffordable, the research arm records the rejected command and stops normally. That outcome is evidence, not a helper error to work around. The helper preserves source/runtime checkpoint identities; a changed rules revision requires a newly played prefix.

By default the helper reuses the prefix's explicitly declared finite-fixture policy configuration. To change it deliberately, supply `--development-config path/to/full-config.json` containing all of `genre`, `theme`, `name_prefix`, `selection` and `hands` (positive `design`, `alpha`, `beta` counts). This overrides both arms equally and is recorded in study provenance. Partial overrides, hidden phase-count defaults and arbitrary custom prefix-policy inference are rejected.

## Comparison and regression evidence

Both cases request command-boundary telemetry and carry `study.pair_id`, `study.arm`, checkpoint/prefix hashes, target Feature, policy hash and the explicit horizon. Use the comparison tool described in [the run guide](../USAGE.md) for per-release Review, timing, cash low point, arrears, Fans, common-calendar observations and first blocked actions. Ending cash alone compares different dates when research costs a cycle; inspect common-calendar snapshots and matching release milestones separately.

Case IDs are deterministic `store-<pair hash>-research_now` and `store-<pair hash>-defer`; use the emitted IDs for exact replay. Replaying verifies recorded commands/results/state; it does not approve the strategy or prove visual, audible or human comprehension outcomes. Preserve both successful and rejected prefixes for source-pinned regression. An additional Feature in the owned pool does not guarantee its draw or committed play.
