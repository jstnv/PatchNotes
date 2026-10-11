# 2026-10-09 AI Competitors overall-first legal-mix follow-up

**Scope:** record the user's choice A for representative jointly legal project mixes in Feature-shopping comparisons. This session is design-only; it authorizes no gameplay, UI, tests, PR merge, `TODO.md` edit, commit or push.

## Checkout and sources

- Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d` at intake and log creation. Existing modified and untracked work was preserved. `docs/codex/TODO.md` was already modified by other work and was not edited here.
- Read current `CURRENT_STATE.md` and `TODO.md`, repo Codex README, relevant local Store/thread records and the existing `DECISIONS.md` diff; inspected branch, HEAD and status before editing. Applied the user's direct **A** answer to the [v8 brief](2026-10-09-next-decision-v8.md). The Drive authority log was not reread.

## Changes

- Added the [best-overall legal-mix decision](2026-10-09-best-overall-legal-mix-decision-v1.md): choose a jointly legal one-project mix by smallest combined proportional gap first; use the targeted gap among equal-overall mixes once a target is known. The pre-target baseline tie is explicitly **OPEN** because the target cannot break a tie before it exists.
- Updated the [thread index](README.md), [working notes](working-notes.md), [resolved v8 brief](2026-10-09-next-decision-v8.md), prior ceiling/relevance/tradeoff/fit/Feature decisions, [PR reconciliation](2026-10-09-reconciliation-v1.md) and `docs/codex/DECISIONS.md`, preserving unrelated edits.
- Added the [next open brief](2026-10-09-next-decision-v9.md) on selecting a baseline among equal-overall mixes before the targeted Core is identified. No choice is recorded there.

## Checks and follow-up

Final checks: all local thread Markdown links resolve; thread Markdown has no trailing whitespace; `git diff --check -- docs/codex/DECISIONS.md` exits 0. No Godot behavior check was needed for documentation-only changes.

Next user choice: pre-target baseline tie priority. Exact legal-mix search, arithmetic/rounding, project snapshot, cash/cycle assumptions and CPU bounds remain **OPEN**.
