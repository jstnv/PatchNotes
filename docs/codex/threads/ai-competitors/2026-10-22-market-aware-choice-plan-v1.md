# Market-aware rival choice study — pre-run plan v1 (2026-10-22)

## Question and status

Can the current two-incumbent Primitive hand selector make better legal Design/Alpha decisions by using each rival project's **frozen four Core Review standards** rather than the Genre base standards? This is an OPEN policy candidate. The current G4 selector and market coefficients remain ACTIVE/TRIAL. A passing simulation will not approve balance or adoption.

The current source is a dirty working tree on `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; the actual working bytes, including untracked rival code, must be captured as an immutable private baseline. No existing checkpoint or player save may cross a source revision. Canonical gameplay is outside this study.

## Hypotheses and comparison

- H1: after a legal same-Genre player release lifts a rival's frozen targets, target-aware scoring changes at least one legal rival Design/Alpha four-card choice versus the current base-Genre proxy. Record a no-change outcome rather than altering seeds, rules or sample size to force it.
- H2: any changed choice improves achieved Core relative to that project's frozen target without degrading Review, legal release cadence or solvency. This is a measurement question, not an assumption.
- H0/control: when the frozen standards equal Genre base, the candidate's selection, commands and authoritative player/rival state remain the same as the baseline. Observation shape may differ; compare stable state/RNG fields and exact commands instead of a raw cross-version observation digest.

Create a current-source baseline with `tools/simulator_variant.py create` under this thread, and a forked candidate from that baseline. Change only the candidate `project/` copy: publish the validated frozen four-int profile in the development observation and use it in the existing Design/Alpha proxy for the two trial rivals. **Keep non-rival calls to the selector's assessor on the original Genre-base path:** the legal strong-player study policy invokes that assessor directly, and changing its player decisions would confound this comparison. An explicit rival-only opt-in at the `RivalTrial` call is permitted, making this a three-file private delta. Preserve the feature-first reference, four-card legality, current cost/cash bound, two hands per phase, Beta selector, legal exits, Fantasy first Theme, rivals/cohort, Store, market coefficients and player rules. A missing or malformed profile may not read the current monthly market; preserve the legal reference choice. No canonical edit or policy expansion to later Store pools.

## Predeclared fresh worlds

Use the same legal founding recipe, Studio ID and seed within each arm. Build the world through `RunFactory` and `RivalTrial`, never inject releases, cash, Fans or Review. The player policy is fixed per route and identical in both arms.

| Route | Seed | Player policy | Rival target exposure | Bound |
| --- | --- | --- | --- | --- |
| Action/War | 4417, 4418 | Existing ordinary two-hand six-release policy | Arcade's later projects can receive population raises | 180 commands, six player releases, 48 productive cycles |
| Strong Action | 4417 | Retained legal Family Funding + Graduate route with a 7.8 first release; two player releases | Category-specific benchmark plus population | 180 commands, two player releases, 36 cycles |
| Puzzle/War | 4417 | Existing ordinary two-hand six-release policy | No rival same-Genre lift, negative control | 180 commands, six player releases, 48 cycles |

First run existing behavior on the frozen baseline. Then run the candidate. Use `tools/simulate.py run --variant` for legal independent-Studio smoke and frozen source bundles; its ordinary campaigns do not advance `RivalWorld`. The interleaved comparison must run an external headless `SceneTree` harness against those frozen private `project/` bundles, with `simulate.py` isolated profiles, unique output and test ports. The existing market-exposure harness is source material but points at canonical and cannot be run unchanged.

## Measurements and checks

Record source identities, variant ancestry, project hashes, exact commands, seed/recipe, initial player/world/RNG state, every rival project's frozen targets, offered and chosen hand tokens, phase exits, resolved Core/Scope/Bugs, Review, release cycle, cash/arrears, and player target/sales exposure. Record per-choice wall time, actual Godot process CPU, world advance time, peak memory, save byte size and replay status. Keep instrumentation overhead distinct from policy cost.

Before interpreting outcomes, check matched legal initial state and RNG compatibility; equal seed alone is insufficient. Compare arms from a fresh start; after first divergent rival action treat later results as policy outcomes, not matched intermediate states. Exercise Studio-only Continue on a representative route. Use representative fresh-process exact tape replays for every changed route and the Puzzle control. Retain rejected, incomplete and timed-out cases and their output tags.

Use a 240-second external hard process limit per world record/replay and a 240-second limit per `simulate.py run`. Stop an arm on source drift, mismatched legal start/RNG, parser errors, illegal command/exit, failed checkpoint, replay mismatch or hard timeout. Do not silently enlarge bounds or replace seeds. Stop target-only promotion if exposed Action and strong routes show no changed legal hand, or if any changed route violates legality, cadence or material CPU/save limits. In that case document the result and move to a separate Store/Core plan rather than tuning the market or adding hands in this version.

## Authority and output

The [G4 synergy trial decision](2026-10-18-g4-synergy-trial-decision-v1.md) authorizes only the current limited Primitive policy as ACTIVE/TRIAL. The [market exposure finding](../../findings/market-exposure-20261022-v1/README.md) motivates this OPEN study but is evidence, not approval. Write a dated finding with every attempted command and result. If the candidate warrants review, create a source-pinned handoff with exact delta, evidence, acceptance criteria and remaining OPEN scope; only then re-read and minimally update `docs/codex/TODO.md`. Do not dispatch or adopt canonical gameplay here.
