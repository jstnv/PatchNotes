# Beta extension and legal recovery loan — predeclared one-case test, 2026-10-27

**Design status:** private diagnostic only. The [user-selected Beta direction](2026-10-26-beta-qa-marketing-loan-direction-v1.md) ranks QA before Marketing, funds useful extra Beta work and considers legal Bank quotes. No five-hand allowance, principal/term or loan trigger is approved gameplay.

## Question and hypothesis

For the already frozen all-Features Adventure stress Studio, will two further legal Beta hands materially reduce Bugs and raise Review, and does an exact recovery quote become available when cash falls below three rents? Hypothesis: the fourth/fifth hand can improve Review if Search/Debug actually appears and is chosen; an extra hand may instead add Marketing or be unaffordable. No 8.0 result or loan acceptance is presumed. The selector is unchanged and uses only public observations; hidden Bugs are evaluated only after launch.

## Arms and legal start

- **A:** frozen `all-features-cash2000-beta3-20261026-v3c` control, existing three Beta hands, no borrowing. Re-run once rather than relying only on its historical report.
- **B:** new child variant of A, same full owned-Feature supply, cash and Review/finance/calendar rules, but a *diagnostic five-hand ceiling*; never request a loan.
- **C:** same child variant and five-hand ceiling; after four Beta hands, if cash is below three actual rents, request one current exact `CampaignSession.quote_bank(150000,12)`. Accept only if `accepted=true` and the quote's net proceeds are positive. No synthetic cash or eligibility bypass. If the quote is unavailable, continue with ordinary legal choices; retain the rejection observation. This is a trial quote probe, not a selected principal or term.

All three use the fresh legal recipe `studio_id=all-features-adventure-4417`, Adventure specialty/project, Fantasy Theme, no traits, seed `4417`, the variant's 42 owned Features and $7,700 cycle-zero finance state. Each is one release target, maximum 180 commands, and runner `--timeout 240` per isolated import/process. Stop at the first legal release, rejected action, blocked policy or command/timeout limit. Do not modify seed, supply, cash, quote or budget after observing results. B/C case IDs differ, but their recipe and policy inputs other than the loan flag match. A versus B/C are different gameplay-policy revisions; compare initial full state and typed RNG, then the common command prefix and declared policy delta. Never edit checkpoint identities.

## Measures and stopping screen

Capture accepted hand and loan commands, actual Search/Debug/Marketing effects, Scope, four Core values, remaining Bugs, Review, release cycle, cash, arrears, typed loan balance/schedule and completed commands. Verify whether quote acceptance and net proceeds were genuinely legal and whether debt service is observed before the one-release stop; mark later repayment unmeasured if not. Inspect any finance/QA telemetry mismatch, preserve failures and replay A and one changed B/C case in fresh processes. A single synthetic Studio cannot establish the two-rival or eight-rival population effect, player market pressure, real opening Store access, loan viability through repayment, or CPU limit. A follow-up cohort study is needed before implementation handoff.

At declaration: shared `main` HEAD `087df09d653858b72c6e2dc344352237433dd3ac`, heavily dirty checkout. Only the new child variant's `project/` copy will be edited. Preserve shared edits, `.codex-godot-temp`, prior variants, outputs and player saves. No canonical gameplay/TODO edit, commit, push or computer control.
