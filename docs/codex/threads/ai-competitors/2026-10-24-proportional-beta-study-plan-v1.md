# Proportional rival Beta hands — bounded design study, 2026-10-24

**User direction:** Beta effort should scale with hands played in Design and Alpha. The proportional formula is **OPEN**; this plan authorizes only a private simulator comparison, not canonical adoption.

## Source and hypothesis

Current local source `main`/`0132c4dab398a2a94dbeae3caa68a36505fbfa4f` has Feature-exhaustion Design/Alpha and fixed two-hand Beta. Its [source-pinned world](sims/rival-feature-exhaustion-canonical-world-4417-20261024-v1/world-report.json) produced ten rival titles by player cycle56, mean Review5.00, one Review≥6.0. Counting distinct accepted play sequence IDs in its ten completed projects gives Design+Alpha 7–10 hands and two Beta hands each. A proportional third may offer more Search/Debug opportunities, but additional productive cycles and rent may lower publication density or block a project.

## Comparison fixed before runs

- A: unchanged canonical two-Beta-hand policy, using a freshly captured current-source bundle. Previously recorded world is contextual only; matching must verify the fresh A source and initial state/RNG.
- B: private simulator variant of that exact source. `Beta target = max(2, ceil((Design hands + Alpha hands)/3))`. Count only accepted productive Design/Alpha hands; Beta redraws and phase transitions do not count. Current trial rivals use only hand plays, so a project-cycle minus completed-Beta-hand calculation is a temporary candidate adapter. Do not treat it as a future-proof ledger if host playtests, redraws or other productive actions enter this policy.
- Alternative retained: one Beta per two Design/Alpha hands, rounded down, would produce 3–5 Beta hands in the observed ten releases; it is not the first tested arm because longer project delay could reduce market presence further. Fixed two is control; one-to-one Beta is rejected as disproportionate to existing production time.
- Keep the actual Beta hand selector, current cash/calendar/rent, two incumbent resources and market coefficients unchanged. No extra cards, Bugs, Review, sales or cash are injected. Ordinary legal exit/confirmation/launch and blocked results remain authoritative. No cap is implied by the trial formula; overflow, infeasible hand and affordability must be reported rather than silently bypassed.

## Cases, measurements and stops

Use legal new-game Action/Fantasy route at seeds `4417` and `4418`, each with identical source-matched A/B initial state and typed RNG. Run seed4417 first; stop numerical extension if B has a legal command rejection, timeout, source drift or replay mismatch. Use existing world-study bounds: at most210 player commands, eight player releases, cycle64, twelve zero-cycle steps and 480 seconds per world process. Never change seed or budget to rescue an arm.

Record per rival completed and right-censored project: Design/Alpha/Beta productive hands, Scope, Core, known/remaining Bugs, Review, publication cycle, cash/bills, Beta Search/Debug availability and selected hands. Report total rival titles, Review≥6/≥7, mean Review, player earned/paid units, cash, Fans, market pressure, run time and checkpoint size at the fixed horizon. Run source-pinned focused legality checks and fresh-process exact replay plus Studio-only Continue on representative B. Keep failed, timed-out and incomplete cases.

**Stopping/ruling boundary:** Passing runs establish only the effect of this candidate ratio. They cannot approve it while reliable Review quality, actual title density/player pressure, cash solvency and population CPU remain uncertain. If the candidate clearly worsens publication density without meaningful quality gain, return to design before any handoff. All values remain OPEN until a dated decision; no TODO implementation entry or canonical gameplay edit follows from a study alone.
