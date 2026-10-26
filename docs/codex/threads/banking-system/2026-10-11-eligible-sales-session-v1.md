# Eligible-sales Banking session — 2026-10-11

Branch `main`; HEAD at study start/source capture `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The shared worktree was dirty before this session and gained concurrent edits in other threads. No existing changes or `.codex-godot-temp` content were changed by this Banking study; no commit or push.

## Banking-owned files

- Added [predeclared plan](2026-10-11-eligible-sales-study-plan-v1.md), two policies and four run configurations under `simulations/`.
- Created private [variant v2](simulators/education-bank-quote-v2/variant.json); its sole project source delta exposes a read-only existing quote in Studio observations. Kept baseline and ancestry in its manifest.
- Retained canonical and variant first-release/Studio runs, eight loan/control arms, four comparison reports, twelve replays, verifier logs, [audit script](simulations/analyze_eligible_sales_v1.py) and [summary](simulations/eligible-sales-summary-v1.json).
- Added [finding](2026-10-11-eligible-sales-finding-v1.md) and [design handoff](HANDOFF-ELIGIBLE-SALES-v1.md); updated thread index and shared TODO disposition only.

## Checks and outcomes

Exact runner, comparison, replay and audit commands, executable paths, source/policy identities and output links are in the finding. `tools/simulate.py run` used unique output paths and `--timeout 240` throughout. Four canonical and four variant first-release cases completed at cycle 13. Four canonical and four variant Studio continuations deliberately stopped at the five-command bound at cycle 16; every specified action was accepted and all eight emitted valid Studio checkpoints. Canonical and variant state digests/cash/commands matched at both boundaries. The eight paired continuations all completed game two at cycle 29. Four comparison reports verified exact starting state/RNG. Twelve fresh-process `tools/simulate.py replay` calls returned `ok=true`, `telemetry_verified=true`. `analyze_eligible_sales_v1.py` passed its four pair reconciliations.

Private-variant import passed. Campaign Session: 81 steps/55 reentrant checks, zero failures. Finance Observation: 108 checks/21 comparisons, zero failures. Bank Loan: 14,112 checks, zero failures. Separate Education Atomicity: 36 checks, zero failures. Education Debt and Education Edges were **incomplete**: both reached a legacy fixture path outside the isolated variant; Debt emitted a script error despite exit 0/printed zero failures, and Edges was interrupted after its script error. Logs are retained; neither is reported as a clean pass.

## Outcome and follow-up

Four eligible $500/12-month quotes issued at cycle 16. Four matched loan/control pairs completed identical actions and second releases. Borrowing raised c29 cash by $226.23 while leaving $249.98 principal; debt-adjusted cash was $23.75 lower, equal to interest paid so far. No financial block was rescued in these adequately funded routes. The next design question is an eligible high-sales/low-cash spend-down route, per the handoff. No Bank balance rule or gameplay adoption was approved.
