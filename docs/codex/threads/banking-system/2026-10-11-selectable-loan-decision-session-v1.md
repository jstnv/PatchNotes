# Banking selectable-loan decision session — 2026-10-11

## Source and scope

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The shared worktree was already dirty with unrelated documentation and private simulator outputs. This session preserved those edits and `.codex-godot-temp`; it made no canonical `patch-notes/` gameplay change, commit or push. The user delegated the pre-implementation design judgment, not final numerical balance approval.

The existing private `education-bank-quote-v4` simulator was reused unchanged. Its baseline, parent and candidate hashes, frozen run identities, legal starting checkpoints and experimental limits are in the [three-hand finding](2026-10-11-three-hand-decision-finding-v1.md). The earlier four-hand counterexample remains part of the decision record.

## Changed files owned by this session

- [Three-hand plan](2026-10-11-three-hand-decision-plan-v1.md), [settlement plan](2026-10-11-three-hand-settlement-plan-v1.md), [finding](2026-10-11-three-hand-decision-finding-v1.md), [decision](2026-10-11-selectable-loan-trial-disposition-v1.md), [handoff](HANDOFF-SELECTABLE-LOAN-TRIAL-v1.md), this log and [thread index](README.md).
- `simulations/build_three_hand_decision_v1.py`, `simulations/build_three_hand_settlement_v1.py`, their versioned JSON configs, and unique `three-hand-*` run, comparison, replay and reduction output directories. No other thread's mutable files or player saves were used.
- A scoped ACTIVE/TRIAL paragraph in [economy-banking.md](../../design/economy-banking.md) and one minimal [TODO](../../TODO.md) disposition entry. TODO was re-read immediately before the edit; prior entries were preserved.

## Checks and results

The exact builder and isolated `tools/simulate.py run` commands, representative reporter/replay/reduction commands, Python and Godot paths and hashes are recorded in the [finding](2026-10-11-three-hand-decision-finding-v1.md). The predeclared six-arm run returned exit 1 as expected: two $2,500/12 arms completed a c27 second release; four no-loan/$1,000 arms retained unaffordable-hand rejections. The separately declared one-command c28 continuation returned exit 1 because both accepted paths met the command bound before the three-release target. No timeouts.

Four `tools/compare_simulations.py` reports returned exit 0 with equal fork state/RNG and telemetry checks; each explicitly recorded `both_cases_completed=false`. Four representative `tools/simulate.py replay` commands returned exit 0 with telemetry verified. Two `tools/reduce_simulation.py --kind rejection` commands returned exit 0 and reproduced the exact no-loan and $1,000 blockers in fresh processes. Both c28 one-command tapes replayed with telemetry verified. The $2,500 arms financed a committed Scripted AI resolution and released Game2 at Review 3.8, below the predeclared 4.0 screen. Actual Game2 sales of $1,356.64 settled at c28; remaining Bank principal was $1,249.98, leaving debt-adjusted cash $215.40 no-trait and negative $350.06 Graduate. These are bounded observations, not final balance approval.

Documentation check: `git diff --check` on the scoped tracked documents and a link-existence scan of this session's new Markdown records were run after writing. The shared `git status` was inspected again to confirm the branch/HEAD and no canonical gameplay edit from this session.

## Decision and follow-up

Retain the implemented selectable Bank contract at playable ACTIVE/TRIAL balance scope. There is no new Banking mechanics or UI adoption delta for PN Implementation. Do not infer a fixed $2,500 tier, larger ceiling, extra reserve gate, rate/term/credit pricing change or duplicate warning. The latest-source exported distressed-debt and human quote-understanding acceptance, varied play-style balance, delayed first-game 6.2 pressure and longer Graduate recovery remain OPEN on their own evidence tracks. The private quote-observation variant is not an adoption candidate.
