# SideStreet two-hand Relationship Brief shadow pilot v1

2026-10-18 (America/Los_Angeles). **PROPOSED experiment only.** Design authority is [two-hand direction](CONTRACT-LENGTH-DIRECTION-2026-10-18-v1.md) and [Brief proposal v3](SIDESTREET-RELATIONSHIP-BRIEF-PROPOSAL-2026-10-18-v3.md); neither approves the numerical promise, a publisher award, or a new offer. Repository baseline at planning: `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree. The variant creation record and frozen run manifest will pin exact source bytes.

## Hypothesis and scope

An independent, side-effect-free scorer on **completed current SideStreet cash Contracts** will reproduce the six legal v11 projected two-hand grades and set the promise grade to zero after one successful redraw, without altering current cash, Promotion, Contract identity, or the existing challenge. This is a shadow scoring experiment. It does not exercise issuance, acceptance, distinct Brief settlement, Publisher Reputation storage, or user interface.

Candidate score in basis points: `C=floor(10000*(4*min(S,10)+sum(min(H_i,6)))/64)`, where `S` is aggregate Scope and `H_i` are aggregate Core half-units. Candidate promise `G=0` after any successful redraw; otherwise `G=10000` at `S<=10`, `5000` at `S=11`, and `0` at `S>=12`. Shadow result `min(C,G)`. All three components are logged only on the completing hand.

## Cases and measurements

- Fresh legal Sports/1104 Studio, no traits; starter purchases `sprites/general_combat/levels`; same v11 Sports/Fantasy development policy and current Ironclad followed by current SideStreet cash Contract. Each case targets two releases, at most 130 accepted commands and 240 seconds. The exact v11 named two-hand card choices provide Scope5 and Scope8 first-hand routes, each with projected full/half/miss second hands: six cases.
- Seventh arm shares the Scope5/full named choices and initial Studio/RNG, then makes one successful SideStreet redraw of a second-hand card outside the four chosen cards before the completing hand. If that redraw is unavailable or changes the four selected cards, retain the rejected/incomplete case; do not substitute another seed or raise the budget.
- Record initial state/RNG identities, visible selected cards, actual aggregate Scope/Core/redraw count, candidate C/G/combined grades, current Contract payout and bonus, calendar/cycles/cash, every rejection, and exact replay step parity. Compare shadow event with independently calculated values. A single seed and purchased pool cannot establish grade frequency, economic value, or specialty fairness.

## Execution and stopping

Create `simulators/sidestreet-relationship-shadow-v1` with `tools/simulator_variant.py create --id sidestreet-relationship-shadow-v1 --owner contracts`; edit only its `project/` for candidate runtime code. Config and observation policy live in this thread folder. Run once into `sims/sidestreet-relationship-shadow-v1-run-01` through `tools/simulate.py run --variant` with the installed Godot 4.7.1 console executable. Replay at least one full, one half, one miss and the redraw case in fresh processes, preserving all seven run cases and any failures. Stop after the fixed cases/replays, a source/integrity failure, or the 240-second per-process bound. No retries with new budgets/seeds for favorable outcomes; an environmental retry must use a new output and be reported. Do not alter canonical gameplay, shared TODO, other thread files, or player saves.
