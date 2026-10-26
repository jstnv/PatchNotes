# Contract-run challenges: first private revision

2026-10-17 (America/Los_Angeles). The user requested Contract-run challenges for current publishers and selected three boundaries: **a separate bonus** for challenge performance rather than reducing existing completion payout/Promotion, **the bonus awards both cash and Promotion**, and **Ironclad stays introductory**. The five named challenge types are intended scope; publisher assignment, thresholds, bonus cents, bonus Promotion points, exact miss curves and UI copy remain **CANDIDATE/OPEN**, pending review. This is not a final-balance ruling.

Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree. [Private variant](simulators/contracts-challenges-v1/variant.json) baseline/creation identity `9382c90ec435272f4caf577d3c8bcd4b59ab89b0d86086db7f4b776c2c0bd1be`. Change only its `project/`; preserve the original baseline/metadata. No canonical gameplay, TODO, shared authority, other thread file or player save change in this experiment.

## Hypothesis and candidate cases

Implement a reusable, integer-only challenge evaluator with clear progress and a separately reported bonus. Compare the existing current-payout control to candidate challenge outcomes at identical final Scope/four-Core scores and redraw history. Under/over target penalties should be monotonic in distance; violating an optional challenge must never reduce existing acceptance/completion/Promotion rewards or block completion. Accepted redraws only count for the no-redraw condition; rejected/no-op redraws do not. No new RNG draws.

Provisional publisher map for testing, **not approved**:

| Publisher | Candidate challenge |
|---|---|
| Ironclad | None; teaches the two-hand flow. |
| SideStreet | No redraws plus a Scope ceiling. |
| Crown | Balance four final Core categories; a dominant Core loses challenge credit. |
| Neon | Final total Core-to-Scope ratio above a floor. |
| Starwave | Four Core target bands with symmetric under/over penalties. |

This v1 implementation should first prove deterministic scoring and existing-value isolation in the private project. Cash and Promotion bonus amounts and publisher activation require a separate decision and, because completed Contract results are checkpoint-validated, a migration/compatibility plan. Do not present scorer output as earned rewards before that full path is implemented.

## Measurements and limits

- Case vectors: no redraw versus one successful/rejected redraw; all-equal versus one dominant Core; low/high Core ratio at Scope 0 and positive Scope; exact/under/over Core targets; Scope at/above ceiling; malformed maps, huge values and unknown challenge IDs.
- Verify the new scorer under Godot 4.7.1 in an isolated profile, then rerun the five existing Contract focused suites against this private variant. Use a legal fresh `simulate.py run --variant` route and exact replay if candidate code touches current action behavior. Retain rejected/incomplete runs. Stop if current payout/Promotion, state/RNG, checkpoint validation or source ancestry changes unintentionally.
- Experiment limits: no more than one existing legal four-release route, 125 commands, 240 seconds plus exact replay in this revision. Existing Case `action-cult20-4417-crown-no-reuse`, seed 4417, Action/Cult20 Studio. The test route is a regression control, not a valid challenge payout or balance sample.

**Recommendation gate:** only after complete publisher bonus, UI, result and checkpoint behavior has approved values and source-pinned acceptance evidence should a gameplay adoption handoff be queued. This first revision may legitimately end as a scorer prototype with precise remaining dependencies.
