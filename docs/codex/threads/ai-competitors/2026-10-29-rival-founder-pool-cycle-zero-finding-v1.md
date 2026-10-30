# Rival founder pool versus cycle-zero 8.0 Reviews — 2026-10-29

**DESIGN finding, not approved gameplay or an implementation handoff.** This executes the [predeclared plan](2026-10-29-rival-founder-pool-cycle-zero-test-plan-v1.md) for one Action rival founded in 1977. No player Review was tested. The candidate uses a larger rival founding pool approximating the historical Action v3 scale and reaches 8.0+ historical Reviews by the player's January 1980 cycle 0 in both declared seeds. The same older-source control also reaches 8.0+, so **the larger founder roster is not shown to cause the high Reviews**. Its first game is worse under the reduced first-project purchase target.

## Source and rule identities

- Shared checkout observed before/after: `main` at `f3e0f2b5d35270c879327bc297b389748571feb4`, dirty with concurrent work. Canonical gameplay, TODO, player saves and `.codex-godot-temp` were not edited in this study.
- Control: retained [`one-action-post-release-market-20261029-v28`](simulators/one-action-post-release-market-20261029-v28/variant.json), frozen prelude source identity `7944a7bbe7dbc324bf423c868707752b3eb9cf36d56eb15db954892ee4707a24`, 12 printed Scope at founding; legal Studio purchases to 36 before first Begin, 36 at January. Its original canonical baseline is `91e4244586bd3bf361a0cbfdb14dedcd4c4e09a14c47f1febabc9b0bba705d7b`.
- Candidate: forked [`rival-founder-v3-action-20261029-v31`](simulators/rival-founder-v3-action-20261029-v31/variant.json), frozen source identity `5aabd70559c406f60bd813dde6c12072ae3ea3c5555bde27b9fdcecbdf8d8af3`. Its **only edited private project files** are `scripts/studio_specialties.gd` (`ROSTER_VERSION` 4→3) and `scripts/debug/one_action_prelude_probe.gd` (first-project purchase target 36→30). It starts Action with 18 owned Features / 27 printed Scope; its legal pre-Begin purchases reach at least 30, and later paid Research targets January 35. The global roster constant is a test shortcut in a rival-only session, **not a rival/player separation implementation**.
- Both arms use the same `full_pool` policy, `midpoint` historical standard, Action/Fantasy, Family Funding + Cult Following, trial $25,000 1977 capital, legal Store/loan/monthly-bill/Design/Alpha/Beta commands, 72-cycle January boundary, 340-command and 240-second limits. Equal seeds identify cases; different roster and decisions mean RNG trajectories and first projects are not paired identical states. No high-Review authoring or score clamp occurs.
- The v28 ancestry predates current v5 Audio retirement. Historical v3 Audio Feature IDs are still future-playable here. Current-source active-equivalent rival rosters, eight-Genre breadth, and live `RivalWorld` integration **remain OPEN**.

## Results from retained release receipts

`cycle: Review (Scope, remaining Bugs)`; all shown releases have required Scope 30 and 0 remaining Bugs.

| Seed | Arm | 1977 founding Scope | Legal purchases / Research / loans | Historical releases by c72 | 8.0+ | January owned Scope / phase |
|---|---|---:|---:|---|---:|---|
| 5607 | control | 12 | 15 / 0 / 0 | c17: 6.9 (36, 0); c37: 9.2 (36, 0); c58: 9.7 (36, 0) | 2 | 36 / Beta |
| 5607 | candidate | 27 | 2 / 8 / 0 | c14: 5.5 (31, 0); c37: 9.2 (35, 0); c55: 9.3 (35, 0) | 2 | 35 / Beta |
| 5613 | control | 12 | 15 / 0 / 0 | c17: 6.8 (36, 0); c35: 8.1 (36, 0); c52: 7.1 (36, 0); c70: 7.9 (36, 0) | 1 | 36 / Design |
| 5613 | candidate | 27 | 2 / 8 / 0 | c14: 5.3 (31, 0); c34: 8.3 (35, 0); c51: 8.3 (35, 0); c67: 7.4 (35, 0) | 2 | 35 / Design |

First candidate release Core vectors (Graphics/Sound/Tech/Design) are **23/18/32/27** in seed 5607 and **21/20/30/21** in seed 5613. A 31-Scope first project can meet the hard release gate yet still score only 5.3–5.5 because its Core values sit below the target standard. The control's earlier 36-Scope first project scores 6.8–6.9. More generous founding ownership reduced initial shopping and moved the first release from c17 to c14, but limiting that first project to ~30 Scope reduced its Review. The candidate's later paid Research to 35 Scope and Core development yield the 8+ titles; these are legal play outcomes under this older rules snapshot, not guaranteed review values.

At the c72 January projection, all 3/4 pre-1980 releases are uniquely frozen historical records in each arm; restored world/checkpoint and RNG checks pass. The projected post-start archive has **zero added Fans and zero old-game earned sales**, with zero old live records/market facts. This verifies the archive boundary for these one-rival cases, not a shared eight-rival market or saturation effect.

## Exact execution and failures

Commands were run from the repository root with bundled Python at `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe` and Godot at `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe` (SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`). The first command created the private candidate; the second froze its source through the documented isolated runner; the third was repeated with the listed bundle/output/seed per case. Each output retains exact `prelude.command.json` argv, import log, result, tape, source manifest and `prelude-run.json`.

```powershell
& $py tools/simulator_variant.py create --id rival-founder-v3-action-20261029-v31 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/one-action-post-release-market-20261029-v28 --output docs/codex/threads/ai-competitors/simulators/rival-founder-v3-action-20261029-v31
& $py tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-founder-v3-action-20261029-v31 --config docs/codex/threads/ai-competitors/sims/one-action-post-release-bundle-20261029-v28b/inputs/experiment.json --output docs/codex/threads/ai-competitors/sims/rival-founder-v3-action-bundle-20261029-v31 --timeout 240 --godot $godot
& $py docs/codex/threads/ai-competitors/run_one_action_january_projection_v1.py --bundle $bundle --output $fresh_output --seed $seed --policy full_pool --standard midpoint --godot $godot
& $py docs/codex/threads/ai-competitors/run_one_action_january_projection_v1.py --bundle docs/codex/threads/ai-competitors/sims/rival-founder-v3-action-bundle-20261029-v31 --output docs/codex/threads/ai-competitors/sims/rival-founder-v3-action-5607-replay-20261029-v31 --seed 5607 --policy full_pool --standard midpoint --replay-tape docs/codex/threads/ai-competitors/sims/rival-founder-v3-action-5607-20261029-v31/prelude.tape.json --godot $godot
```

- Candidate seed 5607: [run](sims/rival-founder-v3-action-5607-20261029-v31/prelude-run.json) / [releases](sims/rival-founder-v3-action-5607-20261029-v31/prelude.json) / [fresh-process replay PASS, 125 steps](sims/rival-founder-v3-action-5607-replay-20261029-v31/prelude-run.json).
- Candidate seed 5613: [run](sims/rival-founder-v3-action-5613-retry2-20261029-v31/prelude-run.json) / [releases](sims/rival-founder-v3-action-5613-retry2-20261029-v31/prelude.json).
- Control seed 5607: [retained run](sims/one-action-5607-prefix-20261029-v28/prelude-run.json) / [retained fresh-process replay PASS](sims/one-action-5607-prefix-replay-20261029-v28/prelude-run.json). Control seed 5613: [run](sims/rival-founder-v4-control-5613-serial-20261029-v31/prelude-run.json).
- Failed attempts retained: [parallel control import crash](sims/rival-founder-v4-control-5613-20261029-v31/prelude-run.json), [parallel candidate import error](sims/rival-founder-v3-action-5613-20261029-v31/prelude-run.json), [candidate serial asset-import allocation failure](sims/rival-founder-v3-action-5613-serial-20261029-v31/prelude-run.json). All failed before a campaign command. Repeating the declared seed sequentially into new outputs succeeded; no seed, policy, horizon or money was changed.

## Recommendation and remaining uncertainty

Keep the user-directed **separate larger rival founder pool** as DESIGN direction. This test shows 8+ pre-start Action games are feasible with legal play, but **does not validate the proposed exact pool or establish that enlarging it raises Reviews**. The initial 5.3–5.5 Reviews miss the desired 6–7 founding band. Next, author active v5 Audio-compatible per-Genre rival rosters, avoid automatically reducing the first project to 30 Scope if 6–7 is important, and run current-source eight-rival 1977→1980 tests with legal Store/cash accounting and the actual January player-cycle market. Keep the player new-save 12-Scope pool separate. Trial capital, standards, eight-roster membership, CPU load and market density remain OPEN. No TODO handoff is ready from this older-source one-Genre screen.
