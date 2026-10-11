# 2026-10-09 AI Competitors excess-Core shopping-fit follow-up

**Scope:** record the user's choice B on Feature-shopping fit above a permanent specialty Core target. This session is design-only; it authorizes no gameplay, UI, tests, PR merge, `TODO.md` edit, commit or push.

## Checkout and sources

- Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d` at intake and log creation. Existing modified and untracked work was preserved. `docs/codex/TODO.md` was already modified by other work and was not edited here.
- Read current `CURRENT_STATE.md` and `TODO.md`, the repo Codex README, relevant local Genre/thread records and the existing `DECISIONS.md` diff; inspected branch, HEAD and status before editing. Applied the user's direct **B** answer to the [v6 brief](2026-10-09-next-decision-v6.md). The Drive authority log was not reread.

## Changes

- Added the [excess-Core decision](2026-10-09-excess-core-shopping-cap-decision-v1.md): shopping fit stops at the studio's permanent specialty target for each Core, with no direct penalty for excess. Whole-vector relevance and conditional net-fit tradeoff remain required.
- Updated the [thread index](README.md), [working notes](working-notes.md), [resolved v6 brief](2026-10-09-next-decision-v6.md), prior relevance/tradeoff/Feature decisions, [PR reconciliation](2026-10-09-reconciliation-v1.md) and `docs/codex/DECISIONS.md`, preserving unrelated edits.
- Added the [next open brief](2026-10-09-next-decision-v7.md) on equal proportional versus equal raw Core gaps in overall Feature-shopping fit. No choice is recorded there.

## Checks and follow-up

Final checks: all local thread Markdown links resolve; thread Markdown has no trailing whitespace; `git diff --check -- docs/codex/DECISIONS.md` exits 0. No Godot behavior check was needed for documentation-only changes.

Next user choice: how positive gaps combine into overall specialty fit. Exact feasible-vector selection, arithmetic/rounding, tie handling, prerequisite lookahead and CPU bound remain **OPEN**.
