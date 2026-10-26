# AI Competitors: six-hand phase allocation — 2026-10-23

**COMPLETE bounded private study; alternative phase counts remain DESIGN/OPEN.** The current two-incumbent world, legal production hands, 2/2/2 phase count, synergy selector and active AI market remain ACTIVE/TRIAL. No canonical gameplay was edited or balance approved.

## Question, source and legal comparison

The [pre-run plan](2026-10-23-six-hand-phase-allocation-plan-v1.md) followed the [rejected extra-hand study](2026-10-23-no-research-project-plan-finding-v1.md): could moving one of the existing Beta hands into Alpha or Design improve quality while preserving the six-hand publication calendar? A used current **2/2/2**, B used **2/3/1**, and C used **3/2/1**. All hands, phase exits, cycles, costs, Scope/Bugs and releases used ordinary legal commands. No Store, cash grant, Review injection, Genre/Theme, player-policy or market coefficient change was made. These allocations are OPEN test values, not approved hand math.

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty shared worktree and `.codex-godot-temp` preserved. The [private variant](simulators/six-hand-phase-allocation-20261023-v1/variant.json) has baseline identity `42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847`, creation identity `ba1da24dc44a7d59942ef742584671f7c00487819c02a296523dfc76529724e7` inherited from the prior no-Research candidate, and frozen candidate identity `be458551ef5f29abac8f5ab1c56171ae8c7e3326d69ca289eb9c424de4b5392b`. The only private project delta against the original baseline is `scripts/market/rival_trial.gd`. Gameplay replay identity `42bcc6ce59c0bcc3c239d97af8d20fcf1ad1eab2ad15a494f4f204e7fcc1a3f0`; Godot executable SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`. The isolated runner reported no baseline drift at freeze. [Exact commands](six-hand-phase-study-20261023-v1/COMMANDS.md) and [matched analysis](six-hand-phase-study-20261023-v1/analysis.json) retain source and accounting evidence.

Seeds **4417/4418** each generated a fresh legal Action/Fantasy player and the two current incumbents. All six A/B/C worlds completed **144 player commands, eight player releases, cycle 56**, within 210-command/64-cycle/480-second limits. Within each seed A/B/C had identical complete initial state and typed RNG. Candidate A 4417 reproduced the earlier frozen current-policy world’s initial/RNG, final state and rival releases across source identities. No checkpoint crossed source revisions. The actual distinct hand counts per incumbent over eight rival projects were A **16/16/16**, B **16/24/8**, C **24/16/8** (Design/Alpha/Beta); ordinary Beta exit after one hand was legal. Minimum observed cash stayed positive and final bill lists were empty.

## Fixed-horizon outcomes

| Seed | Arm | Arcade releases / Review-tenths sum / best / remaining-Bugs sum | Wayfinder same | Player earned units and settled cash vs A |
| --- | --- | --- | --- | --- |
| 4417 | A 2/2/2 | 8 / 190 / 37 / 31 | 8 / 217 / 37 / 23 | baseline |
| 4417 | B 2/3/1 | 8 / 255 / 36 / 54 | 8 / 246 / 36 / 46 | unchanged |
| 4417 | C 3/2/1 | 8 / 216 / 35 / 51 | 8 / 241 / 37 / 44 | unchanged |
| 4418 | A 2/2/2 | 8 / 221 / 32 / 39 | 8 / 170 / 28 / 24 | baseline |
| 4418 | B 2/3/1 | 8 / 281 / 43 / 55 | 8 / 219 / 33 / 44 | unchanged |
| 4418 | C 3/2/1 | 8 / 245 / 36 / 50 | 8 / 229 / 38 / 45 | unchanged |

B raised combined published Review tenths by **94/109** in seeds 4417/4418; C raised them by **50/83**. Both retained all 16 rival publications per world and increased remaining Bugs from less QA. Individual best Reviews did not improve uniformly; the highest candidate release was **4.3**, still below the **7.0** strong-Core gate. The player’s eight Review values, earned/paid units, settled cents, final cash and Fans were **exactly identical** across A/B/C in each seed. Same result under this fixed-input Action/Fantasy route does not prove other player routes are insensitive; no broader population or longer campaign was tested.

All six record worlds passed **15,174** assertions each, including stale-command rejection, source fences and monthly market/Fan/finance audits. [B 4417 exact fresh replay](sims/six-hand-phase-4417-B-replay-v1/world-run.json) and [C 4418 exact fresh replay](sims/six-hand-phase-4418-C-replay-v1/world-run.json) passed **144 interleaved steps and 15,258 assertions each**. [B 4418 Studio-only Continue](sims/six-hand-phase-4418-B-restore-v1/world-run.json) passed eight restore assertions. No failed simulator run was discarded. World process CPU ranged roughly **63–164 seconds**; C 4418 took **349.5 wall seconds** inside its 480-second guard. These two-rival timings are not a stable population CPU budget. Graphical/EXE input and human balance were not tested.

## Design disposition

**Do not queue either allocation for implementation as a market-challenge change.** B is the stronger bounded quality candidate, but its extra Bugs, mixed best-Review results, no 7.0 release and identical player market outcomes leave the user’s challenge objective unproven. C offers smaller Review-sum gains with the same QA loss and no player effect. The [dated disposition](2026-10-23-six-hand-phase-allocation-disposition-v1.md) keeps both as OPEN evidence, not a rule.

Next DESIGN topic: introduce legal later-project Genre/Theme variation at the existing hand/calendar budget and test how actual publication mix changes player Genre/Theme saturation across overlapping and disjoint routes. The fixed incumbent output is narrow; this may affect market challenge without paying an extra project month. Exact choice policy and any entrant/population number remain OPEN. Store/Core supply, following-month high-Review news, leaderboard, final market coefficients and population CPU limits remain separate OPEN work. No sealed adoption handoff, canonical edit, commit or push follows from this study.
