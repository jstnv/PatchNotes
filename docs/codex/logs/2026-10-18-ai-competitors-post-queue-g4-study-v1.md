# AI Competitors after queue review and G4 quote study — 2026-10-18

## Source and scope

The user confirmed the latest implementation queue and AI intake review are done, with no separate active-market branch or PR. Read `CURRENT_STATE.md`, `TODO.md`, `README.md`, relevant AI decisions, design and findings; inspected source, branch, HEAD, status and diff. Repository `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; the shared worktree was dirty and continued changing during simulator capture. All existing edits and `.codex-godot-temp` were preserved. No canonical gameplay edit, commit or push was made by this design pass.

The [implementation intake](../findings/queue-20261018-v1/AI-REVIEW.md) completed a sealed v29 review, not adoption. The locally implemented AI scope remains the ACTIVE/TRIAL two-rival foundation plus neutral real-release index. Active Review/sales pressure, detailed AI, entrants, news and leaderboard remain OPEN. Current canonical source inspection found no active market transaction/standard/factor code.

## Changed records

- `docs/codex/DECISIONS.md`: corrected the neutral release index from QUEUED to IMPLEMENTED locally and clarified that market influence on Reviews is OPEN within the later user-directed scope.
- `docs/codex/threads/ai-competitors/README.md`: reconciled the completed intake and linked the new G4 study.
- `docs/codex/TODO.md`: added the minimal item 22 G4 DESIGN-review disposition; no implementation queue or trial-value approval.
- Thread-owned G4 plan, inputs, private variants, retained simulation/replay outputs, [finding](../threads/ai-competitors/2026-10-18-g4-current-hand-finding-v1.md), [design review](../threads/ai-competitors/2026-10-18-g4-current-hand-quote-design-review-v1.md) and [sealed quote-only packet](../threads/ai-competitors/handoffs/g4-current-hand-quote-20261018-v1/HANDOFF.md) were created for evidence. Only private `project/` source was edited.

## Checks and outcome

- Existing canonical control: first capture **INCOMPLETE** from concurrent `hand_presentation.gd` drift before any case; same-input retry 4/4 legal releases. A newly captured unchanged private v1 baseline supplied the valid same-source comparator.
- Quote-and-test-policy v2: four reference routes and four cheapest-affordable routes completed one legal release in 18 commands each; reference and frozen control matched full actions/state/RNG. Cheapest saved $480–$560 at first launch but lost 1.3–1.7 Review points. Studio-only Action/4417 continuations both made a second release; cheapest ended at Review 1.0/$2,488.60/7 Fans versus reference 2.6/$3,136.78/12 Fans. Exact fresh-process replays passed for sampled openings and continuations.
- Quote-only v3: four reference routes matched frozen-control actions/state/RNG. Focused exact quote verifier **207/0** on v2 and v3, including 35 unique current-hand combinations, repeated observation purity and selected quote-to-play receipt/next-cash equality. Actual two-rival 20-cycle verifiers passed **118/0** each on frozen v1 and v3 with identical cycle/release traces. The v3 sealed handoff has a one-file private delta, no current overlap at capture and is **not adopted**.
- Measured four-route `policy_and_observation_us` was 2.14–3.50× the unchanged baseline with the 35-quote observation. Population CPU limits remain OPEN; unavailable quote reasons and negative-state/all-choice execution coverage are also missing. The read-only quote shape is retained as a DESIGN candidate; cheapest-only AI is rejected for the sampled challenge objective. No market coefficient or hand-count rule was selected.
- `git -c core.whitespace=cr-at-eol diff --check -- docs/codex/DECISIONS.md docs/codex/TODO.md docs/codex/threads/ai-competitors/README.md` — **PASS**. All five current review/study/handoff links checked with `Test-Path` — **True**. Agent packet integrity check: **13/13** files. No full current-canonical Gameplay/export acceptance was run or claimed for this private study.

Next design work is a bounded observation/world CPU budget and optimized shared or selective quote with explicit unavailable reasons, followed by a benefit-versus-cost/legal-exit policy study. Item 22 remains PARTIAL; active market effects require their own numerical and source-reconciliation ruling.
