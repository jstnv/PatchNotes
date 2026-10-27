# Rival Core supply, Store growth, and Beta timing — bounded finding, 2026-10-27

**Status: DESIGN evidence. No gameplay adoption or balance approval.** This follows the [actual two-rival QA/Bank finding](2026-10-27-rival-world-qa-loan-finding-v1.md). The question was whether the frozen 35-Scope rivals can reach 8.0 by the intended opening date through better existing hand selection, one legal specialty Store purchase, or shorter Bug-safe Beta. The predeclared [Core-hand](2026-10-27-rival-core-hand-study-plan-v1.md), [Store](2026-10-27-rival-store-core-acquisition-plan-v1.md), [second-game Store](2026-10-27-rival-second-game-store-plan-v1.md), [solo-career replacement](2026-10-27-rival-solo-store-career-plan-v1.md), [parent correction](2026-10-27-rival-solo-store-parent-correction-v1.md), [five-hand](2026-10-27-rival-beta-marginal-qa-plan-v1.md), [six-hand](2026-10-27-rival-six-hand-sensitivity-plan-v1.md), and [Search-receipt](2026-10-27-rival-search-receipt-exit-plan-v1.md) plans record hypotheses, starting conditions, seeds, bounds, measurements, and stopping rules before each run.

## Source and execution

- Checkout when frozen: `main` at `087df09d653858b72c6e2dc344352237433dd3ac`, dirty shared worktree. All changes are in thread-owned private variants. Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- G actual-world seven-Beta baseline and L0 solo-career control use project source identity `3c53e42f6cb99cf870011786c5f40424516244bd8acdfc877fd94cc8c1d0b5f0`. I richer-hand proxy `eeb70f7bec1be962c49ddf79854b359149638103862052b85e8fa428784eac8b`; M one-Store-purchase solo career `76407b2d02801d219e08286964b3df1d6cf94c2efee891cdb8141ae1bad86398`; N five-hand `9239697306c37d4a7e33a40281a8ea35dc3cffdcdbdf52136dbfa8c827a6835b`; O six-hand `3cccbafd6c0aab35187e62dfd7cbf722f8f90d84597bba32fc997401f49624ed`. P changes only M's private probe/controller, so its gameplay source identity remains `76407b2d02801d219e08286964b3df1d6cf94c2efee891cdb8141ae1bad86398`; its unique bundle manifest is `cadc007f64c4f98853e2897dc240681bb9efe4e01b90ab8bd65a8d72f60c2232`.
- All successful paired solo runs had the same per-seed cycle-zero cash, owned Features, and RNG. A neutral standalone `CampaignSession` for each trial rival removed the dummy player's insolvent clock; it did **not** simulate shared Market saturation or publication competition. Each session used only accepted actions, ordinary Store/Bank quotes, max 150 decisions and cycle 48, with two releases as the target. Three declared seeds: `4417`, `4423`, `4431`. The frozen cohort is an older private 35-Scope trial roster; the current canonical opening roster has changed. These are mechanism studies, not current new-save forecasts.
- Runner examples, with `$pnPython = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'` and `$pnGodot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'`:

  ```powershell
  & $pnPython tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-search-receipt-exit-20261027-v1 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-solo-P-bundle-20261027-v1 --godot $pnGodot --timeout 240
  & $pnPython docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/rival-solo-P-bundle-20261027-v1 --output docs/codex/threads/ai-competitors/sims/rival-solo-P-4417-20261027-v1 --seed 4417 --godot $pnGodot
  & $pnPython tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/rival-solo-P-bundle-20261027-v1 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/rival-solo-P-replay-20261027-v1 --godot $pnGodot --timeout 240
  ```

  The same probe command ran with seeds `4423`,`4431` into their named P folders and seed `4417` into `rival-solo-P-4417-repeat-20261027-v1`. Every successful bundle has `run-report.json`; each career has `prestart-shadow-run.json` and `prestart-shadow.json`.

## Outcomes

**Existing hand selector:** I's richer `SynergyChoice` flag changed no choice trace, Core, Scope, Bugs, Review or release cycle against G in all three 24-cycle actual-world seeds. G/I first Reviews were 5.7/6.4, 5.9/7.6, and 5.4/7.5. There was no 8.0. [I runs](sims/rival-core-aware-I-bundle-20261027-v1) and [G seed 4431](sims/rival-core-aware-G-4431-20261027-v1) retain the receipts. This proxy alone is not a Core-aware planner.

**Store eligibility and failures:** J tried to buy a Feature before its first project. The founding starter-selection gate rejected all 48 attempts (`Selected specialty Store quote unavailable`), producing zero releases in the completed seed-4417 clock. The originally named `character_development` also has *both* Character Backstories and Save Files as authored parents, not one parent. K0's shared 48-cycle control stopped at cycle 25 because the dummy player had no cash for bills. K1 and further J seeds were **NOT RUN** under those invalid starting conditions. [J failure](sims/rival-store-core-J-4417-20261027-v1), [K0 failure](sims/rival-48-K0-4417-20261027-v1). No player funds were injected to hide either condition.

**Legal post-first Store purchase:** M corrected Wayfinder's target to parent-legal `turn_based_combat`; Arcade bought `animated_sprites`. Both are diagnostic Core-supply examples, not approved shopping choices. L1's earlier Character Development attempt remained incomplete for Wayfinder at cycle 48; Arcade alone reached 8.0 at cycle 38. All M sessions completed two releases with recorded accepted Store payments. Paired second-title results follow; first titles were identical in L0 and M.

| Seed | Studio | L0 no purchase | M one purchase | Effect |
| --- | --- | --- | --- | --- |
| 4417 | Arcade | 7.7 at c35 | **8.0 at c38** | +0.3 Review, +3 cycles |
| 4417 | Wayfinder | 6.7 at c33 | 7.4 at c36 | +0.7, +3 cycles |
| 4423 | Arcade | 6.9 at c37 | 7.2 at c40 | +0.3, +3 cycles |
| 4423 | Wayfinder | 6.7 at c32 | 6.9 at c34 | +0.2, +2 cycles |
| 4431 | Arcade | 6.3 at c33 | 6.5 at c34 | +0.2, +1 cycle |
| 4431 | Wayfinder | 7.3 at c36 | 7.0 at c38 | −0.3, +2 cycles |

M produced one 8.0 among six second titles by c48 and zero by c36. The purchase sometimes worsened the actual four-Core mix, so a fixed specialty purchase is not a safe permanent policy. [L0 controls](sims/rival-solo-L0-4417-20261027-v1), [M seed 4417](sims/rival-solo-M-4417-20261027-v1), [M seed 4423](sims/rival-solo-M-4423-20261027-v1), [M seed 4431](sims/rival-solo-M-4431-20261027-v1). M's 18-command cold replay passed; seed-4417 fresh repeat had identical result SHA-256 `00021bdca782db640fba5a2a9d932d55614ef9e51c6b7760c631b652bb7582ff`.

**Beta timing:** Fixed public Known-Bugs exits after five hands (N) or six (O) moved Arcade's 8.0 seed-4417 second game to c34/c35, but lowered other Reviews and leaked hidden Bugs: N Wayfinder seed-4417 second game was 6.4 with four Bugs; O was 5.9 with six, versus M 7.4 with zero. [N runs](sims/rival-solo-N-4417-20261027-v1), [O runs](sims/rival-solo-O-4417-20261027-v1). Both fixed early-exit rules are rejected as QA policy.

P used an accepted Beta Search receipt (`requested=2`, `actual=0`) as a public certificate of zero hidden Bugs, then exited after five hands only when the same project had Known Bugs zero and legal exit. The current `ProjectState.discover_bugs(requested)` returns `min(requested, hidden_bugs)`, and Beta corrective Core work in this frozen source adds no Bugs. All **eight certified early exits** across twelve games released with zero remaining Bugs. Six other releases followed M's ordinary policy; one uncertified Wayfinder second game still released with one Bug. P's accepted certificates are in each `prestart-shadow.json` `studios[].early_exits` with event IDs. This is proof of the narrow receipt mechanism, not proof that every release can be Bug-free.

| Seed | Studio | M game 1 → P game 1 | M game 2 → P game 2 | P game 2 Bugs |
| --- | --- | --- | --- | --- |
| 4417 | Arcade | 5.9 c16 → 5.9 c14 | **8.0 c38 → 8.0 c34** | 0 |
| 4417 | Wayfinder | 6.4 c15 → 6.4 c13 | 7.4 c36 → 7.1 c34 | 1 |
| 4423 | Arcade | 7.7 c18 → 7.7 c16 | 7.2 c40 → 7.4 c38 | 2 |
| 4423 | Wayfinder | 5.6 c15 → 5.6 c15 | 6.9 c34 → 6.9 c34 | 0 |
| 4431 | Arcade | 6.2 c17 → 6.2 c17 | 6.5 c34 → 6.5 c33 | 0 |
| 4431 | Wayfinder | 7.0 c18 → 7.0 c16 | 7.0 c38 → 7.0 c35 | 0 |

P's [bundle](sims/rival-solo-P-bundle-20261027-v1), [seed 4417](sims/rival-solo-P-4417-20261027-v1), [seed 4423](sims/rival-solo-P-4423-20261027-v1), [seed 4431](sims/rival-solo-P-4431-20261027-v1) and [replay](sims/rival-solo-P-replay-20261027-v1) all passed; 18 replay steps accepted. The [fresh seed-4417 repeat](sims/rival-solo-P-4417-repeat-20261027-v1) had identical result SHA-256 `5cb560fd4fa2b495dcad71106f14f662519ba279bf0f14d40030bf9641af1341`. There were no failed actions in P; its two or three per-seed blocked entries are legal temporary Store affordability waits, retained in the output.

## Design conclusion and next gate

- **LOCKED user direction remains:** full Scope, exhaust legally possible Features before phase progression, QA before Marketing when funded, and legal financing. These experiments do not weaken those rules.
- **OPEN recommendation:** preserve a Search result as per-project AI memory, with event ID, requested/actual and project identity; an accepted positive-request/zero-discovery receipt may permit an earlier legal Beta exit when Known Bugs are zero. A future policy must handle save/Continue, resets after later Bug-creating actions, Bank/Store budgeting, and CPU. The P controller reads only accepted public receipts, but the current `RivalTrial` observation does not expose this memory. It is not ready to queue as canonical gameplay.
- **OPEN quality path:** one legal Store acquisition can produce an 8.0 title, but only 1/6 second titles and 0/6 by c36 under M. P moves that single 8.0 to c34; it does not generate several opening 8s. Stronger legal Core supply/planning and 1977 pre-start histories still need a shared-world study against the current roster, eight-rival CPU, persistence, Market standards and live saturation. Current canonical rival Reviews, January population and player challenge cannot be inferred from this neutral solo screen.
