# 2026-10-09 AI Competitors Core-tradeoff follow-up

**Scope:** record the user's choice B on whether a targeted-Core gain may worsen another specialty shortfall. This session is design-only; it authorizes no gameplay, UI, tests, PR merge, `TODO.md` edit, commit or push.

## Checkout and sources

- Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d` at intake and log creation. Existing modified and untracked work was preserved. `docs/codex/TODO.md` was already modified by other work and was not edited here.
- Read current `CURRENT_STATE.md` and `TODO.md`, relevant local Genre/thread records and the existing `DECISIONS.md` diff; inspected branch, HEAD and status before editing. Applied the user's direct **B** answer to the [v5 brief](2026-10-09-next-decision-v5.md). The Drive authority log was not reread.

## Changes

- Added the [Core-tradeoff decision](2026-10-09-net-fit-tradeoff-decision-v1.md): a candidate may worsen another specialty Core shortfall only if completed legal ownership enables a jointly attainable one-project mix that strictly improves both the targeted shortfall and overall four-Core specialty fit. The comparison math stays **OPEN**.
- Updated the [thread index](README.md), [working notes](working-notes.md), [resolved v5 brief](2026-10-09-next-decision-v5.md), prior Feature relevance and news decisions, [PR reconciliation](2026-10-09-reconciliation-v1.md) and `docs/codex/DECISIONS.md`, preserving unrelated edits.
- Added the [next open brief](2026-10-09-next-decision-v6.md) on whether excess Core above the permanent specialty target earns extra Feature-shopping fit credit. No choice is recorded there.

## Checks and follow-up

Final checks: all local thread Markdown links resolve; thread Markdown has no trailing whitespace; `git diff --check -- docs/codex/DECISIONS.md` exits 0. No Godot behavior check was needed for documentation-only changes.

Next user choice: whether excess Core above the permanent specialty target improves rival Feature-shopping fit. Normalization, weights, feasible-vector selection and CPU budget remain **OPEN**.
