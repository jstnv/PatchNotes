# Contract challenges: approved direction and open terms

2026-10-17 (America/Los_Angeles). This is this design thread's decision record. It does not activate candidate values in the authoritative game.

## Approved direction from the user

- Add challenges to Contract runs for current publishers, with an extensible set of challenge types. The requested types are no redraws, balanced Core categories with a dominant-category penalty, a high Core-to-Scope ratio, specific target scores with penalties above and below, and a Scope ceiling with an overage penalty. More types may follow.
- Keep Ironclad introductory. It has no challenge in the first rollout.
- Challenge performance controls a **separate bonus**. Missing a challenge does not lower today's acceptance receipt, completion cash, or base Promotion.
- The separate bonus awards **both cash and Promotion**. The exact caps and rounding remain OPEN.

## Candidate pilot, not approved

The private [v3 scorer](simulators/contracts-challenges-v3/README.md) assigns SideStreet no-redraw and Scope ceiling, Crown balanced Cores, Neon Core-to-Scope ratio, and Starwave target Core scores. It combines multiple conditions by the lowest grade, 0–10,000 basis points. The exact publisher assignments, targets, fade curves, grading policy, cash cap, Promotion cap, and UI words are **CANDIDATE**. The [finding](CHALLENGES-FINDINGS-2026-10-17-v1.md) tests only the scorer and baseline isolation.

For a first playable pilot, the thread recommends a **candidate** maximum of $100 cash plus 4 Promotion per challenged Contract, each scaled by the final grade and rounded down. The user has approved the two reward currencies, **not** these amounts or the partial-grade formula. Review them against the publisher map and legal attainable routes before marking them ACTIVE/TRIAL.

## Implementation boundary

No challenge reward is currently earned in canonical gameplay. An adoption decision needs a complete, versioned rule for successful redraw tracking, score timing, cash and Promotion bonus calculation, player-facing explanation, finance posting, exactly-once results, and checkpoint validation/migration. Old completed Contracts must retain their original settlement semantics. The [proposed handoff](CHALLENGES-HANDOFF-2026-10-17-v1.md) details acceptance criteria. Existing ACTIVE/TRIAL publisher terms remain intact.
