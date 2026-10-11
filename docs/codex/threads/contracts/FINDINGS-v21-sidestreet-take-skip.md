# SideStreet take versus skip — current-rule headless finding

2026-10-11 (America/Los_Angeles). **Completed bounded read-only evidence. No rule approval or gameplay adoption.** The question was whether one SideStreet completion before a pending Crown first offer improves early cash and Starwave access enough to offset Contract time and possible later reward changes. [Predeclaration and initial failure](PLAN-v2-sidestreet-take-skip.md); [eligibility repair declared before v3](PLAN-v3-sidestreet-starter-prefix.md).

## Source, setup and stopping rules

- Repository `main` HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, with pre-existing dirty edits. The isolated runner froze the actual gameplay source: mechanics identity `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f`, frozen source identity `2973b7d4c150a7e668c75c1de6e254a6fe8d1bd30036b6c1e095bb806738e994`, external v3 policy identity `0def850c16005540a17d217a6ebe5021341793f15270863d9edbcb84330004a8`. [Run report](sim-v20/pair-v3-run-01/run-report.json), [snapshot hashes](sim-v20/pair-v3-run-01/snapshot-manifest.json), and the bundle's `source.diff.patch` retain the dirty-source pin. Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- Two predeclared Sports/Fantasy seeds, `4417` and `1104`, used current creation cash, no traits, three genuine $450 starter purchases (`sprites`, `general_combat`, `levels`), an Ironclad completion, two actual launches, and only visible legal cards. Game 1 used 3/4/4 Design/Alpha/Beta hands; later games used 5/6/6. No loan, research, hire, campaign, redraw, injected value or artificial wait. A qualifying Studio prefix required two distinct releases, completed Ironclad, pending SideStreet and pending Crown/Neon.
- Prefix limit 180 commands; pair limit 140 commands to Game 3, 240 seconds per run. Reject or retain any malformed, ineligible, incomplete, timed-out or financially blocked case. The paired arms received **identical checkpoint bytes, initial state and RNG**. Take completed SideStreet then Crown; Skip left SideStreet pending and completed Crown. Both used the same Game 3 policy. The branch necessarily changes later Contract draws and calendar.
- This tested **existing canonical rules in frozen isolated runner copies**. No candidate simulator variant or gameplay rule edit was needed.

## Retained attempts and checks

| Attempt | Outcome | Interpretation |
|---|---|---|
| [v1 prefix](sim-v20/prefix-v1-run-01/run-report.json) | Policy import passed; both cases stopped at zero commands because its self-load path did not match the runner's copied policy path. | Retained policy plumbing failure, not a game blocker. |
| [v2 prefix](sim-v20/prefix-v2-run-01/run-report.json) | Both reached two releases and Ironclad but Scope24 against required30, Review below7, Awareness below125; neither had the two needed offers. | Retained ineligible outcomes. The repair changed only the legal route policy, declared before v3. |
| [v3 prefix](sim-v20/prefix-v3-run-01/run-report.json) | Sports/1104 reached Studio at cycle32, 56 commands, two releases, cash $1,682.82, Ironclad complete, and both pending offers. Sports/4417 reached cycle32, 59 commands and two releases, but Game2 Review6.7 and no Crown/Neon offer. | Exactly one eligible checkpoint; the 4417 miss remains in the sample. |
| [v3 pair](sim-v20/pair-v3-run-01/run-report.json) | Take 37 accepted commands, cycle54/Game3; Skip 32 accepted commands, cycle52/Game3. No rejected command, sampled financial block or arrears. | Both completed the declared target. |
| [paired reporter](sim-v20/pair-v3-comparison-01/comparison.md) | Source/checkpoint/RNG identity and both completed arms verified. | Right-minus-left means Take minus Skip. |
| Fresh-process [Take replay](sim-v20/pair-v3-sports-1104-take-replay-01/replay-report.json) and [Skip replay](sim-v20/pair-v3-sports-1104-skip-replay-01/replay-report.json) | Both `ok`; every command accepted, telemetry verified, exact final-state hashes reproduced. | Deterministic trace confirmation, not another independent route. |

The [pair input](sim-v20/pair-v3.json) embeds the same checkpoint in both arms; its source checkpoint SHA-256 is `6df258265c33a820827147f51cf234f20677c5443471635bc4cd6cde936f3b50`. The [comparison JSON](sim-v20/pair-v3-comparison-01/comparison.json) records initial-state `1811386e9b18d0d5bdc09c035411b706c79c5ee7eeb5264907c98f864f1e7fe2`, full initial RNG and observed samples. Studio-only Continue and matching source identity were enforced by the runner. No starting state was equated merely because the seed matched.

## Observed tradeoff

| Measure | Take SideStreet | Skip SideStreet |
|---|---:|---:|
| SideStreet direct receipt | $1,125.00; no advance or Promotion | $0; offer pending |
| Crown total receipt (including $150 advance) | $1,276.36, 7 Promotion | $1,759.09, 10 Promotion |
| Cash at last shared cycle 52 | $8,500.32 | $7,858.05 |
| Game3 launch | Cycle54, Review7.3 | Cycle52, Review7.3 |
| Cash at each separate Game3 launch | $8,042.28 | $7,858.05 |
| Starwave first offer after Game3 | present, pending | absent |
| Overdue peak / sampled cash low after common start | $0 / $1,682.82 | $0 / $1,682.82 |

The same-candidate policy produced a **$482.73 lower Crown receipt and three fewer Crown Promotion points after SideStreet**. SideStreet added $1,125, and Take was $642.27 ahead at the last matched cycle. This is a total route effect, not an isolated payout effect: SideStreet consumes two productive cycles and changes the later Crown hand state/draw sequence. Its completion also made Ironclad + SideStreet + Crown three distinct completed Contracts, so the Starwave offer was present after Game3; Skip had only Ironclad + Crown. Neither arm accepted Starwave. The Game3 Review and Fans (152) matched, but Take launched two cycles later and with Awareness166 versus Skip169. The new game's sales had **not settled** at either endpoint; comparing $8,042.28 to $7,858.05 across different cycles is not a calendar-controlled win.

Both arms remained solvent in the observed window. At separate endpoints, Take had credit621 versus Skip624, zero overdue and no loan. This does not test debt rescue, an actual arrears case, later Store options, post-Game3 sales, or Starwave payout. The comparison includes one eligible route after two predeclared seeds and cannot establish typical value or final balance.

## Recommendation and status

**Recommendation: retain current SideStreet and Crown/Neon/Starwave rules.** Put the strategic take/skip tradeoff in design review, especially whether earlier Starwave access matters enough to justify delayed launch and weaker Crown outcomes across additional legal routes. A next study should predeclare at least one more eligible seed or specialty and continue the exact pair past Game3's first two actual settlements at shared cycles; measure exact sales, rent, credit and later work progress. Do not infer a SideStreet cap, payout, access-gate or Crown Promotion change from this one pair. Existing Ironclad/SideStreet rules remain LOCKED/implemented; Crown/Neon/Starwave numbers remain approved **ACTIVE/TRIAL** with final balance OPEN. [Design-review handoff](HANDOFF-SIDESTREET-v1.md) contains the conditional acceptance boundary.

## Exact commands

PowerShell from repository root (the first two lines name the exact executables):

```powershell
$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $py tools/simulate.py run --godot $godot --config docs/codex/threads/contracts/sim-v20/prefix-v3.json --output docs/codex/threads/contracts/sim-v20/prefix-v3-run-01 --timeout 240
& $py docs/codex/threads/contracts/sim-v20/prepare_pair_v3.py
& $py tools/simulate.py run --godot $godot --config docs/codex/threads/contracts/sim-v20/pair-v3.json --output docs/codex/threads/contracts/sim-v20/pair-v3-run-01 --timeout 240
& $py tools/compare_simulations.py --bundle docs/codex/threads/contracts/sim-v20/pair-v3-run-01 --left sports-1104-skip --right sports-1104-take --output docs/codex/threads/contracts/sim-v20/pair-v3-comparison-01
& $py tools/simulate.py replay --godot $godot --bundle docs/codex/threads/contracts/sim-v20/pair-v3-run-01 --case sports-1104-take --output docs/codex/threads/contracts/sim-v20/pair-v3-sports-1104-take-replay-01 --timeout 240
& $py tools/simulate.py replay --godot $godot --bundle docs/codex/threads/contracts/sim-v20/pair-v3-run-01 --case sports-1104-skip --output docs/codex/threads/contracts/sim-v20/pair-v3-sports-1104-skip-replay-01 --timeout 240
```
