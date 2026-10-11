# 2026-10-09 AI Competitors opening revision session v13

**Scope:** documentation-only response to the user's explicit selection of the recommended opening rule and clarification that a 10.0 player first game should be impossible by design. No gameplay, UI, tests, balance parameters or PR branch were changed.

## Source and worktree

- Intake branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. `CURRENT_STATE.md`, `TODO.md`, `DECISIONS.md` and the AI Competitors thread were already dirty; unrelated source, other threads and `.codex-godot-temp` were preserved. No commit or push is claimed.
- Read `CURRENT_STATE.md` and `TODO.md` first, then repo provenance, system design, thread decisions, staged handoff and [G1 findings](../../findings/ai-competitors-gates-v1/README.md). The Drive authority log was not reread. PR #1 remains unmerged on this checkout.
- A read-only source audit independently found no legality defect in the 10.0 witness. It confirmed a first release through native legal hands, ordinary Action targets/scoring and Review cap, valid Family Funding + Graduate creation, no prior release, an under-Scope launch confirmation, $840 final cash and no arrears. It compared the finding's 761-file source snapshot with the current checkout; only an unrelated debug verifier differed. This audit did not rerun gameplay. The two fresh-process route and 2,327 assertions are evidence from the separate implementation task, not new tests in this thread.

## Decisions and documentation

- Added the [superseding opening decision](2026-10-09-opening-rule-revision-decision-v1.md): strong incumbent history/resources and actual legal post-start hands remain; universal strict Review ordering is SUPERSEDED, so an exceptional player first game may match or beat an incumbent. The user separately locked the target that every legal player first release remains below 10.0. The current legal 10.0 route makes that target unmet; mechanism and universal proof remain OPEN.
- Updated [core gameplay design](../../design/core-and-studio.md), [cross-system decisions](../../DECISIONS.md), [current state](../../CURRENT_STATE.md) and [TODO item 22](../../TODO.md). Revised G1a covers legal incumbent history/resources/routes; separate G1b covers a chosen first-game balance mechanism and a source-matched at-most-9.9 bound. G2–G5 retain their OPEN decisions.
- Updated the [thread index](README.md), [current handoff](HANDOFF.md), [working notes](working-notes.md), [staged brief](2026-10-09-implementation-handoff-draft-v1.md) and historical opening/option/TODO records with explicit supersession notes. The alternative opening choices remain logged. Market influence on Reviews remains separate.

## Checks and follow-up

- Local Markdown target scan across the AI thread and edited shared docs: all targets exist after this log was created.
- Trailing-whitespace scan across the same files: no hits. `git diff --check` for the tracked edited docs: no diagnostics. Active handoff/TODO/current-state stale-pending-phrase search: no hits.
- No gameplay tests, simulations, implementation, cross-thread message, commit or push. The separate implementation task must use the updated local handoff; this design thread did not message it.
- Next decisions: choose a source-backed mechanism and proof plan for G1b; choose G1a incumbent assets and G2–G5 values/policies before claiming those slices. The current 10.0 witness must remain a regression case, but removing that one route alone is not a universal proof.
