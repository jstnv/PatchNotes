# First rival Genre/Core fit audit — 2026-10-26

**Finding: fixed specialty Genre sometimes mismatches produced Core, but changing Genre alone cannot solve low Reviews.** In the eight first legal releases from the four-seed current-source cause census, the finished four-Core vector fit a different base Genre better in seven. The best alternate raises formula-only production rating by 0.05–0.31 in those seven cases; holding actual Scope, Bugs and variance fixed raises Review by only 0.1–0.3. The observed 2.4 Adventure game would be 2.5 as Puzzle under that invalid hindsight substitution. No substitute reaches 5.6. One Adventure release already fits its specialty best. These are diagnostic upper choices over the *observed* Core vectors, not legal alternate projects or a proven prospective AI gain.

## Source and method

- [Predeclared audit plan](2026-10-26-genre-core-fit-audit-plan-v1.md), [read-only script](audit_first_rival_genre_fit_v1.py), and [all eight output rows](sims/first-rival-genre-fit-20261026-v1.json). The input is the [16-release cause-analysis output](sims/low-review-cause-analysis-20261026-v1.json); its gameplay source identity is `a4d9fc318694ef143ea9d59147ae8c5e33a823d31d05a68b35d74203025b51c5`. Original seed starting states differ across seeds; no new run or cross-revision pairing occurred. At audit time, shared `main` HEAD was `087df09d653858b72c6e2dc344352237433dd3ac` with concurrent dirty edits. Current shared source has since added Balanced Production, so the prior review arithmetic is a frozen evidence screen, not a claim about the latest rules.
- The script requires exactly one first title per rival in seeds 4417, 4418, 4423 and 4431; confirms each actual frozen standard equals its base Genre table; recomputes each actual production rating and Review exactly; then substitutes all eight base target vectors into the [production formula](../../../../patch-notes/scripts/review/primitive_review_calculator.gd) without changing the release's observed Core, Scope, Bugs or variance. Input verification passed for all eight. An alternate Genre could change Market standards, future actions, cards selected and market context in a real campaign; this audit holds all of those fixed and cannot claim such a route is reachable.

| Seed | Rival | Actual Genre / Review | Best hindsight Genre / formula-only Review | Production gain |
|---|---|---:|---:|---:|
|4417|Arcade|Action 4.7|Puzzle 5.0|+0.28|
|4417|Wayfinder|Adventure 3.5|Adventure 3.5|0.00|
|4418|Wayfinder|Adventure 2.4|Puzzle 2.5|+0.20|
|4418|Arcade|Action 4.0|Sports 4.2|+0.18|
|4423|Arcade|Action 4.2|Puzzle 4.5|+0.30|
|4423|Wayfinder|Adventure 3.8|Simulation 3.9|+0.10|
|4431|Arcade|Action 4.0|Simulation 4.3|+0.31|
|4431|Wayfinder|Adventure 3.5|Simulation 3.6|+0.05|

The current [trial policy](../../../../patch-notes/scripts/market/rival_trial.gd) captures `get_studio_specialty()` as `genre` in `policies()` and passes it to `begin_development` at Studio. It does not measure owned-feature Core capability or compare prospective Genre standards. The user has therefore correctly identified a policy gap. The table also confirms that weak Core supply, full-Scope viability and Bug reduction remain separate quality constraints. In the 2.4 case, the observed Core was `[20,10,13,17]`; no Genre change can turn that vector into an ordinary 6.x title under the same Scope/Bugs.

## Disposition

Apply the [new qualitative project-Genre rule](2026-10-26-rival-genre-core-selection-decision-v1.md): estimate a legal, funded attainable four-Core vector before Begin, select only a fitting Genre against its prospective frozen Market standards, and defer when none fits. This is a DESIGN rule, not a simulator or canonical implementation. Exact estimator, suitability gate, Store target interaction, legal outcomes, player-market effect, CPU and save/Continue remain OPEN. Next, make a source-matched private variant with current rules and compare fresh legal starts at fixed seeds and calendar horizons; retain failures and publication losses before an adoption handoff.

## Exact command and result

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/audit_first_rival_genre_fit_v1.py --input docs/codex/threads/ai-competitors/sims/low-review-cause-analysis-20261026-v1.json --output docs/codex/threads/ai-competitors/sims/first-rival-genre-fit-20261026-v1.json
```

Exited 0; output reports eight audited rows and seven non-specialty best fits. No headless simulation, replay, old-save test or new gameplay check was run for this arithmetic audit.
