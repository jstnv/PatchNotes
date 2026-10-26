# SideStreet two-hand Relationship Brief — aggregate feasibility v2

2026-10-18 (America/Los_Angeles). **Read-only screen and legal current-rule witnesses complete. Recommendation PROPOSED, not approved or implemented.** Predeclared [v9 deal observation](SIDESTREET-TWO-HAND-PLAN-2026-10-18-v9.md), [v10 target screen](SIDESTREET-TWO-HAND-PLAN-2026-10-18-v10.md), and [v11 committed witnesses](SIDESTREET-TWO-HAND-PLAN-2026-10-18-v11.md). The user's [two-hand direction](CONTRACT-LENGTH-DIRECTION-2026-10-18-v1.md) supersedes the one-hand Brief specification. Existing two-hand SideStreet cash/Promotion remains the gameplay control.

## Source, route and measurements

- Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree preserved. Isolated runner SHA256 `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193`; Godot 4.7.1 console SHA256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. [V9 run](sims/sidestreet-two-hand-v9-run-01/run-report.json) frozen source `b77115e69e2b056de2fb34eff8d30b97dee53bc4bb2b62d06c53bc41a3929b79`, report SHA256 `9C68B9D07E02EE34AD98E32B2C4FBB5B6388F9C40121784E0DCA02E2834FB6EC`. [V11 successful run](sims/sidestreet-two-hand-v11-run-02/run-report.json) frozen source `f51bbc29564d9b1bcd0dd91d5ced63a9e0cc52a12a051f0bfc9dc662393cdc9e`, report SHA256 `3840A864271871A8577A67154AAA231F79E40E0A7713AC53CC539A21B96D7590`.
- V9 and v11 use the same legal Sports/1104 fresh Studio recipe and `sprites/general_combat/levels` purchases; no traits, Ironclad Feature-first, Sports/Fantasy 3/4/4 first game and 5/6/6 second game. Each case targets two releases, at most 130 accepted commands and 240 seconds. Every successful case completed 61 accepted commands and two releases at cycle34. Paired v9 starts match full initial Studio/RNG; all six v11 starts match full initial Studio/RNG. Each v11 result was replayed in a fresh process for all 61 steps.
- V9→v11 snapshot manifests differ in injected observation policy and audio/Store/UI verifier paths; Contract/card/ledger mechanics are unchanged in that comparison. Do not treat v9/v11 as byte-identical sources. Within each batch, arms share one frozen source. The first action/state divergence between the two v9 route groups is step31, the intended first SideStreet hand. V11 makes exact named first/second-hand choices only from visible candidates, including two separate renewable Sound Pass tokens in one case. No redraws.

## Visible second deals and target screen

The first route played `power_ups,split_screen,text,sound_pass`, Scope5. Its second seven-card deal included `controller`, `menu_system`, `multiple_endings`, `music`, `sound_effects`, `sound_pass` and `technology_pass`. The second route played `controller,split_screen,menu_system,multiple_endings`, Scope8. Its second deal included `power_ups`, `text`, `music`, `sound_effects`, two separate `sound_pass` tokens and `technology_pass`. [V9 screen](SIDESTREET-TWO-HAND-SCREEN-2026-10-18-v9.csv) enumerates 35 possible four-token second choices per route, SHA256 `7DEFB98313EE6203F0FA53120CDAA9F76CD26A749D459CC4A20EB6715C850644`. The initial arithmetic script rejected an invalid assumption that second-hand token IDs are reindexed 0–6; they retain their run indices. The corrected script checks seven **distinct** tokens and validates its computed selected-hand Scope/Core against committed checkpoints. No false case result was produced by that setup error.

The current SideStreet challenge control (no redraw, total Scope<=12 then fade over four Scope) gives a full promise grade on **35/35** second choices after the Scope5 first hand and **34/35** after Scope8. With the current two-hand cash completion target Scope12/each Core6, there are no full combined choices in either observed deal; maximum combined is 9375 basis points. A reputation Brief using those terms would offer little grade distinction in this sample.

The predeclared [v10 screen](SIDESTREET-TWO-HAND-TARGETS-2026-10-18-v10.json), SHA256 `B0B1BFFA675CEF67D1DE78F83CA634610021339F7E6EFE84AE6069C926CB5EBD`, compared aggregate Scope targets 9, 10 and 11, each Core target3, with full/half/miss Scope promise at `<=T`, `T+1`, `>=T+2`:

| Aggregate target T | Scope5 start: full/half/miss promise choices | Scope8 start: full/half/miss promise choices | Full combined choices, Scope5 / Scope8 |
|---:|---:|---:|---:|
| 9 | 16 / 12 / 7 | 3 / 10 / 22 | 9 / 1 |
| **10** | **28 / 5 / 2** | **13 / 12 / 10** | **12 / 6** |
| 11 | 33 / 2 / 0 | 25 / 9 / 1 | 5 / 6 |

These are possible token selections from *one observed second deal per first-hand route*, not equal-probability events or actual Contract results. Scope9 is highly unforgiving after the Scope8 start; Scope11 has no missed choice after Scope5. Scope10 permits all three promise grades and full combined outcomes in both observed routes. The candidate completion normalization is `C=floor(10000*(4*min(total Scope,10)+Σ min(total CoreHalf_i,6))/64)`; candidate no-redraw promise `G=max(0,10000-5000*max(total Scope-10,0))`; projected reputation grade `min(C,G)`. These are **unapproved trial values**.

## Six committed two-hand witnesses

The [v11 run](sims/sidestreet-two-hand-v11-run-02/run-report.json) committed exact current-rule hands that the candidate screen labeled full, half and missed under each first-hand route. All six have `C=10000` under the candidate Core3/Scope10 normalization; the promise alone distinguishes the projected grade. Current game SideStreet still uses its existing Scope12/fade4 challenge and no new reputation outcome was emitted.

| First-hand route | Second-hand choice | Final Scope | Final CoreHalf G/S/T/D | Shadow C/G/combined bp |
|---|---|---:|---|---:|
| Scope5 | controller, menu_system, multiple_endings, sound_pass | 10 | 6/10/30/16 | 10000/10000/10000 |
| Scope5 | controller, menu_system, multiple_endings, sound_effects | 11 | 6/10/32/16 | 10000/5000/5000 |
| Scope5 | controller, menu_system, multiple_endings, music | 12 | 6/20/30/16 | 10000/0/0 |
| Scope8 | power_ups, text, sound_pass, sound_pass | 10 | 6/10/30/16 | 10000/10000/10000 |
| Scope8 | power_ups, text, sound_pass, sound_effects | 11 | 6/10/32/16 | 10000/5000/5000 |
| Scope8 | power_ups, text, sound_pass, music | 12 | 6/20/30/16 | 10000/0/0 |

Each v11 case has zero successful redraws, `status=completed`, 61 accepted commands, two releases at cycle34, and [fresh replay](sims/) `ok=true` with 61 verified steps (folders `sidestreet-two-hand-v11-<case-suffix>-replay-01`). This validates legal card access and the **observed** aggregate Scope/Core. It does not validate proposed payout, new Contract type, reputation ledger, cadence, UI or save migration.

## Commands, retained failure and recommendation

From repository root, the exact run/screen commands used were:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'tools/simulate.py' run --config 'docs/codex/threads/contracts/sidestreet-two-hand-deal-v9.json' --output 'docs/codex/threads/contracts/sims/sidestreet-two-hand-v9-run-01' --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'docs/codex/threads/contracts/sidestreet_two_hand_screen_v9.py'
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'docs/codex/threads/contracts/sidestreet_two_hand_target_screen_v10.py'
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'tools/simulate.py' run --config 'docs/codex/threads/contracts/sidestreet-two-hand-witness-v11.json' --output 'docs/codex/threads/contracts/sims/sidestreet-two-hand-v11-run-02' --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 240
```

An identical first v11 command into [run-01](sims/sidestreet-two-hand-v11-run-01/run-report.json) failed **before source preparation/cases** with `[Errno 28] No space left on device`; the partial folder is retained. After disk free space recovered, the predeclared same-input retry used unique run-02. The six replay commands used `tools/simulate.py replay --bundle docs/codex/threads/contracts/sims/sidestreet-two-hand-v11-run-02 --case sports-1104-<suffix> --output docs/codex/threads/contracts/sims/sidestreet-two-hand-v11-<suffix>-replay-01 --godot <same-console-executable> --timeout 240`, for suffixes `scope5-full-10`, `scope5-half-11`, `scope5-miss-12`, `scope8-full-10`, `scope8-half-11`, `scope8-miss-12`; all six returned exit0 and `ok=true`.

**Recommendation for design review:** carry aggregate Scope10/each Core3 and a no-redraw full/half/miss Scope10/11/12+ promise as the **first private two-hand SideStreet Relationship Brief candidate**. It has legally committed witnesses for all three projected grades from both observed first-hand routes, whereas the current Scope12 promise scarcely distinguishes their second choices. This does **not** approve a reputation award, monetary cap, repeatability, premium three-hand ladder or final balance. Test other specialties, seeds, owned pools, redraw decisions, rent/credit opportunity cost and actual two-hand Brief settlement before a canonical implementation handoff. With only one Sports seed and chosen purchases, fairness and draw frequency remain OPEN.
