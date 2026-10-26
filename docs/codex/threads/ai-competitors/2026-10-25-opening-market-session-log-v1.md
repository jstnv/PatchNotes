# Opening market capability review — session log, 2026-10-25

## Checkout and scope

- `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; the shared checkout was already dirty (182 tracked paths at initial inspection). Existing edits and `.codex-godot-temp` were preserved.
- This session added `2026-10-25-opening-market-capability-review-v1.md`, added an index entry to this thread's `README.md`, and wrote this log. It did not change canonical gameplay, the internal TODO, or trial coefficients. No commit or push.
- The user reported rival first games averaging about 4.7–5.6 and directed a stronger initial cohort. This report was not independently replayed in this session.

## Checks and result

- Read `docs/codex/CURRENT_STATE.md`, `TODO.md`, `README.md`, the relevant AI Competitors and market decisions/findings, and the current `RivalTrial`, `StudioSpecialties`, card ledger, market, Fanbase, checkpoint and Review source.
- `git branch --show-current` → `main`; `git rev-parse HEAD` → hash above; `git status --short` and scoped `git diff --name-only` showed extensive concurrent changes. No unrelated files were edited.
- Read-only reconstruction of current root-first v3 incumbent ownership from `StudioSpecialties.preview`, incumbent extras and card ledger: Arcade Foundry 31 and Wayfinder Works 27 unique printed Scope. The specific legal candidate additions in the review reach 35 each on paper. Actual draw, playable Scope and affordability were **NOT RUN**.
- Read-only Review formula counterfactual: the October 9 legal Action first-game witness, held at its old Core/Scope/Bugs/variance, rounds to 9.1 under the largest current market target lift. Its legality under today's v3 roster was **NOT RUN**; no current first-game ceiling is claimed.
- Link targets in the review and README exist; the two new records have no trailing whitespace. `git diff --check -- docs/codex/threads/ai-competitors/README.md` reports CRLF lines as trailing whitespace across the already-dirty README diff, so that broad check is **FAIL/INCONCLUSIVE** for this addition. No whole-file newline rewrite was attempted.
- Simulator worlds, replay, Continue, CPU and save checks were **NOT RUN**. The review is a design screen and experiment plan, not an adoption packet.

## Follow-up

Resolve whether the desired first-player-game 7.0 limit is absolute for every legal route or a usual outcome. Then author dated incumbent archive Core profiles, cash/Fan provenance, legal 35-Scope pools and the opening benchmark lifetime as **OPEN** trial cases; run the source-matched checks in a new private variant before considering a TODO handoff. Preserve the current market trial and live-release index until an evidence-backed revision is selected.
