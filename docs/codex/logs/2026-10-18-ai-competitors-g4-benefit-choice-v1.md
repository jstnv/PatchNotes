# AI Competitors G4 benefit-choice design session — 2026-10-18

## Source and edits

Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared worktree dirty before and after. Existing edits and `.codex-godot-temp` preserved. No canonical `patch-notes/` gameplay, player saves, commit or push changed. The separate [G4 quote performance log](2026-10-18-ai-competitors-g4-quote-performance-v1.md) records the earlier v5 study this session builds on.

Created thread-owned plans/configs, private `g4-benefit-choice-20261018-v1` and `v2` simulator versions, isolated run/audit/replay folders, audit/config helpers, [finding](../threads/ai-competitors/2026-10-18-g4-benefit-choice-finding-v1.md) and [design review](../threads/ai-competitors/2026-10-18-g4-benefit-choice-design-review-v1.md). Updated only this thread's README and item 22's TODO paragraph outside the thread. V2 adds a test policy under its private `project/scripts/debug/`; v2 `run_state.gd` and `development_session.gd` hashes match v5 exactly. The v1 factory defect and both v1/v2 frozen outputs remain retained.

## Checks and exact commands

From repository root with `$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'`, `$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'`, `$t='docs/codex/threads/ai-competitors'`:

```powershell
& $py tools/simulate.py run --variant "$t/simulators/g4-benefit-choice-20261018-v1" --config "$t/2026-10-18-g4-benefit-choice-study-v1.json" --output "$t/sims/g4-benefit-choice-20261018-v1" --godot $godot --timeout 240
& $py tools/simulate.py run --variant "$t/simulators/g4-benefit-choice-20261018-v2" --config "$t/2026-10-18-g4-benefit-choice-study-v1.json" --output "$t/sims/g4-benefit-choice-20261018-v2" --godot $godot --timeout 240
& $py "$t/audit_g4_benefit_choice_v2.py" --bundle "$t/sims/g4-benefit-choice-20261018-v2" --output "$t/sims/g4-benefit-choice-audit-corrected-20261018-v2"
& $py tools/simulate.py run --variant "$t/simulators/g4-benefit-choice-20261018-v2" --config "$t/2026-10-18-g4-benefit-cross-genre-study-v1.json" --output "$t/sims/g4-benefit-cross-genre-20261018-v2" --godot $godot --timeout 240
& $py "$t/audit_g4_benefit_cross_genre_v1.py" --bundle "$t/sims/g4-benefit-cross-genre-20261018-v2" --output "$t/sims/g4-benefit-cross-genre-audit-20261018-v2"
& $py tools/simulate.py run --variant "$t/simulators/g4-benefit-choice-20261018-v2" --config "$t/sims/g4-benefit-action-4417-continuation-study-20261018-v2.json" --output "$t/sims/g4-benefit-action-4417-continuation-20261018-v2" --godot $godot --timeout 240
& $py tools/simulate.py replay --bundle "$t/sims/g4-benefit-cross-genre-20261018-v2" --case strategy-4417-benefit --output "$t/sims/g4-benefit-cross-genre-replay-strategy-4417-20261018-v2" --godot $godot --timeout 240
```

The first run **failed as expected evidence**: 12 `invalid_policy` results at command 0 because raw integer/JSON-float Dictionary equality rejected all hand-count configs. A new v2 policy fixed only that guard. V2 first panel **12/12 completed**, 216 accepted commands and 48 selected exact quote/receipt checks; corrected audit PASS. The all-Genre panel **48/48 completed**, 864 accepted commands and 192 selected quote/receipt checks; source/input/initial-state/RNG and finance audit PASS. The twelve repeated Action/Adventure cases had equal final state/command counts. All three Action/4417 Studio-only continuations **PASS**, 18 additional accepted commands each and two releases; each continuation started at its own preceding final state/RNG. Fresh-process first release Action/4417 and Adventure/90210, second release Action/4417 and cross-Genre Strategy/4417 benefit replays **PASS** with 18 steps and telemetry verified each. Exact additional replay commands and folders are in the [finding](../threads/ai-competitors/2026-10-18-g4-benefit-choice-finding-v1.md).

The original first-panel audit mislabeled launch projected units as actual units. A versioned corrected helper and new audit folder fixed the label; the earlier output remains retained and is not used for outcome claims. `git -c core.whitespace=cr-at-eol diff --check -- docs/codex/TODO.md docs/codex/threads/ai-competitors/README.md` PASS; new finding/review/plan relative links missing 0; both v2 inherited gameplay files hash-identical to v5.

## Disposition and blockers

The tested benefit proxy gives 4 higher, 10 equal and 2 lower first Reviews against token-first across 16 matched Genre/seed openings (mean zero); cheapest-affordable loses all 16. [Design review](../threads/ai-competitors/2026-10-18-g4-benefit-choice-design-review-v1.md) rejects both as universal AI. Token-first stays ACTIVE/TRIAL control. **OPEN:** exact production/Bug/Scope benefit and future-liquidity plan, hand counts and legal exits, Store capability planner, quote unavailable reasons and low-cash parity, population CPU, active market values and real player challenge. No adoption packet or canonical implementation was queued.
